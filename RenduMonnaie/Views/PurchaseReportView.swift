//
//  PurchaseReportView.swift
//  Comptoir de change
//
//  Mise en page du bilan de voyage exporté en PDF : résumé et détail de
//  chaque achat (devise, montants, lieu). Couleurs figées en clair, quel
//  que soit le thème de l'appareil au moment de l'export — un PDF se lit
//  et s'imprime sur fond blanc.
//

import SwiftUI

struct PurchaseReportView: View {

    struct Row: Identifiable {
        let entry: PurchaseEntry
        let placeName: String?
        var id: UUID { entry.id }
    }

    /// Type des transactions du rapport : toutes les lignes partagent le même type,
    /// achats et ventes étant exportés séparément.
    let kind: TransactionKind
    /// Transactions triées chronologiquement, du plus ancien au plus récent.
    let rows: [Row]
    let summary: JournalSummary
    /// Devise choisie pour le total du bilan (l'euro par défaut, mais personnalisable).
    let totalCurrencyCode: String
    let total: Double
    let generatedAt: Date

    private let pageWidth: CGFloat = 595   // largeur A4, en points

    private var groupedRows: [(day: Date, rows: [Row])] {
        let calendar = Calendar.autoupdatingCurrent
        let groups = Dictionary(grouping: rows) { calendar.startOfDay(for: $0.entry.date) }
        return groups.keys.sorted().map { day in
            (day, groups[day]!.sorted { $0.entry.date < $1.entry.date })
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            summarySection
            if !rows.isEmpty {
                Divider().overlay(Color.black.opacity(0.15))
                detailSection
            }
        }
        .padding(32)
        .frame(width: pageWidth, alignment: .leading)
        .background(Color.white)
        .foregroundStyle(Color.black)
    }

    // MARK: - En-tête

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(kind.summaryTitle)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .tracking(2.5)
                .foregroundStyle(Color.accentGreen)
            Text("Comptoir de change")
                .font(.system(size: 11))
                .foregroundStyle(Color.black.opacity(0.5))
            Text("Généré le \(Fmt.time(generatedAt))")
                .font(.system(size: 10))
                .foregroundStyle(Color.black.opacity(0.4))
        }
    }

    // MARK: - Résumé

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(totalHeaderLabel)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(Color.black.opacity(0.5))
            Text(totalAmountText)
                .font(.system(size: 30, weight: .bold, design: .monospaced))
            Text(countLabel)
                .font(.system(size: 12))
                .foregroundStyle(Color.black.opacity(0.55))

            VStack(alignment: .leading, spacing: 6) {
                ForEach(summary.totals) { total in
                    totalRow(total)
                }
            }
            .padding(.top, 4)
        }
    }

    private var countLabel: String { kind.countRegistered(summary.count) }
    private var totalHeaderLabel: LocalizedStringKey { "TOTAL EN \(totalCurrencyCode)" }
    private var totalAmountText: String {
        "≈ " + Fmt.amount(total, currency: CurrencyCatalog.currency(totalCurrencyCode)) + " " + totalCurrencyCode
    }

    private func totalRow(_ total: JournalSummary.CurrencyTotal) -> some View {
        let currency = CurrencyCatalog.currency(total.code)
        return HStack(spacing: 8) {
            Text("\(currency.flag) \(total.code)")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
            Spacer()
            Text("\(Fmt.amount(total.totalPrice + total.totalTip, currency: currency)) \(total.code)")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
            Text(verbatim: "(\(kind.count(total.count)))")
                .font(.system(size: 11))
                .foregroundStyle(Color.black.opacity(0.45))
        }
    }

    // MARK: - Détail

    private var detailSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(kind.detailSectionTitle)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .tracking(1.5)
                .foregroundStyle(Color.black.opacity(0.5))

            ForEach(groupedRows, id: \.day) { group in
                VStack(alignment: .leading, spacing: 10) {
                    Text(Fmt.day(group.day))
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.6)
                        .textCase(.uppercase)
                        .foregroundStyle(Color.black.opacity(0.55))

                    ForEach(group.rows) { row in
                        rowView(row)
                    }
                }
            }
        }
    }

    private func rowView(_ row: Row) -> some View {
        let entry = row.entry
        let priceCurrency = CurrencyCatalog.currency(entry.priceCurrencyCode)
        let paidCurrency = CurrencyCatalog.currency(entry.paidCurrencyCode)
        let changeCurrency = CurrencyCatalog.currency(entry.changeCurrencyCode)
        return VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline) {
                Text(entry.note.isEmpty ? entry.kind.label : entry.note)
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("\(Fmt.amount(entry.totalPrice, currency: priceCurrency)) \(entry.priceCurrencyCode)")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
            }
            Text(Fmt.dateAndTime(entry.date))
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Color.black.opacity(0.4))
            Text("Reçu \(Fmt.amount(entry.receivedAmount, currency: paidCurrency)) \(entry.paidCurrencyCode) · rendu \(Fmt.amount(entry.changeAmount, currency: changeCurrency)) \(entry.changeCurrencyCode)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color.black.opacity(0.6))
            Text("📍 \(row.placeName ?? String(localized: "Lieu non disponible"))")
                .font(.system(size: 11))
                .foregroundStyle(Color.black.opacity(0.5))
        }
        .padding(.bottom, 4)
    }
}

#Preview {
    PurchaseReportView(
        kind: .achat,
        rows: [
            .init(
                entry: PurchaseEntry(
                    note: "Café",
                    priceCurrencyCode: "EUR", price: 4.5,
                    paidCurrencyCode: "USD", receivedAmount: 10,
                    changeAmount: 5.06, changeCurrencyCode: "EUR",
                    rate: 0.9
                ),
                placeName: "Paris, France"
            ),
        ],
        summary: [
            PurchaseEntry(
                priceCurrencyCode: "EUR", price: 4.5,
                paidCurrencyCode: "USD", receivedAmount: 10,
                changeAmount: 5.06, changeCurrencyCode: "EUR",
                rate: 0.9
            ),
        ].summary,
        totalCurrencyCode: "EUR",
        total: 4.5,
        generatedAt: Date()
    )
}

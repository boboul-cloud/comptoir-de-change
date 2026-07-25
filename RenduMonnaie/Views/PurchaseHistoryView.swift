//
//  PurchaseHistoryView.swift
//  Comptoir de change
//
//  Journal des achats enregistrés et bilan financier de fin de voyage.
//

import SwiftUI

struct PurchaseHistoryView: View {
    let journal: PurchaseJournal
    let rateStore: RateStore
    let locationService: LocationService

    @Environment(\.dismiss) private var dismiss
    @State private var confirmingClear = false
    @State private var selectedEntry: PurchaseEntry?
    @State private var isPreparingReport = false
    @State private var reportURL: URL?
    @State private var showReportShareSheet = false

    private var summary: JournalSummary { journal.summary }

    private var groupedEntries: [(day: Date, entries: [PurchaseEntry])] {
        let calendar = Calendar.autoupdatingCurrent
        let groups = Dictionary(grouping: journal.entries) { calendar.startOfDay(for: $0.date) }
        return groups.keys.sorted(by: >).map { day in
            (day, groups[day]!.sorted { $0.date > $1.date })
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if journal.entries.isEmpty {
                        emptyState
                    } else {
                        summaryCard
                        ForEach(groupedEntries, id: \.day) { group in
                            dayGroup(group)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
            .background(Color.paperBG.ignoresSafeArea())
            .navigationTitle("Historique des achats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
                if !journal.entries.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        if isPreparingReport {
                            ProgressView()
                        } else {
                            Menu {
                                Button {
                                    Task { await prepareReport() }
                                } label: {
                                    Label("Exporter le bilan en PDF", systemImage: "square.and.arrow.up")
                                }
                                Button(role: .destructive) {
                                    confirmingClear = true
                                } label: {
                                    Label("Nouveau voyage", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                            .accessibilityLabel("Options du journal")
                        }
                    }
                }
            }
            .confirmationDialog(
                "Effacer l'historique ?",
                isPresented: $confirmingClear,
                titleVisibility: .visible
            ) {
                Button("Supprimer", role: .destructive) { journal.clear() }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Cette action supprimera définitivement les achats enregistrés de ce voyage. Elle est irréversible.")
            }
            .sheet(item: $selectedEntry) { entry in
                PurchaseDetailView(entry: entry)
            }
            .sheet(isPresented: $showReportShareSheet) {
                if let reportURL {
                    ActivityView(activityItems: [reportURL])
                }
            }
        }
    }

    // MARK: - Bilan

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("BILAN DU VOYAGE")
                .scaledFont(11, weight: .bold, design: .monospaced)
                .tracking(2.5)
                .foregroundStyle(.white.opacity(0.55))

            Text(countLabel)
                .scaledFont(12, design: .monospaced)
                .foregroundStyle(.white.opacity(0.75))

            VStack(alignment: .leading, spacing: 2) {
                Text("TOTAL EN EUROS")
                    .scaledFont(10, weight: .semibold, design: .monospaced)
                    .tracking(2)
                    .foregroundStyle(Color.accentGold)
                Text("≈ \(Fmt.amount(totalInEUR, currency: CurrencyCatalog.currency("EUR"))) €")
                    .scaledFont(34, weight: .bold, design: .monospaced)
                    .foregroundStyle(Color.cream)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            .padding(.vertical, 2)

            Divider().overlay(.white.opacity(0.12))

            VStack(spacing: 12) {
                ForEach(summary.totals) { totalRow($0) }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.boardBG, in: .rect(cornerRadius: 14))
    }

    private var countLabel: String {
        summary.count == 1
            ? String(localized: "1 achat enregistré")
            : String(localized: "\(summary.count) achats enregistrés")
    }

    /// Somme, en euros au cours actuel, de tous les achats toutes devises confondues.
    private var totalInEUR: Double {
        summary.totals.reduce(0) { partial, total in
            let rate = total.code == "EUR" ? 1 : rateStore.rate(from: total.code, to: "EUR")
            guard rate > 0 else { return partial }
            return partial + (total.totalPrice + total.totalTip) * rate
        }
    }

    private func totalRow(_ total: JournalSummary.CurrencyTotal) -> some View {
        let currency = CurrencyCatalog.currency(total.code)
        return VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(currency.flag) \(total.code)")
                    .scaledFont(13, weight: .semibold, design: .monospaced)
                    .foregroundStyle(Color.accentGold)
                Spacer()
                Text("\(Fmt.amount(total.totalPrice + total.totalTip, currency: currency)) \(total.code)")
                    .scaledFont(18, weight: .bold, design: .monospaced)
                    .foregroundStyle(Color.cream)
            }
            Text(detailText(total))
                .scaledFont(11, design: .monospaced)
                .foregroundStyle(.white.opacity(0.5))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func detailText(_ total: JournalSummary.CurrencyTotal) -> String {
        var parts = [
            total.count == 1 ? String(localized: "1 achat") : String(localized: "\(total.count) achats"),
        ]
        if total.totalTip > 0 {
            let currency = CurrencyCatalog.currency(total.code)
            parts.append(String(localized: "dont \(Fmt.amount(total.totalTip, currency: currency)) de pourboire"))
        }
        if let eur = eurEquivalent(total) {
            parts.append(eur)
        }
        return parts.joined(separator: " · ")
    }

    /// Contre-valeur approximative en euros, au cours actuel — un repère utile
    /// quand le voyage mélange plusieurs devises.
    private func eurEquivalent(_ total: JournalSummary.CurrencyTotal) -> String? {
        guard total.code != "EUR" else { return nil }
        let rate = rateStore.rate(from: total.code, to: "EUR")
        guard rate > 0 else { return nil }
        let value = (total.totalPrice + total.totalTip) * rate
        return "≈ " + Fmt.amount(value, currency: CurrencyCatalog.currency("EUR")) + " €"
    }

    // MARK: - Journal

    private func dayGroup(_ group: (day: Date, entries: [PurchaseEntry])) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Fmt.day(group.day))
                .scaledFont(11, weight: .semibold)
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(group.entries.enumerated()), id: \.element.id) { index, entry in
                    row(entry)
                    if index < group.entries.count - 1 {
                        Divider().overlay(Color.cardLine)
                    }
                }
            }
            .padding(.horizontal, 16)
            .background(Color.cardBG, in: .rect(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.cardLine, lineWidth: 1))
        }
    }

    private func row(_ entry: PurchaseEntry) -> some View {
        let priceCurrency = CurrencyCatalog.currency(entry.priceCurrencyCode)
        let paidCurrency = CurrencyCatalog.currency(entry.paidCurrencyCode)
        let changeCurrency = CurrencyCatalog.currency(entry.changeCurrencyCode)
        return HStack(alignment: .top, spacing: 10) {
            Button {
                selectedEntry = entry
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 5) {
                            Text(entry.note.isEmpty ? String(localized: "Achat") : entry.note)
                                .scaledFont(14, weight: .semibold)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            if entry.hasLocation {
                                Image(systemName: "mappin.circle.fill")
                                    .scaledFont(11)
                                    .foregroundStyle(Color.accentGreen)
                            }
                        }
                        Text("\(Fmt.amount(entry.receivedAmount, currency: paidCurrency)) \(entry.paidCurrencyCode) → \(Fmt.amount(entry.changeAmount, currency: changeCurrency)) \(entry.changeCurrencyCode) rendus")
                            .scaledFont(11, design: .monospaced)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(Fmt.amount(entry.totalPrice, currency: priceCurrency)) \(entry.priceCurrencyCode)")
                            .scaledFont(14, weight: .semibold, design: .monospaced)
                        Text(Fmt.clock(entry.date))
                            .scaledFont(11, design: .monospaced)
                            .foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                delete(entry)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .scaledFont(15)
                    .foregroundStyle(.secondary.opacity(0.5))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Supprimer cet achat")
        }
        .padding(.vertical, 12)
    }

    private func delete(_ entry: PurchaseEntry) {
        guard let index = journal.entries.firstIndex(where: { $0.id == entry.id }) else { return }
        withAnimation { journal.remove(at: IndexSet(integer: index)) }
    }

    // MARK: - État vide

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bag")
                .scaledFont(34)
                .foregroundStyle(Color.accentGreen)
            Text("Aucun achat enregistré")
                .scaledFont(17, weight: .semibold)
            Text("Enregistre un achat depuis l'écran principal pour construire ton bilan de voyage.")
                .scaledFont(13)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.top, 80)
    }

    // MARK: - Partage

    /// Reconstitue le lieu de chaque achat (géocodage inverse quand une position a été
    /// relevée), puis met en page et exporte le bilan détaillé en PDF avant de proposer
    /// le partage système.
    private func prepareReport() async {
        isPreparingReport = true
        defer { isPreparingReport = false }

        var rows: [PurchaseReportView.Row] = []
        for entry in journal.entries.sorted(by: { $0.date < $1.date }) {
            var placeName: String?
            if let latitude = entry.latitude, let longitude = entry.longitude {
                placeName = await locationService.placeName(latitude: latitude, longitude: longitude)
            }
            rows.append(.init(entry: entry, placeName: placeName))
        }

        let report = PurchaseReportView(
            rows: rows,
            summary: summary,
            totalInEUR: totalInEUR,
            generatedAt: Date()
        )

        if let url = PDFExporter.export(report, fileName: "Bilan-de-voyage.pdf") {
            reportURL = url
            showReportShareSheet = true
        }
    }
}

#Preview {
    let journal = PurchaseJournal(defaults: UserDefaults(suiteName: "preview-history")!)
    journal.add(PurchaseEntry(
        note: "Café",
        priceCurrencyCode: "EUR", price: 4.5,
        paidCurrencyCode: "USD", receivedAmount: 10,
        changeAmount: 5.06, changeCurrencyCode: "EUR",
        rate: 0.9
    ))
    return PurchaseHistoryView(journal: journal, rateStore: RateStore(), locationService: LocationService())
}

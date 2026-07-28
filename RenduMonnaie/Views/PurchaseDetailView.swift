//
//  PurchaseDetailView.swift
//  Comptoir de change
//
//  Détail d'un achat du journal, avec le lieu relevé au moment de
//  l'enregistrement, s'il a pu être obtenu.
//

import SwiftUI
import MapKit

struct PurchaseDetailView: View {
    let entry: PurchaseEntry

    @Environment(\.dismiss) private var dismiss

    private var coordinate: CLLocationCoordinate2D? {
        guard let latitude = entry.latitude, let longitude = entry.longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ticketCard
                    if let coordinate {
                        mapCard(at: coordinate)
                    } else {
                        noLocationCard
                    }
                }
                .padding(16)
            }
            .background(Color.paperBG.ignoresSafeArea())
            .navigationTitle(entry.note.isEmpty ? entry.kind.label : entry.note)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }

    // MARK: - Ticket

    private var ticketCard: some View {
        let priceCurrency = CurrencyCatalog.currency(entry.priceCurrencyCode)
        let paidCurrency = CurrencyCatalog.currency(entry.paidCurrencyCode)
        let changeCurrency = CurrencyCatalog.currency(entry.changeCurrencyCode)

        return VStack(spacing: 14) {
            Text(entry.kind.label)
                .scaledFont(10, weight: .bold, design: .monospaced)
                .tracking(2)
                .foregroundStyle(Color.accentGreen)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.accentGreen.opacity(0.15), in: .capsule)

            Text(Fmt.time(entry.date))
                .scaledFont(11, design: .monospaced)
                .tracking(1.5)
                .foregroundStyle(.white)

            Text("\(Fmt.amount(entry.totalPrice, currency: priceCurrency)) \(entry.priceCurrencyCode)")
                .scaledFont(34, weight: .bold, design: .monospaced)
                .foregroundStyle(Color.cream)

            if entry.tipAmount > 0 {
                Text("dont \(Fmt.amount(entry.tipAmount, currency: priceCurrency)) \(entry.priceCurrencyCode) de pourboire")
                    .scaledFont(11, design: .monospaced)
                    .foregroundStyle(Color.accentGold)
            }

            Divider().overlay(.white.opacity(0.12))

            VStack(spacing: 8) {
                detailRow("Reçu", "\(Fmt.amount(entry.receivedAmount, currency: paidCurrency)) \(entry.paidCurrencyCode)")
                detailRow("Rendu", "\(Fmt.amount(entry.changeAmount, currency: changeCurrency)) \(entry.changeCurrencyCode)")
                detailRow("Taux appliqué", "\(Fmt.rate(entry.rate))")
                if entry.commissionAmount > 0 {
                    detailRow("Commission", "\(Fmt.amount(entry.commissionAmount, currency: priceCurrency)) \(entry.priceCurrencyCode) (\(Fmt.rate(entry.commissionPercent))%)")
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.boardBG, in: .rect(cornerRadius: 14))
    }

    private func detailRow(_ label: LocalizedStringKey, _ value: String) -> some View {
        HStack {
            Text(label)
                .scaledFont(12, design: .monospaced)
                .foregroundStyle(.white)
            Spacer()
            Text(value)
                .scaledFont(13, weight: .semibold, design: .monospaced)
                .foregroundStyle(Color.cream)
        }
    }

    // MARK: - Lieu

    private func mapCard(at coordinate: CLLocationCoordinate2D) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel(entry.kind.locationLabel)
            Map(initialPosition: .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            )) {
                Marker(entry.note.isEmpty ? entry.kind.label : entry.note, coordinate: coordinate)
                    .tint(Color.accentGreen)
            }
            .frame(height: 260)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.cardLine, lineWidth: 1))
        }
    }

    private var noLocationCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "location.slash")
                .scaledFont(26)
                .foregroundStyle(.secondary)
            Text("Lieu non disponible")
                .scaledFont(14, weight: .semibold)
            Text(entry.kind.locationUnavailableMessage)
                .scaledFont(12)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.cardBG, in: .rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.cardLine, lineWidth: 1))
    }

    private func fieldLabel(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .scaledFont(11, weight: .semibold)
            .tracking(0.8)
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
    }

    /// Variante pour un libellé déjà résolu (ex. dépendant du type de transaction),
    /// affiché tel quel plutôt que relocalisé via le catalogue de chaînes.
    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .scaledFont(11, weight: .semibold)
            .tracking(0.8)
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
    }
}

#Preview {
    PurchaseDetailView(entry: PurchaseEntry(
        note: "Café",
        priceCurrencyCode: "EUR", price: 4.5,
        paidCurrencyCode: "USD", receivedAmount: 10,
        changeAmount: 5.06, changeCurrencyCode: "EUR",
        rate: 0.9,
        latitude: 48.8566, longitude: 2.3522
    ))
}

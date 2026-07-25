//
//  CustomerDisplayView.swift
//  Comptoir de change
//
//  Écran affiché côté client quand le téléphone est retourné vers lui :
//  transparence totale sur le prix, la somme à fournir et la monnaie rendue.
//

import SwiftUI

struct CustomerDisplayView: View {
    let priceAmount: Double
    let priceCurrency: Currency

    let isInsufficient: Bool
    let missingAmount: Double

    let receivedAmount: Double
    let receivedCurrency: Currency

    let changeAmount: Double
    let changeCurrency: Currency
    let changeSecondaryAmount: Double
    let changeSecondaryCurrency: Currency

    let commissionAmount: Double
    let commissionPercent: Double
    let tipAmount: Double
    let tipPercent: Double

    var body: some View {
        VStack(spacing: 28) {
            row(label: "PRIX", value: Fmt.amount(priceAmount, currency: priceCurrency), code: priceCurrency.code)

            Divider().overlay(.white.opacity(0.15))

            if receivedAmount > 0 {
                row(label: "REÇU", value: Fmt.amount(receivedAmount, currency: receivedCurrency), code: receivedCurrency.code)
            }

            Divider().overlay(.white.opacity(0.15))

            if isInsufficient {
                row(label: "IL MANQUE", value: Fmt.amount(missingAmount, currency: priceCurrency), code: priceCurrency.code, accent: Color.dangerRed)
            } else {
                row(label: "MONNAIE RENDUE", value: Fmt.amount(changeAmount, currency: changeCurrency), code: changeCurrency.code)
                Text("soit \(Fmt.amount(changeSecondaryAmount, currency: changeSecondaryCurrency)) \(changeSecondaryCurrency.code)")
                    .scaledFont(15, design: .monospaced)
                    .foregroundStyle(.white.opacity(0.6))
            }

            if commissionAmount > 0 || tipAmount > 0 {
                Divider().overlay(.white.opacity(0.1))
                HStack(spacing: 32) {
                    if commissionAmount > 0 {
                        detailRow(label: "COMMISSION", amount: commissionAmount, currency: priceCurrency, percent: commissionPercent)
                    }
                    if tipAmount > 0 {
                        detailRow(label: "POURBOIRE", amount: tipAmount, currency: priceCurrency, percent: tipPercent)
                    }
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.boardBG)
        .accessibilityElement(children: .combine)
    }

    private func row(label: LocalizedStringKey, value: String, code: String, accent: Color = .cream) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .scaledFont(13, design: .monospaced)
                .tracking(2.5)
                .foregroundStyle(.white.opacity(0.5))
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(value)
                    .scaledFont(40, weight: .bold, design: .monospaced)
                    .foregroundStyle(accent)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(code)
                    .scaledFont(16, design: .monospaced)
                    .foregroundStyle(Color.accentGold)
            }
        }
    }

    private func detailRow(label: LocalizedStringKey, amount: Double, currency: Currency, percent: Double) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .scaledFont(11, design: .monospaced)
                .tracking(2)
                .foregroundStyle(.white.opacity(0.45))
            HStack(spacing: 6) {
                Text("\(Fmt.amount(amount, currency: currency)) \(currency.code)")
                    .scaledFont(15, weight: .semibold, design: .monospaced)
                    .foregroundStyle(Color.accentGold)
                Text("(\(String(format: "%.1f", percent))%)")
                    .scaledFont(12, design: .monospaced)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }
}

#Preview {
    let eur = CurrencyCatalog.currency("EUR")
    let usd = CurrencyCatalog.currency("USD")
    return CustomerDisplayView(
        priceAmount: 49.50,
        priceCurrency: eur,
        isInsufficient: false,
        missingAmount: 0,
        receivedAmount: 60,
        receivedCurrency: usd,
        changeAmount: 3.17,
        changeCurrency: eur,
        changeSecondaryAmount: 3.61,
        changeSecondaryCurrency: usd,
        commissionAmount: 2.50,
        commissionPercent: 3.0,
        tipAmount: 4.50,
        tipPercent: 10.0
    )
}

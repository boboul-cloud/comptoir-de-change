//
//  ResultBoard.swift
//  Comptoir de change
//
//  Le « ticket » sombre qui affiche la monnaie à rendre et son détail.
//

import SwiftUI

struct ResultBoard: View {
    let isInsufficient: Bool
    let mainAmount: Double
    let mainCurrency: Currency
    let breakdown: [CashLine]
    let secondaryAmount: Double
    let secondaryCurrency: Currency
    let missingAmount: Double
    let priceCurrency: Currency

    private var mainText: String { Fmt.amount(max(mainAmount, 0), currency: mainCurrency) }

    var body: some View {
        VStack(spacing: 0) {
            Text(isInsufficient ? "MONTANT INSUFFISANT" : "MONNAIE À RENDRE")
                .scaledFont(11, design: .monospaced)
                .tracking(2.5)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.bottom, 12)

            Text(isInsufficient ? "----.--" : mainText)
                .scaledFont(44, weight: .bold, design: .monospaced)
                .foregroundStyle(isInsufficient ? Color.dangerRed : Color.cream)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text("\(mainCurrency.flag) \(mainCurrency.code)")
                .scaledFont(13, design: .monospaced)
                .tracking(2)
                .foregroundStyle(Color.accentGold)
                .padding(.top, 8)

            if isInsufficient {
                Text("Il manque \(Fmt.amount(missingAmount, currency: priceCurrency)) \(priceCurrency.code)")
                    .scaledFont(12, design: .monospaced)
                    .foregroundStyle(Color.dangerRed.opacity(0.95))
                    .padding(.top, 12)
            } else {
                if !breakdown.isEmpty {
                    Divider().overlay(.white.opacity(0.12)).padding(.vertical, 18)
                    CashBreakdownView(lines: breakdown, currency: mainCurrency)
                }

                Divider().overlay(.white.opacity(0.12)).padding(.top, 16)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("soit")
                        .scaledFont(12, design: .monospaced)
                        .foregroundStyle(.white.opacity(0.5))
                    Text(Fmt.amount(secondaryAmount, currency: secondaryCurrency))
                        .scaledFont(17, weight: .bold, design: .monospaced)
                        .foregroundStyle(Color.cream)
                    Text("\(secondaryCurrency.flag) \(secondaryCurrency.code)")
                        .scaledFont(12, design: .monospaced)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.top, 14)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 26)
        .frame(maxWidth: .infinity)
        .background(Color.boardBG, in: .rect(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        if isInsufficient {
            let manque = Fmt.amount(missingAmount, currency: priceCurrency)
            return String(localized: "Montant insuffisant. Il manque \(manque) \(priceCurrency.code).")
        }
        return String(localized: "Monnaie à rendre : \(mainText) \(mainCurrency.code).")
    }
}

#Preview {
    let eur = CurrencyCatalog.currency("EUR")
    let usd = CurrencyCatalog.currency("USD")
    return ResultBoard(
        isInsufficient: false,
        mainAmount: 47.85,
        mainCurrency: eur,
        breakdown: eur.makeChange(for: 47.85),
        secondaryAmount: 54.62,
        secondaryCurrency: usd,
        missingAmount: 0,
        priceCurrency: eur
    )
    .padding()
    .background(Color.paperBG)
}

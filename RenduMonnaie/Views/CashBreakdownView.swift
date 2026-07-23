//
//  CashBreakdownView.swift
//  Comptoir de change
//
//  Détail des billets et pièces à rendre, affiché sur l'« ardoise ».
//

import SwiftUI

struct CashBreakdownView: View {
    let lines: [CashLine]
    let currency: Currency

    var body: some View {
        VStack(spacing: 10) {
            ForEach(lines) { line in
                HStack(spacing: 12) {
                    Text("\(line.count)")
                        .scaledFont(15, weight: .bold, design: .monospaced)
                        .foregroundStyle(Color.accentGold)
                        .frame(minWidth: 26, alignment: .trailing)

                    Text("×")
                        .scaledFont(13, design: .monospaced)
                        .foregroundStyle(.white.opacity(0.4))

                    Text("\(Fmt.amount(line.value, currency: currency)) \(currency.code)")
                        .scaledFont(15, weight: .medium, design: .monospaced)
                        .foregroundStyle(Color.cream)

                    Spacer(minLength: 8)

                    Text(Fmt.amount(line.total, currency: currency))
                        .scaledFont(13, design: .monospaced)
                        .foregroundStyle(.white.opacity(0.45))
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("\(line.count) fois \(Fmt.amount(line.value, currency: currency)) \(currency.code)"))
            }
        }
    }
}

#Preview {
    let eur = CurrencyCatalog.currency("EUR")
    return CashBreakdownView(lines: eur.makeChange(for: 47.85), currency: eur)
        .padding(24)
        .background(Color.boardBG)
}

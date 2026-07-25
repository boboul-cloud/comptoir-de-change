//
//  CashBreakdown.swift
//  Comptoir de change
//
//  Décomposition d'un montant en billets et pièces d'une devise.
//

import Foundation

/// Une ligne du détail : « 3 × 20 € ».
struct CashLine: Identifiable, Equatable, Sendable {
    let value: Double
    let count: Int
    var id: Double { value }
    var total: Double { value * Double(count) }
}

/// Suggestion de règlement : un montant rond, arrondi à la dizaine supérieure, mis en avant
/// comme solution principale ; le billet entier existant qui couvrirait aussi le montant
/// n'est qu'une information secondaire, quand il diffère du montant arrondi.
struct PaymentSuggestion: Equatable, Sendable {
    let roundedAmount: Double
    let singleBill: Double?
}

extension Currency {

    /// Arrondit un montant au plus proche multiple de l'incrément de caisse
    /// (ex. 4,87 CHF → 4,85 ; 1499,6 ¥ → 1500).
    func roundedToCash(_ amount: Double) -> Double {
        guard cashIncrement > 0 else { return amount }
        return (amount / cashIncrement).rounded() * cashIncrement
    }

    /// Décompose un montant positif en un minimum de billets et de pièces.
    ///
    /// Le calcul se fait en nombres entiers d'incréments de caisse : il est
    /// donc exact, sans erreur d'arrondi sur les flottants.
    func makeChange(for amount: Double) -> [CashLine] {
        guard amount > 0, cashIncrement > 0 else { return [] }

        var remaining = Int((roundedToCash(amount) / cashIncrement).rounded())
        var lines: [CashLine] = []

        for denomination in denominations.sorted(by: >) {
            let step = Int((denomination / cashIncrement).rounded())
            guard step > 0, remaining >= step else { continue }
            let count = remaining / step
            lines.append(CashLine(value: denomination, count: count))
            remaining -= count * step
        }
        return lines
    }

    /// Montant arrondi à la dizaine supérieure permettant de régler `amount` sans faire
    /// l'appoint au centime près, accompagné (à titre indicatif) du billet entier existant
    /// qui couvrirait aussi le montant, s'il existe et diffère du montant arrondi.
    func paymentSuggestion(coveringAtLeast amount: Double) -> PaymentSuggestion? {
        guard amount > 0 else { return nil }
        let roundedAmount = (amount / 10).rounded(.up) * 10
        let bill = denominations.sorted().first(where: { $0 >= amount - 1e-9 })
        return PaymentSuggestion(roundedAmount: roundedAmount, singleBill: bill == roundedAmount ? nil : bill)
    }
}

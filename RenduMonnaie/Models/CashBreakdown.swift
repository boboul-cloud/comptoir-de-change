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
}

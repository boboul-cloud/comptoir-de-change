//
//  ChangeCalculation.swift
//  Comptoir de change
//
//  Logique de calcul du rendu de monnaie, isolée de l'interface pour
//  pouvoir être testée indépendamment.
//

import Foundation

/// Calcul pur du rendu de monnaie entre deux devises.
///
/// - `rate` : nombre d'unités de la devise du prix pour 1 unité de la devise payée.
/// - `price` : prix à payer, exprimé dans la devise du prix.
/// - `received` : montant remis par le client, exprimé dans la devise payée.
/// - `commissionPercent` : marge de change appliquée en faveur du comptoir.
struct ChangeCalculation: Equatable, Sendable {
    var rate: Double
    var price: Double
    var received: Double
    var commissionPercent: Double = 0

    /// Taux effectivement appliqué, commission déduite.
    var effectiveRate: Double { rate * (1 - commissionPercent / 100) }

    /// Montant reçu converti dans la devise du prix (commission incluse).
    var receivedConverted: Double { received * effectiveRate }

    /// Monnaie à rendre dans la devise du prix.
    var changeInPriceCurrency: Double { receivedConverted - price }

    /// Monnaie à rendre dans la devise payée par le client.
    var changeInPaidCurrency: Double {
        effectiveRate != 0 ? changeInPriceCurrency / effectiveRate : 0
    }

    /// `true` si le montant reçu ne couvre pas le prix (tolérance d'un demi-centime).
    var isInsufficient: Bool { changeInPriceCurrency < -0.005 }

    /// Montant manquant (positif) lorsque le paiement est insuffisant.
    var missingInPriceCurrency: Double { max(-changeInPriceCurrency, 0) }
}

extension ChangeCalculation {
    /// Écart, en pourcentage, entre un taux saisi et un taux de référence.
    static func deviationPercent(applied: Double, reference: Double) -> Double {
        guard reference != 0 else { return 0 }
        return abs((applied - reference) / reference) * 100
    }
}

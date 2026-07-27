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
    ///
    /// Reconversion au taux brut (`rate`), pas au taux effectif : la commission n'est
    /// prélevée qu'une fois, au moment de convertir le montant reçu (`receivedConverted`).
    /// La reconvertir une seconde fois ici annulerait une partie de la commission —
    /// le client récupérerait alors plus de monnaie que la commission affichée ne
    /// devrait en laisser, et l'écart grandirait avec le taux de commission.
    var changeInPaidCurrency: Double {
        rate != 0 ? changeInPriceCurrency / rate : 0
    }

    /// Montant retenu par le comptoir au titre de la commission, dans la devise du prix
    /// (écart entre une conversion au taux plein et la conversion effectivement appliquée).
    var commissionAmount: Double { received * rate * commissionPercent / 100 }

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

    /// Montant du pourboire, à partir d'une saisie exprimée en montant ou en pourcentage du prix.
    static func tipAmount(price: Double, input: Double, isPercent: Bool) -> Double {
        isPercent ? price * input / 100 : input
    }

    /// Pourcentage que représente le pourboire par rapport au prix, quelle que soit l'unité saisie.
    static func tipPercent(price: Double, input: Double, isPercent: Bool) -> Double {
        guard !isPercent else { return input }
        guard price != 0 else { return 0 }
        return input / price * 100
    }
}

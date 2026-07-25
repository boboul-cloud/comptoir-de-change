//
//  Currency.swift
//  Comptoir de change
//
//  Modèle de devise (décimales, dénominations, taux legacy) et catalogue.
//

import Foundation

/// Une devise affichable dans le sélecteur.
struct Currency: Identifiable, Hashable, Sendable {
    let code: String
    let flag: String
    let country: String
    /// Nombre de décimales affichées pour cette devise (0 pour le yen, le won…).
    let minorUnitDigits: Int
    /// Plus petite valeur réglable en espèces (0,01 € ; 1 ¥ ; 0,05 CHF…).
    let cashIncrement: Double
    /// Coupures réelles (billets + pièces) ; générées si non fournies.
    private let explicitDenominations: [Double]?
    /// Taux irrévocable vers l'euro (unités pour 1 €) si c'est une ancienne devise.
    let legacyRatePerEUR: Double?

    init(
        code: String,
        flag: String,
        country: String,
        digits: Int = 2,
        increment: Double? = nil,
        denominations: [Double]? = nil,
        legacyRatePerEUR: Double? = nil
    ) {
        self.code = code
        self.flag = flag
        self.country = country
        self.minorUnitDigits = digits
        self.cashIncrement = increment ?? pow(10, Double(-digits))
        self.explicitDenominations = denominations
        self.legacyRatePerEUR = legacyRatePerEUR
    }

    var id: String { code }
    var isLegacy: Bool { legacyRatePerEUR != nil }
    var label: String { "\(flag) \(country) — \(code)\(isLegacy ? " (ancienne)" : "")" }

    /// Coupures disponibles, de la plus grande à la plus petite.
    var denominations: [Double] {
        if let explicit = explicitDenominations { return explicit }
        return Self.ladder(increment: cashIncrement)
    }

    /// Échelle 1–2–5 générée à partir de l'incrément (pour les devises sans table dédiée).
    private static func ladder(increment: Double) -> [Double] {
        let maxValue = increment * 20_000
        var values: [Double] = []
        var scale = increment
        while scale <= maxValue + 1e-9 {
            for base in [1.0, 2.0, 5.0] {
                let v = (scale * base)
                if v <= maxValue + 1e-9 { values.append((v * 100).rounded() / 100) }
            }
            scale *= 10
        }
        return values.sorted(by: >)
    }
}

/// Liste des devises proposées à l'utilisateur.
enum CurrencyCatalog {

    /// Devises courantes.
    private static let modern: [Currency] = [
        .init(code: "AUD", flag: "🇦🇺", country: "Australie", increment: 0.05,
              denominations: [100, 50, 20, 10, 5, 2, 1, 0.5, 0.2, 0.1, 0.05]),
        .init(code: "BGN", flag: "🇧🇬", country: "Bulgarie"),
        .init(code: "BRL", flag: "🇧🇷", country: "Brésil"),
        .init(code: "CAD", flag: "🇨🇦", country: "Canada", increment: 0.05,
              denominations: [100, 50, 20, 10, 5, 2, 1, 0.25, 0.1, 0.05]),
        .init(code: "CHF", flag: "🇨🇭", country: "Suisse", increment: 0.05,
              denominations: [1000, 200, 100, 50, 20, 10, 5, 2, 1, 0.5, 0.2, 0.1, 0.05]),
        .init(code: "CNY", flag: "🇨🇳", country: "Chine", increment: 0.1,
              denominations: [100, 50, 20, 10, 5, 1, 0.5, 0.1]),
        .init(code: "CZK", flag: "🇨🇿", country: "République tchèque", digits: 0),
        .init(code: "DKK", flag: "🇩🇰", country: "Danemark"),
        .init(code: "EUR", flag: "🇪🇺", country: "Zone euro",
              denominations: [500, 200, 100, 50, 20, 10, 5, 2, 1, 0.5, 0.2, 0.1, 0.05, 0.02, 0.01]),
        .init(code: "GBP", flag: "🇬🇧", country: "Royaume-Uni",
              denominations: [50, 20, 10, 5, 2, 1, 0.5, 0.2, 0.1, 0.05, 0.02, 0.01]),
        .init(code: "HKD", flag: "🇭🇰", country: "Hong Kong"),
        .init(code: "HUF", flag: "🇭🇺", country: "Hongrie", digits: 0, increment: 5),
        .init(code: "IDR", flag: "🇮🇩", country: "Indonésie", digits: 0),
        .init(code: "ILS", flag: "🇮🇱", country: "Israël"),
        .init(code: "INR", flag: "🇮🇳", country: "Inde", digits: 0),
        .init(code: "ISK", flag: "🇮🇸", country: "Islande", digits: 0),
        .init(code: "JPY", flag: "🇯🇵", country: "Japon", digits: 0,
              denominations: [10000, 5000, 2000, 1000, 500, 100, 50, 10, 5, 1]),
        .init(code: "KRW", flag: "🇰🇷", country: "Corée du Sud", digits: 0),
        .init(code: "MXN", flag: "🇲🇽", country: "Mexique"),
        .init(code: "MYR", flag: "🇲🇾", country: "Malaisie"),
        .init(code: "NOK", flag: "🇳🇴", country: "Norvège", digits: 0),
        .init(code: "NZD", flag: "🇳🇿", country: "Nouvelle-Zélande", increment: 0.1,
              denominations: [100, 50, 20, 10, 5, 2, 1, 0.5, 0.2, 0.1]),
        .init(code: "PHP", flag: "🇵🇭", country: "Philippines"),
        .init(code: "PLN", flag: "🇵🇱", country: "Pologne"),
        .init(code: "RON", flag: "🇷🇴", country: "Roumanie"),
        .init(code: "SEK", flag: "🇸🇪", country: "Suède", digits: 0),
        .init(code: "SGD", flag: "🇸🇬", country: "Singapour"),
        .init(code: "THB", flag: "🇹🇭", country: "Thaïlande"),
        .init(code: "TRY", flag: "🇹🇷", country: "Turquie"),
        .init(code: "USD", flag: "🇺🇸", country: "États-Unis",
              denominations: [100, 50, 20, 10, 5, 1, 0.25, 0.1, 0.05, 0.01]),
        .init(code: "VND", flag: "🇻🇳", country: "Viêt Nam", digits: 0,
              denominations: [500000, 200000, 100000, 50000, 20000, 10000, 5000, 2000, 1000, 500, 200]),
        .init(code: "ZAR", flag: "🇿🇦", country: "Afrique du Sud"),
    ]

    /// Anciennes devises de la zone euro, à taux de conversion irrévocable.
    private static let legacy: [Currency] = [
        .init(code: "FRF", flag: "🇫🇷", country: "France (franc)", legacyRatePerEUR: 6.55957),
        .init(code: "DEM", flag: "🇩🇪", country: "Allemagne (mark)", legacyRatePerEUR: 1.95583),
        .init(code: "ITL", flag: "🇮🇹", country: "Italie (lire)", digits: 0, legacyRatePerEUR: 1936.27),
        .init(code: "ESP", flag: "🇪🇸", country: "Espagne (peseta)", digits: 0, legacyRatePerEUR: 166.386),
        .init(code: "PTE", flag: "🇵🇹", country: "Portugal (escudo)", digits: 0, legacyRatePerEUR: 200.482),
        .init(code: "BEF", flag: "🇧🇪", country: "Belgique (franc)", legacyRatePerEUR: 40.3399),
        .init(code: "LUF", flag: "🇱🇺", country: "Luxembourg (franc)", legacyRatePerEUR: 40.3399),
        .init(code: "NLG", flag: "🇳🇱", country: "Pays-Bas (florin)", legacyRatePerEUR: 2.20371),
        .init(code: "ATS", flag: "🇦🇹", country: "Autriche (schilling)", legacyRatePerEUR: 13.7603),
        .init(code: "FIM", flag: "🇫🇮", country: "Finlande (mark)", legacyRatePerEUR: 5.94573),
        .init(code: "IEP", flag: "🇮🇪", country: "Irlande (livre)", legacyRatePerEUR: 0.787564),
        .init(code: "GRD", flag: "🇬🇷", country: "Grèce (drachme)", digits: 0, legacyRatePerEUR: 340.750),
    ]

    static let all: [Currency] = modern + legacy

    private static let index: [String: Currency] =
        Dictionary(uniqueKeysWithValues: all.map { ($0.code, $0) })

    /// Taux irrévocables des devises legacy, en « unités pour 1 € ».
    static let legacyRatesEUR: [String: Double] =
        Dictionary(uniqueKeysWithValues: legacy.map { ($0.code, $0.legacyRatePerEUR!) })

    /// Retourne la devise correspondant au code, ou un substitut neutre si inconnu.
    static func currency(_ code: String) -> Currency {
        index[code] ?? .init(code: code, flag: "💱", country: code)
    }

    static func isLegacy(_ code: String) -> Bool { currency(code).isLegacy }
}

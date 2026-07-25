//
//  Formatting.swift
//  Comptoir de change
//
//  Helpers de saisie et d'affichage des nombres et dates.
//

import Foundation

enum Fmt {
    /// Séparateur décimal fixe (point) pour l'esthétique « caisse enregistreuse ».
    private static let tillLocale = Locale(identifier: "en_US_POSIX")

    /// Accepte indifféremment la virgule et le point comme séparateur décimal.
    static func number(_ text: String) -> Double {
        Double(text.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    /// Montant affiché sur le « ticket », avec le nombre de décimales de la devise.
    static func amount(_ value: Double, digits: Int = 2) -> String {
        guard value.isFinite else { return String(repeating: "0", count: 1) }
        return abs(value).formatted(
            .number.precision(.fractionLength(digits)).grouping(.never).locale(tillLocale)
        )
    }

    /// Montant formaté selon les règles d'une devise (yen sans décimales, etc.).
    static func amount(_ value: Double, currency: Currency) -> String {
        amount(value, digits: currency.minorUnitDigits)
    }

    /// Taux de change : précision variable selon l'ordre de grandeur.
    static func rate(_ value: Double) -> String {
        guard value.isFinite, value != 0 else { return "0" }
        let fraction: Int = value >= 1000 ? 2 : (value >= 1 ? 5 : 6)
        return value.formatted(
            .number.precision(.fractionLength(fraction)).grouping(.never).locale(tillLocale)
        )
    }

    /// Horodatage court, dans la langue de l'appareil (« 23 juil. à 14:05 »).
    static func time(_ date: Date) -> String {
        date.formatted(
            .dateTime.locale(.autoupdatingCurrent)
                .day().month(.abbreviated).hour().minute()
        )
    }

    /// Heure seule (« 14:05 »), pour les lignes du journal déjà regroupées par jour.
    static func clock(_ date: Date) -> String {
        date.formatted(.dateTime.locale(.autoupdatingCurrent).hour().minute())
    }

    /// Date et heure complètes, année incluse (« 25 juillet 2026 à 17:55 ») — pour les
    /// documents exportés, destinés à être relus bien après l'écran qui les a produits.
    static func dateAndTime(_ date: Date) -> String {
        date.formatted(
            .dateTime.locale(.autoupdatingCurrent)
                .day().month(.wide).year().hour().minute()
        )
    }

    /// Étiquette de jour pour les regroupements du journal (« Aujourd'hui », « Hier »,
    /// ou date complète).
    static func day(_ date: Date) -> String {
        let calendar = Calendar.autoupdatingCurrent
        if calendar.isDateInToday(date) { return String(localized: "Aujourd'hui") }
        if calendar.isDateInYesterday(date) { return String(localized: "Hier") }
        return date.formatted(
            .dateTime.locale(.autoupdatingCurrent)
                .day().month(.wide).year()
        )
    }
}

extension String {
    /// `nil` plutôt qu'une chaîne vide — pratique pour chaîner des valeurs optionnelles
    /// construites par concaténation (ex. un lieu géocodé sans composant disponible).
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

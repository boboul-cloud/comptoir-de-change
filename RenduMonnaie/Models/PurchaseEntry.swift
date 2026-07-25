//
//  PurchaseEntry.swift
//  Comptoir de change
//
//  Un achat enregistré depuis l'écran de calcul, et le bilan qui s'en déduit
//  pour le voyage.
//

import Foundation

/// Un achat conservé dans le journal de voyage.
struct PurchaseEntry: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var date: Date
    var note: String

    /// Devise et prix affiché en caisse (hors pourboire).
    var priceCurrencyCode: String
    var price: Double
    var tipAmount: Double

    /// Devise et montant remis par le client.
    var paidCurrencyCode: String
    var receivedAmount: Double

    /// Monnaie effectivement rendue.
    var changeAmount: Double
    var changeCurrencyCode: String

    var rate: Double
    var commissionPercent: Double
    var commissionAmount: Double

    /// Position relevée au moment de l'enregistrement (absente si la localisation
    /// n'était pas autorisée ou disponible à cet instant).
    var latitude: Double?
    var longitude: Double?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        note: String = "",
        priceCurrencyCode: String,
        price: Double,
        tipAmount: Double = 0,
        paidCurrencyCode: String,
        receivedAmount: Double,
        changeAmount: Double,
        changeCurrencyCode: String,
        rate: Double,
        commissionPercent: Double = 0,
        commissionAmount: Double = 0,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = id
        self.date = date
        self.note = note
        self.priceCurrencyCode = priceCurrencyCode
        self.price = price
        self.tipAmount = tipAmount
        self.paidCurrencyCode = paidCurrencyCode
        self.receivedAmount = receivedAmount
        self.changeAmount = changeAmount
        self.changeCurrencyCode = changeCurrencyCode
        self.rate = rate
        self.commissionPercent = commissionPercent
        self.commissionAmount = commissionAmount
        self.latitude = latitude
        self.longitude = longitude
    }

    /// Prix total réellement payé (prix + pourboire), dans la devise du prix.
    var totalPrice: Double { price + tipAmount }

    var hasLocation: Bool { latitude != nil && longitude != nil }
}

/// Bilan agrégé d'un ensemble d'achats, regroupés par devise du prix.
struct JournalSummary: Equatable, Sendable {

    struct CurrencyTotal: Identifiable, Equatable, Sendable {
        let code: String
        var count: Int = 0
        var totalPrice: Double = 0
        var totalTip: Double = 0
        var totalCommission: Double = 0
        var id: String { code }
    }

    var totals: [CurrencyTotal] = []
    var count: Int = 0
    var firstDate: Date?
    var lastDate: Date?
}

extension Array where Element == PurchaseEntry {
    /// Regroupe les achats par devise du prix et cumule les montants — le bilan de voyage.
    var summary: JournalSummary {
        var byCode: [String: JournalSummary.CurrencyTotal] = [:]
        for entry in self {
            var total = byCode[entry.priceCurrencyCode] ?? .init(code: entry.priceCurrencyCode)
            total.count += 1
            total.totalPrice += entry.price
            total.totalTip += entry.tipAmount
            total.totalCommission += entry.commissionAmount
            byCode[entry.priceCurrencyCode] = total
        }
        let dates = map(\.date)
        return JournalSummary(
            totals: byCode.values.sorted { $0.totalPrice > $1.totalPrice },
            count: count,
            firstDate: dates.min(),
            lastDate: dates.max()
        )
    }
}

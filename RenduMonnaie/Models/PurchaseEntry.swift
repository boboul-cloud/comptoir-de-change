//
//  PurchaseEntry.swift
//  Comptoir de change
//
//  Un achat enregistré depuis l'écran de calcul, et le bilan qui s'en déduit
//  pour le voyage.
//

import Foundation

/// Le rôle joué par l'utilisateur dans la transaction : il achète (client face à un
/// vendeur) ou il vend et rend la monnaie à un client (comptoir, étal, change). Le
/// calcul est identique dans les deux cas — seuls le vocabulaire et le classement dans
/// le journal en dépendent.
enum TransactionKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case achat
    case vente

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .achat: "bag"
        case .vente: "banknote"
        }
    }

    var label: String {
        switch self {
        case .achat: String(localized: "Achat")
        case .vente: String(localized: "Vente")
        }
    }

    var saveActionLabel: String {
        switch self {
        case .achat: String(localized: "Enregistrer cet achat")
        case .vente: String(localized: "Enregistrer cette vente")
        }
    }

    var savedLabel: String {
        switch self {
        case .achat: String(localized: "Achat enregistré")
        case .vente: String(localized: "Vente enregistrée")
        }
    }

    var deleteLabel: String {
        switch self {
        case .achat: String(localized: "Supprimer cet achat")
        case .vente: String(localized: "Supprimer cette vente")
        }
    }

    var saveCaption: String {
        switch self {
        case .achat: String(localized: "Cumule tes achats ici pour retrouver un bilan complet en fin de voyage.")
        case .vente: String(localized: "Cumule tes ventes ici pour retrouver un bilan complet de ton activité.")
        }
    }

    var historyTitle: String {
        switch self {
        case .achat: String(localized: "Historique des achats")
        case .vente: String(localized: "Historique des ventes")
        }
    }

    var summaryTitle: String {
        switch self {
        case .achat: String(localized: "BILAN DES ACHATS")
        case .vente: String(localized: "BILAN DES VENTES")
        }
    }

    var detailSectionTitle: String {
        switch self {
        case .achat: String(localized: "DÉTAIL DES ACHATS")
        case .vente: String(localized: "DÉTAIL DES VENTES")
        }
    }

    var locationLabel: String {
        switch self {
        case .achat: String(localized: "Lieu de l'achat")
        case .vente: String(localized: "Lieu de la vente")
        }
    }

    var locationUnavailableMessage: String {
        switch self {
        case .achat: String(localized: "La position n'a pas pu être relevée lors de l'enregistrement de cet achat.")
        case .vente: String(localized: "La position n'a pas pu être relevée lors de l'enregistrement de cette vente.")
        }
    }

    var emptyStateTitle: String {
        switch self {
        case .achat: String(localized: "Aucun achat enregistré")
        case .vente: String(localized: "Aucune vente enregistrée")
        }
    }

    var emptyStateMessage: String {
        switch self {
        case .achat: String(localized: "Enregistre un achat depuis l'écran principal pour construire ton bilan de voyage.")
        case .vente: String(localized: "Enregistre une vente depuis l'écran principal pour construire ton bilan d'activité.")
        }
    }

    func count(_ n: Int) -> String {
        switch self {
        case .achat: n == 1 ? String(localized: "1 achat") : String(localized: "\(n) achats")
        case .vente: n == 1 ? String(localized: "1 vente") : String(localized: "\(n) ventes")
        }
    }

    func countRegistered(_ n: Int) -> String {
        switch self {
        case .achat: n == 1 ? String(localized: "1 achat enregistré") : String(localized: "\(n) achats enregistrés")
        case .vente: n == 1 ? String(localized: "1 vente enregistrée") : String(localized: "\(n) ventes enregistrées")
        }
    }
}

/// Un achat ou une vente conservé dans le journal de voyage.
struct PurchaseEntry: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var date: Date
    var note: String

    /// Achat (le client, c'est moi) ou vente (je rends la monnaie à un client).
    var kind: TransactionKind

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
        kind: TransactionKind = .achat,
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
        self.kind = kind
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

    private enum CodingKeys: String, CodingKey {
        case id, date, note, kind
        case priceCurrencyCode, price, tipAmount
        case paidCurrencyCode, receivedAmount
        case changeAmount, changeCurrencyCode
        case rate, commissionPercent, commissionAmount
        case latitude, longitude
    }

    /// Décodage manuel : les entrées enregistrées avant l'ajout du mode achat/vente
    /// n'ont pas la clé `kind`. Elles proviennent toutes de l'ancien mode unique de
    /// l'app, assimilé à un achat — sans ce filet, un journal existant serait
    /// silencieusement vidé au premier lancement après mise à jour.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        note = try container.decode(String.self, forKey: .note)
        kind = try container.decodeIfPresent(TransactionKind.self, forKey: .kind) ?? .achat
        priceCurrencyCode = try container.decode(String.self, forKey: .priceCurrencyCode)
        price = try container.decode(Double.self, forKey: .price)
        tipAmount = try container.decode(Double.self, forKey: .tipAmount)
        paidCurrencyCode = try container.decode(String.self, forKey: .paidCurrencyCode)
        receivedAmount = try container.decode(Double.self, forKey: .receivedAmount)
        changeAmount = try container.decode(Double.self, forKey: .changeAmount)
        changeCurrencyCode = try container.decode(String.self, forKey: .changeCurrencyCode)
        rate = try container.decode(Double.self, forKey: .rate)
        commissionPercent = try container.decode(Double.self, forKey: .commissionPercent)
        commissionAmount = try container.decode(Double.self, forKey: .commissionAmount)
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
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

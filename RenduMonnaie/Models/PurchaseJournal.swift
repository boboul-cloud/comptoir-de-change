//
//  PurchaseJournal.swift
//  Comptoir de change
//
//  Journal persistant des achats enregistrés, pour construire le bilan
//  financier de fin de voyage.
//

import Foundation
import Observation

@MainActor
@Observable
final class PurchaseJournal {

    private(set) var entries: [PurchaseEntry]

    private let defaults: UserDefaults
    private static let key = "rendu_monnaie_purchase_journal"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        entries = Self.load(from: defaults)
    }

    var summary: JournalSummary { entries.summary }

    func add(_ entry: PurchaseEntry) {
        entries.insert(entry, at: 0)
        save()
    }

    func remove(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        save()
    }

    func clear() {
        entries.removeAll()
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: Self.key)
    }

    private static func load(from defaults: UserDefaults) -> [PurchaseEntry] {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([PurchaseEntry].self, from: data)
        else { return [] }
        return decoded
    }
}

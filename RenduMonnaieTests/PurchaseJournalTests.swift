//
//  PurchaseJournalTests.swift
//  RenduMonnaieTests
//
//  Tests du journal des achats et du bilan de voyage qui s'en déduit.
//

import Foundation
import Testing
@testable import RenduMonnaie

private func isolatedDefaults(_ name: String) -> UserDefaults {
    let defaults = UserDefaults(suiteName: name)!
    defaults.removePersistentDomain(forName: name)
    return defaults
}

private func entry(
    note: String = "",
    priceCurrency: String = "EUR",
    price: Double,
    tip: Double = 0,
    paidCurrency: String = "USD",
    received: Double = 0,
    change: Double = 0,
    changeCurrency: String = "EUR",
    commissionAmount: Double = 0,
    latitude: Double? = nil,
    longitude: Double? = nil
) -> PurchaseEntry {
    PurchaseEntry(
        note: note,
        priceCurrencyCode: priceCurrency,
        price: price,
        tipAmount: tip,
        paidCurrencyCode: paidCurrency,
        receivedAmount: received,
        changeAmount: change,
        changeCurrencyCode: changeCurrency,
        rate: 1,
        commissionAmount: commissionAmount,
        latitude: latitude,
        longitude: longitude
    )
}

@MainActor
@Suite(.serialized)
struct PurchaseJournalTests {

    @Test func ajouterInsereEnTete() {
        let journal = PurchaseJournal(defaults: isolatedDefaults("test.journal.insere"))
        journal.add(entry(price: 10))
        journal.add(entry(price: 20))

        #expect(journal.entries.count == 2)
        #expect(journal.entries.first?.price == 20)   // le plus récent en tête
    }

    @Test func persisteEntreDeuxInstances() {
        let name = "test.journal.persiste"
        let defaults = isolatedDefaults(name)

        let first = PurchaseJournal(defaults: defaults)
        first.add(entry(note: "Café", price: 4.5))

        let second = PurchaseJournal(defaults: defaults)
        #expect(second.entries.count == 1)
        #expect(second.entries.first?.note == "Café")
    }

    @Test func lePersisteLeLieuQuandDisponible() {
        let name = "test.journal.lieu"
        let defaults = isolatedDefaults(name)

        let first = PurchaseJournal(defaults: defaults)
        first.add(entry(price: 12, latitude: 48.8566, longitude: 2.3522))
        first.add(entry(price: 8))   // sans lieu (refusé ou indisponible)

        let second = PurchaseJournal(defaults: defaults)
        let avecLieu = second.entries.first { $0.price == 12 }
        let sansLieu = second.entries.first { $0.price == 8 }

        #expect(avecLieu?.hasLocation == true)
        #expect(avecLieu?.latitude == 48.8566)
        #expect(sansLieu?.hasLocation == false)
    }

    @Test func supprimerRetireLaBonneEntree() {
        let journal = PurchaseJournal(defaults: isolatedDefaults("test.journal.supprime"))
        journal.add(entry(price: 10))
        journal.add(entry(price: 20))
        journal.add(entry(price: 30))

        // Les entrées sont en tête d'ordre décroissant : [30, 20, 10].
        journal.remove(at: IndexSet(integer: 1))

        #expect(journal.entries.map(\.price) == [30, 10])
    }

    @Test func clearVideEtPersiste() {
        let name = "test.journal.clear"
        let defaults = isolatedDefaults(name)
        let journal = PurchaseJournal(defaults: defaults)
        journal.add(entry(price: 10))
        journal.clear()

        #expect(journal.entries.isEmpty)
        #expect(PurchaseJournal(defaults: defaults).entries.isEmpty)
    }

    @Test func bilanRegroupeParDeviseDuPrix() {
        let journal = PurchaseJournal(defaults: isolatedDefaults("test.journal.bilan"))
        journal.add(entry(priceCurrency: "EUR", price: 10, tip: 1))
        journal.add(entry(priceCurrency: "EUR", price: 20, tip: 0))
        journal.add(entry(priceCurrency: "USD", price: 15, tip: 0))

        let summary = journal.summary
        #expect(summary.count == 3)

        let eur = summary.totals.first { $0.code == "EUR" }
        #expect(eur?.count == 2)
        #expect(eur?.totalPrice == 30)
        #expect(eur?.totalTip == 1)

        let usd = summary.totals.first { $0.code == "USD" }
        #expect(usd?.count == 1)
        #expect(usd?.totalPrice == 15)
    }

    @Test func totalPriceInclutLePourboire() {
        let e = entry(price: 45, tip: 5)
        #expect(e.totalPrice == 50)
    }

    @Test func bilanVideNeContientAucunTotal() {
        let summary: [PurchaseEntry] = []
        #expect(summary.summary.totals.isEmpty)
        #expect(summary.summary.count == 0)
        #expect(summary.summary.firstDate == nil)
    }
}

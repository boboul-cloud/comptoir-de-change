//
//  CashBreakdownTests.swift
//  RenduMonnaieTests
//

import Testing
@testable import RenduMonnaie

struct CashBreakdownTests {

    private func sum(_ lines: [CashLine]) -> Double {
        lines.reduce(0) { $0 + $1.total }
    }

    @Test func euroRendExactement() {
        let eur = CurrencyCatalog.currency("EUR")
        let lines = eur.makeChange(for: 47.85)
        #expect(abs(sum(lines) - 47.85) < 1e-6)
        // Rendu optimal : un seul billet de 20 apparaît en 2 exemplaires, etc.
        #expect(lines.first?.value == 20)
        #expect(lines.first?.count == 2)
    }

    @Test func yenSansDecimales() {
        let jpy = CurrencyCatalog.currency("JPY")
        #expect(jpy.minorUnitDigits == 0)
        let lines = jpy.makeChange(for: 1500)
        #expect(lines == [CashLine(value: 1000, count: 1), CashLine(value: 500, count: 1)])
    }

    @Test func suisseArrondiCinqCentimes() {
        let chf = CurrencyCatalog.currency("CHF")
        #expect(abs(chf.roundedToCash(4.87) - 4.85) < 1e-9)
        #expect(abs(chf.roundedToCash(4.88) - 4.90) < 1e-9)
        let lines = chf.makeChange(for: 4.87)      // arrondi interne à 4,85
        #expect(abs(sum(lines) - 4.85) < 1e-6)
    }

    @Test func sommeToujoursEgaleAuMontantArrondi() {
        let eur = CurrencyCatalog.currency("EUR")
        for cents in stride(from: 1, through: 9999, by: 137) {
            let amount = Double(cents) / 100
            let lines = eur.makeChange(for: amount)
            #expect(abs(sum(lines) - eur.roundedToCash(amount)) < 1e-6)
        }
    }

    @Test func montantNulOuNegatifDonneRienARendre() {
        let eur = CurrencyCatalog.currency("EUR")
        #expect(eur.makeChange(for: 0).isEmpty)
        #expect(eur.makeChange(for: -10).isEmpty)
    }
}

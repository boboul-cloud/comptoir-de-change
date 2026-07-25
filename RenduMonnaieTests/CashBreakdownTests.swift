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

    @Test func suggestionProposeLaDizaineSuperieureEtLeBilletEnInformation() {
        let eur = CurrencyCatalog.currency("EUR")
        // 32,50 € à fournir : la dizaine supérieure (40) est mise en avant, tandis que le
        // billet entier existant qui couvrirait aussi le montant (50) n'est qu'une information.
        let suggestion = eur.paymentSuggestion(coveringAtLeast: 32.50)
        #expect(suggestion == PaymentSuggestion(roundedAmount: 40, singleBill: 50))
    }

    @Test func suggestionSansBilletDistinctNOmetPasDinformationRedondante() {
        let usd = CurrencyCatalog.currency("USD")
        // 17,20 USD : la dizaine supérieure (20) coïncide avec le plus petit billet qui
        // suffit ; l'information sur le billet entier est alors superflue.
        let suggestion = usd.paymentSuggestion(coveringAtLeast: 17.20)
        #expect(suggestion == PaymentSuggestion(roundedAmount: 20, singleBill: nil))
    }

    @Test func suggestionArrondieALaDizaineSuperieureQuandAucuneCoupureNeSuffit() {
        let eur = CurrencyCatalog.currency("EUR")
        // Aucun billet ne dépasse 500 € : pas d'information sur un billet entier possible.
        let suggestion = eur.paymentSuggestion(coveringAtLeast: 803)
        #expect(suggestion == PaymentSuggestion(roundedAmount: 810, singleBill: nil))
        #expect(suggestion?.roundedAmount == 810)
    }

    @Test func suggestionArrondieALaDizaineSuperieurePourGrosseSomme() {
        let chf = CurrencyCatalog.currency("CHF")
        // 1250,03 CHF dépasse la plus grande coupure (1000) : on arrondit à la dizaine
        // supérieure plutôt que de détailler une combinaison précise de coupures.
        let suggestion = chf.paymentSuggestion(coveringAtLeast: 1250.03)
        #expect(suggestion == PaymentSuggestion(roundedAmount: 1260, singleBill: nil))
    }

    @Test func suggestionMontantNulOuNegatifNeRenvoieRien() {
        let eur = CurrencyCatalog.currency("EUR")
        #expect(eur.paymentSuggestion(coveringAtLeast: 0) == nil)
        #expect(eur.paymentSuggestion(coveringAtLeast: -5) == nil)
    }
}

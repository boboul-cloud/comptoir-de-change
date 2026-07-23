//
//  ChangeCalculationTests.swift
//  RenduMonnaieTests
//
//  Tests de la logique pure de rendu de monnaie.
//

import Testing
@testable import RenduMonnaie

struct ChangeCalculationTests {

    @Test func renduSimpleMemeDevise() {
        // Prix 45, reçu 50, taux 1 → il faut rendre 5.
        let c = ChangeCalculation(rate: 1, price: 45, received: 50)
        #expect(c.changeInPriceCurrency == 5)
        #expect(c.changeInPaidCurrency == 5)
        #expect(c.isInsufficient == false)
    }

    @Test func renduAvecConversion() {
        // 1 USD = 0,9 EUR, prix 45 EUR, client donne 60 USD (= 54 EUR).
        let c = ChangeCalculation(rate: 0.9, price: 45, received: 60)
        #expect(c.receivedConverted == 54)
        #expect(c.changeInPriceCurrency == 9)               // 9 EUR à rendre
        #expect(abs(c.changeInPaidCurrency - 10) < 1e-9)    // soit 10 USD
    }

    @Test func paiementInsuffisant() {
        let c = ChangeCalculation(rate: 1, price: 50, received: 45)
        #expect(c.isInsufficient)
        #expect(c.missingInPriceCurrency == 5)
    }

    @Test func toleranceDemiCentime() {
        // Un manque de 0,004 reste considéré comme payé.
        let c = ChangeCalculation(rate: 1, price: 50.004, received: 50)
        #expect(c.isInsufficient == false)
    }

    @Test func tauxNulNeDiviseJamaisParZero() {
        let c = ChangeCalculation(rate: 0, price: 10, received: 10)
        #expect(c.changeInPaidCurrency == 0)
    }

    @Test func ecartParRapportAuxReference() {
        let ecart = ChangeCalculation.deviationPercent(applied: 1.1, reference: 1.0)
        #expect(abs(ecart - 10) < 1e-9)
        #expect(ChangeCalculation.deviationPercent(applied: 1, reference: 0) == 0)
    }

    @Test func commissionReduitLaValeurRecue() {
        // 100 unités reçues, taux 1, commission 10 % → 90 dans la devise du prix.
        let c = ChangeCalculation(rate: 1, price: 45, received: 100, commissionPercent: 10)
        #expect(abs(c.effectiveRate - 0.9) < 1e-9)
        #expect(abs(c.receivedConverted - 90) < 1e-9)
        #expect(abs(c.changeInPriceCurrency - 45) < 1e-9)
    }

    @Test func sansCommissionInchange() {
        let c = ChangeCalculation(rate: 1.2, price: 10, received: 20)
        #expect(c.effectiveRate == 1.2)
    }
}

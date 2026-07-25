//
//  RateStoreTests.swift
//  RenduMonnaieTests
//
//  Tests du fournisseur de taux avec un réseau simulé (URLProtocol).
//

import Foundation
import Testing
@testable import RenduMonnaie

/// Intercepte les requêtes réseau pour renvoyer une réponse contrôlée.
final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var responseData: Data?
    nonisolated(unsafe) static var statusCode = 200
    nonisolated(unsafe) static var failWith: URLError?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        if let error = Self.failWith {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        let response = HTTPURLResponse(
            url: request.url!, statusCode: Self.statusCode, httpVersion: nil, headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        if let data = Self.responseData {
            client?.urlProtocol(self, didLoad: data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }
}

private func mockedSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: config)
}

@MainActor
@Suite(.serialized)
struct RateStoreTests {

    @Test func refreshMetAJourLesTaux() async {
        MockURLProtocol.failWith = nil
        MockURLProtocol.statusCode = 200
        MockURLProtocol.responseData = #"{"date":"2026-01-02","rates":{"USD":1.10,"GBP":0.85}}"#.data(using: .utf8)

        let store = RateStore(session: mockedSession())
        await store.refresh()

        #expect(store.isFallback == false)
        #expect(store.lastError == nil)
        #expect(abs((store.ratesEUR["USD"] ?? 0) - 1.10) < 1e-9)
    }

    @Test func deviseFigeeJamaisEcrasee() async {
        MockURLProtocol.failWith = nil
        MockURLProtocol.statusCode = 200
        // Le réseau tente d'imposer un FRF fantaisiste : il doit être ignoré.
        MockURLProtocol.responseData = #"{"date":"x","rates":{"FRF":999}}"#.data(using: .utf8)

        let store = RateStore(session: mockedSession())
        await store.refresh()

        #expect(store.ratesEUR["FRF"] == 6.55957)
    }

    @Test func echecReseauConserveLesTauxEtDetailleLerreur() async {
        MockURLProtocol.responseData = nil
        MockURLProtocol.failWith = URLError(.notConnectedToInternet)

        let store = RateStore(session: mockedSession())
        await store.refresh()

        // Le libellé exact dépend de la langue de l'appareil (String Catalog) : on
        // vérifie qu'une erreur est bien remontée, pas son texte précis.
        #expect(store.lastError?.isEmpty == false)
        #expect(store.ratesEUR["EUR"] == 1)   // taux de secours conservés
    }

    @Test func tauxCroise() async {
        MockURLProtocol.failWith = nil
        MockURLProtocol.statusCode = 200
        MockURLProtocol.responseData = #"{"date":"x","rates":{"USD":1.25}}"#.data(using: .utf8)

        let store = RateStore(session: mockedSession())
        await store.refresh()

        // 1 USD vaut 1/1,25 = 0,8 EUR.
        #expect(abs(store.rate(from: "USD", to: "EUR") - 0.8) < 1e-9)
    }
}

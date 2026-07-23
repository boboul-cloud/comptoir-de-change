//
//  RateStore.swift
//  Comptoir de change
//
//  Fournisseur de taux de change : API Frankfurter (données BCE),
//  avec cache local, table de secours hors ligne et devises à taux figé.
//

import Foundation
import Observation

/// Réponse de l'API Frankfurter (données BCE).
private struct FrankfurterResponse: Decodable, Sendable {
    let date: String
    let rates: [String: Double]
}

@MainActor
@Observable
final class RateStore {

    /// Taux exprimés en « 1 EUR = X devise ».
    private(set) var ratesEUR: [String: Double]
    private(set) var lastUpdated: Date?
    private(set) var isLoading = false
    private(set) var lastError: String?
    /// `true` tant que les taux affichés proviennent encore de la table de secours.
    private(set) var isFallback = true

    private let session: URLSession
    private let endpoint = URL(string: "https://api.frankfurter.app/latest?from=EUR")!

    /// Table de secours utilisée hors ligne ou en cas d'échec réseau.
    private static let fallback: [String: Double] = [
        "AUD": 1.629861, "BGN": 1.95583, "BRL": 5.779369, "CAD": 1.60699,
        "CHF": 0.929764, "CNY": 7.738438, "CZK": 24.173763, "DKK": 7.47564,
        "EUR": 1, "GBP": 0.853733, "HKD": 8.962422,
        "HUF": 363.821323, "IDR": 20474.332318, "ILS": 3.500984, "INR": 110.351112,
        "ISK": 143.408544, "JPY": 186.441599, "KRW": 1677.791699, "MXN": 19.874531,
        "MYR": 4.670304, "NOK": 10.935907, "NZD": 1.963548, "PHP": 70.593651,
        "PLN": 4.32891, "RON": 5.237867, "SEK": 11.063988, "SGD": 1.473889,
        "THB": 38.667479, "TRY": 53.998092, "USD": 1.1431, "ZAR": 18.718743,
    ]

    init(session: URLSession = .shared) {
        self.session = session
        // On repart des derniers taux enregistrés si l'app a déjà tourné.
        if let saved = Self.loadCache() {
            ratesEUR = Self.withFixedRates(saved.rates)
            lastUpdated = saved.date
            isFallback = false
        } else {
            ratesEUR = Self.withFixedRates(Self.fallback)
        }
    }

    /// Superpose l'euro (= 1) et les taux irrévocables des anciennes devises.
    private static func withFixedRates(_ base: [String: Double]) -> [String: Double] {
        var dict = base
        dict["EUR"] = 1
        for (code, rate) in CurrencyCatalog.legacyRatesEUR {
            dict[code] = rate
        }
        return dict
    }

    /// Taux croisé « 1 unité de `from` = X unités de `to` ».
    func rate(from: String, to: String) -> Double {
        guard let a = ratesEUR[from], let b = ratesEUR[to], a != 0 else { return 0 }
        return b / a
    }

    func refresh() async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            var request = URLRequest(url: endpoint)
            request.timeoutInterval = 12
            request.cachePolicy = .reloadIgnoringLocalCacheData

            let (data, response) = try await session.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            guard (200..<300).contains(http.statusCode) else {
                throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"])
            }

            let decoded = try JSONDecoder().decode(FrankfurterResponse.self, from: data)

            var merged = ratesEUR
            for (code, value) in decoded.rates {
                merged[code] = value
            }
            merged = Self.withFixedRates(merged)   // euro + devises figées inviolables

            ratesEUR = merged
            let now = Date()
            lastUpdated = now
            isFallback = false
            Self.saveCache(rates: merged, date: now)

        } catch {
            lastError = Self.message(for: error)
        }
    }

    /// Message d'erreur adapté à la nature de la panne réseau.
    private static func message(for error: Error) -> String {
        let base: String
        switch error {
        case let urlError as URLError:
            switch urlError.code {
            case .notConnectedToInternet, .dataNotAllowed:
                base = String(localized: "Aucune connexion Internet")
            case .timedOut:
                base = String(localized: "Délai d'attente dépassé")
            case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
                base = String(localized: "Serveur des cours injoignable")
            case .badServerResponse:
                base = String(localized: "Réponse du serveur invalide")
            default:
                base = String(localized: "Cours indisponible")
            }
        case is DecodingError:
            base = String(localized: "Données de cours illisibles")
        default:
            base = String(localized: "Cours indisponible")
        }
        return String(localized: "\(base) — taux enregistrés conservés.")
    }

    // MARK: - Persistance légère

    private static let cacheKey = "rendu_monnaie_rates"
    private static let cacheDateKey = "rendu_monnaie_rates_date"

    private static func saveCache(rates: [String: Double], date: Date) {
        UserDefaults.standard.set(rates, forKey: cacheKey)
        UserDefaults.standard.set(date, forKey: cacheDateKey)
    }

    private static func loadCache() -> (rates: [String: Double], date: Date)? {
        guard let rates = UserDefaults.standard.dictionary(forKey: cacheKey) as? [String: Double],
              let date = UserDefaults.standard.object(forKey: cacheDateKey) as? Date,
              !rates.isEmpty
        else { return nil }
        return (rates, date)
    }
}

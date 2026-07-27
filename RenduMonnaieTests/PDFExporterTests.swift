//
//  PDFExporterTests.swift
//  RenduMonnaieTests
//
//  Vérifie que le bilan de voyage se restitue bien en un fichier PDF valide.
//

import Foundation
import Testing
@testable import RenduMonnaie

@MainActor
struct PDFExporterTests {

    @Test func exportProduitUnPDFValide() {
        let entries = [
            PurchaseEntry(
                note: "Café",
                priceCurrencyCode: "EUR", price: 4.5,
                paidCurrencyCode: "USD", receivedAmount: 10,
                changeAmount: 5.06, changeCurrencyCode: "EUR",
                rate: 0.9,
                latitude: 48.8566, longitude: 2.3522
            ),
            PurchaseEntry(
                note: "Taxi",
                priceCurrencyCode: "USD", price: 15,
                paidCurrencyCode: "USD", receivedAmount: 20,
                changeAmount: 5, changeCurrencyCode: "USD",
                rate: 1
            ),
        ]
        let rows = entries.map { PurchaseReportView.Row(entry: $0, placeName: $0.hasLocation ? "Paris, France" : nil) }
        let report = PurchaseReportView(kind: .achat, rows: rows, summary: entries.summary, totalCurrencyCode: "EUR", total: 18.2, generatedAt: Date())

        let url = PDFExporter.export(report, fileName: "test-bilan.pdf")

        #expect(url != nil)
        guard let url, let data = try? Data(contentsOf: url) else {
            Issue.record("Aucun fichier PDF produit")
            return
        }
        #expect(data.count > 100)
        #expect(data.starts(with: "%PDF".data(using: .ascii)!))

        try? FileManager.default.removeItem(at: url)
    }

    @Test func exportGereUneListeVide() {
        let report = PurchaseReportView(kind: .achat, rows: [], summary: [].summary, totalCurrencyCode: "EUR", total: 0, generatedAt: Date())
        let url = PDFExporter.export(report, fileName: "test-bilan-vide.pdf")

        #expect(url != nil)
        if let url {
            #expect((try? Data(contentsOf: url))?.isEmpty == false)
            try? FileManager.default.removeItem(at: url)
        }
    }
}

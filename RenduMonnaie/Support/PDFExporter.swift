//
//  PDFExporter.swift
//  Comptoir de change
//
//  Rendu d'une vue SwiftUI en PDF vectoriel, page unique dimensionnée au
//  contenu (cf. le bilan de voyage détaillé).
//

import SwiftUI

@MainActor
enum PDFExporter {

    /// Restitue `view` dans un fichier PDF temporaire et renvoie son emplacement,
    /// ou `nil` si le rendu échoue.
    static func export(_ view: some View, fileName: String) -> URL? {
        let renderer = ImageRenderer(content: view)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        var success = false

        renderer.render { size, context in
            var box = CGRect(origin: .zero, size: size)
            guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            pdf.beginPDFPage(nil)
            context(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
            success = true
        }

        return success ? url : nil
    }
}

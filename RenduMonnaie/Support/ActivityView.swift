//
//  ActivityView.swift
//  Comptoir de change
//
//  Pont SwiftUI vers la feuille de partage système, pour partager le PDF
//  généré (ShareLink ne sait pas attendre un fichier produit de façon
//  asynchrone).
//

import SwiftUI

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

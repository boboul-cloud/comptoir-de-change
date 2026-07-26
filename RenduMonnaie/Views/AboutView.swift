//
//  AboutView.swift
//  Comptoir de change
//
//  Fiche « À propos » : version de l'app et liens vers le site, la politique
//  de confidentialité et les conditions d'utilisation.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return String(localized: "Version \(version) (\(build))")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 6) {
                        Image(systemName: "banknote.fill")
                            .scaledFont(34)
                            .foregroundStyle(Color.accentGreen)
                        Text("Comptoir de change")
                            .scaledFont(20, weight: .bold)
                        Text(versionString)
                            .scaledFont(13, design: .monospaced)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 12)
                    .accessibilityElement(children: .combine)

                    VStack(spacing: 0) {
                        linkRow("Politique de confidentialité", systemImage: "hand.raised", url: AboutLinks.privacy)
                        Divider().overlay(Color.cardLine).padding(.leading, 52)
                        linkRow("Conditions d'utilisation", systemImage: "doc.text", url: AboutLinks.terms)
                        Divider().overlay(Color.cardLine).padding(.leading, 52)
                        linkRow("Site web", systemImage: "globe", url: AboutLinks.website)
                    }
                    .background(Color.cardBG, in: .rect(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.cardLine, lineWidth: 1))
                }
                .padding(16)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
            .background(Color.paperBG.ignoresSafeArea())
            .navigationTitle("À propos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }

    private func linkRow(_ title: LocalizedStringKey, systemImage: String, url: URL) -> some View {
        Link(destination: url) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .scaledFont(15, weight: .medium)
                    .foregroundStyle(Color.accentGreen)
                    .frame(width: 22)
                Text(title)
                    .scaledFont(14)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .scaledFont(11, weight: .semibold)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private enum AboutLinks {
    static let website = URL(string: "https://boboul-cloud.github.io/comptoir-de-change/")!
    static let privacy = URL(string: "https://boboul-cloud.github.io/comptoir-de-change/privacy.html")!
    static let terms = URL(string: "https://boboul-cloud.github.io/comptoir-de-change/terms.html")!
}

#Preview {
    AboutView()
}

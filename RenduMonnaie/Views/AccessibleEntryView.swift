//
//  AccessibleEntryView.swift
//  Comptoir de change
//
//  Écran de saisie en gros caractères pour les utilisateurs malvoyants : les mêmes
//  informations que l'écran principal (devises, prix, commission, pourboire, montant
//  reçu, résultat), avec un texte et des cibles tactiles nettement plus grands. Les
//  champs sont liés directement à l'état de l'écran principal — toute saisie ici s'y
//  reflète aussitôt, et réciproquement.
//

import SwiftUI

struct AccessibleEntryView: View {
    @Binding var deviseA: String
    @Binding var deviseB: String
    @Binding var prix: String
    @Binding var commissionTexte: String
    @Binding var pourboireTexte: String
    @Binding var pourboireEnPourcent: Bool
    @Binding var recu: String

    let currA: Currency
    let currB: Currency
    let suggestionReglement: PaymentSuggestion?
    let pourboireMontant: Double
    let pourboirePourcent: Double

    let isInsufficient: Bool
    let mainAmount: Double
    let payoutCurrency: Currency
    let breakdown: [CashLine]
    let secondaryAmount: Double
    let secondaryCurrency: Currency
    let missingAmount: Double

    // Repris tels quels par l'écran client (« écran inversé ») quand l'appareil est
    // retourné vers lui — voir `CustomerDisplayOverlay`.
    let priceAmount: Double
    var priceEquivalents: [CustomerDisplayView.CurrencyEquivalent] = []
    let commissionAmount: Double
    let commissionPercent: Double
    var commissionEquivalents: [CustomerDisplayView.CurrencyEquivalent] = []
    var tipEquivalents: [CustomerDisplayView.CurrencyEquivalent] = []

    let swapCurrencies: () -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var champActif: Champ?
    private enum Champ: Hashable { case prix, commission, pourboire, recu }

    private var pourboireSaisie: Double { Fmt.number(pourboireTexte) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    currencySection
                    prixSection
                    commissionSection
                    pourboireSection
                    recuSection
                    ResultBoard(
                        isInsufficient: isInsufficient,
                        mainAmount: mainAmount,
                        mainCurrency: payoutCurrency,
                        breakdown: breakdown,
                        secondaryAmount: secondaryAmount,
                        secondaryCurrency: secondaryCurrency,
                        missingAmount: missingAmount,
                        priceCurrency: currB,
                        tipAmount: pourboireMontant,
                        tipPercent: pourboirePourcent
                    )
                }
                .padding(20)
                .padding(.bottom, 32)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.paperBG.ignoresSafeArea())
            .navigationTitle("Saisie en gros caractères")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                        .scaledFont(20, weight: .semibold)
                }
            }
        }
        .modifier(CustomerDisplayOverlay(
            priceAmount: priceAmount,
            priceCurrency: currB,
            priceEquivalents: priceEquivalents,
            isInsufficient: isInsufficient,
            missingAmount: missingAmount,
            receivedAmount: Fmt.number(recu),
            receivedCurrency: currA,
            changeAmount: mainAmount,
            changeCurrency: payoutCurrency,
            changeSecondaryAmount: secondaryAmount,
            changeSecondaryCurrency: secondaryCurrency,
            commissionAmount: commissionAmount,
            commissionPercent: commissionPercent,
            commissionEquivalents: commissionEquivalents,
            tipAmount: pourboireMontant,
            tipPercent: pourboirePourcent,
            tipEquivalents: tipEquivalents
        ))
        // Déclaré ici, après le modifier de l'écran client plutôt que dans le .toolbar
        // du ScrollView : imbriqué plus profondément (dans le ZStack introduit par ce
        // modifier), l'accessoire clavier ne s'affichait pas de façon fiable.
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("OK") { champActif = nil }
                    .scaledFont(20, weight: .semibold)
            }
        }
    }

    // MARK: - Devises

    private var currencySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            currencyRow(titleKey: "Devise payée", selection: $deviseA)

            Button(action: swapCurrencies) {
                Label("Inverser les deux devises", systemImage: "arrow.up.arrow.down")
                    .scaledFont(20, weight: .semibold)
                    .foregroundStyle(Color.accentGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.cardBG, in: .rect(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.cardLine, lineWidth: 1))
            }
            .buttonStyle(.plain)

            currencyRow(titleKey: "Devise du prix", selection: $deviseB)
        }
    }

    private func currencyRow(titleKey: LocalizedStringKey, selection: Binding<String>) -> some View {
        let current = CurrencyCatalog.currency(selection.wrappedValue)
        return VStack(alignment: .leading, spacing: 10) {
            sectionLabel(titleKey)
            Menu {
                Picker(titleKey, selection: selection) {
                    ForEach(CurrencyCatalog.all) { c in
                        Text(c.label).tag(c.code)
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Text("\(current.flag) \(current.code)")
                        .scaledFont(30, weight: .bold, design: .monospaced)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.up.chevron.down")
                        .scaledFont(20, weight: .semibold)
                        .foregroundStyle(Color.accentGreen)
                }
                .padding(.horizontal, 20)
                .frame(minHeight: 72)
                .frame(maxWidth: .infinity)
                .background(Color.cardBG, in: .rect(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.cardLine, lineWidth: 1))
            }
            .accessibilityLabel(Text(titleKey) + Text(" : ") + Text(LocalizedStringKey(current.country)))
            Text(LocalizedStringKey(current.country))
                .scaledFont(16)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Prix

    private var prixSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("Prix à payer (en \(deviseB))")
            bigTextField($prix, focus: .prix)
            if let suggestion = suggestionReglement {
                suggestionCard(suggestion)
            }
        }
    }

    private func suggestionCard(_ suggestion: PaymentSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb")
                    .scaledFont(18)
                    .foregroundStyle(Color.accentGreen)
                Text(suggestionText(suggestion))
                    .scaledFont(18)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button {
                recu = Fmt.amount(suggestion.roundedAmount, currency: currA)
            } label: {
                Text("Utiliser cette proposition")
                    .scaledFont(18, weight: .semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentGreen, in: .rect(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.accentGreen.opacity(0.08), in: .rect(cornerRadius: 14))
    }

    private func suggestionText(_ suggestion: PaymentSuggestion) -> LocalizedStringKey {
        let rounded = Fmt.amount(suggestion.roundedAmount, currency: currA)
        guard let bill = suggestion.singleBill else {
            return "Proposer \(rounded) \(deviseA)."
        }
        return "Proposer \(rounded) \(deviseA) (billet entier existant : \(Fmt.amount(bill, currency: currA)) \(deviseA))."
    }

    // MARK: - Commission

    private var commissionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Commission")
            HStack(spacing: 12) {
                TextField("0", text: $commissionTexte)
                    .scaledFont(30, weight: .semibold, design: .monospaced)
                    .keyboardType(.numericEntry)
                    .multilineTextAlignment(.trailing)
                    .focused($champActif, equals: .commission)
                    .accessibilityLabel("Commission en pourcentage")
                Text("%")
                    .scaledFont(24, design: .monospaced)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.paperBG, in: .rect(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.cardLine, lineWidth: 1))
        }
    }

    // MARK: - Pourboire

    private var pourboireSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionLabel("Pourboire")
                Spacer()
                Button {
                    pourboireEnPourcent.toggle()
                } label: {
                    Text(pourboireEnPourcent ? "%" : deviseB)
                        .scaledFont(20, weight: .bold)
                        .foregroundStyle(Color.accentGreen)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(Color.accentGreen.opacity(0.12), in: .rect(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Changer l'unité du pourboire")
            }
            TextField("0", text: $pourboireTexte)
                .scaledFont(30, weight: .semibold, design: .monospaced)
                .keyboardType(.numericEntry)
                .multilineTextAlignment(.trailing)
                .focused($champActif, equals: .pourboire)
                .accessibilityLabel("Montant du pourboire")
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.paperBG, in: .rect(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.cardLine, lineWidth: 1))
            if pourboireSaisie > 0, let equivalent = pourboireEquivalent {
                Text(equivalent)
                    .scaledFont(16)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var pourboireEquivalent: LocalizedStringKey? {
        guard pourboireSaisie > 0 else { return nil }
        if pourboireEnPourcent {
            return "= \(Fmt.amount(pourboireMontant, currency: currB)) \(deviseB)"
        }
        return "= \(String(format: "%.1f", pourboirePourcent))% du prix"
    }

    // MARK: - Montant reçu

    private var recuSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("Montant reçu (en \(deviseA))")
            bigTextField($recu, focus: .recu)
        }
    }

    // MARK: - Composants

    private func sectionLabel(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .scaledFont(18, weight: .bold)
            .tracking(0.5)
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
    }

    private func bigTextField(_ binding: Binding<String>, focus: Champ) -> some View {
        TextField("0", text: binding)
            .scaledFont(40, weight: .semibold, design: .monospaced)
            .keyboardType(.numericEntry)
            .focused($champActif, equals: focus)
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(Color.paperBG, in: .rect(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.cardLine, lineWidth: 1))
    }
}

#Preview {
    PreviewWrapper()
}

private struct PreviewWrapper: View {
    @State private var deviseA = "USD"
    @State private var deviseB = "EUR"
    @State private var prix = "45.00"
    @State private var commissionTexte = ""
    @State private var pourboireTexte = ""
    @State private var pourboireEnPourcent = true
    @State private var recu = "60.00"

    var body: some View {
        let currA = CurrencyCatalog.currency(deviseA)
        let currB = CurrencyCatalog.currency(deviseB)
        AccessibleEntryView(
            deviseA: $deviseA, deviseB: $deviseB, prix: $prix,
            commissionTexte: $commissionTexte, pourboireTexte: $pourboireTexte,
            pourboireEnPourcent: $pourboireEnPourcent, recu: $recu,
            currA: currA, currB: currB,
            suggestionReglement: currA.paymentSuggestion(coveringAtLeast: 45),
            pourboireMontant: 0, pourboirePourcent: 0,
            isInsufficient: false, mainAmount: 15, payoutCurrency: currB,
            breakdown: currB.makeChange(for: 15), secondaryAmount: 16.5, secondaryCurrency: currA,
            missingAmount: 0,
            priceAmount: 45, commissionAmount: 0, commissionPercent: 0,
            swapCurrencies: {}
        )
    }
}

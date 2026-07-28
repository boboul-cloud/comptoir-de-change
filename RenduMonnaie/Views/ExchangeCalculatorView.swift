//
//  ExchangeCalculatorView.swift
//  Comptoir de change
//
//  Calcul de change autonome, indépendant du prix à payer et du rendu de
//  monnaie : un montant remis dans une devise, converti dans une autre,
//  commission déduite. En gros caractères, comme l'écran de saisie
//  accessible dont il partage le style.
//

import SwiftUI

struct ExchangeCalculatorView: View {
    let rateStore: RateStore

    @AppStorage("changeDeviseSource") private var deviseSource = "USD"
    @AppStorage("changeDeviseCible") private var deviseCible = "EUR"
    @State private var montantTexte = ""
    @State private var commissionTexte = ""

    @Environment(\.dismiss) private var dismiss
    @FocusState private var champActif: Champ?
    private enum Champ: Hashable { case montant, commission }

    private var currSource: Currency { CurrencyCatalog.currency(deviseSource) }
    private var currCible: Currency { CurrencyCatalog.currency(deviseCible) }
    private var montant: Double { Fmt.number(montantTexte) }
    private var commission: Double { Fmt.number(commissionTexte) }
    private var taux: Double { rateStore.rate(from: deviseSource, to: deviseCible) }

    /// Réutilise le calcul de rendu de monnaie avec un prix nul : le « rendu »
    /// devient alors exactement la conversion souhaitée, commission comprise —
    /// même formule que partout ailleurs dans l'app, donc même garanties.
    private var calcul: ChangeCalculation {
        ChangeCalculation(rate: taux, price: 0, received: montant, commissionPercent: commission)
    }
    private var montantConverti: Double { max(calcul.changeInPriceCurrency, 0) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    currencySection
                    montantSection
                    commissionSection
                    resultCard
                }
                .padding(20)
                .padding(.bottom, 32)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.paperBG.ignoresSafeArea())
            .navigationTitle("Calcul de change")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                        .scaledFont(20, weight: .semibold)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("OK") { champActif = nil }
                        .scaledFont(20, weight: .semibold)
                }
            }
        }
    }

    // MARK: - Devises

    private var currencySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            currencyRow(titleKey: "Devise remise", selection: $deviseSource)

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

            currencyRow(titleKey: "Devise souhaitée", selection: $deviseCible)
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

    private func swapCurrencies() {
        swap(&deviseSource, &deviseCible)
    }

    // MARK: - Montant et commission

    private var montantSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("Montant remis (en \(deviseSource))")
            bigTextField($montantTexte, focus: .montant)
        }
    }

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

    // MARK: - Résultat

    private var resultCard: some View {
        VStack(spacing: 12) {
            Text("MONTANT CONVERTI")
                .scaledFont(13, design: .monospaced)
                .tracking(2.5)
                .foregroundStyle(.white.opacity(0.5))
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(Fmt.amount(montantConverti, currency: currCible))
                    .scaledFont(40, weight: .bold, design: .monospaced)
                    .foregroundStyle(Color.cream)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(currCible.code)
                    .scaledFont(16, design: .monospaced)
                    .foregroundStyle(Color.accentGold)
            }
            if calcul.commissionAmount > 0 {
                Divider().overlay(.white.opacity(0.12))
                VStack(spacing: 4) {
                    Text("DONT COMMISSION")
                        .scaledFont(11, design: .monospaced)
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.45))
                    HStack(spacing: 6) {
                        Text("\(Fmt.amount(calcul.commissionAmount, currency: currCible)) \(currCible.code)")
                            .scaledFont(18, weight: .semibold, design: .monospaced)
                            .foregroundStyle(Color.accentGold)
                        Text("(\(Fmt.rate(commission))%)")
                            .scaledFont(14, design: .monospaced)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.boardBG, in: .rect(cornerRadius: 14))
        .accessibilityElement(children: .combine)
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
    ExchangeCalculatorView(rateStore: RateStore())
}

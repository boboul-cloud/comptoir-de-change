//
//  ContentView.swift
//  Comptoir de change
//
//  Écran principal : saisie du prix, du montant reçu et affichage du rendu.
//

import SwiftUI

struct ContentView: View {

    @State private var store = RateStore()

    // Devises et cible de rendu mémorisées entre deux lancements.
    @AppStorage("deviseA") private var deviseA = "USD"   // devise payée par le client
    @AppStorage("deviseB") private var deviseB = "EUR"   // devise du prix / de la caisse
    @AppStorage("rendreEnB") private var rendreEnB = true

    @State private var tauxTexte = ""
    @State private var tauxPersonnalise = false
    @State private var commissionTexte = ""
    @State private var prix = "45.00"
    @State private var recu = "60.00"

    @FocusState private var champActif: Champ?
    private enum Champ: Hashable { case taux, commission, prix, recu }

    // MARK: - Devises

    private var currA: Currency { CurrencyCatalog.currency(deviseA) }
    private var currB: Currency { CurrencyCatalog.currency(deviseB) }
    private var payoutCurrency: Currency { rendreEnB ? currB : currA }
    private var secondaryCurrency: Currency { rendreEnB ? currA : currB }

    // MARK: - Calculs

    private var tauxReference: Double { store.rate(from: deviseA, to: deviseB) }
    private var taux: Double { Fmt.number(tauxTexte) }
    private var commission: Double { Fmt.number(commissionTexte) }
    private var tauxFixe: Bool { currA.isLegacy || currB.isLegacy }

    private var calcul: ChangeCalculation {
        ChangeCalculation(rate: taux, price: Fmt.number(prix),
                          received: Fmt.number(recu), commissionPercent: commission)
    }

    private var rawMain: Double {
        rendreEnB ? calcul.changeInPriceCurrency : calcul.changeInPaidCurrency
    }
    private var mainAmount: Double { payoutCurrency.roundedToCash(max(rawMain, 0)) }
    private var breakdown: [CashLine] {
        calcul.isInsufficient ? [] : payoutCurrency.makeChange(for: mainAmount)
    }
    private var secondaryAmount: Double {
        rendreEnB ? calcul.changeInPaidCurrency : calcul.changeInPriceCurrency
    }

    private var ecartPourcent: Double {
        ChangeCalculation.deviationPercent(applied: taux, reference: tauxReference)
    }
    private var ecartImportant: Bool { tauxPersonnalise && ecartPourcent > 8 }

    // MARK: - Corps

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                ResultBoard(
                    isInsufficient: calcul.isInsufficient,
                    mainAmount: mainAmount,
                    mainCurrency: payoutCurrency,
                    breakdown: breakdown,
                    secondaryAmount: secondaryAmount,
                    secondaryCurrency: secondaryCurrency,
                    missingAmount: calcul.missingInPriceCurrency,
                    priceCurrency: currB
                )
                formCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 48)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.paperBG.ignoresSafeArea())
        .task {
            syncRate()
            await store.refresh()
            if !tauxPersonnalise { syncRate() }
        }
        .onChange(of: deviseA) { syncRate() }
        .onChange(of: deviseB) { syncRate() }
        .refreshable {
            await store.refresh()
            if !tauxPersonnalise { syncRate() }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("OK") { champActif = nil }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("COMPTOIR DE CHANGE")
                .scaledFont(11, weight: .bold, design: .monospaced)
                .tracking(3)
                .foregroundStyle(Color.accentGreen)
            Text("Rendu de monnaie")
                .scaledFont(26, weight: .bold)
                .foregroundStyle(.primary)
            Text("entre deux devises")
                .scaledFont(14)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Formulaire

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 22) {
            currencyPickers
            rateRow
            commissionRow
            amountFields
            renderTargetPicker
        }
        .padding(20)
        .background(Color.cardBG, in: .rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.cardLine, lineWidth: 1))
    }

    private var currencyPickers: some View {
        HStack(alignment: .top, spacing: 10) {
            currencyPicker(titleKey: "Devise payée", selection: $deviseA)

            Button(action: swapCurrencies) {
                Image(systemName: "arrow.left.arrow.right")
                    .scaledFont(14, weight: .medium)
                    .foregroundStyle(Color.accentGreen)
                    .frame(width: 38, height: 38)
                    .background(Color.paperBG, in: .circle)
                    .overlay(Circle().stroke(Color.cardLine, lineWidth: 1))
            }
            .padding(.top, 27)
            .accessibilityLabel("Inverser les deux devises")

            currencyPicker(titleKey: "Devise du prix", selection: $deviseB)
        }
    }

    private func currencyPicker(titleKey: LocalizedStringKey, selection: Binding<String>) -> some View {
        let current = CurrencyCatalog.currency(selection.wrappedValue)
        return VStack(alignment: .leading, spacing: 8) {
            fieldLabel(titleKey)

            Menu {
                Picker(titleKey, selection: selection) {
                    ForEach(CurrencyCatalog.all) { c in
                        Text(c.label).tag(c.code)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text("\(current.flag) \(current.code)")
                        .scaledFont(16, weight: .semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.up.chevron.down")
                        .scaledFont(12, weight: .semibold)
                        .foregroundStyle(Color.accentGreen)
                }
                .padding(.horizontal, 12)
                .frame(minHeight: 48)
                .frame(maxWidth: .infinity)
                .background(Color.paperBG, in: .rect(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cardLine, lineWidth: 1))
            }
            .accessibilityLabel(Text(titleKey) + Text(" : \(current.country)"))

            Text(current.country)
                .scaledFont(11)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private var rateRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("1 \(deviseA) =")
                    .scaledFont(13, design: .monospaced)
                    .foregroundStyle(.secondary)

                TextField("", text: $tauxTexte)
                    .scaledFont(13, design: .monospaced)
                    .keyboardType(.decimalPad)
                    .focused($champActif, equals: .taux)
                    .disabled(!tauxPersonnalise)
                    .foregroundStyle(tauxPersonnalise ? Color.primary : Color.secondary)
                    .frame(width: 110)
                    .accessibilityLabel("Taux de change")

                Text(deviseB)
                    .scaledFont(13, design: .monospaced)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    if tauxPersonnalise {
                        syncRate()
                    } else {
                        tauxPersonnalise = true
                        champActif = .taux
                    }
                } label: {
                    Image(systemName: tauxPersonnalise ? "arrow.counterclockwise" : "lock.open")
                        .scaledFont(13)
                        .foregroundStyle(Color.accentGreen)
                }
                .disabled(tauxFixe)
                .accessibilityLabel(Text(tauxPersonnalise ? "Rétablir le taux de référence" : "Modifier le taux"))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.paperBG, in: .rect(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cardLine, lineWidth: 1))

            HStack(spacing: 6) {
                if store.isLoading {
                    ProgressView().scaleEffect(0.6).frame(width: 12, height: 12)
                } else {
                    Image(systemName: statusIcon).scaledFont(10)
                }
                Text(statusText)
                    .scaledFont(11)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if ecartImportant {
                Text("⚠️ Ce taux s'écarte de \(String(format: "%.1f", ecartPourcent))% du cours de référence — vérifie-le avant de rendre la monnaie.")
                    .scaledFont(12)
                    .foregroundStyle(Color.dangerRed)
                    .padding(10)
                    .background(Color.dangerRed.opacity(0.10), in: .rect(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.dangerRed.opacity(0.25), lineWidth: 1))
            }
        }
    }

    private var commissionRow: some View {
        HStack(spacing: 8) {
            fieldLabel("Commission")
            Spacer()
            TextField("0", text: $commissionTexte)
                .scaledFont(13, design: .monospaced)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .focused($champActif, equals: .commission)
                .frame(width: 64)
                .accessibilityLabel("Commission en pourcentage")
            Text("%")
                .scaledFont(13, design: .monospaced)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.paperBG, in: .rect(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cardLine, lineWidth: 1))
    }

    private var statusIcon: String {
        if tauxPersonnalise { return "pencil" }
        if tauxFixe { return "lock.fill" }
        return store.isFallback ? "exclamationmark.triangle" : "checkmark.circle"
    }

    private var statusText: LocalizedStringKey {
        if tauxPersonnalise {
            return "Taux personnalisé — référence : \(Fmt.rate(tauxReference))"
        }
        if tauxFixe {
            return "Taux de conversion officiel figé (irrévocable)"
        }
        if let error = store.lastError {
            return "\(error)"
        }
        if let date = store.lastUpdated {
            return "Cours en direct — mis à jour le \(Fmt.time(date))"
        }
        return "Taux enregistrés — tire vers le bas pour actualiser"
    }

    private var amountFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                fieldLabel("Prix à payer (en \(deviseB))")
                textField($prix, focus: .prix)
            }
            VStack(alignment: .leading, spacing: 6) {
                fieldLabel("Montant reçu (en \(deviseA))")
                textField($recu, focus: .recu)
            }
            Text(recuLabel)
                .scaledFont(12)
                .foregroundStyle(.secondary)
        }
    }

    private var recuLabel: LocalizedStringKey {
        let montant = Fmt.amount(calcul.receivedConverted, currency: currB)
        if commission > 0 {
            return "Le montant reçu représente \(montant) \(deviseB). (commission \(Fmt.rate(commission))% incluse)"
        }
        return "Le montant reçu représente \(montant) \(deviseB)."
    }

    private var renderTargetPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Rendre la monnaie en")
            HStack(spacing: 8) {
                toggleButton(code: deviseA, active: !rendreEnB) { rendreEnB = false }
                toggleButton(code: deviseB, active: rendreEnB) { rendreEnB = true }
            }
        }
    }

    // MARK: - Composants

    private func fieldLabel(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .scaledFont(11, weight: .semibold)
            .tracking(0.8)
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
    }

    private func textField(_ binding: Binding<String>, focus: Champ) -> some View {
        TextField("", text: binding)
            .scaledFont(15, design: .monospaced)
            .keyboardType(.decimalPad)
            .focused($champActif, equals: focus)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color.paperBG, in: .rect(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cardLine, lineWidth: 1))
    }

    private func toggleButton(code: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("\(CurrencyCatalog.currency(code).flag) \(code)")
                .scaledFont(13, weight: .medium)
                .foregroundStyle(active ? Color.white : Color.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(active ? Color.accentGreen : Color.paperBG, in: .rect(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(active ? Color.accentGreen : Color.cardLine, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(active ? [.isSelected] : [])
    }

    // MARK: - Actions

    /// Réaligne le champ de taux sur le cours de référence et reverrouille la saisie.
    private func syncRate() {
        tauxTexte = Fmt.rate(store.rate(from: deviseA, to: deviseB))
        tauxPersonnalise = false
    }

    private func swapCurrencies() {
        swap(&deviseA, &deviseB)
        rendreEnB.toggle()
    }
}

#Preview {
    ContentView()
}

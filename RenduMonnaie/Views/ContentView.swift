//
//  ContentView.swift
//  Comptoir de change
//
//  Écran principal : saisie du prix, du montant reçu et affichage du rendu.
//

import SwiftUI
import UIKit

struct ContentView: View {

    @State private var store = RateStore()
    @State private var journal = PurchaseJournal()
    @State private var locationService = LocationService()
    @State private var orientation: UIDeviceOrientation = UIDevice.current.orientation
    @State private var showHistory = false
    @State private var showAbout = false
    @State private var achatNote = ""
    @State private var achatEnregistre = false

    // Devises et cible de rendu mémorisées entre deux lancements.
    @AppStorage("deviseA") private var deviseA = "USD"   // devise payée par le client
    @AppStorage("deviseB") private var deviseB = "EUR"   // devise du prix / de la caisse
    @AppStorage("rendreEnB") private var rendreEnB = true

    @State private var tauxTexte = ""
    @State private var tauxPersonnalise = false
    @State private var commissionTexte = ""
    @State private var prix = "45.00"
    @State private var recu = "60.00"
    @State private var pourboireTexte = ""
    @State private var pourboireEnPourcent = true

    @FocusState private var champActif: Champ?
    private enum Champ: Hashable { case taux, commission, prix, recu, pourboire }

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

    // MARK: - Pourboire

    private var prixSaisi: Double { Fmt.number(prix) }
    private var pourboireSaisie: Double { Fmt.number(pourboireTexte) }
    private var pourboireMontant: Double {
        ChangeCalculation.tipAmount(price: prixSaisi, input: pourboireSaisie, isPercent: pourboireEnPourcent)
    }
    private var pourboirePourcent: Double {
        ChangeCalculation.tipPercent(price: prixSaisi, input: pourboireSaisie, isPercent: pourboireEnPourcent)
    }

    private var calcul: ChangeCalculation {
        ChangeCalculation(rate: taux, price: prixSaisi + pourboireMontant,
                          received: Fmt.number(recu), commissionPercent: commission)
    }

    // MARK: - Suggestion de règlement

    /// Prix (pourboire inclus) converti dans la devise remise par le client.
    private var prixEnDeviseA: Double {
        calcul.effectiveRate != 0 ? calcul.price / calcul.effectiveRate : 0
    }
    private var suggestionReglement: PaymentSuggestion? {
        currA.paymentSuggestion(coveringAtLeast: prixEnDeviseA)
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

    /// `true` quand le téléphone est physiquement retourné vers le client, quelle que soit
    /// l'orientation d'interface supportée par l'appareil (l'iPhone ne pivote pas son interface
    /// à l'envers, mais le capteur d'orientation continue de le signaler).
    private var showCustomerDisplay: Bool { orientation == .portraitUpsideDown }

    // MARK: - Corps

    var body: some View {
        ZStack {
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
                        priceCurrency: currB,
                        tipAmount: pourboireMontant,
                        tipPercent: pourboirePourcent
                    )
                    formCard
                    saveCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 48)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.paperBG.ignoresSafeArea())
            .refreshable {
                await store.refresh()
                if !tauxPersonnalise { syncRate() }
            }

            if showCustomerDisplay {
                CustomerDisplayView(
                    priceAmount: calcul.price,
                    priceCurrency: currB,
                    isInsufficient: calcul.isInsufficient,
                    missingAmount: calcul.missingInPriceCurrency,
                    receivedAmount: Fmt.number(recu),
                    receivedCurrency: currA,
                    changeAmount: mainAmount,
                    changeCurrency: payoutCurrency,
                    changeSecondaryAmount: secondaryAmount,
                    changeSecondaryCurrency: secondaryCurrency,
                    commissionAmount: calcul.commissionAmount,
                    commissionPercent: calcul.commissionPercent,
                    tipAmount: pourboireMontant,
                    tipPercent: pourboirePourcent
                )
                .rotationEffect(.degrees(180))
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showCustomerDisplay)
        .task {
            syncRate()
            await store.refresh()
            if !tauxPersonnalise { syncRate() }
        }
        .onChange(of: deviseA) { syncRate() }
        .onChange(of: deviseB) { syncRate() }
        .sheet(isPresented: $showHistory) {
            PurchaseHistoryView(journal: journal, rateStore: store, locationService: locationService)
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("OK") { champActif = nil }
            }
        }
        .onAppear { UIDevice.current.beginGeneratingDeviceOrientationNotifications() }
        .onDisappear { UIDevice.current.endGeneratingDeviceOrientationNotifications() }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            let current = UIDevice.current.orientation
            // Le capteur signale aussi .faceUp/.faceDown/.unknown en cours de mouvement :
            // on les ignore pour ne garder que les quatre orientations stables.
            guard current.isValidInterfaceOrientation else { return }
            orientation = current
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            // Les boutons vivent sur leur propre ligne, au-dessus du titre : ainsi ils ne
            // peuvent jamais le chevaucher, quels que soient la largeur de l'écran ou la
            // taille de texte choisie par l'utilisateur.
            HStack(spacing: 10) {
                aboutButton
                Spacer()
                resetButton
                historyButton
            }

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
            .frame(maxWidth: .infinity)
        }
    }

    private var aboutButton: some View {
        Button { showAbout = true } label: {
            Image(systemName: "info.circle")
                .scaledFont(15, weight: .medium)
                .foregroundStyle(Color.accentGreen)
                .frame(width: 38, height: 38)
                .background(Color.cardBG, in: .circle)
                .overlay(Circle().stroke(Color.cardLine, lineWidth: 1))
        }
        .accessibilityLabel("À propos")
    }

    private var resetButton: some View {
        Button(action: resetForm) {
            Image(systemName: "arrow.counterclockwise.circle")
                .scaledFont(15, weight: .medium)
                .foregroundStyle(Color.accentGreen)
                .frame(width: 38, height: 38)
                .background(Color.cardBG, in: .circle)
                .overlay(Circle().stroke(Color.cardLine, lineWidth: 1))
        }
        .accessibilityLabel("Réinitialiser le calcul en cours")
    }

    private var historyButton: some View {
        Button { showHistory = true } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "clock.arrow.circlepath")
                    .scaledFont(15, weight: .medium)
                    .foregroundStyle(Color.accentGreen)
                    .frame(width: 38, height: 38)
                    .background(Color.cardBG, in: .circle)
                    .overlay(Circle().stroke(Color.cardLine, lineWidth: 1))

                if !journal.entries.isEmpty {
                    Text("\(journal.entries.count)")
                        .scaledFont(9, weight: .bold)
                        .foregroundStyle(.white)
                        .frame(minWidth: 15, minHeight: 15)
                        .background(Color.accentGold, in: .circle)
                        .offset(x: 5, y: -5)
                }
            }
        }
        .accessibilityLabel(Text("Historique des achats, \(journal.entries.count) enregistrés"))
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

    private var saveCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            fieldLabel("Libellé (optionnel)")
            TextField("Ex. café, souvenir, taxi…", text: $achatNote)
                .scaledFont(14)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.paperBG, in: .rect(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cardLine, lineWidth: 1))

            Button(action: savePurchase) {
                HStack {
                    Image(systemName: achatEnregistre ? "checkmark.circle.fill" : "tray.and.arrow.down")
                    Text(achatEnregistre ? "Achat enregistré" : "Enregistrer cet achat")
                }
                .scaledFont(14, weight: .semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(canSave ? Color.accentGreen : Color.secondary.opacity(0.35), in: .rect(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .disabled(!canSave)

            Text("Cumule tes achats ici pour retrouver un bilan complet en fin de voyage.")
                .scaledFont(11)
                .foregroundStyle(.secondary)
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
            .accessibilityLabel(Text(titleKey) + Text(" : ") + Text(LocalizedStringKey(current.country)))

            Text(LocalizedStringKey(current.country))
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
                if let equivalent = prixEnEuro {
                    Text(equivalent)
                        .scaledFont(11)
                        .foregroundStyle(.secondary)
                }
            }
            pourboireRow
            VStack(alignment: .leading, spacing: 6) {
                fieldLabel("Montant reçu (en \(deviseA))")
                textField($recu, focus: .recu)
            }
            if let suggestion = suggestionReglement {
                suggestionRow(suggestion)
            }
            Text(recuLabel)
                .scaledFont(12)
                .foregroundStyle(.secondary)
        }
    }

    private var pourboireRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                fieldLabel("Pourboire")
                Spacer()
                Button {
                    pourboireEnPourcent.toggle()
                } label: {
                    Text(pourboireEnPourcent ? "%" : deviseB)
                        .scaledFont(12, weight: .semibold)
                        .foregroundStyle(Color.accentGreen)
                        .frame(minWidth: 32)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 6)
                        .background(Color.accentGreen.opacity(0.12), in: .rect(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Changer l'unité du pourboire")

                TextField("0", text: $pourboireTexte)
                    .scaledFont(13, design: .monospaced)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .focused($champActif, equals: .pourboire)
                    .frame(width: 64)
                    .accessibilityLabel("Montant du pourboire")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.paperBG, in: .rect(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cardLine, lineWidth: 1))

            if pourboireSaisie > 0, let equivalent = pourboireEquivalent {
                Text(equivalent)
                    .scaledFont(11)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Prix saisi converti en euros, affiché comme repère quand la devise du prix n'est pas déjà l'euro.
    private var prixEnEuro: LocalizedStringKey? {
        guard deviseB != "EUR", prixSaisi > 0 else { return nil }
        let value = prixSaisi * store.rate(from: deviseB, to: "EUR")
        guard value > 0 else { return nil }
        return "≈ \(Fmt.amount(value, currency: CurrencyCatalog.currency("EUR"))) €"
    }

    private var pourboireEquivalent: LocalizedStringKey? {
        guard pourboireSaisie > 0 else { return nil }
        if pourboireEnPourcent {
            return "= \(Fmt.amount(pourboireMontant, currency: currB)) \(deviseB)"
        }
        return "= \(String(format: "%.1f", pourboirePourcent))% du prix"
    }

    private func suggestionRow(_ suggestion: PaymentSuggestion) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lightbulb")
                .scaledFont(11)
                .foregroundStyle(Color.accentGreen)
            Text(suggestionText(suggestion))
                .scaledFont(12)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 4)
            Button("Utiliser") {
                recu = Fmt.amount(suggestion.roundedAmount, currency: currA)
            }
            .scaledFont(11, weight: .semibold)
            .foregroundStyle(Color.accentGreen)
            .accessibilityLabel("Remplir le montant reçu avec cette suggestion")
        }
    }

    private func suggestionText(_ suggestion: PaymentSuggestion) -> LocalizedStringKey {
        let rounded = Fmt.amount(suggestion.roundedAmount, currency: currA)
        guard let bill = suggestion.singleBill else {
            return "Proposer \(rounded) \(deviseA)."
        }
        return "Proposer \(rounded) \(deviseA) (billet entier existant : \(Fmt.amount(bill, currency: currA)) \(deviseA))."
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

    /// Efface la saisie en cours (prix, reçu, pourboire, commission, libellé) pour repartir
    /// sur un nouveau calcul, sans toucher aux devises ni à l'historique.
    private func resetForm() {
        champActif = nil
        prix = ""
        recu = ""
        pourboireTexte = ""
        commissionTexte = ""
        achatNote = ""
        syncRate()
    }

    /// `true` quand le calcul courant représente un achat valide, enregistrable dans le journal.
    private var canSave: Bool {
        !calcul.isInsufficient && prixSaisi > 0 && Fmt.number(recu) > 0
    }

    /// Ajoute l'achat courant au journal de voyage et affiche une confirmation brève.
    /// Le lieu (si autorisé) est relevé au moment même de la validation.
    private func savePurchase() {
        guard canSave else { return }

        // On fige les valeurs de l'achat avant l'attente de la position, pour ne pas
        // enregistrer des montants que l'utilisateur aurait modifiés entre-temps.
        let note = achatNote.trimmingCharacters(in: .whitespacesAndNewlines)
        let priceCurrencyCode = deviseB
        let price = prixSaisi
        let tipAmount = pourboireMontant
        let paidCurrencyCode = deviseA
        let receivedAmount = Fmt.number(recu)
        let changeAmount = mainAmount
        let changeCurrencyCode = payoutCurrency.code
        let rate = taux
        let commissionPercent = commission
        let commissionAmount = calcul.commissionAmount

        achatNote = ""
        withAnimation { achatEnregistre = true }

        Task {
            let location = await locationService.currentLocation()
            journal.add(PurchaseEntry(
                note: note,
                priceCurrencyCode: priceCurrencyCode,
                price: price,
                tipAmount: tipAmount,
                paidCurrencyCode: paidCurrencyCode,
                receivedAmount: receivedAmount,
                changeAmount: changeAmount,
                changeCurrencyCode: changeCurrencyCode,
                rate: rate,
                commissionPercent: commissionPercent,
                commissionAmount: commissionAmount,
                latitude: location?.coordinate.latitude,
                longitude: location?.coordinate.longitude
            ))
            try? await Task.sleep(for: .seconds(1.6))
            withAnimation { achatEnregistre = false }
        }
    }
}

#Preview {
    ContentView()
}

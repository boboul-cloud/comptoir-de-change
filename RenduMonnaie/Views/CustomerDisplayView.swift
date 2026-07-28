//
//  CustomerDisplayView.swift
//  Comptoir de change
//
//  Écran affiché côté client quand le téléphone est retourné vers lui :
//  transparence totale sur le prix, la somme à fournir et la monnaie rendue.
//

import SwiftUI
import UIKit

struct CustomerDisplayView: View {

    /// Contre-valeur d'un montant dans une autre devise que celle où il est affiché
    /// en premier lieu (ex. le prix, aussi exprimé dans la devise du reçu et du rendu).
    struct CurrencyEquivalent: Identifiable {
        let amount: Double
        let currency: Currency
        var id: String { currency.code }
    }

    let priceAmount: Double
    let priceCurrency: Currency
    /// Contre-valeurs du prix dans la devise du reçu et celle du rendu, quand elles
    /// diffèrent de la devise du prix (et entre elles) — transparence totale pour le
    /// client, qui ne connaît pas forcément la devise du prix.
    var priceEquivalents: [CurrencyEquivalent] = []

    let isInsufficient: Bool
    let missingAmount: Double

    let receivedAmount: Double
    let receivedCurrency: Currency

    let changeAmount: Double
    let changeCurrency: Currency
    let changeSecondaryAmount: Double
    let changeSecondaryCurrency: Currency

    let commissionAmount: Double
    let commissionPercent: Double
    /// Contre-valeurs de la commission dans la devise du reçu et celle du rendu, mêmes
    /// règles que `priceEquivalents`.
    var commissionEquivalents: [CurrencyEquivalent] = []
    let tipAmount: Double
    let tipPercent: Double
    /// Contre-valeurs du pourboire dans la devise du reçu et celle du rendu, mêmes
    /// règles que `priceEquivalents`.
    var tipEquivalents: [CurrencyEquivalent] = []

    var body: some View {
        VStack(spacing: 28) {
            row(
                label: "PRIX", value: Fmt.amount(priceAmount, currency: priceCurrency), code: priceCurrency.code,
                equivalents: priceEquivalents
            )

            Divider().overlay(.white.opacity(0.15))

            if receivedAmount > 0 {
                row(label: "REÇU", value: Fmt.amount(receivedAmount, currency: receivedCurrency), code: receivedCurrency.code)
            }

            Divider().overlay(.white.opacity(0.15))

            if isInsufficient {
                row(label: "IL MANQUE", value: Fmt.amount(missingAmount, currency: priceCurrency), code: priceCurrency.code, accent: Color.dangerRed)
            } else {
                row(label: "MONNAIE RENDUE", value: Fmt.amount(changeAmount, currency: changeCurrency), code: changeCurrency.code)
                Text("soit \(Fmt.amount(changeSecondaryAmount, currency: changeSecondaryCurrency)) \(changeSecondaryCurrency.code)")
                    .scaledFont(15, design: .monospaced)
                    .foregroundStyle(.white)
            }

            if commissionAmount > 0 || tipAmount > 0 {
                Divider().overlay(.white.opacity(0.1))
                HStack(spacing: 32) {
                    if commissionAmount > 0 {
                        detailRow(
                            label: "COMMISSION", amount: commissionAmount, currency: priceCurrency,
                            percent: commissionPercent, equivalents: commissionEquivalents
                        )
                    }
                    if tipAmount > 0 {
                        detailRow(
                            label: "POURBOIRE", amount: tipAmount, currency: priceCurrency,
                            percent: tipPercent, equivalents: tipEquivalents
                        )
                    }
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.boardBG)
        .accessibilityElement(children: .combine)
    }

    private func row(
        label: LocalizedStringKey, value: String, code: String, accent: Color = .cream,
        equivalents: [CurrencyEquivalent] = []
    ) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .scaledFont(13, design: .monospaced)
                .tracking(2.5)
                .foregroundStyle(.white)
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(value)
                    .scaledFont(40, weight: .bold, design: .monospaced)
                    .foregroundStyle(accent)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(code)
                    .scaledFont(16, design: .monospaced)
                    .foregroundStyle(Color.accentGold)
            }
            ForEach(equivalents) { equivalent in
                Text("soit \(Fmt.amount(equivalent.amount, currency: equivalent.currency)) \(equivalent.currency.code)")
                    .scaledFont(15, design: .monospaced)
                    .foregroundStyle(.white)
            }
        }
    }

    private func detailRow(
        label: LocalizedStringKey, amount: Double, currency: Currency, percent: Double,
        equivalents: [CurrencyEquivalent] = []
    ) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .scaledFont(11, design: .monospaced)
                .tracking(2)
                .foregroundStyle(.white)
            HStack(spacing: 6) {
                Text("\(Fmt.amount(amount, currency: currency)) \(currency.code)")
                    .scaledFont(15, weight: .semibold, design: .monospaced)
                    .foregroundStyle(Color.accentGold)
                Text("(\(String(format: "%.1f", percent))%)")
                    .scaledFont(12, design: .monospaced)
                    .foregroundStyle(.white)
            }
            ForEach(equivalents) { equivalent in
                Text("soit \(Fmt.amount(equivalent.amount, currency: equivalent.currency)) \(equivalent.currency.code)")
                    .scaledFont(11, design: .monospaced)
                    .foregroundStyle(.white)
            }
        }
    }
}

/// Superpose l'« écran inversé » (`CustomerDisplayView`) dès que l'appareil est
/// physiquement retourné vers le client, quel que soit l'écran affiché par ailleurs —
/// écran principal ou saisie en gros caractères. Le calcul en cours est fourni par
/// l'appelant ; ce modifier ne gère que la détection d'orientation et la rotation.
struct CustomerDisplayOverlay: ViewModifier {
    let priceAmount: Double
    let priceCurrency: Currency
    var priceEquivalents: [CustomerDisplayView.CurrencyEquivalent] = []

    let isInsufficient: Bool
    let missingAmount: Double

    let receivedAmount: Double
    let receivedCurrency: Currency

    let changeAmount: Double
    let changeCurrency: Currency
    let changeSecondaryAmount: Double
    let changeSecondaryCurrency: Currency

    let commissionAmount: Double
    let commissionPercent: Double
    var commissionEquivalents: [CustomerDisplayView.CurrencyEquivalent] = []
    let tipAmount: Double
    let tipPercent: Double
    var tipEquivalents: [CustomerDisplayView.CurrencyEquivalent] = []

    @State private var orientation: UIDeviceOrientation = UIDevice.current.orientation

    /// `true` quand le téléphone est physiquement retourné vers le client, quelle que
    /// soit l'orientation d'interface supportée par l'appareil (l'iPhone ne pivote pas
    /// son interface à l'envers, mais le capteur d'orientation continue de le signaler).
    private var showCustomerDisplay: Bool { orientation == .portraitUpsideDown }

    /// Sur iPhone, `UISupportedInterfaceOrientations` exclut le mode tête-en-bas :
    /// l'interface reste fixe et il faut donc pivoter manuellement l'affichage client
    /// de 180°. Sur iPad en revanche, `UISupportedInterfaceOrientations_iPad` inclut ce
    /// mode : iOS pivote déjà nativement toute l'interface quand la tablette est
    /// retournée. Ajouter une rotation manuelle par-dessus annulerait cette correction
    /// native (180 + 180 = 360°) et afficherait l'écran client à l'envers.
    private var needsManualCustomerRotation: Bool { UIDevice.current.userInterfaceIdiom != .pad }

    func body(content: Content) -> some View {
        ZStack {
            content

            if showCustomerDisplay {
                CustomerDisplayView(
                    priceAmount: priceAmount,
                    priceCurrency: priceCurrency,
                    priceEquivalents: priceEquivalents,
                    isInsufficient: isInsufficient,
                    missingAmount: missingAmount,
                    receivedAmount: receivedAmount,
                    receivedCurrency: receivedCurrency,
                    changeAmount: changeAmount,
                    changeCurrency: changeCurrency,
                    changeSecondaryAmount: changeSecondaryAmount,
                    changeSecondaryCurrency: changeSecondaryCurrency,
                    commissionAmount: commissionAmount,
                    commissionPercent: commissionPercent,
                    commissionEquivalents: commissionEquivalents,
                    tipAmount: tipAmount,
                    tipPercent: tipPercent,
                    tipEquivalents: tipEquivalents
                )
                .rotationEffect(.degrees(needsManualCustomerRotation ? 180 : 0))
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showCustomerDisplay)
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
}

#Preview {
    let eur = CurrencyCatalog.currency("EUR")
    let usd = CurrencyCatalog.currency("USD")
    return CustomerDisplayView(
        priceAmount: 49.50,
        priceCurrency: eur,
        priceEquivalents: [.init(amount: 53.80, currency: usd)],
        isInsufficient: false,
        missingAmount: 0,
        receivedAmount: 60,
        receivedCurrency: usd,
        changeAmount: 3.17,
        changeCurrency: eur,
        changeSecondaryAmount: 3.61,
        changeSecondaryCurrency: usd,
        commissionAmount: 2.50,
        commissionPercent: 3.0,
        commissionEquivalents: [.init(amount: 2.72, currency: usd)],
        tipAmount: 4.50,
        tipPercent: 10.0,
        tipEquivalents: [.init(amount: 4.89, currency: usd)]
    )
}

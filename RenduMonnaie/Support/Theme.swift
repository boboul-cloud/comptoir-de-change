//
//  Theme.swift
//  Comptoir de change
//
//  Palette de couleurs adaptative (clair / sombre) et police redimensionnable.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

extension Color {
    // Couleurs signatures, identiques dans les deux thèmes (elles vivent sur l'« ardoise »).
    static let boardBG = Color(red: 0.11, green: 0.12, blue: 0.11)
    static let cream = Color(red: 0.95, green: 0.93, blue: 0.89)
    static let accentGreen = Color(red: 0.30, green: 0.55, blue: 0.36)
    static let accentGold = Color(red: 0.84, green: 0.66, blue: 0.29)
    static let dangerRed = Color(red: 0.78, green: 0.33, blue: 0.25)

    // Surfaces adaptatives.
    static let paperBG = adaptive(light: (0.96, 0.95, 0.93), dark: (0.07, 0.08, 0.07))
    static let cardBG  = adaptive(light: (1.00, 1.00, 1.00), dark: (0.13, 0.14, 0.13))
    static let cardLine = adaptive(light: (0.87, 0.85, 0.79), dark: (0.24, 0.26, 0.24))

    private static func adaptive(
        light: (Double, Double, Double),
        dark: (Double, Double, Double)
    ) -> Color {
        #if canImport(UIKit)
        return Color(UIColor { trait in
            let c = trait.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
        })
        #else
        return Color(red: light.0, green: light.1, blue: light.2)
        #endif
    }
}

// MARK: - Police redimensionnable (Dynamic Type)

/// Police à taille fixe mais qui suit les réglages d'accessibilité de l'utilisateur.
private struct ScaledFont: ViewModifier {
    @ScaledMetric private var size: CGFloat
    private let weight: Font.Weight
    private let design: Font.Design

    init(size: CGFloat, relativeTo: Font.TextStyle, weight: Font.Weight, design: Font.Design) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: relativeTo)
        self.weight = weight
        self.design = design
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight, design: design))
    }
}

extension View {
    /// Comme `.font(.system(size:))` mais redimensionnable via Dynamic Type.
    func scaledFont(
        _ size: CGFloat,
        relativeTo: Font.TextStyle = .body,
        weight: Font.Weight = .regular,
        design: Font.Design = .default
    ) -> some View {
        modifier(ScaledFont(size: size, relativeTo: relativeTo, weight: weight, design: design))
    }
}

#if canImport(UIKit)
extension UIKeyboardType {
    /// Sur iPad, `.decimalPad` s'affiche toujours en petit panneau flottant qui peut
    /// recouvrir le champ de saisie — c'est le seul type de clavier iPad qui n'a pas de
    /// disposition ancrée pleine largeur, quel que soit le réglage clavier de
    /// l'utilisateur. `.numbersAndPunctuation` a cette disposition ancrée et couvre les
    /// mêmes besoins (chiffres, virgule, point) ; on ne le réserve pas à l'iPhone, où
    /// `.decimalPad` s'affiche déjà ancré en pleine largeur.
    @MainActor
    static var numericEntry: UIKeyboardType {
        UIDevice.current.userInterfaceIdiom == .pad ? .numbersAndPunctuation : .decimalPad
    }
}
#endif

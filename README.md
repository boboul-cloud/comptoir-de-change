# Comptoir de change

Application iOS (SwiftUI) de calcul du rendu de monnaie entre deux devises,
pensée pour un vrai comptoir de change.

- **Détail des billets et pièces à rendre** (rendu optimal par dénominations).
- **Taux en direct** via l'API [Frankfurter](https://www.frankfurter.app) (données BCE),
  avec cache local et table de secours hors ligne.
- **Décimales et arrondis corrects par devise** : le yen n'a pas de centimes,
  le franc suisse s'arrondit à 0,05, etc.
- **Commission / marge** de change optionnelle.
- **Anciennes devises de la zone euro** à taux irrévocable (franc, mark, lire, peseta…).
- **Thème clair / sombre** adaptatif, **Dynamic Type** et libellés **VoiceOver**.
- **Bilingue** français / anglais (String Catalog).

## Ouvrir le projet

```bash
xcodegen generate        # (re)génère RenduMonnaie.xcodeproj depuis project.yml
open RenduMonnaie.xcodeproj
```

Lancer la cible **RenduMonnaie** sur un simulateur ou un iPhone (iOS 17+).

## Ligne de commande

```bash
# Compiler
xcodebuild -scheme RenduMonnaie -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' build

# Tester
xcodebuild -scheme RenduMonnaie \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

La CI (GitHub Actions, `.github/workflows/ci.yml`) rejoue build + tests à chaque push.

## Architecture

```
RenduMonnaie/
  App/        Point d'entrée (@main)
  Models/     Currency, CashBreakdown, ChangeCalculation (logique pure), RateStore (@Observable)
  Support/    Formatting, Theme (couleurs adaptatives + Dynamic Type)
  Views/      ContentView, ResultBoard, CashBreakdownView
  Resources/  Assets.xcassets, Localizable.xcstrings
RenduMonnaieTests/   Tests Swift Testing (calcul, rendu cash, réseau mocké)
design/              Source vectorielle de l'icône (AppIcon.svg)
```

Les calculs (`ChangeCalculation`, `CashBreakdown`) et le réseau (`RateStore`, via une
`URLSession` injectable) sont isolés de l'interface pour être testés indépendamment.

## Pile technique

- Swift 6 / SwiftUI, cible iOS 17
- Framework **Observation** (`@Observable`) pour l'état
- Persistance des préférences via `@AppStorage`, cache des taux via `UserDefaults`
- Tests avec **Swift Testing**, projet généré par **XcodeGen**

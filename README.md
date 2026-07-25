# Comptoir de change

Application iOS (SwiftUI) de calcul du rendu de monnaie entre deux devises,
pensée pour un vrai comptoir de change — et pour tenir le bilan financier
d'un voyage à l'étranger.

[Site & politique de confidentialité](https://boboul-cloud.github.io/comptoir-de-change/) · [Licence MIT](LICENSE)

## Fonctionnalités

- **Détail des billets et pièces à rendre** (rendu optimal par dénominations).
- **Taux en direct** via l'API [Frankfurter](https://www.frankfurter.app) (données BCE),
  avec cache local et table de secours hors ligne.
- **Décimales et arrondis corrects par devise** : le yen n'a pas de centimes,
  le franc suisse s'arrondit à 0,05, etc.
- **Commission / marge** de change optionnelle, et **pourboire** en montant ou en %.
- **Anciennes devises de la zone euro** à taux irrévocable (franc, mark, lire, peseta…).
- **Journal d'achats de voyage** : chaque calcul peut être enregistré (devise, montants,
  lieu relevé au moment de la validation), avec un **bilan** total en euros et par devise.
- **Export PDF** du bilan détaillé (achats groupés par jour, devise, lieu) depuis
  l'historique, prêt à partager.
- **Fiche par achat** avec le lieu affiché sur une carte (MapKit), quand la
  localisation était autorisée.
- **Écran client** : retourner le téléphone affiche le détail en transparence côté client.
- **Thème clair / sombre** adaptatif, **Dynamic Type** et libellés **VoiceOver**.
- **Bilingue** français / anglais (String Catalog), suit la langue de l'appareil.

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
  Models/     Currency, CashBreakdown, ChangeCalculation (logique pure),
              RateStore, LocationService, PurchaseEntry, PurchaseJournal (@Observable)
  Support/    Formatting, Theme, PDFExporter, ActivityView
  Views/      ContentView, ResultBoard, CashBreakdownView, CustomerDisplayView,
              PurchaseHistoryView, PurchaseDetailView, PurchaseReportView (PDF)
  Resources/  Assets.xcassets, Localizable.xcstrings, PrivacyInfo.xcprivacy
RenduMonnaieTests/   Tests Swift Testing (calcul, rendu cash, journal, PDF, réseau mocké)
docs/                Site GitHub Pages (accueil + politique de confidentialité)
design/              Source vectorielle de l'icône (AppIcon.svg)
```

Les calculs (`ChangeCalculation`, `CashBreakdown`) et le réseau (`RateStore`, via une
`URLSession` injectable) sont isolés de l'interface pour être testés indépendamment.

## Pile technique

- Swift 6 / SwiftUI, cible iOS 17
- Framework **Observation** (`@Observable`) pour l'état
- Persistance des préférences via `@AppStorage`, cache des taux et journal via `UserDefaults`
- **CoreLocation** (position ponctuelle + géocodage inverse) et **MapKit**
- Export PDF vectoriel via `ImageRenderer`
- Tests avec **Swift Testing**, projet généré par **XcodeGen**

## Confidentialité

Aucune donnée n'est envoyée à un serveur nous appartenant : les taux de change viennent
d'API publiques tierces (sans identifiant utilisateur), et le lieu d'un achat est
géocodé uniquement via le service Apple. Le journal d'achats reste stocké localement
sur l'appareil. Détails : [politique de confidentialité](https://boboul-cloud.github.io/comptoir-de-change/privacy.html).

## Licence

[MIT](LICENSE) — voir le fichier `LICENSE`.

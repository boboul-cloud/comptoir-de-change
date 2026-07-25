# Fiche App Store — brouillon

Ce document rassemble tout le texte prêt à copier-coller dans App Store Connect.
Les captures d'écran et l'envoi du build restent à faire depuis Xcode (voir
checklist en bas).

## Identité

| Champ | Valeur |
|---|---|
| Nom de l'app | Comptoir de change |
| Sous-titre (30 car. max) | Rendu de monnaie & bilan voyage |
| Bundle ID | `com.oulhen.rendumonnaie` |
| Catégorie principale | Finance |
| Catégorie secondaire | Voyage |
| Classification d'âge | 4+ (aucun contenu sensible) |
| Prix | Gratuit |
| URL de support | https://boboul-cloud.github.io/comptoir-de-change/ |
| URL politique de confidentialité | https://boboul-cloud.github.io/comptoir-de-change/privacy.html |

## Description (français)

```
Comptoir de change calcule le rendu de monnaie entre deux devises avec le
détail exact des billets et pièces à rendre — pensé pour un vrai comptoir
de change, mais tout aussi utile en voyage.

FONCTIONNALITÉS
• Rendu optimal en billets et pièces, par dénominations réelles de chaque devise
• Taux de change en direct (données BCE), avec cache hors ligne
• Décimales et arrondis corrects par devise (yen sans centimes, franc suisse
  arrondi à 0,05…)
• Commission de change et pourboire optionnels
• Anciennes devises de la zone euro à taux irrévocable

JOURNAL DE VOYAGE
Enregistre chaque achat calculé avec un libellé et le lieu où il a eu lieu.
Retrouve un bilan complet — total en euros et par devise — et exporte-le en
PDF détaillé pour le partager ou le garder en souvenir.

CONÇU POUR ÊTRE UTILISÉ AU COMPTOIR
Retourne le téléphone pour afficher le calcul en toute transparence côté
client. Thème clair et sombre, VoiceOver, texte adaptatif.

Aucun compte requis. Aucune donnée personnelle collectée ni revendue.
```

## Description (English)

```
Comptoir de change calculates the exact change due between two currencies,
down to the bills and coins — built for a real currency exchange counter,
and just as handy on a trip.

FEATURES
• Optimal change breakdown in real bills and coins per currency
• Live exchange rates (ECB data), with offline cache
• Correct decimals and rounding per currency (no cents for yen, Swiss franc
  rounds to 0.05…)
• Optional exchange commission and tip
• Legacy eurozone currencies at their fixed conversion rate

TRIP JOURNAL
Save any calculation as a purchase with a label and the place it happened.
Get a full summary — total in euros and by currency — and export it as a
detailed PDF to share or keep.

BUILT FOR THE COUNTER
Flip the phone to show the calculation transparently to the customer. Light
and dark themes, VoiceOver, adaptive text.

No account required. No personal data collected or sold.
```

## Mots-clés (100 car. max, séparés par des virgules)

```
change,devise,monnaie,voyage,currency,exchange,change,billet,pourboire,taux,bilan,budget
```

## Texte promotionnel (170 car. max — modifiable sans nouvelle version)

```
Nouveau : journal d'achats de voyage avec bilan en euros et export PDF détaillé, lieu par achat inclus.
```

## Notes de version — 1.0.0

```
Première version : calcul du rendu de monnaie, taux en direct, journal
d'achats de voyage avec bilan et export PDF, écran client, thème clair/sombre.
```

## Checklist avant soumission

- [ ] Créer l'app dans App Store Connect (bundle ID `com.oulhen.rendumonnaie`)
- [ ] Renseigner la fiche avec le texte ci-dessus
- [ ] Captures d'écran requises (au moins iPhone 6,9" ; iPad si `TARGETED_DEVICE_FAMILY`
      inclut l'iPad, ce qui est le cas ici) — à faire depuis un simulateur ou un appareil
- [ ] Vérifier dans Xcode : signature automatique avec ton compte développeur,
      Team ID renseigné dans les réglages de signature du projet
- [ ] Répondre au questionnaire de confidentialité App Store Connect en cohérence
      avec `RenduMonnaie/Resources/PrivacyInfo.xcprivacy` et la politique publiée
      (résumé : localisation précise accédée mais non transmise à un serveur,
      non liée à l'identité, non utilisée pour le tracking)
- [ ] Product → Archive dans Xcode, puis envoyer via l'Organizer
- [ ] Soumettre le build pour validation App Store

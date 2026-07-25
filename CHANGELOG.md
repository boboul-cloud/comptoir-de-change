# Journal des modifications

Ce projet suit [Semantic Versioning](https://semver.org/lang/fr/).

## [1.0.0] - 2026-07-25

### Ajouté

- Calcul du rendu de monnaie entre deux devises, avec détail des billets et pièces.
- Taux de change en direct (API Frankfurter / BCE), cache local, table de secours hors ligne.
- Commission de change et pourboire (montant ou pourcentage) optionnels.
- Anciennes devises de la zone euro à taux irrévocable.
- Écran client (retournement du téléphone) affichant le détail en transparence.
- **Journal d'achats de voyage** : enregistrement d'un calcul avec libellé et lieu
  relevé au moment de la validation.
- **Bilan de voyage** dans l'historique : total en euros et détail par devise.
- **Export PDF** du bilan détaillé (achats groupés par jour, devise, lieu).
- **Fiche par achat** avec carte (MapKit) du lieu, quand disponible.
- Bouton de réinitialisation rapide du calcul en cours.
- Thème clair / sombre adaptatif, Dynamic Type, VoiceOver.
- App bilingue français / anglais, suit la langue de l'appareil.

# Journal des modifications

Ce projet suit [Semantic Versioning](https://semver.org/lang/fr/).

## [1.1.0] - 2026-07-30

### Ajouté

- Rendu de monnaie dans n'importe quelle devise du catalogue, pas seulement les
  deux devises de la transaction.
- **Calcul de change autonome** : un montant, une commission, un résultat clair,
  indépendant du prix à payer et du rendu de monnaie.
- Distinction **achats / ventes** : historique, bilan et export PDF filtrés
  séparément par type de transaction.
- Choix de la devise du bilan de voyage (euro par défaut).
- **Écran de saisie en gros caractères** pour les utilisateurs malvoyants,
  synchronisé en temps réel avec l'écran principal.
- 11 nouvelles devises : dirham des Émirats et du Maroc, riyal saoudien et
  qatari, livre égyptienne, dinar algérien et tunisien, franc CFA (Afrique de
  l'Ouest et centrale), franc CFP (Polynésie française), dollar taïwanais.
- L'écran client affiche désormais le prix, la commission et le pourboire dans
  les devises du reçu et du rendu quand elles diffèrent.
- Page d'assistance sur le site (FAQ, contact).

### Corrigé

- L'écran client (« écran inversé ») s'affichait à l'envers sur iPad, faute de
  distinguer la rotation déjà gérée nativement par l'OS.
- Le clavier numérique s'affichait en panneau flottant sur iPad au lieu d'être
  ancré en pleine largeur.
- Un bug de calcul rendait trop de monnaie dans la devise payée dès qu'une
  commission était appliquée.
- Amélioration du contraste : les informations sur fond sombre, auparavant en
  gris peu lisible, sont maintenant en blanc plein.

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

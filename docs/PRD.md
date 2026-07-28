# FishMap AI — Product Requirements Document

Version: 0.1  
Statut: Phase 4 — conception détaillée

## 1. Vision

FishMap AI aide les pêcheurs à préparer, exécuter et analyser une session de pêche à partir de données géographiques, météo, marines et communautaires.

Le produit ne promet jamais une capture. Il fournit une recommandation explicable, contextualisée et présentée comme une aide à la décision.

## 2. Utilisateur cible du MVP

Le MVP vise en priorité les pêcheurs du bord en Corse, débutants à confirmés, qui veulent décider rapidement :

- où aller ;
- quand partir ;
- quelle espèce cibler ;
- quel matériel préparer ;
- quel plan de repli utiliser.

## 3. Proposition de valeur

En moins de 30 secondes, l’utilisateur obtient un plan de session comprenant :

- un spot principal ;
- un créneau conseillé ;
- un FishScore expliqué ;
- les espèces probables ;
- le matériel recommandé ;
- un ou deux spots de secours.

## 4. Fonctionnalités du MVP

### 4.1 Authentification

- inscription par e-mail ;
- connexion ;
- réinitialisation du mot de passe ;
- suppression du compte.

### 4.2 Carte

- géolocalisation ;
- affichage des spots publics ;
- filtres par espèce, technique et distance ;
- fiche spot ;
- favoris.

### 4.3 FishScore v1

Le score est calculé à partir de règles transparentes :

- vent ;
- houle ;
- température ;
- heure du jour ;
- phase lunaire ;
- historique disponible ;
- compatibilité spot/espèce.

Chaque score doit afficher ses principaux facteurs positifs et négatifs.

### 4.4 Plan de session

- heure de départ conseillée ;
- durée estimée ;
- spot principal ;
- spots de secours ;
- espèces ciblées ;
- matériel conseillé ;
- résumé météo.

### 4.5 Journal de captures

- date et heure ;
- position approximative ou privée ;
- espèce ;
- taille et poids facultatifs ;
- leurre/appât ;
- photo ;
- remise à l’eau ;
- notes personnelles.

### 4.6 Profil

- niveau ;
- techniques préférées ;
- espèces favorites ;
- matériel principal ;
- paramètres de confidentialité.

## 5. Hors périmètre du MVP

- messagerie privée ;
- marketplace ;
- compétition ;
- reconnaissance automatique d’espèces ;
- navigation marine professionnelle ;
- prédiction probabiliste avancée par apprentissage automatique ;
- couverture européenne complète.

## 6. Exigences de confiance

1. Aucune donnée inventée.
2. Les estimations sont identifiées comme telles.
3. Les spots privés ne sont jamais rendus publics par défaut.
4. Les coordonnées sensibles peuvent être arrondies.
5. Le FishScore reste explicable.
6. Les sources externes et leur date de mise à jour doivent être traçables.

## 7. Indicateurs du MVP

- taux d’activation : premier plan de session créé ;
- nombre de sessions préparées par utilisateur ;
- taux de retour à 7 jours ;
- nombre de captures enregistrées ;
- pourcentage de recommandations jugées utiles ;
- taux de signalement de données incorrectes.

## 8. Critères de réussite de la bêta

La bêta est considérée exploitable lorsque :

- un utilisateur peut créer un compte ;
- ouvrir la carte ;
- consulter un spot ;
- obtenir un FishScore expliqué ;
- générer un plan de session ;
- enregistrer une capture ;
- gérer la confidentialité de ses données ;
- utiliser l’application sans blocage majeur sur Android.

## 9. Décisions encore requises

- nom commercial définitif ;
- modèle gratuit/premium précis ;
- fournisseur météo marine ;
- stratégie légale pour les données bathymétriques ;
- niveau de précision des coordonnées publiques ;
- périmètre exact de la première zone pilote en Corse.

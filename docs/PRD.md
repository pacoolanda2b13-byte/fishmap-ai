# FishMap AI — Product Requirements Document

Version: 0.2  
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

## 3. Zone pilote validée

La première bêta sera concentrée sur le littoral entre **Solenzara et Aléria**.

Ce choix permet :

- de limiter le volume initial de données à contrôler ;
- de tester le produit sur une zone connue du fondateur ;
- de valider les recommandations sur le terrain ;
- de recueillir des observations locales fiables ;
- d’itérer rapidement avant une extension au reste de la Corse.

Espèces prioritaires pour la bêta :

1. barracuda ;
2. dorade royale ;
3. loup ;
4. liche.

Type de pratique prioritaire : **pêche du bord en Méditerranée**.

## 4. Proposition de valeur

En moins de 30 secondes, l’utilisateur obtient un plan de session comprenant :

- un spot principal ;
- un créneau conseillé ;
- un FishScore expliqué ;
- les espèces probables ;
- le matériel recommandé ;
- un ou deux spots de secours.

## 5. Fonctionnalités du MVP

### 5.1 Authentification

- inscription par e-mail ;
- connexion ;
- réinitialisation du mot de passe ;
- suppression du compte.

### 5.2 Carte

- géolocalisation ;
- affichage des spots publics ;
- filtres par espèce, technique et distance ;
- fiche spot ;
- favoris.

### 5.3 FishScore v1

Le score est calculé à partir de règles transparentes :

- vent ;
- houle ;
- température ;
- heure du jour ;
- phase lunaire ;
- historique disponible ;
- compatibilité spot/espèce.

Chaque score doit afficher ses principaux facteurs positifs et négatifs.

### 5.4 Plan de session

- heure de départ conseillée ;
- durée estimée ;
- spot principal ;
- spots de secours ;
- espèces ciblées ;
- matériel conseillé ;
- résumé météo.

### 5.5 Journal de captures

- date et heure ;
- position approximative ou privée ;
- espèce ;
- taille et poids facultatifs ;
- leurre/appât ;
- photo ;
- remise à l’eau ;
- notes personnelles.

### 5.6 Profil

- niveau ;
- techniques préférées ;
- espèces favorites ;
- matériel principal ;
- paramètres de confidentialité.

## 6. Hors périmètre du MVP

- messagerie privée ;
- marketplace ;
- compétition ;
- reconnaissance automatique d’espèces ;
- navigation marine professionnelle ;
- prédiction probabiliste avancée par apprentissage automatique ;
- couverture européenne complète.

## 7. Exigences de confiance

1. Aucune donnée inventée.
2. Les estimations sont identifiées comme telles.
3. Les spots privés ne sont jamais rendus publics par défaut.
4. Les coordonnées sensibles peuvent être arrondies.
5. Le FishScore reste explicable.
6. Les sources externes et leur date de mise à jour doivent être traçables.

## 8. Indicateurs du MVP

- taux d’activation : premier plan de session créé ;
- nombre de sessions préparées par utilisateur ;
- taux de retour à 7 jours ;
- nombre de captures enregistrées ;
- pourcentage de recommandations jugées utiles ;
- taux de signalement de données incorrectes.

## 9. Critères de réussite de la bêta

La bêta est considérée exploitable lorsque :

- un utilisateur peut créer un compte ;
- ouvrir la carte ;
- consulter un spot ;
- obtenir un FishScore expliqué ;
- générer un plan de session ;
- enregistrer une capture ;
- gérer la confidentialité de ses données ;
- utiliser l’application sans blocage majeur sur Android.

## 10. Décisions encore requises

- nom commercial définitif ;
- modèle gratuit/premium précis ;
- fournisseur météo marine ;
- stratégie légale pour les données bathymétriques ;
- niveau de précision des coordonnées publiques.

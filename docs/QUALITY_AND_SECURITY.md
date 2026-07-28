# FishMap AI — Qualité, sécurité et vérifications

Version: 0.1

## Portes de validation

Une fonctionnalité n’est considérée terminée que si:

1. le comportement attendu est documenté ;
2. les cas d’erreur sont gérés ;
3. les données privées sont protégées ;
4. les tests automatiques passent ;
5. aucune clé secrète n’est présente dans le dépôt ;
6. les journaux ne contiennent ni jeton ni coordonnées privées exactes.

## Vérifications base de données

- migrations rejouables sur une base vide ;
- clés étrangères valides ;
- index PostGIS présents sur les colonnes géographiques ;
- contraintes FishScore entre 0 et 100 ;
- RLS activée sur les tables personnelles ;
- tests d’accès avec deux utilisateurs distincts ;
- suppression de compte testée.

## Vérifications FishScore

- déterministe pour une entrée identique ;
- score borné entre 0 et 100 ;
- niveau de confiance réduit quand une source manque ;
- explication contenant au moins un facteur lorsque le score est disponible ;
- aucune formulation promettant une capture ;
- pondérations versionnées ;
- tests spécifiques aux quatre espèces pilotes.

## Vérifications application

- analyse statique Flutter sans erreur ;
- tests unitaires des règles métier ;
- tests widgets des écrans critiques ;
- test d’intégration du parcours inscription → plan → capture ;
- gestion du refus de géolocalisation ;
- gestion du mode hors connexion ;
- accessibilité minimale: tailles tactiles, contrastes, libellés.

## Menaces prioritaires

- consultation d’un spot privé d’un autre utilisateur ;
- modification d’une capture appartenant à un tiers ;
- extraction massive de coordonnées ;
- fuite d’une clé météo ou cartographique ;
- téléversement de fichier non conforme ;
- abus de génération de plans ;
- injection de contenu dans les champs libres.

## Réponses prévues

- RLS et contrôles serveur ;
- limitation de débit ;
- validation stricte des entrées ;
- URL signées pour les médias privés ;
- secrets exclusivement côté serveur ;
- arrondi des positions sensibles ;
- taille et type MIME contrôlés pour les photos ;
- audit des actions sensibles sans stocker les données privées en clair.

## Revue par agents IA

Les agents peuvent assister sur:

- revue SQL et détection de contraintes manquantes ;
- génération de cas de tests ;
- revue de sécurité ;
- comparaison PRD/API/schéma ;
- analyse statique du code.

Toute conclusion d’agent doit être vérifiée par un test exécutable ou une revue humaine avant une mise en production.

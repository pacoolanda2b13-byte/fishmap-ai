# FishMap AI — Roadmap

## Progression globale

Avancement estimé : **45 %** — backend complet, prêt à être consommé par
l'application Flutter.

Cette estimation mesure le chemin jusqu’à une première bêta Android testable, pas seulement la documentation.

## Phase 1 — Vision produit

Statut : terminée

- problème utilisateur ;
- proposition de valeur ;
- personas ;
- positionnement.

## Phase 2 — Architecture générale

Statut : terminée

- choix de la stack ;
- modules principaux ;
- principes de données ;
- stratégie MVP.

## Phase 3 — Plan fonctionnel

Statut : terminée

- fonctionnalités MVP ;
- navigation ;
- premiers concepts FishScore et plan de session ;
- backlog général.

## Phase 4 — Dossier technique

Statut : en cours

Livrables :

- [x] dépôt GitHub ;
- [x] README ;
- [x] PRD v0.1 ;
- [x] roadmap initiale ;
- [x] schéma PostgreSQL/PostGIS ;
- [x] règles FishScore v1 ;
- [x] moteur FishScore v1 (package Dart `packages/fishscore`, testé, CI) ;
- [x] contrat API ;
- [x] architecture de confidentialité ;
- [ ] design system ;
- [ ] parcours UX détaillés ;
- [ ] backlog du Sprint 1 prêt pour développement.

## Phase 5 — Fondation technique

- initialisation Flutter ;
- initialisation Supabase ;
- environnements local, test et production ;
- authentification ;
- migrations de base de données ;
- CI minimale.

## Phase 6 — MVP fonctionnel

- carte ;
- spots ;
- météo ;
- FishScore ;
- plan de session ;
- journal de captures ;
- profil et confidentialité.

## Phase 7 — Bêta privée

- tests Android ;
- pilotes en Corse ;
- correction des bugs ;
- mesure de l’utilité des recommandations ;
- amélioration de l’onboarding.

## Phase 8 — Lancement initial

- publication Android ;
- offre gratuite/premium ;
- support ;
- suivi des métriques ;
- préparation iOS.

## Ordre de développement (arbitrage CTO, session 3)

Les données réelles avant l'interface : l'application pourra ainsi consommer
immédiatement une API fonctionnelle.

1. [x] `packages/core` — socle commun ;
2. [x] architecture météo multi-fournisseurs (`WeatherRepository`) ;
3. [x] `OpenMeteoProvider` — premier adaptateur réel, avec démonstration
   exécutable `example/` ;
4. [x] backend Supabase — migrations versionnées, cache météo et Edge Function
   `POST /evaluate` ;
5. [ ] Flutter — application mobile ;
6. [ ] notifications ;
7. [ ] IA de prédiction ;
8. [ ] optimisations.

## Règles d'architecture actées

- `fishscore` reste indépendant de Flutter, Supabase et `weather` ;
- la pression atmosphérique demeure un **modificateur borné (±6 %)**, jamais
  une composante principale ;
- le pipeline `WeatherData → WeatherMapper → FishScoreInput → FishScore` est
  définitif ;
- aucun package métier ne dépend d'un autre package métier ; seules les couches
  de composition (`scoring_pipeline`) assemblent plusieurs packages — règle
  vérifiée automatiquement en CI ;
- `knowledge/species/*.json` est la **seule** source de vérité de la
  calibration ; le catalogue Dart est généré.

## Prochain seuil

**60 %** sera atteint lorsque l'application Flutter consommera l'API :

1. [ ] initialisation `apps/mobile` (Riverpod, GoRouter) ;
2. [ ] écran d'évaluation branché sur `POST /evaluate` ;
3. [ ] carte et authentification Supabase.

## Dette technique identifiée

Relevée lors de la revue de fin de session 5, par ordre de priorité :

1. **4 lectures de cache par requête** au lieu d'une — l'évaluation boucle sur
   les espèces et chacune interroge le dépôt météo.
2. **Aucune limitation de débit** sur `/evaluate`, alors que le contrat API
   prévoit 60 lectures/minute.
3. **Pas de protection contre les rafales de cache** : des requêtes
   simultanées identiques appellent toutes le fournisseur.
4. **Entrées de cache périmées jamais supprimées** par l'application ; la
   fonction `purge_expired_weather_cache()` existe mais n'est pas planifiée.
5. **`CORS_ALLOWED_ORIGIN` vaut `*` par défaut** — à restreindre en production.

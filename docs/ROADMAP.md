# FishMap AI — Roadmap

## Progression globale

Avancement estimé : **22 %**

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

## Prochain seuil

**30 %** sera atteint lorsque la Phase 5 aura démarré côté code :

1. initialisation de l'application Flutter `apps/mobile` ;
2. intégration du package `fishscore` dans un premier écran d'évaluation ;
3. migrations Supabase versionnées et fonction serveur d'évaluation FishScore.

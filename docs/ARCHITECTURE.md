# FishMap AI — Architecture MVP

Version: 0.2

## Règles d'architecture

Ces règles sont contraignantes et vérifiées automatiquement lorsque c'est
possible.

1. **Indépendance des packages.** Aucun package métier ne dépend d'un autre
   package métier. On doit pouvoir supprimer `packages/weather` sans casser
   `packages/fishscore`, et inversement. Tous ne dépendent que de
   `packages/core`. Vérifié par
   `packages/core/test/architecture_rules_test.dart`.
2. **Composition explicite.** Les assemblages entre packages métier vivent dans
   des couches dédiées (`packages/scoring_pipeline`), seules autorisées à
   dépendre de plusieurs d'entre eux.
3. **FishScore isolé.** Le moteur reste indépendant de Flutter, de Supabase et
   de la couche météo.
4. **Pression atmosphérique.** Elle reste un modificateur borné (±6 %) et ne
   devient jamais une composante pondérée principale.
5. **Pipeline météo figé.**
   `WeatherData → WeatherMapper → FishScoreInput → FishScore`.
6. **Connaissances pilotées par les données.** `knowledge/species/*.json` est
   la seule source de vérité de la calibration ; le catalogue Dart est généré
   et sa fraîcheur est vérifiée en CI.

### Dépendances des packages

```text
            scoring_pipeline          ← composition
             /            \
        fishscore        weather      ← métier (ne se connaissent pas)
             \            /
                  core                ← socle commun
```

## Choix principal

Architecture mobile-first composée de:

- application Flutter Android/iOS ;
- Supabase Auth ;
- PostgreSQL + PostGIS ;
- Supabase Storage pour les photos ;
- fonctions serveur pour les appels météo et le calcul FishScore ;
- fournisseur cartographique configurable ;
- observabilité et journalisation sans coordonnées privées en clair.

## Flux principal

1. L’utilisateur choisit une espèce, un horaire et une distance maximale.
2. L’application envoie la demande authentifiée.
3. Le backend récupère les spots accessibles dans le rayon.
4. Les conditions météo/marines sont récupérées ou lues depuis le cache.
5. FishScore évalue chaque combinaison spot/espèce/créneau.
6. Le moteur renvoie un spot principal, des alternatives et une explication.
7. Le plan est enregistré uniquement pour son propriétaire.

## Modules Flutter proposés

```text
apps/mobile/lib/
  app/
  core/
    config/
    errors/
    networking/
    privacy/
  features/
    auth/
    map/
    species/
    spots/
    fish_score/
    session_plans/
    catches/
    profile/
  shared/
```

Chaque fonctionnalité suit une séparation simple:

```text
feature/
  data/
  domain/
  presentation/
```

## Backend

Les opérations simples utilisent l’API Supabase avec RLS. Les opérations métier sensibles passent par des fonctions serveur:

- génération d’un plan ;
- agrégation météo ;
- calcul FishScore ;
- traitement des photos ;
- arrondi ou masquage des coordonnées ;
- limitation de débit.

## Confidentialité

- `private`: coordonnées exactes réservées au propriétaire ;
- `approximate`: coordonnées arrondies côté serveur ;
- `public`: coordonnées visibles selon les règles de publication ;
- aucune clé fournisseur n’est embarquée dans l’application ;
- les journaux techniques excluent les coordonnées exactes et les jetons.

## Résilience

- cache météo avec date de validité ;
- réponse dégradée lorsque certaines données manquent ;
- FishScore accompagné d’un niveau de confiance ;
- nouvelle tentative contrôlée sur erreur réseau ;
- écran hors connexion pour les derniers plans sauvegardés.

## Décisions différées

- fournisseur cartographique définitif ;
- fournisseur météo marine définitif ;
- système de paiement premium ;
- analytics produit définitif ;
- moteur d’apprentissage automatique après collecte suffisante de données.

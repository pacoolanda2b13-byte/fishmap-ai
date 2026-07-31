# knowledge/species

Fiches de connaissances des espèces MVP de FishMap AI.

Ce dossier est la **seule source de vérité** de la calibration FishScore. Les
paramètres ne sont **jamais** codés en dur ni maintenus à la main dans le
moteur : le catalogue Dart est **généré automatiquement** depuis ces fiches.

```
knowledge/species/*.json ──▶ generator ──▶ species_catalog.g.dart
```

Après toute modification d'une fiche :

```bash
cd packages/fishscore
dart run tool/generate_species_catalog.dart
```

La CI vérifie que le catalogue généré est à jour (`--check`).

## Zone pilote

Solenzara → Aléria (côte est de la Corse).

## Espèces

| Slug | Nom | Confiance |
|---|---|---|
| `barracuda` | Barracuda | `hypothesis` |
| `loup` | Loup (bar) | `hypothesis` |
| `dorade-royale` | Dorade royale | `hypothesis` |
| `liche` | Liche amie | `hypothesis` |

## Niveau de confiance (`confidence`)

- `hypothesis` — valeurs prudentes non encore vérifiées ;
- `observed` — valeurs appuyées par un volume d'observations terrain ;
- `validated` — valeurs confirmées par des sources fiables et référencées.

Tant qu'une fiche n'est pas `validated`, l'application doit rester prudente
dans la présentation des scores.

## Sources traçables (`sources`)

Chaque fiche liste des sources **typées** justifiant sa calibration :

| Type | Description |
|---|---|
| `ifremer` | données ou publications Ifremer |
| `scientific_publication` | publication scientifique |
| `fishing_guide` | guide de pêche reconnu |
| `field_observation` | observations terrain agrégées |

Chaque entrée peut préciser `count` (nombre d'éléments), `reference`, `url`
et `note` :

```json
"sources": [
  { "type": "field_observation", "count": 42 },
  { "type": "scientific_publication", "count": 3, "reference": "…" }
]
```

Objectif produit : toute recommandation doit être **traçable**. FishMap doit
pouvoir expliquer, par exemple :

> Score calculé grâce à 42 observations terrain + 3 publications scientifiques.

Le moteur expose cette information via `SpeciesProfile.provenanceSummaryFr`.

## Format

Chaque fiche est un fichier `<slug>.json` conforme à
[`schema.json`](./schema.json). Elle comprend :

- des champs **descriptifs** (nom, nom scientifique, habitat, comportement,
  techniques, meilleures périodes) destinés aux humains ;
- un bloc **`calibration`** consommé par le moteur FishScore.

### Bloc `calibration`

| Clé | Description |
|---|---|
| `wind.ideal_max_kmh` / `tolerable_max_kmh` | vent idéal / limite |
| `waves.ideal_min_m` / `ideal_max_m` / `falloff_m` | plage de houle idéale et décroissance |
| `hours.prime` / `good` | fenêtres horaires `[début, fin]` (peuvent traverser minuit) |
| `hours.baseline_score` | note des heures hors fenêtres |
| `thermal.ideal_min_c` / `ideal_max_c` / `tolerance_c` | plage de température d'eau |
| `thermal.season_scores` | note 0-100 par saison (`winter`,`spring`,`summer`,`autumn`) |
| `bottoms` | note 0-100 par type de fond (`sand`,`gravel`,`rock`,`posidonia`,`mixed`,`mud`) |
| `depth.ideal_min_m` / `ideal_max_m` / `falloff_m` | plage de profondeur idéale |
| `moon.favors_spring_tide` | l'espèce est-elle réputée plus active en vive-eau |
| `weight_overrides` | surcharges de poids par composante (optionnel) |

## Contribuer

1. Modifier la fiche JSON (pas le code).
2. Renseigner ou compléter `sources` lorsqu'une valeur passe en `validated`.
3. Lancer les tests du package `fishscore` : ils vérifient que chaque fiche
   reste valide et cohérente avec le moteur.

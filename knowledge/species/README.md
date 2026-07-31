# knowledge/species

Fiches de connaissances des espèces MVP de FishMap AI.

Ce dossier est la **source de vérité** de la calibration FishScore. Les
paramètres ne doivent **jamais** être codés en dur dans le moteur : le package
`fishscore` construit ses `SpeciesProfile` à partir de ces fiches via
`SpeciesProfile.fromJson`.

## Zone pilote

Solenzara → Aléria (côte est de la Corse).

## Espèces

| Slug | Nom | Statut calibration |
|---|---|---|
| `barracuda` | Barracuda | hypothèse |
| `loup` | Loup (bar) | hypothèse |
| `dorade-royale` | Dorade royale | hypothèse |
| `liche` | Liche amie | hypothèse |

## Statut de calibration

- `hypothesis` — valeurs prudentes non encore validées scientifiquement, à
  confirmer par des sources fiables ou un volume suffisant d'observations
  terrain ;
- `validated` — valeurs confirmées et référencées.

Tant qu'une fiche est en `hypothesis`, l'application doit rester prudente dans
la présentation des scores.

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

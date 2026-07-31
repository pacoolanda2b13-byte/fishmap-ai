# fishscore — Architecture

Version : 1.0

## Objectif

Fournir un moteur de scoring **explicable, déterministe et améliorable**, sans
dépendance à Flutter, réutilisable côté application mobile et côté fonction
serveur.

## Vue d'ensemble

```
FishScoreInput ─▶ FishScoreEngine ─▶ FishScoreResult
                     │
                     ├─ composantes (ScoreComponent)      → notes 0-100
                     ├─ renormalisation des poids
                     ├─ modificateur de pression (borné)
                     ├─ calcul de confiance
                     └─ sélection des facteurs (≤3 / ≤3)

SpeciesProfile ◀── knowledge/species/*.json (source de vérité, jamais codé en dur)
```

## Principes

### 1. Composantes pluggables

Chaque composante implémente `ScoreComponent` : elle transforme une partie des
conditions en note 0-100, ou renvoie `null` si la donnée manque. Ajouter,
retirer ou remplacer une composante ne touche pas le reste du moteur.

### 2. Renormalisation sur données disponibles

Les poids ne s'appliquent qu'aux composantes qui ont pu être évaluées. Une
donnée absente disparaît du calcul au lieu de le fausser, et fait baisser la
confiance.

### 3. Pression = modificateur borné, pas composante

Conformément à l'arbitrage produit, la pression atmosphérique n'est pas une
8ᵉ composante pondérée : elle applique un ajustement borné (±6 %) au score
renormalisé. Cela préserve exactement la formule pondérée de la spec tout en
exploitant un signal fort.

### 4. Confiance découplée du score

La confiance mesure la **qualité des données** (couverture, fraîcheur météo,
qualité de la source du spot, volume d'observations), pas la qualité des
conditions. Un bon score peu fiable est signalé comme tel.

### 5. Calibration pilotée par les données

Les `SpeciesProfile` sont construits depuis `knowledge/species/*.json` via
`SpeciesProfile.fromJson`. Le catalogue embarqué (`SpeciesCatalog`) est une
valeur par défaut hors ligne, vérifiée cohérente avec les fiches par test. La
calibration n'est **jamais** codée en dur.

### 6. Déterminisme

Aucune source d'aléa ni d'horloge implicite : les mêmes entrées produisent
toujours la même sortie, condition nécessaire à la reproductibilité et aux
tests.

## Fichiers

```
lib/src/
  models/        FishScoreInput, FishScoreResult, enums, MoonPhase, LocalHistory
  scoring/       ScoringMath (fonctions de notation réutilisables)
  components/    ScoreComponent + 7 composantes
  species/       SpeciesProfile (+ fromJson/toJson), SpeciesCatalog
  engine/        FishScoreEngine (orchestration, confiance, meilleur créneau)
```

## Évolutions prévues

- pondération des composantes affinée par espèce via `weight_overrides` ;
- composante « qualité de l'eau / turbidité » lorsque la donnée sera disponible ;
- apprentissage progressif des poids à partir de l'historique de captures ;
- direction du vent/houle relative à l'exposition du spot.

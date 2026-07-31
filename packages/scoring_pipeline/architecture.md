# scoring_pipeline — Architecture

Version : 0.1

## Objectif

Offrir un point d'assemblage unique entre les packages métier, afin que ceux-ci
restent totalement indépendants les uns des autres.

## Position dans le dépôt

```
      ┌────────────────────────────────┐
      │      scoring_pipeline          │  ← couche de composition
      │  (le seul à voir les deux)     │
      └───────┬──────────────┬─────────┘
              │              │
      ┌───────▼─────┐  ┌─────▼──────┐
      │  fishscore  │  │  weather   │   ← packages métier, mutuellement ignorants
      └───────┬─────┘  └─────┬──────┘
              └───────┬──────┘
                 ┌────▼────┐
                 │  core   │
                 └─────────┘
```

## Décisions

### 1. La composition est explicite, pas implicite

Plutôt que de laisser `weather` dépendre de `fishscore` « parce que c'est
pratique », la dépendance croisée est remontée dans un package dédié. Le coût
est un package de plus ; le bénéfice est que chaque package métier reste
supprimable, testable et réutilisable isolément.

### 2. `SpotContext` sépare les responsabilités

Le mapper combine deux sources distinctes : la météo (`WeatherForecast`) et le
contexte du spot (`SpotContext`). Aucune des deux ne contamine l'autre.

### 3. Le service renvoie un `Result`

`ScoringService.evaluateSpot` ne lève pas : indisponibilité météo et espèce
inconnue reviennent en `Failure` typé. L'appelant (backend ou app) est obligé
de traiter la dégradation.

### 4. La provenance voyage avec le score

`ScoredForecast` transporte le fournisseur météo et la provenance des
connaissances. La traçabilité n'est pas reconstruite après coup : elle est
produite en même temps que le score.

### 5. Aucune logique métier ici

Ce package **assemble**, il ne calcule pas. Toute règle de scoring appartient à
`fishscore` ; toute normalisation météo appartient à `weather`. Si une règle
apparaît ici, c'est qu'elle est au mauvais endroit.

## Évolutions prévues

- planification de session (meilleur créneau sur plusieurs spots) ;
- comparaison de spots pour une même espèce et un même créneau ;
- exploitation de `WeatherRepository.fetchFromAll` pour pondérer plusieurs
  fournisseurs et enrichir la confiance.

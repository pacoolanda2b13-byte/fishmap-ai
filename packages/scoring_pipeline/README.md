# scoring_pipeline

Couche de **composition** de FishMap AI.

C'est le **seul** package autorisé à connaître plusieurs packages métier. Il
assemble la chaîne complète, de la météo au score explicable.

## Pourquoi ce package existe

La règle d'architecture du dépôt impose que `fishscore` et `weather` s'ignorent
mutuellement (on doit pouvoir supprimer l'un sans casser l'autre). Il faut
pourtant bien un endroit où les deux se rencontrent : c'est ici.

```
WeatherRepository ──▶ WeatherMapper ──▶ FishScoreEngine ──▶ ScoredForecast
   (weather)          (+ SpotContext)     (fishscore)      (score + provenance)
```

## Composants

| Élément | Rôle |
|---|---|
| `SpotContext` | contexte non météo d'un spot (compatibilité, fond, profondeur, qualité, historique) |
| `WeatherMapper` | `WeatherForecast` + `SpotContext` → `FishScoreInput` |
| `ScoringService` | orchestre récupération météo, mapping, scoring |
| `ScoredForecast` | résultat FishScore + **traçabilité** (fournisseur météo, confiance et sources de la calibration) |

## Utilisation

```dart
import 'package:core/core.dart';
import 'package:scoring_pipeline/scoring_pipeline.dart';
import 'package:weather/weather.dart';

final service = ScoringService(
  weatherRepository: WeatherRepository(providers: <WeatherProvider>[
    // OpenMeteoProvider(...),
    StaticWeatherProvider.synthetic(location: location, from: from, to: to),
  ]),
);

final result = await service.evaluateSpot(
  location: const Coordinates(latitude: 41.86, longitude: 9.40),
  speciesSlug: 'loup',
  evaluatedAt: DateTime.utc(2026, 10, 15, 19),
  spot: const SpotContext(
    spotSuitability: 80,
    bottomType: BottomType.rock,
    depthMeters: 6,
    spotQuality: DataQuality.observed,
  ),
);

result.fold(
  onSuccess: (s) {
    print('${s.result.score}/100 — ${s.result.level.labelFr}');
    print(s.result.explanation);
    print(s.provenanceFr); // Météo : open-meteo. Connaissances : …
  },
  onFailure: (f) => print('indisponible : ${f.code}'),
);
```

## Traçabilité

`ScoredForecast` répond à l'exigence produit : toute recommandation doit être
explicable. Il porte le fournisseur météo utilisé, le niveau de confiance de la
calibration de l'espèce et le résumé de ses sources — par exemple
« 42 observations terrain + 3 publications scientifiques ».

## Développement

```bash
dart pub get
dart analyze
dart test
```

Voir [`architecture.md`](./architecture.md).

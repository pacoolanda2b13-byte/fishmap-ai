# weather

Couche météo **provider-agnostic et multi-fournisseurs** de FishMap AI.

Ne dépend que de [`core`](../core) — jamais d'un autre package métier.

## Architecture

```
WeatherRepository            ← seule porte d'entrée météo
   ├─ OpenMeteoProvider      (à venir : premier adaptateur réel)
   ├─ StormGlassProvider     (à venir)
   ├─ OpenWeatherProvider    (à venir)
   └─ StaticWeatherProvider  (mémoire — hors ligne, démos, tests)
              │
              ▼
        WeatherForecast  (série triée de WeatherData normalisées)
```

Le dépôt choisit le meilleur fournisseur disponible et masque les pannes :

- **repli automatique** — les fournisseurs sont essayés dans l'ordre ;
- **comparaison** — `fetchFromAll` interroge tout le monde (base de la future
  fusion de sources) ;
- **hors ligne** — un fournisseur local en dernier garantit une réponse ;
- **échecs typés** — retour en `Result`/`Failure`, jamais d'exception qui fuit.

## Composants

| Élément | Rôle |
|---|---|
| `WeatherData` | observation/prévision à un instant, **normalisée** (km/h, m, s, °C, hPa) |
| `WeatherForecast` | série triée + `nearest()` + tendance de pression sur 3 h |
| `WeatherProvider` | contrat de récupération (aucun fournisseur réseau embarqué) |
| `StaticWeatherProvider` | fournisseur mémoire + générateur déterministe `.synthetic` |
| `WeatherRepository` | orchestration multi-fournisseurs, repli, comparaison |

## Utilisation

```dart
import 'package:core/core.dart';
import 'package:weather/weather.dart';

const location = Coordinates(latitude: 41.86, longitude: 9.40);

final repository = WeatherRepository(
  providers: <WeatherProvider>[
    // OpenMeteoProvider(...),                    // principal
    StaticWeatherProvider.synthetic(              // repli hors ligne
      location: location, from: from, to: to,
    ),
  ],
  logger: ConsoleLogger(),
);

final result = await repository.fetchForecast(location, from: from, to: to);

result.fold(
  onSuccess: (p) => print('${p.providerName} → ${p.forecast.samples.length}'),
  onFailure: (f) => print('indisponible : ${f.code}'),
);
```

## Écrire un fournisseur

Implémenter `WeatherProvider`, convertir les unités natives via `Units` (de
`core`), retourner un `WeatherForecast` de `WeatherData` normalisées, et lever
`WeatherProviderException` en cas d'échec. Le dépôt s'occupe du reste.

```dart
class OpenMeteoProvider implements WeatherProvider {
  @override
  String get name => 'open-meteo';

  @override
  Future<WeatherForecast> fetchForecast(Coordinates location,
      {required DateTime from, required DateTime to}) async {
    // 1. appel HTTP, 2. Units.msToKmh(...), 3. WeatherData(...).
    throw UnimplementedError();
  }
}
```

## Et le FishScore ?

Ce package **ignore** l'existence de `fishscore`. La conversion
`WeatherForecast → FishScoreInput` vit dans la couche de composition
[`scoring_pipeline`](../scoring_pipeline).

## Développement

```bash
dart pub get
dart analyze
dart test
```

Voir [`architecture.md`](./architecture.md) pour les décisions de conception.

# weather

Couche météo **provider-agnostic** de FishMap AI.

Elle normalise les données météo et marines, les organise en séries temporelles
et les transforme en entrées FishScore — **sans dépendre d'un fournisseur
particulier**. Changer d'API météo (Open-Meteo, Stormglass, Météo-France…)
n'impacte que l'adaptateur, jamais le reste de l'application.

## Pipeline

```
WeatherProvider ──▶ WeatherForecast ──▶ WeatherMapper ──▶ FishScoreInput
   (interface)        (série de            (pont)          (moteur FishScore)
                       WeatherData)
```

- **`WeatherData`** — observation/prévision à un instant, **normalisée** (km/h,
  m, s, °C, hPa). Champs optionnels : un fournisseur ne couvre pas tout.
- **`WeatherForecast`** — série triée de `WeatherData` ; accès par proximité
  temporelle (`nearest`) et calcul de la **tendance de pression sur 3 h**.
- **`WeatherProvider`** — interface de récupération. Ce package ne contient
  **aucun** fournisseur réseau ; seulement le contrat et un fournisseur en
  mémoire.
- **`StaticWeatherProvider`** — fournisseur en mémoire pour le dev hors ligne,
  les démos et les tests, avec un générateur **déterministe** (`.synthetic`).
- **`WeatherMapper`** — convertit une prévision + un `SpotContext` en
  `FishScoreInput`.
- **`WeatherUnits`** — conversions d'unités pour les adaptateurs de
  fournisseurs.

## Utilisation

```dart
import 'package:fishscore/fishscore.dart';
import 'package:weather/weather.dart';

const location = GeoPoint(latitude: 41.86, longitude: 9.40); // côte est corse

// 1. Un fournisseur (ici synthétique et hors ligne).
final provider = StaticWeatherProvider.synthetic(
  location: location,
  from: DateTime.utc(2026, 10, 15, 0),
  to: DateTime.utc(2026, 10, 15, 23),
);

// 2. Une prévision.
final forecast = await provider.fetchForecast(
  location,
  from: DateTime.utc(2026, 10, 15, 0),
  to: DateTime.utc(2026, 10, 15, 23),
);

// 3. Une entrée FishScore.
final input = const WeatherMapper().toFishScoreInput(
  forecast: forecast,
  speciesSlug: 'loup',
  evaluatedAt: DateTime.utc(2026, 10, 15, 19),
  spot: const SpotContext(
    spotSuitability: 80,
    bottomType: BottomType.rock,
    depthMeters: 6,
    spotQuality: DataQuality.observed,
  ),
);

// 4. Un score.
final result = FishScoreEngine().evaluate(input);
```

## Écrire un vrai fournisseur

Implémenter `WeatherProvider` dans un package/adaptateur dédié, convertir les
unités natives via `WeatherUnits`, et retourner un `WeatherForecast` de
`WeatherData` normalisées. Le reste de l'application n'a pas à changer.

```dart
class OpenMeteoProvider implements WeatherProvider {
  @override
  String get name => 'open-meteo';

  @override
  Future<WeatherForecast> fetchForecast(GeoPoint location,
      {required DateTime from, required DateTime to}) async {
    // 1. appel HTTP, 2. WeatherUnits.msToKmh(...), 3. WeatherData(...).
    throw UnimplementedError();
  }
}
```

## Développement

```bash
dart pub get
dart analyze
dart test
```

Voir [`architecture.md`](./architecture.md) pour les décisions de conception.

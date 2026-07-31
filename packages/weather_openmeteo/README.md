# weather_openmeteo

Adaptateur **Open-Meteo** pour FishMap AI — premier fournisseur météo officiel.

Responsabilité unique :

```
HTTP ──▶ JSON ──▶ WeatherData
```

Aucune logique métier, aucune connaissance du FishScore.

## Ce qu'il récupère

| API | Hôte | Variables |
|---|---|---|
| Prévision | `api.open-meteo.com` | vent, rafales, direction du vent, température de l'air, pression, précipitations, couverture nuageuse |
| Marine | `marine-api.open-meteo.com` | hauteur de houle, période, direction, température de la mer |

Les deux séries sont fusionnées sur leurs horodatages. **Aucune clé d'API**
n'est requise : aucun secret n'est embarqué.

## Conversion d'unités

Le mapper ne suppose pas que l'API a honoré les unités demandées : il lit le
bloc `hourly_units` de la réponse et convertit vers les unités canoniques du
projet via `core.Units`.

| Déclaré par l'API | Converti en |
|---|---|
| `km/h`, `m/s`, `kn`, `mp/h` | km/h |
| `°C`, `°F`, `K` | °C |
| `hPa`, `Pa`, `inHg` | hPa |
| `m`, `ft` | m |
| `mm`, `inch` | mm |

Une unité inconnue lève une erreur plutôt que de corrompre silencieusement les
données.

## Utilisation

```dart
import 'package:core/core.dart';
import 'package:weather/weather.dart';
import 'package:weather_openmeteo/weather_openmeteo.dart';

final repository = WeatherRepository(
  providers: <WeatherProvider>[
    OpenMeteoProvider(),                    // fournisseur officiel
    StaticWeatherProvider.synthetic(...),   // repli hors ligne
  ],
);

final result = await repository.fetchForecast(
  const Coordinates(latitude: 41.86, longitude: 9.40),
  from: from,
  to: to,
);
```

### Options

| Paramètre | Défaut | Rôle |
|---|---|---|
| `httpClient` | client interne | injecter un client (tests, proxy, pooling) |
| `timeout` | 10 s | délai par requête |
| `includeMarine` | `true` | interroger aussi l'API marine |
| `endpoints` | hôtes officiels | pointer un miroir |
| `logger` | silencieux | tracer les dégradations |

Appeler `close()` lorsque le client HTTP n'a pas été injecté.

## Comportement en cas d'échec

| Situation | Comportement |
|---|---|
| API marine indisponible | **dégradation gracieuse** : données atmosphériques renvoyées, houle absente, avertissement journalisé |
| API prévision indisponible | échec — `WeatherProviderException` |
| Erreur applicative Open-Meteo (`error: true`) | échec, la raison de l'API est remontée |
| Délai dépassé, réseau, JSON invalide, statut ≠ 200 | échec typé |
| Série trouée (`null`) | champs absents — jamais de valeur inventée |

Le `WeatherRepository` convertit ces échecs en `Failure` et bascule sur le
fournisseur suivant.

## Ajouter un autre fournisseur

Créer un paquet frère (`weather_stormglass`, `weather_openweather`)
implémentant `WeatherProvider`, puis l'insérer dans la liste du dépôt. **Aucun
code existant n'est modifié.**

## Tests

29 tests sur des fixtures figées reproduisant le format réel des réponses
Open-Meteo — **aucun appel réseau**, donc déterministes et exécutables en CI.
Voir [`test/fixtures/README.md`](./test/fixtures/README.md).

```bash
dart pub get
dart analyze
dart test
```

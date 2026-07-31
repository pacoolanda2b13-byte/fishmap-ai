# core

Briques communes de FishMap AI. **Aucune logique métier, aucune dépendance
Flutter.**

## Règle d'architecture

> Tous les packages du projet dépendent **uniquement** de `core` — jamais entre
> eux. On doit pouvoir supprimer n'importe quel package métier sans casser les
> autres.

## Contenu

| Brique | Rôle |
|---|---|
| `Result<T>` | succès/échec explicite (`fold`, `map`, `flatMap`, `getOrElse`) |
| `Failure` | échecs typés à codes stables (`NetworkFailure`, `TimeoutFailure`, `ValidationFailure`, `NotFoundFailure`, `UnavailableFailure`, `UnexpectedFailure`, `CompositeFailure`) |
| `Logger` | contrat de journalisation + `ConsoleLogger`, `NoopLogger`, `MemoryLogger` (tests) — jamais de coordonnées exactes ni de secrets |
| `AppConfig` | configuration en lecture seule (`require`, `getInt`, `getBool`…) |
| `Coordinates` | point WGS84 + distance haversine |
| `Distance` | value object distance (mètres/kilomètres, comparable) |
| `Units` | conversions vers les unités canoniques (km/h, m, °C, hPa…) |
| `TimeProvider` | horloge injectable (`SystemTimeProvider`, `FixedTimeProvider`) |
| `AppException` | exceptions de base (`ConfigException`, `ValidationException`) |

## Conventions

- Les échecs **attendus** (réseau, données absentes) circulent en `Result` +
  `Failure` ; les exceptions sont réservées aux erreurs de programmation.
- Unités canoniques partout : vitesse km/h, longueur m, température °C,
  pression hPa. Les conversions se font aux frontières via `Units`.
- Le temps s'obtient par `TimeProvider` injecté, jamais `DateTime.now()` en
  direct dans du code testable.

## Développement

```bash
dart pub get
dart analyze
dart test
```

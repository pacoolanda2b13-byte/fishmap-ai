/// Couche de composition de FishMap AI.
///
/// Règle d'architecture : les packages métier (`fishscore`, `weather`) ne se
/// connaissent pas. Ce package est le **seul** autorisé à dépendre de
/// plusieurs d'entre eux, afin d'assembler la chaîne complète :
///
/// ```
/// WeatherRepository ─▶ WeatherMapper ─▶ FishScoreEngine ─▶ ScoredForecast
/// ```
///
/// ```dart
/// final service = ScoringService(weatherRepository: repository);
/// final result = await service.evaluateSpot(
///   location: const Coordinates(latitude: 41.86, longitude: 9.40),
///   speciesSlug: 'loup',
///   evaluatedAt: DateTime.utc(2026, 10, 15, 19),
/// );
/// ```
library;

export 'src/scoring_service.dart';
export 'src/spot_context.dart';
export 'src/weather_mapper.dart';

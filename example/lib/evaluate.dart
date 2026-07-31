import 'package:core/core.dart';
import 'package:fishscore/fishscore.dart';
import 'package:scoring_pipeline/scoring_pipeline.dart';
import 'package:weather/weather.dart';
import 'package:weather_openmeteo/weather_openmeteo.dart';

/// Évaluation d'une espèce pour un point et un instant donnés.
class SpeciesEvaluation {
  const SpeciesEvaluation({
    required this.speciesSlug,
    required this.commonNameFr,
    required this.scored,
  });

  final String speciesSlug;
  final String commonNameFr;
  final ScoredForecast scored;

  int get score => scored.result.score;
  int get confidence => scored.result.confidence;
  String get explanation => scored.result.explanation;
  String get provenance => scored.provenanceFr;
}

/// Construit le dépôt météo par défaut : Open-Meteo en fournisseur officiel.
///
/// L'ordre des fournisseurs matérialise la stratégie de repli. Ajouter
/// StormGlass ou OpenWeather consiste à insérer une ligne ici, sans modifier
/// le reste de la chaîne.
WeatherRepository defaultWeatherRepository({Logger? logger}) =>
    WeatherRepository(
      providers: <WeatherProvider>[
        OpenMeteoProvider(logger: logger ?? const NoopLogger()),
        // StormGlassProvider(...),   // à venir
        // OpenWeatherProvider(...),  // à venir
      ],
      logger: logger ?? const NoopLogger(),
    );

/// Évalue toutes les espèces MVP pour un point et une date, à partir de
/// **données météo réelles**.
///
/// Renvoie les évaluations triées par score décroissant, ou un [Failure] si
/// aucune donnée météo n'est disponible.
Future<Result<List<SpeciesEvaluation>>> evaluate({
  required double latitude,
  required double longitude,
  required DateTime date,
  WeatherRepository? repository,
  SpotContext spot = const SpotContext(),
  Logger logger = const NoopLogger(),
}) async {
  final Coordinates location =
      Coordinates(latitude: latitude, longitude: longitude);
  final ScoringService service = ScoringService(
    weatherRepository: repository ?? defaultWeatherRepository(logger: logger),
  );

  final List<SpeciesEvaluation> evaluations = <SpeciesEvaluation>[];
  Failure? lastFailure;

  for (final MapEntry<String, SpeciesProfile> entry
      in SpeciesCatalog.all.entries) {
    final Result<ScoredForecast> result = await service.evaluateSpot(
      location: location,
      speciesSlug: entry.key,
      evaluatedAt: date,
      spot: spot,
    );

    result.fold(
      onSuccess: (ScoredForecast scored) => evaluations.add(
        SpeciesEvaluation(
          speciesSlug: entry.key,
          commonNameFr: entry.value.commonNameFr,
          scored: scored,
        ),
      ),
      onFailure: (Failure f) => lastFailure = f,
    );
  }

  if (evaluations.isEmpty) {
    return Result<List<SpeciesEvaluation>>.failure(
      lastFailure ?? const UnavailableFailure('Aucune évaluation produite'),
    );
  }

  evaluations.sort(
    (SpeciesEvaluation a, SpeciesEvaluation b) => b.score.compareTo(a.score),
  );
  return Result<List<SpeciesEvaluation>>.success(evaluations);
}

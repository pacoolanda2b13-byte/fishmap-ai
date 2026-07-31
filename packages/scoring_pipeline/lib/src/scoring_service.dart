import 'package:core/core.dart';
import 'package:fishscore/fishscore.dart';
import 'package:weather/weather.dart';

import 'spot_context.dart';
import 'weather_mapper.dart';

/// Score accompagné de sa provenance.
///
/// Permet d'expliquer à l'utilisateur d'où viennent les données ayant produit
/// la recommandation : quel fournisseur météo, et sur quelles sources de
/// connaissance repose la calibration de l'espèce.
class ScoredForecast {
  const ScoredForecast({
    required this.result,
    required this.weatherProvider,
    required this.speciesConfidence,
    required this.knowledgeSummaryFr,
  });

  /// Résultat FishScore explicable.
  final FishScoreResult result;

  /// Fournisseur météo ayant produit les données.
  final String weatherProvider;

  /// Niveau de confiance de la calibration de l'espèce.
  final KnowledgeConfidence speciesConfidence;

  /// Résumé des sources de connaissance
  /// (ex. « 42 observations terrain + 3 publications scientifiques »).
  final String knowledgeSummaryFr;

  /// Phrase de traçabilité prête pour l'affichage.
  String get provenanceFr =>
      'Météo : $weatherProvider. Connaissances : $knowledgeSummaryFr.';
}

/// Assemble météo + contexte de spot + moteur FishScore.
///
/// Seul point du projet qui connaît à la fois `weather` et `fishscore` ; les
/// deux packages restent mutuellement ignorants.
class ScoringService {
  ScoringService({
    required WeatherRepository weatherRepository,
    FishScoreEngine? engine,
    WeatherMapper mapper = const WeatherMapper(),
  })  : _weatherRepository = weatherRepository,
        _engine = engine ?? FishScoreEngine(),
        _mapper = mapper;

  final WeatherRepository _weatherRepository;
  final FishScoreEngine _engine;
  final WeatherMapper _mapper;

  /// Évalue un spot pour une espèce à un instant donné.
  ///
  /// Récupère la météo via le dépôt (avec repli automatique), la convertit en
  /// entrée FishScore et renvoie un score explicable et traçable. Renvoie un
  /// [Failure] si aucune donnée météo n'est disponible ou si l'espèce est
  /// inconnue.
  Future<Result<ScoredForecast>> evaluateSpot({
    required Coordinates location,
    required String speciesSlug,
    required DateTime evaluatedAt,
    SpotContext spot = const SpotContext(),
    MoonPhase? moonPhase,
    Duration lookbehind = const Duration(hours: 6),
    Duration lookahead = const Duration(hours: 6),
  }) async {
    final Result<ProviderForecast> weather =
        await _weatherRepository.fetchForecast(
      location,
      from: evaluatedAt.subtract(lookbehind),
      to: evaluatedAt.add(lookahead),
    );

    final ProviderForecast? provided = weather.valueOrNull;
    if (provided == null) {
      return Result<ScoredForecast>.failure(weather.failureOrNull!);
    }

    final FishScoreInput input = _mapper.toFishScoreInput(
      forecast: provided.forecast,
      speciesSlug: speciesSlug,
      evaluatedAt: evaluatedAt,
      spot: spot,
      moonPhase: moonPhase,
    );

    final SpeciesProfile? profile = _engine.speciesProfiles[speciesSlug];
    if (profile == null) {
      return Result<ScoredForecast>.failure(
        NotFoundFailure('Espèce inconnue : "$speciesSlug"'),
      );
    }

    return Result<ScoredForecast>.success(
      ScoredForecast(
        result: _engine.evaluate(input),
        weatherProvider: provided.providerName,
        speciesConfidence: profile.confidence,
        knowledgeSummaryFr: profile.provenanceSummaryFr,
      ),
    );
  }
}

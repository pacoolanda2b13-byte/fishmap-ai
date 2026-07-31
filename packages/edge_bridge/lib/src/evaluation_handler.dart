import 'package:core/core.dart';
import 'package:fishscore/fishscore.dart';
import 'package:scoring_pipeline/scoring_pipeline.dart';
import 'package:weather/weather.dart';

import 'evaluate_request.dart';

/// Orchestration de `POST /evaluate`, en Dart pur.
///
/// Volontairement dépourvue d'interop JavaScript : la logique est ainsi
/// testable dans la VM Dart, et la couche Deno se réduit à fournir les
/// entrées/sorties (HTTP, cache PostgreSQL).
///
/// Le gestionnaire **n'appelle jamais un fournisseur directement** : il passe
/// toujours par le [WeatherRepository], donc par le cache.
class EvaluationHandler {
  EvaluationHandler({
    required WeatherRepository weatherRepository,
    FishScoreEngine? engine,
    Map<String, SpeciesProfile>? speciesProfiles,
  })  : _service = ScoringService(
          weatherRepository: weatherRepository,
          engine: engine,
        ),
        _profiles = speciesProfiles ?? SpeciesCatalog.all;

  final ScoringService _service;
  final Map<String, SpeciesProfile> _profiles;

  /// Traite une requête déjà analysée et renvoie le corps de réponse JSON.
  Future<Result<Map<String, dynamic>>> handle(
    EvaluateRequest request, {
    SpotContext spot = const SpotContext(),
  }) async {
    final String? requested = request.speciesSlug;

    if (requested != null && !_profiles.containsKey(requested)) {
      return Result<Map<String, dynamic>>.failure(
        NotFoundFailure('Espèce inconnue : "$requested"'),
      );
    }

    final Iterable<String> slugs =
        requested != null ? <String>[requested] : _profiles.keys;

    final List<Map<String, dynamic>> results = <Map<String, dynamic>>[];
    Failure? lastFailure;

    for (final String slug in slugs) {
      final Result<ScoredForecast> scored = await _service.evaluateSpot(
        location: request.location,
        speciesSlug: slug,
        evaluatedAt: request.evaluatedAt,
        spot: spot,
      );

      scored.fold(
        onSuccess: (ScoredForecast s) => results.add(<String, dynamic>{
          'species': slug,
          'common_name_fr': _profiles[slug]!.commonNameFr,
          ...s.toJson(),
        }),
        onFailure: (Failure f) => lastFailure = f,
      );
    }

    if (results.isEmpty) {
      return Result<Map<String, dynamic>>.failure(
        lastFailure ?? const UnavailableFailure('Aucune évaluation produite'),
      );
    }

    // Classement par pertinence : le premier élément est la recommandation.
    results.sort((Map<String, dynamic> a, Map<String, dynamic> b) =>
        (b['score'] as int).compareTo(a['score'] as int));

    return Result<Map<String, dynamic>>.success(<String, dynamic>{
      'evaluated_at': request.evaluatedAt.toIso8601String(),
      'location': request.location.toJson(),
      'results': results,
    });
  }

  /// Traduit un [Failure] en code HTTP.
  static int httpStatusFor(Failure failure) => switch (failure.code) {
        'VALIDATION_ERROR' => 400,
        'NOT_FOUND' => 404,
        'TIMEOUT' => 504,
        'UNAVAILABLE' || 'COMPOSITE' || 'NETWORK_ERROR' => 503,
        _ => 500,
      };

  /// Corps de réponse d'erreur, aligné sur le format du contrat API.
  static Map<String, dynamic> errorBody(Failure failure) => <String, dynamic>{
        'error': <String, dynamic>{
          'code': failure.code,
          'message': failure.message,
          'details': null,
        },
      };
}

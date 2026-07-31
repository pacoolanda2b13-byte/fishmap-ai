import 'package:core/core.dart';
import 'package:fishscore/fishscore.dart';
import 'package:scoring_pipeline/scoring_pipeline.dart';
import 'package:test/test.dart';
import 'package:weather/weather.dart';

/// Fournisseur qui échoue, pour valider le repli de bout en bout.
class FailingProvider implements WeatherProvider {
  @override
  String get name => 'failing';

  @override
  Future<WeatherForecast> fetchForecast(
    Coordinates location, {
    required DateTime from,
    required DateTime to,
  }) async =>
      throw const WeatherProviderException('hors service');
}

void main() {
  const Coordinates corse = Coordinates(latitude: 41.86, longitude: 9.40);
  final DateTime evaluatedAt = DateTime.utc(2026, 10, 15, 19);
  const WeatherMapper mapper = WeatherMapper();

  WeatherForecast syntheticForecast() => WeatherForecast(
        location: corse,
        samples: <WeatherData>[
          WeatherData(
            observedAt: DateTime.utc(2026, 10, 15, 16),
            source: 'test',
            windSpeedKmh: 16,
            waveHeightM: 0.7,
            seaTemperatureC: 17.5,
            pressureHpa: 1016,
          ),
          WeatherData(
            observedAt: DateTime.utc(2026, 10, 15, 19),
            source: 'test',
            windSpeedKmh: 18,
            gustSpeedKmh: 26,
            waveHeightM: 0.6,
            wavePeriodS: 5,
            seaTemperatureC: 17.2,
            pressureHpa: 1013,
          ),
        ],
      );

  WeatherRepository repositoryWith(List<WeatherProvider> providers) =>
      WeatherRepository(providers: providers);

  StaticWeatherProvider staticProvider() =>
      StaticWeatherProvider(syntheticForecast(), name: 'open-meteo');

  group('WeatherMapper', () {
    test('mappe l\'échantillon le plus proche et la tendance de pression', () {
      final FishScoreInput input = mapper.toFishScoreInput(
        forecast: syntheticForecast(),
        speciesSlug: 'loup',
        evaluatedAt: evaluatedAt,
      );
      expect(input.windSpeedKmh, 18);
      expect(input.seaTemperatureC, 17.2);
      expect(input.weatherObservedAt, DateTime.utc(2026, 10, 15, 19));
      // 1016 -> 1013 sur 3 h.
      expect(input.pressureTrendHpaPer3h, closeTo(-3, 0.001));
    });

    test('propage le contexte du spot', () {
      final FishScoreInput input = mapper.toFishScoreInput(
        forecast: syntheticForecast(),
        speciesSlug: 'loup',
        evaluatedAt: evaluatedAt,
        spot: const SpotContext(
          spotSuitability: 82,
          bottomType: BottomType.rock,
          depthMeters: 5,
          spotQuality: DataQuality.verified,
          history: LocalHistory(observationCount: 6, userCatchCount: 3),
        ),
        moonPhase: MoonPhase.newMoon,
      );
      expect(input.spotSuitability, 82);
      expect(input.bottomType, BottomType.rock);
      expect(input.spotQuality, DataQuality.verified);
      expect(input.moonPhase, isNotNull);
    });

    test('prévision vide : entrée sans météo mais toujours valide', () {
      final FishScoreInput input = mapper.toFishScoreInput(
        forecast:
            WeatherForecast(location: corse, samples: const <WeatherData>[]),
        speciesSlug: 'loup',
        evaluatedAt: evaluatedAt,
      );
      expect(input.windSpeedKmh, isNull);
      final FishScoreResult r = FishScoreEngine().evaluate(input);
      expect(r.score, inInclusiveRange(0, 100));
      expect(r.hasLimitedData, isTrue);
    });
  });

  group('ScoringService', () {
    test('chaîne complète : météo → mapper → score traçable', () async {
      final ScoringService service = ScoringService(
        weatherRepository: repositoryWith(<WeatherProvider>[staticProvider()]),
      );

      final Result<ScoredForecast> result = await service.evaluateSpot(
        location: corse,
        speciesSlug: 'loup',
        evaluatedAt: evaluatedAt,
        spot: const SpotContext(
          spotSuitability: 80,
          bottomType: BottomType.rock,
          depthMeters: 6,
          spotQuality: DataQuality.observed,
        ),
      );

      expect(result.isSuccess, isTrue);
      final ScoredForecast scored = result.valueOrNull!;
      expect(scored.result.score, inInclusiveRange(0, 100));
      expect(scored.result.score, greaterThan(50));
      expect(scored.weatherProvider, 'open-meteo');
      expect(scored.speciesConfidence, KnowledgeConfidence.hypothesis);
      expect(scored.provenanceFr, contains('open-meteo'));
    });

    test('repli automatique jusqu\'au fournisseur hors ligne', () async {
      final ScoringService service = ScoringService(
        weatherRepository: repositoryWith(<WeatherProvider>[
          FailingProvider(),
          staticProvider(),
        ]),
      );

      final Result<ScoredForecast> result = await service.evaluateSpot(
        location: corse,
        speciesSlug: 'loup',
        evaluatedAt: evaluatedAt,
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.weatherProvider, 'open-meteo');
    });

    test('échec propre quand aucune météo n\'est disponible', () async {
      final ScoringService service = ScoringService(
        weatherRepository: repositoryWith(<WeatherProvider>[FailingProvider()]),
      );

      final Result<ScoredForecast> result = await service.evaluateSpot(
        location: corse,
        speciesSlug: 'loup',
        evaluatedAt: evaluatedAt,
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<CompositeFailure>());
    });

    test('espèce inconnue renvoie NotFoundFailure', () async {
      final ScoringService service = ScoringService(
        weatherRepository: repositoryWith(<WeatherProvider>[staticProvider()]),
      );

      final Result<ScoredForecast> result = await service.evaluateSpot(
        location: corse,
        speciesSlug: 'thon-rouge',
        evaluatedAt: evaluatedAt,
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull!.code, 'NOT_FOUND');
    });
  });
}

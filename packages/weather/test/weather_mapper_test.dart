import 'package:fishscore/fishscore.dart';
import 'package:test/test.dart';
import 'package:weather/weather.dart';

void main() {
  const GeoPoint corse = GeoPoint(latitude: 41.86, longitude: 9.40);
  const WeatherMapper mapper = WeatherMapper();

  Future<WeatherForecast> syntheticDay() {
    final StaticWeatherProvider provider = StaticWeatherProvider.synthetic(
      location: corse,
      from: DateTime.utc(2026, 10, 15, 0),
      to: DateTime.utc(2026, 10, 15, 23),
    );
    return provider.fetchForecast(
      corse,
      from: DateTime.utc(2026, 10, 15, 0),
      to: DateTime.utc(2026, 10, 15, 23),
    );
  }

  group('WeatherMapper', () {
    test('mappe l\'échantillon le plus proche vers FishScoreInput', () async {
      final WeatherForecast forecast = await syntheticDay();
      final FishScoreInput input = mapper.toFishScoreInput(
        forecast: forecast,
        speciesSlug: 'loup',
        evaluatedAt: DateTime.utc(2026, 10, 15, 19),
      );
      expect(input.speciesSlug, 'loup');
      expect(input.windSpeedKmh, isNotNull);
      expect(input.seaTemperatureC, isNotNull);
      expect(input.pressureHpa, isNotNull);
      // La fraîcheur s'appuie sur l'instant d'observation retenu.
      expect(input.weatherObservedAt, isNotNull);
      expect(input.pressureTrendHpaPer3h, isNotNull);
    });

    test('propage le contexte du spot', () async {
      final WeatherForecast forecast = await syntheticDay();
      final FishScoreInput input = mapper.toFishScoreInput(
        forecast: forecast,
        speciesSlug: 'loup',
        evaluatedAt: DateTime.utc(2026, 10, 15, 19),
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

    test('la chaîne complète produit un score exploitable', () async {
      final WeatherForecast forecast = await syntheticDay();
      final FishScoreEngine engine = FishScoreEngine();
      final FishScoreInput input = mapper.toFishScoreInput(
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
      final FishScoreResult result = engine.evaluate(input);
      expect(result.score, inInclusiveRange(0, 100));
      // Conditions favorables au crépuscule d'automne pour le loup.
      expect(result.score, greaterThan(50));
      expect(result.confidence, greaterThan(40));
    });

    test('série vide : entrée sans météo, mais toujours valide', () {
      final WeatherForecast empty =
          WeatherForecast(location: corse, samples: const <WeatherData>[]);
      final FishScoreInput input = mapper.toFishScoreInput(
        forecast: empty,
        speciesSlug: 'loup',
        evaluatedAt: DateTime.utc(2026, 10, 15, 19),
      );
      expect(input.windSpeedKmh, isNull);
      expect(input.weatherObservedAt, isNull);
      // Le moteur doit rester capable de produire un score dégradé.
      final FishScoreResult result = FishScoreEngine().evaluate(input);
      expect(result.score, inInclusiveRange(0, 100));
      expect(result.hasLimitedData, isTrue);
    });
  });
}

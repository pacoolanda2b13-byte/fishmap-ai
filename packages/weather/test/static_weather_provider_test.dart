import 'package:core/core.dart';
import 'package:test/test.dart';
import 'package:weather/weather.dart';

void main() {
  const Coordinates corse = Coordinates(latitude: 41.86, longitude: 9.40);

  group('StaticWeatherProvider', () {
    test('restitue une prévision fournie filtrée sur l\'intervalle', () async {
      final WeatherForecast preset = WeatherForecast(
        location: corse,
        samples: <WeatherData>[
          WeatherData(
              observedAt: DateTime.utc(2026, 10, 15, 5), source: 'preset'),
          WeatherData(
              observedAt: DateTime.utc(2026, 10, 15, 12), source: 'preset'),
          WeatherData(
              observedAt: DateTime.utc(2026, 10, 15, 20), source: 'preset'),
        ],
      );
      final StaticWeatherProvider provider = StaticWeatherProvider(preset);
      final WeatherForecast out = await provider.fetchForecast(
        corse,
        from: DateTime.utc(2026, 10, 15, 6),
        to: DateTime.utc(2026, 10, 15, 18),
      );
      expect(out.samples.length, 1);
      expect(out.samples.single.observedAt.hour, 12);
    });

    test('synthetic génère une série horaire déterministe', () async {
      StaticWeatherProvider build() => StaticWeatherProvider.synthetic(
            location: corse,
            from: DateTime.utc(2026, 10, 15, 0),
            to: DateTime.utc(2026, 10, 15, 23),
          );
      final DateTime from = DateTime.utc(2026, 10, 15, 0);
      final DateTime to = DateTime.utc(2026, 10, 15, 23);

      final WeatherForecast a =
          await build().fetchForecast(corse, from: from, to: to);
      final WeatherForecast b =
          await build().fetchForecast(corse, from: from, to: to);

      expect(a.samples.length, 24);
      // Déterminisme : deux générations identiques.
      expect(a.samples.first.seaTemperatureC, b.samples.first.seaTemperatureC);
      expect(a.samples.last.pressureHpa, b.samples.last.pressureHpa);
      // Tous les champs clés sont renseignés.
      for (final WeatherData s in a.samples) {
        expect(s.windSpeedKmh, isNotNull);
        expect(s.seaTemperatureC, isNotNull);
        expect(s.pressureHpa, isNotNull);
      }
    });

    test('synthetic produit une tendance de pression négative', () async {
      final StaticWeatherProvider provider = StaticWeatherProvider.synthetic(
        location: corse,
        from: DateTime.utc(2026, 10, 15, 0),
        to: DateTime.utc(2026, 10, 15, 23),
      );
      final WeatherForecast f = await provider.fetchForecast(
        corse,
        from: DateTime.utc(2026, 10, 15, 0),
        to: DateTime.utc(2026, 10, 15, 23),
      );
      final double? trend =
          f.pressureTrendHpaPer3h(DateTime.utc(2026, 10, 15, 12));
      expect(trend, isNotNull);
      expect(trend, lessThan(0));
    });
  });
}

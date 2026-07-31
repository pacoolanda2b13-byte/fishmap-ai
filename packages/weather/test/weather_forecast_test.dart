import 'package:core/core.dart';
import 'package:test/test.dart';
import 'package:weather/weather.dart';

WeatherData sample(int hour, {double? pressure}) => WeatherData(
      observedAt: DateTime.utc(2026, 10, 15, hour),
      source: 'test',
      pressureHpa: pressure,
    );

void main() {
  const Coordinates corse = Coordinates(latitude: 41.86, longitude: 9.40);

  group('WeatherForecast', () {
    test('trie les échantillons par ordre chronologique', () {
      final WeatherForecast f = WeatherForecast(
        location: corse,
        samples: <WeatherData>[sample(12), sample(6), sample(9)],
      );
      expect(
        f.samples.map((WeatherData s) => s.observedAt.hour).toList(),
        <int>[6, 9, 12],
      );
    });

    test('nearest renvoie l\'échantillon le plus proche', () {
      final WeatherForecast f = WeatherForecast(
        location: corse,
        samples: <WeatherData>[sample(6), sample(9), sample(12)],
      );
      expect(f.nearest(DateTime.utc(2026, 10, 15, 10))!.observedAt.hour, 9);
      expect(f.nearest(DateTime.utc(2026, 10, 15, 11))!.observedAt.hour, 12);
    });

    test('nearest sur série vide renvoie null', () {
      final WeatherForecast f =
          WeatherForecast(location: corse, samples: const <WeatherData>[]);
      expect(f.nearest(DateTime.utc(2026, 10, 15, 10)), isNull);
      expect(f.isEmpty, isTrue);
    });

    test('pressureTrend calcule une pente ramenée à 3 heures', () {
      final WeatherForecast f = WeatherForecast(
        location: corse,
        samples: <WeatherData>[
          sample(16, pressure: 1016),
          sample(19, pressure: 1013),
        ],
      );
      // -3 hPa sur 3 h → -3 hPa/3h.
      expect(
        f.pressureTrendHpaPer3h(DateTime.utc(2026, 10, 15, 19)),
        closeTo(-3, 0.0001),
      );
    });

    test('pressureTrend null si un seul échantillon', () {
      final WeatherForecast f = WeatherForecast(
        location: corse,
        samples: <WeatherData>[sample(19, pressure: 1013)],
      );
      expect(f.pressureTrendHpaPer3h(DateTime.utc(2026, 10, 15, 19)), isNull);
    });

    test('pressureTrend null si pression absente', () {
      final WeatherForecast f = WeatherForecast(
        location: corse,
        samples: <WeatherData>[sample(16), sample(19)],
      );
      expect(f.pressureTrendHpaPer3h(DateTime.utc(2026, 10, 15, 19)), isNull);
    });

    test('coverage reflète la fenêtre couverte', () {
      final WeatherForecast f = WeatherForecast(
        location: corse,
        samples: <WeatherData>[sample(6), sample(18)],
      );
      expect(f.coverage!.start.hour, 6);
      expect(f.coverage!.end.hour, 18);
    });

    test('toJson/fromJson round-trip', () {
      final WeatherForecast f = WeatherForecast(
        location: corse,
        samples: <WeatherData>[sample(6, pressure: 1015), sample(9)],
      );
      final WeatherForecast back = WeatherForecast.fromJson(f.toJson());
      expect(back.samples.length, 2);
      expect(back.location, corse);
    });
  });
}

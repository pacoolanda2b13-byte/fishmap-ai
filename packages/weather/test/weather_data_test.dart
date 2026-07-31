import 'package:test/test.dart';
import 'package:weather/weather.dart';

void main() {
  group('WeatherData', () {
    test('isEmpty vrai sans aucun paramètre', () {
      final WeatherData d = WeatherData(
          observedAt: DateTime.utc(2026, 10, 15, 7), source: 'test');
      expect(d.isEmpty, isTrue);
    });

    test('isEmpty faux dès qu\'un paramètre est présent', () {
      final WeatherData d = WeatherData(
        observedAt: DateTime.utc(2026, 10, 15, 7),
        source: 'test',
        windSpeedKmh: 12,
      );
      expect(d.isEmpty, isFalse);
    });

    test('rejette une direction de vent hors bornes', () {
      expect(
        () => WeatherData(
          observedAt: DateTime.utc(2026, 10, 15, 7),
          source: 'test',
          windDirectionDeg: 400,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('toJson/fromJson round-trip', () {
      final WeatherData d = WeatherData(
        observedAt: DateTime.utc(2026, 10, 15, 7),
        source: 'open-meteo',
        windSpeedKmh: 18.5,
        gustSpeedKmh: 26,
        waveHeightM: 0.6,
        wavePeriodS: 5,
        seaTemperatureC: 17.2,
        pressureHpa: 1013.4,
      );
      final WeatherData back = WeatherData.fromJson(d.toJson());
      expect(back.observedAt, d.observedAt);
      expect(back.source, 'open-meteo');
      expect(back.windSpeedKmh, 18.5);
      expect(back.waveHeightM, 0.6);
      expect(back.pressureHpa, 1013.4);
    });

    test('toJson omet les champs absents', () {
      final WeatherData d = WeatherData(
        observedAt: DateTime.utc(2026, 10, 15, 7),
        source: 'test',
        windSpeedKmh: 10,
      );
      final Map<String, dynamic> json = d.toJson();
      expect(json.containsKey('wind_speed_kmh'), isTrue);
      expect(json.containsKey('wave_height_m'), isFalse);
    });

    test('copyWith remplace uniquement les champs fournis', () {
      final WeatherData d = WeatherData(
        observedAt: DateTime.utc(2026, 10, 15, 7),
        source: 'test',
        windSpeedKmh: 10,
        seaTemperatureC: 18,
      );
      final WeatherData d2 = d.copyWith(windSpeedKmh: 25);
      expect(d2.windSpeedKmh, 25);
      expect(d2.seaTemperatureC, 18);
    });
  });
}

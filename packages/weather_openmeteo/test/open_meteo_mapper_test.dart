import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:weather/weather.dart';
import 'package:weather_openmeteo/weather_openmeteo.dart';

Map<String, dynamic> fixture(String name) {
  final File file = File('test/fixtures/$name');
  expect(file.existsSync(), isTrue, reason: 'fixture manquante : $name');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  const OpenMeteoMapper mapper = OpenMeteoMapper();

  group('mapping nominal', () {
    late List<WeatherData> samples;

    setUp(() {
      samples = mapper.toWeatherData(
        forecastJson: fixture('forecast_solenzara.json'),
        marineJson: fixture('marine_solenzara.json'),
        source: 'open-meteo',
      );
    });

    test('produit un échantillon par horodatage', () {
      expect(samples.length, 6);
      expect(samples.first.observedAt, DateTime.utc(2026, 10, 15, 16));
      expect(samples.last.observedAt, DateTime.utc(2026, 10, 15, 21));
    });

    test('interprète les horodatages sans suffixe comme de l\'UTC', () {
      for (final WeatherData s in samples) {
        expect(s.observedAt.isUtc, isTrue);
      }
    });

    test('fusionne données atmosphériques et marines', () {
      final WeatherData at19 = samples
          .firstWhere((WeatherData s) => s.observedAt.hour == 19);
      // Atmosphère.
      expect(at19.windSpeedKmh, 14.4);
      expect(at19.gustSpeedKmh, 25.2);
      expect(at19.windDirectionDeg, 101);
      expect(at19.airTemperatureC, 19.2);
      expect(at19.pressureHpa, 1014.2);
      expect(at19.precipitationMm, 0.0);
      expect(at19.cloudCoverPct, 45);
      // Marine.
      expect(at19.waveHeightM, 0.51);
      expect(at19.wavePeriodS, 4.5);
      expect(at19.waveDirectionDeg, 112);
      expect(at19.seaTemperatureC, 19.5);
    });

    test('trace la source', () {
      expect(samples.every((WeatherData s) => s.source == 'open-meteo'), isTrue);
    });
  });

  group('conversion d\'unités pilotée par hourly_units', () {
    test('convertit °F, mp/h, nœuds et pouces vers les unités canoniques', () {
      final List<WeatherData> samples = mapper.toWeatherData(
        forecastJson: fixture('forecast_imperial_units.json'),
        source: 'open-meteo',
      );
      final WeatherData s = samples.single;
      // 50 °F = 10 °C.
      expect(s.airTemperatureC, closeTo(10, 0.0001));
      // 10 mph = 16.09344 km/h.
      expect(s.windSpeedKmh, closeTo(16.09344, 0.0001));
      // 10 nœuds = 18.52 km/h.
      expect(s.gustSpeedKmh, closeTo(18.52, 0.0001));
      // 1 pouce = 25.4 mm.
      expect(s.precipitationMm, closeTo(25.4, 0.0001));
    });

    test('rejette une unité inconnue plutôt que de deviner', () {
      final Map<String, dynamic> json = fixture('forecast_solenzara.json');
      (json['hourly_units'] as Map<String, dynamic>)['wind_speed_10m'] =
          'furlongs/fortnight';
      expect(
        () => mapper.toWeatherData(forecastJson: json, source: 'open-meteo'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('données partielles', () {
    late List<WeatherData> samples;

    setUp(() {
      samples = mapper.toWeatherData(
        forecastJson: fixture('forecast_partial_data.json'),
        source: 'open-meteo',
      );
    });

    test('les valeurs nulles deviennent des champs absents', () {
      final WeatherData at19 =
          samples.firstWhere((WeatherData s) => s.observedAt.hour == 19);
      expect(at19.airTemperatureC, isNull);
      expect(at19.windDirectionDeg, isNull);
      expect(at19.windSpeedKmh, 14.4);
    });

    test('une série entièrement nulle n\'invente aucune valeur', () {
      expect(samples.every((WeatherData s) => s.pressureHpa == null), isTrue);
    });

    test('les échantillons partiels restent exploitables', () {
      expect(samples.length, 3);
      expect(samples.every((WeatherData s) => !s.isEmpty), isTrue);
    });
  });

  group('robustesse', () {
    test('fonctionne sans réponse marine', () {
      final List<WeatherData> samples = mapper.toWeatherData(
        forecastJson: fixture('forecast_solenzara.json'),
        source: 'open-meteo',
      );
      expect(samples.length, 6);
      expect(samples.every((WeatherData s) => s.waveHeightM == null), isTrue);
      expect(samples.every((WeatherData s) => s.windSpeedKmh != null), isTrue);
    });

    test('conserve les instants présents seulement côté marine', () {
      final Map<String, dynamic> marine = fixture('marine_solenzara.json');
      (marine['hourly'] as Map<String, dynamic>)['time'] = <String>[
        '2026-10-15T22:00',
      ];
      for (final String key in <String>[
        'wave_height',
        'wave_period',
        'wave_direction',
        'sea_surface_temperature',
      ]) {
        (marine['hourly'] as Map<String, dynamic>)[key] = <double>[0.4];
      }

      final List<WeatherData> samples = mapper.toWeatherData(
        forecastJson: fixture('forecast_solenzara.json'),
        marineJson: marine,
        source: 'open-meteo',
      );
      expect(samples.length, 7);
      expect(samples.last.observedAt, DateTime.utc(2026, 10, 15, 22));
      expect(samples.last.waveHeightM, 0.4);
      expect(samples.last.windSpeedKmh, isNull);
    });

    test('normalise une direction hors bornes', () {
      final Map<String, dynamic> json = fixture('forecast_solenzara.json');
      (json['hourly'] as Map<String, dynamic>)['wind_direction_10m'] =
          <double>[360, 361, -10, 720, 45, 90];
      final List<WeatherData> samples =
          mapper.toWeatherData(forecastJson: json, source: 'open-meteo');
      expect(samples[0].windDirectionDeg, 0);
      expect(samples[1].windDirectionDeg, 1);
      expect(samples[2].windDirectionDeg, 350);
      expect(samples[3].windDirectionDeg, 0);
    });

    test('rejette une réponse sans bloc hourly', () {
      expect(
        () => mapper.toWeatherData(
          forecastJson: <String, dynamic>{'latitude': 41.8},
          source: 'open-meteo',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejette un bloc hourly sans série time', () {
      expect(
        () => mapper.toWeatherData(
          forecastJson: <String, dynamic>{
            'hourly': <String, dynamic>{'temperature_2m': <double>[12]},
          },
          source: 'open-meteo',
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

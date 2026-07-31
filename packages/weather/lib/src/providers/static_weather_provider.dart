import 'dart:math' as math;

import '../models/geo_point.dart';
import '../models/weather_data.dart';
import '../models/weather_forecast.dart';
import 'weather_provider.dart';

/// Fournisseur météo en mémoire, sans réseau.
///
/// Sert au développement hors ligne, aux démonstrations et aux tests. Il peut
/// restituer une prévision fournie, ou en générer une **déterministe** via
/// [StaticWeatherProvider.synthetic].
class StaticWeatherProvider implements WeatherProvider {
  StaticWeatherProvider(this._forecast, {this.name = 'static'});

  final WeatherForecast _forecast;

  @override
  final String name;

  @override
  Future<WeatherForecast> fetchForecast(
    GeoPoint location, {
    required DateTime from,
    required DateTime to,
  }) async {
    final List<WeatherData> inRange = _forecast.samples
        .where((WeatherData s) =>
            !s.observedAt.isBefore(from) && !s.observedAt.isAfter(to))
        .toList();
    return WeatherForecast(location: _forecast.location, samples: inRange);
  }

  /// Génère une prévision synthétique et déterministe, échantillonnée toutes
  /// les [step] entre [from] et [to].
  ///
  /// Les valeurs suivent des variations journalières plausibles (température
  /// maximale l'après-midi, pression en lente évolution). Utile pour tester la
  /// chaîne complète sans dépendre d'un fournisseur réel.
  factory StaticWeatherProvider.synthetic({
    required GeoPoint location,
    required DateTime from,
    required DateTime to,
    Duration step = const Duration(hours: 1),
    double baseSeaTemperatureC = 20,
    double basePressureHpa = 1016,
    double pressureSlopeHpaPerHour = -0.3,
    String source = 'synthetic',
  }) {
    assert(!to.isBefore(from));
    assert(step.inMinutes > 0);

    final List<WeatherData> samples = <WeatherData>[];
    DateTime cursor = from;
    int index = 0;
    while (!cursor.isAfter(to)) {
      final double hour = cursor.hour + cursor.minute / 60;
      final double dayPhase = (hour - 15) / 24 * 2 * math.pi;
      final double hoursFromStart = index * step.inMinutes / 60;

      samples.add(WeatherData(
        observedAt: cursor,
        source: source,
        windSpeedKmh: _round(12 + 6 * math.sin((hour - 9) / 24 * 2 * math.pi)),
        windDirectionDeg: 90,
        gustSpeedKmh:
            _round((12 + 6 * math.sin((hour - 9) / 24 * 2 * math.pi)) * 1.4),
        waveHeightM: _round(0.4 + 0.2 * math.sin(dayPhase), 2),
        wavePeriodS: 4.5,
        waveDirectionDeg: 90,
        seaTemperatureC:
            _round(baseSeaTemperatureC + 1.5 * math.sin(dayPhase), 2),
        airTemperatureC:
            _round(baseSeaTemperatureC + 2 + 4 * math.sin(dayPhase), 2),
        pressureHpa: _round(
            basePressureHpa + pressureSlopeHpaPerHour * hoursFromStart, 2),
        precipitationMm: 0,
        cloudCoverPct: 20,
      ));

      cursor = cursor.add(step);
      index++;
    }

    return StaticWeatherProvider(
      WeatherForecast(location: location, samples: samples),
      name: source,
    );
  }

  static double _round(double value, [int decimals = 1]) {
    final num factor = math.pow(10, decimals);
    return (value * factor).round() / factor;
  }
}

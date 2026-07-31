import 'package:core/core.dart';
import 'package:weather/weather.dart';

/// Convertit les réponses JSON d'Open-Meteo en [WeatherData] normalisées.
///
/// Le mapper est **conscient des unités** : plutôt que de supposer que l'API
/// renvoie les unités demandées, il lit le bloc `hourly_units` de la réponse et
/// convertit vers les unités canoniques du projet via `core.Units`. Un
/// changement de configuration côté API ne peut donc pas corrompre
/// silencieusement les données.
///
/// Aucune logique métier ici : uniquement JSON → modèle normalisé.
class OpenMeteoMapper {
  const OpenMeteoMapper();

  /// Fusionne les réponses des API prévision et marine en une série unique.
  ///
  /// Les deux réponses sont alignées sur leurs horodatages. Les instants
  /// présents uniquement dans la réponse marine sont conservés : une donnée
  /// partielle vaut mieux qu'aucune donnée, et le moteur FishScore sait
  /// composer avec les champs absents.
  ///
  /// Lève [FormatException] si la structure attendue est absente.
  List<WeatherData> toWeatherData({
    required Map<String, dynamic> forecastJson,
    Map<String, dynamic>? marineJson,
    required String source,
  }) {
    final _HourlyBlock forecast = _HourlyBlock.parse(forecastJson);
    final _HourlyBlock? marine =
        marineJson == null ? null : _HourlyBlock.parse(marineJson);

    // Union ordonnée des horodatages des deux séries.
    final Set<DateTime> instants = <DateTime>{
      ...forecast.times,
      if (marine != null) ...marine.times,
    };
    final List<DateTime> ordered = instants.toList()
      ..sort((DateTime a, DateTime b) => a.compareTo(b));

    final List<WeatherData> samples = <WeatherData>[];
    for (final DateTime instant in ordered) {
      final WeatherData sample = WeatherData(
        observedAt: instant,
        source: source,
        windSpeedKmh: _speed(forecast, 'wind_speed_10m', instant),
        windDirectionDeg: _direction(forecast, 'wind_direction_10m', instant),
        gustSpeedKmh: _speed(forecast, 'wind_gusts_10m', instant),
        airTemperatureC: _temperature(forecast, 'temperature_2m', instant),
        pressureHpa: _pressure(forecast, 'pressure_msl', instant),
        precipitationMm:
            _length(forecast, 'precipitation', instant, millimetres: true),
        cloudCoverPct: _percentage(forecast, 'cloud_cover', instant),
        waveHeightM: _length(marine, 'wave_height', instant),
        wavePeriodS: _seconds(marine, 'wave_period', instant),
        waveDirectionDeg: _direction(marine, 'wave_direction', instant),
        seaTemperatureC:
            _temperature(marine, 'sea_surface_temperature', instant),
      );

      // Un instant sans aucune mesure exploitable n'apporte rien.
      if (!sample.isEmpty) samples.add(sample);
    }

    return samples;
  }

  double? _speed(_HourlyBlock? block, String key, DateTime instant) {
    final double? raw = block?.valueAt(key, instant);
    if (raw == null) return null;
    return switch (_normalizeUnit(block!.unitOf(key))) {
      'kmh' || 'km/h' => raw,
      'ms' || 'm/s' => Units.msToKmh(raw),
      'kn' || 'kt' || 'knots' => Units.knotsToKmh(raw),
      'mph' || 'mp/h' => Units.mphToKmh(raw),
      final String unit => throw FormatException(
          'Unité de vitesse inconnue pour "$key" : "$unit"'),
    };
  }

  double? _temperature(_HourlyBlock? block, String key, DateTime instant) {
    final double? raw = block?.valueAt(key, instant);
    if (raw == null) return null;
    return switch (_normalizeUnit(block!.unitOf(key))) {
      'c' || '°c' || 'celsius' => raw,
      'f' || '°f' || 'fahrenheit' => Units.fahrenheitToCelsius(raw),
      'k' || 'kelvin' => Units.kelvinToCelsius(raw),
      final String unit => throw FormatException(
          'Unité de température inconnue pour "$key" : "$unit"'),
    };
  }

  double? _pressure(_HourlyBlock? block, String key, DateTime instant) {
    final double? raw = block?.valueAt(key, instant);
    if (raw == null) return null;
    return switch (_normalizeUnit(block!.unitOf(key))) {
      'hpa' => raw,
      'pa' => Units.paToHpa(raw),
      'inhg' => Units.inHgToHpa(raw),
      final String unit => throw FormatException(
          'Unité de pression inconnue pour "$key" : "$unit"'),
    };
  }

  double? _length(
    _HourlyBlock? block,
    String key,
    DateTime instant, {
    bool millimetres = false,
  }) {
    final double? raw = block?.valueAt(key, instant);
    if (raw == null) return null;
    final String unit = _normalizeUnit(block!.unitOf(key));
    if (millimetres) {
      return switch (unit) {
        'mm' => raw,
        'inch' || 'in' => raw * 25.4,
        _ => throw FormatException(
            'Unité de précipitation inconnue pour "$key" : "$unit"'),
      };
    }
    return switch (unit) {
      'm' => raw,
      'ft' || 'feet' => Units.feetToMeters(raw),
      _ => throw FormatException(
          'Unité de longueur inconnue pour "$key" : "$unit"'),
    };
  }

  double? _seconds(_HourlyBlock? block, String key, DateTime instant) {
    final double? raw = block?.valueAt(key, instant);
    if (raw == null) return null;
    final String unit = _normalizeUnit(block!.unitOf(key));
    if (unit != 's' && unit != 'sec' && unit != 'seconds') {
      throw FormatException('Unité de période inconnue pour "$key" : "$unit"');
    }
    return raw;
  }

  double? _direction(_HourlyBlock? block, String key, DateTime instant) {
    final double? raw = block?.valueAt(key, instant);
    if (raw == null) return null;
    // Ramène dans [0, 360) : WeatherData refuse les valeurs hors bornes.
    final double normalized = raw % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }

  double? _percentage(_HourlyBlock? block, String key, DateTime instant) {
    final double? raw = block?.valueAt(key, instant);
    if (raw == null) return null;
    return raw.clamp(0, 100).toDouble();
  }

  /// Normalise une unité pour comparaison : minuscules, sans espace ni
  /// caractère de degré.
  static String _normalizeUnit(String? unit) =>
      (unit ?? '').toLowerCase().replaceAll(' ', '').replaceAll('°', '');
}

/// Bloc `hourly` + `hourly_units` d'une réponse Open-Meteo, indexé par instant.
class _HourlyBlock {
  _HourlyBlock._(this.times, this._indexByTime, this._values, this._units);

  /// Horodatages de la série, dans l'ordre de la réponse.
  final List<DateTime> times;

  final Map<DateTime, int> _indexByTime;
  final Map<String, List<double?>> _values;
  final Map<String, String> _units;

  /// Analyse une réponse Open-Meteo.
  ///
  /// Lève [FormatException] si le bloc `hourly` ou sa série `time` est absent.
  static _HourlyBlock parse(Map<String, dynamic> json) {
    final Object? hourly = json['hourly'];
    if (hourly is! Map<String, dynamic>) {
      throw const FormatException('Réponse Open-Meteo sans bloc "hourly"');
    }
    final Object? rawTimes = hourly['time'];
    if (rawTimes is! List) {
      throw const FormatException('Bloc "hourly" sans série "time"');
    }

    final List<DateTime> times = rawTimes
        .map((Object? t) => _parseUtc(t as String))
        .toList(growable: false);

    final Map<DateTime, int> indexByTime = <DateTime, int>{
      for (int i = 0; i < times.length; i++) times[i]: i,
    };

    final Map<String, List<double?>> values = <String, List<double?>>{};
    for (final MapEntry<String, dynamic> entry in hourly.entries) {
      if (entry.key == 'time') continue;
      final Object? series = entry.value;
      if (series is! List) continue;
      values[entry.key] = series
          .map((Object? v) => v is num ? v.toDouble() : null)
          .toList(growable: false);
    }

    final Object? rawUnits = json['hourly_units'];
    final Map<String, String> units = <String, String>{
      if (rawUnits is Map<String, dynamic>)
        for (final MapEntry<String, dynamic> e in rawUnits.entries)
          if (e.value is String) e.key: e.value as String,
    };

    return _HourlyBlock._(times, indexByTime, values, units);
  }

  /// Valeur de [key] à [instant], ou `null` si absente ou non mesurée.
  double? valueAt(String key, DateTime instant) {
    final int? index = _indexByTime[instant];
    if (index == null) return null;
    final List<double?>? series = _values[key];
    if (series == null || index >= series.length) return null;
    return series[index];
  }

  /// Unité déclarée pour [key].
  String? unitOf(String key) => _units[key];

  /// Interprète un horodatage Open-Meteo comme de l'UTC.
  ///
  /// Avec `timezone=UTC`, l'API renvoie `2026-10-15T06:00` sans suffixe de
  /// fuseau : `DateTime.parse` produirait une date locale.
  static DateTime _parseUtc(String raw) {
    final String normalized =
        raw.endsWith('Z') || raw.contains('+') ? raw : '${raw}Z';
    return DateTime.parse(normalized).toUtc();
  }
}

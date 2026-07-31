import 'package:meta/meta.dart';

import 'geo_point.dart';
import 'weather_data.dart';

/// Série temporelle de [WeatherData] pour un point donné.
///
/// Les échantillons sont triés par ordre chronologique croissant. La série
/// fournit un accès par proximité temporelle et calcule la tendance de
/// pression, indépendamment du fournisseur d'origine.
@immutable
class WeatherForecast {
  WeatherForecast({
    required this.location,
    required List<WeatherData> samples,
  }) : samples = List<WeatherData>.unmodifiable(
          samples.toList()
            ..sort((WeatherData a, WeatherData b) =>
                a.observedAt.compareTo(b.observedAt)),
        );

  /// Point de référence de la prévision.
  final GeoPoint location;

  /// Échantillons triés par `observedAt` croissant.
  final List<WeatherData> samples;

  bool get isEmpty => samples.isEmpty;
  bool get isNotEmpty => samples.isNotEmpty;

  /// Échantillon le plus proche de [instant], ou `null` si la série est vide.
  WeatherData? nearest(DateTime instant) {
    if (samples.isEmpty) return null;
    WeatherData best = samples.first;
    Duration bestGap = _absGap(best.observedAt, instant);
    for (final WeatherData sample in samples.skip(1)) {
      final Duration gap = _absGap(sample.observedAt, instant);
      if (gap < bestGap) {
        best = sample;
        bestGap = gap;
      }
    }
    return best;
  }

  /// Tendance de pression sur 3 heures (hPa) autour de [instant].
  ///
  /// Renvoie `null` si la série ne permet pas de comparer deux instants
  /// distincts disposant tous deux d'une pression.
  double? pressureTrendHpaPer3h(DateTime instant) {
    final WeatherData? current = nearest(instant);
    final WeatherData? previous =
        nearest(instant.subtract(const Duration(hours: 3)));
    if (current == null || previous == null) return null;
    if (current.observedAt == previous.observedAt) return null;
    final double? p1 = current.pressureHpa;
    final double? p0 = previous.pressureHpa;
    if (p1 == null || p0 == null) return null;

    // Ramène la variation à une base de 3 heures pour rester comparable.
    final double hours =
        current.observedAt.difference(previous.observedAt).inMinutes / 60;
    if (hours == 0) return null;
    return (p1 - p0) / hours * 3;
  }

  /// Fenêtre couverte par la série, ou `null` si elle est vide.
  DateTimeRange? get coverage => samples.isEmpty
      ? null
      : DateTimeRange(samples.first.observedAt, samples.last.observedAt);

  static Duration _absGap(DateTime a, DateTime b) {
    final Duration diff = a.difference(b);
    return diff.isNegative ? -diff : diff;
  }

  factory WeatherForecast.fromJson(Map<String, dynamic> json) =>
      WeatherForecast(
        location: GeoPoint.fromJson(json['location'] as Map<String, dynamic>),
        samples: ((json['samples'] as List<dynamic>?) ?? const <dynamic>[])
            .map((dynamic e) => WeatherData.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'location': location.toJson(),
        'samples': samples.map((WeatherData s) => s.toJson()).toList(),
      };
}

/// Intervalle temporel simple (début/fin inclus).
@immutable
class DateTimeRange {
  const DateTimeRange(this.start, this.end);
  final DateTime start;
  final DateTime end;

  Duration get duration => end.difference(start);

  bool contains(DateTime instant) =>
      !instant.isBefore(start) && !instant.isAfter(end);
}

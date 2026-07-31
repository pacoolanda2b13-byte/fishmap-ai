import 'package:meta/meta.dart';

/// Distance non négative, stockée en mètres.
///
/// Value object : évite de faire circuler des `double` ambigus (mètres ?
/// kilomètres ?) dans les signatures.
@immutable
class Distance implements Comparable<Distance> {
  const Distance.meters(this.meters) : assert(meters >= 0, 'distance négative');

  factory Distance.kilometers(double km) => Distance.meters(km * 1000);

  static const Distance zero = Distance.meters(0);

  /// Valeur en mètres.
  final double meters;

  /// Valeur en kilomètres.
  double get kilometers => meters / 1000;

  Distance operator +(Distance other) => Distance.meters(meters + other.meters);

  bool operator <(Distance other) => meters < other.meters;
  bool operator <=(Distance other) => meters <= other.meters;
  bool operator >(Distance other) => meters > other.meters;
  bool operator >=(Distance other) => meters >= other.meters;

  @override
  int compareTo(Distance other) => meters.compareTo(other.meters);

  @override
  bool operator ==(Object other) => other is Distance && other.meters == meters;

  @override
  int get hashCode => meters.hashCode;

  @override
  String toString() => kilometers >= 1
      ? '${kilometers.toStringAsFixed(2)} km'
      : '${meters.toStringAsFixed(0)} m';
}

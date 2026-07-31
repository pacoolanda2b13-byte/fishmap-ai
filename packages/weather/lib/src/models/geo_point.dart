import 'dart:math' as math;

import 'package:meta/meta.dart';

/// Point géographique en coordonnées WGS84 (EPSG:4326).
@immutable
class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude})
      : assert(latitude >= -90 && latitude <= 90, 'latitude invalide'),
        assert(longitude >= -180 && longitude <= 180, 'longitude invalide');

  final double latitude;
  final double longitude;

  /// Distance approximative en kilomètres (formule de haversine).
  double distanceKmTo(GeoPoint other) {
    const double earthRadiusKm = 6371;
    final double dLat = _radians(other.latitude - latitude);
    final double dLon = _radians(other.longitude - longitude);
    final double a = math.pow(math.sin(dLat / 2), 2).toDouble() +
        math.cos(_radians(latitude)) *
            math.cos(_radians(other.latitude)) *
            math.pow(math.sin(dLon / 2), 2).toDouble();
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _radians(double degrees) => degrees * math.pi / 180;

  factory GeoPoint.fromJson(Map<String, dynamic> json) => GeoPoint(
        latitude: (json['lat'] as num).toDouble(),
        longitude: (json['lng'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'lat': latitude,
        'lng': longitude,
      };

  @override
  bool operator ==(Object other) =>
      other is GeoPoint &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() =>
      'GeoPoint(${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)})';
}

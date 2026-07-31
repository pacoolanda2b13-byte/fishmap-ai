import 'package:core/core.dart';
import 'package:meta/meta.dart';

/// Clé d'entrée de cache météo.
///
/// Deux demandes proches dans l'espace et dans le temps doivent partager la
/// même entrée : c'est ce qui évite d'appeler le fournisseur à chaque requête
/// utilisateur. La clé applique donc deux arrondis :
///
/// - **spatial** : les coordonnées sont arrondies à [precisionDegrees]
///   (0,05° ≈ 5 km), car la météo marine ne varie pas significativement à
///   cette échelle ;
/// - **temporel** : la fenêtre est alignée sur l'heure pleine, l'API ne
///   fournissant de toute façon qu'un point par heure.
///
/// La clé ne contient **aucune référence à un fournisseur** : le cache reste
/// indépendant de la source des données.
@immutable
class WeatherCacheKey {
  WeatherCacheKey({
    required Coordinates location,
    required DateTime from,
    required DateTime to,
    this.precisionDegrees = defaultPrecisionDegrees,
    this.namespace = 'forecast',
  })  : assert(precisionDegrees > 0, 'la précision doit être positive'),
        latitude = _round(location.latitude, precisionDegrees),
        longitude = _round(location.longitude, precisionDegrees),
        from = _floorToHour(from),
        to = _ceilToHour(to);

  /// Précision spatiale par défaut : 0,05° ≈ 5 km.
  static const double defaultPrecisionDegrees = 0.05;

  /// Latitude arrondie.
  final double latitude;

  /// Longitude arrondie.
  final double longitude;

  /// Début de fenêtre aligné à l'heure inférieure.
  final DateTime from;

  /// Fin de fenêtre alignée à l'heure supérieure.
  final DateTime to;

  /// Pas d'arrondi spatial appliqué.
  final double precisionDegrees;

  /// Espace de noms, pour cloisonner plusieurs usages dans un même magasin.
  final String namespace;

  /// Représentation textuelle stable, utilisable comme clé de stockage.
  String get value => '$namespace:'
      '${latitude.toStringAsFixed(3)}:'
      '${longitude.toStringAsFixed(3)}:'
      '${from.toIso8601String()}:'
      '${to.toIso8601String()}';

  static double _round(double degrees, double precision) {
    // Arrondi au multiple de `precision` le plus proche.
    final double rounded = (degrees / precision).round() * precision;
    // Neutralise les artefacts de flottants (ex. 41.85000000000001).
    return double.parse(rounded.toStringAsFixed(6));
  }

  static DateTime _floorToHour(DateTime instant) {
    final DateTime utc = instant.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day, utc.hour);
  }

  static DateTime _ceilToHour(DateTime instant) {
    final DateTime utc = instant.toUtc();
    final DateTime floored =
        DateTime.utc(utc.year, utc.month, utc.day, utc.hour);
    return floored == utc ? floored : floored.add(const Duration(hours: 1));
  }

  @override
  bool operator ==(Object other) =>
      other is WeatherCacheKey && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'WeatherCacheKey($value)';
}

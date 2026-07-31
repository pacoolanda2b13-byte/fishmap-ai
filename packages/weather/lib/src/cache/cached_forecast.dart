import 'package:meta/meta.dart';

import '../models/weather_forecast.dart';

/// Entrée de cache : une prévision, sa provenance et sa date de péremption.
@immutable
class CachedForecast {
  const CachedForecast({
    required this.forecast,
    required this.providerName,
    required this.storedAt,
    required this.expiresAt,
  });

  /// Prévision mise en cache.
  final WeatherForecast forecast;

  /// Fournisseur ayant produit la donnée, conservé pour la traçabilité.
  final String providerName;

  /// Instant d'écriture dans le cache.
  final DateTime storedAt;

  /// Instant à partir duquel l'entrée n'est plus servie.
  final DateTime expiresAt;

  /// Vrai si l'entrée est périmée à [now].
  ///
  /// La péremption est stricte : une entrée expirant exactement à [now] est
  /// considérée comme périmée, afin qu'un TTL nul ne serve jamais de donnée.
  bool isExpired(DateTime now) => !now.isBefore(expiresAt);

  /// Âge de l'entrée à [now].
  Duration ageAt(DateTime now) {
    final Duration age = now.difference(storedAt);
    return age.isNegative ? Duration.zero : age;
  }

  factory CachedForecast.fromJson(Map<String, dynamic> json) => CachedForecast(
        forecast:
            WeatherForecast.fromJson(json['forecast'] as Map<String, dynamic>),
        providerName: json['provider_name'] as String,
        storedAt: DateTime.parse(json['stored_at'] as String).toUtc(),
        expiresAt: DateTime.parse(json['expires_at'] as String).toUtc(),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'forecast': forecast.toJson(),
        'provider_name': providerName,
        'stored_at': storedAt.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
      };
}

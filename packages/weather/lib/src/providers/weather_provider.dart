import '../models/geo_point.dart';
import '../models/weather_forecast.dart';

/// Contrat d'un fournisseur de données météo/marines.
///
/// Ce package ne contient **aucun** fournisseur concret relié à une API
/// externe : il définit uniquement l'interface. Les implémentations réelles
/// (Open-Meteo, Stormglass, etc.) vivent dans leurs propres adaptateurs et
/// convertissent leurs unités natives via `WeatherUnits`, de sorte que le
/// reste de l'application reste totalement découplé du fournisseur.
abstract interface class WeatherProvider {
  /// Nom lisible du fournisseur (traçabilité, journalisation).
  String get name;

  /// Récupère une prévision couvrant l'intervalle \[from, to] pour [location].
  ///
  /// Doit lever une [WeatherProviderException] en cas d'échec récupérable.
  Future<WeatherForecast> fetchForecast(
    GeoPoint location, {
    required DateTime from,
    required DateTime to,
  });
}

/// Erreur levée par un fournisseur météo.
class WeatherProviderException implements Exception {
  const WeatherProviderException(this.message, {this.provider, this.cause});

  final String message;
  final String? provider;
  final Object? cause;

  @override
  String toString() {
    final String origin = provider == null ? '' : ' [$provider]';
    final String detail = cause == null ? '' : ' (cause: $cause)';
    return 'WeatherProviderException$origin: $message$detail';
  }
}

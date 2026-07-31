import 'package:core/core.dart';

/// Construit les URL des API Open-Meteo.
///
/// Open-Meteo expose deux services distincts :
/// - l'API **prévision** (atmosphère) : vent, rafales, direction, température
///   de l'air, pression ;
/// - l'API **marine** : hauteur, période et direction de houle, température de
///   surface de la mer.
///
/// Aucune clé d'API n'est requise pour l'usage non commercial ; aucun secret
/// n'est donc embarqué. Les hôtes restent configurables pour permettre un
/// miroir ou un environnement de test.
class OpenMeteoEndpoints {
  const OpenMeteoEndpoints({
    this.forecastHost = defaultForecastHost,
    this.marineHost = defaultMarineHost,
  });

  static const String defaultForecastHost = 'api.open-meteo.com';
  static const String defaultMarineHost = 'marine-api.open-meteo.com';

  final String forecastHost;
  final String marineHost;

  /// Variables horaires demandées à l'API prévision.
  static const List<String> forecastHourlyVariables = <String>[
    'temperature_2m',
    'pressure_msl',
    'wind_speed_10m',
    'wind_direction_10m',
    'wind_gusts_10m',
    'precipitation',
    'cloud_cover',
  ];

  /// Variables horaires demandées à l'API marine.
  static const List<String> marineHourlyVariables = <String>[
    'wave_height',
    'wave_period',
    'wave_direction',
    'sea_surface_temperature',
  ];

  /// URL de l'API prévision pour la fenêtre \[from, to].
  Uri forecast(Coordinates location, {required DateTime from, required DateTime to}) =>
      Uri.https(forecastHost, '/v1/forecast', <String, String>{
        ..._commonParameters(location, from: from, to: to),
        'hourly': forecastHourlyVariables.join(','),
        // Unités explicites : le mapper les revalide via `hourly_units`.
        'wind_speed_unit': 'kmh',
        'temperature_unit': 'celsius',
        'precipitation_unit': 'mm',
      });

  /// URL de l'API marine pour la fenêtre \[from, to].
  Uri marine(Coordinates location, {required DateTime from, required DateTime to}) =>
      Uri.https(marineHost, '/v1/marine', <String, String>{
        ..._commonParameters(location, from: from, to: to),
        'hourly': marineHourlyVariables.join(','),
      });

  Map<String, String> _commonParameters(
    Coordinates location, {
    required DateTime from,
    required DateTime to,
  }) =>
      <String, String>{
        'latitude': location.latitude.toStringAsFixed(4),
        'longitude': location.longitude.toStringAsFixed(4),
        // Open-Meteo raisonne en jours pleins : on borne par date.
        'start_date': _isoDate(from),
        'end_date': _isoDate(to),
        'timezone': 'UTC',
      };

  static String _isoDate(DateTime instant) {
    final DateTime utc = instant.toUtc();
    final String month = utc.month.toString().padLeft(2, '0');
    final String day = utc.day.toString().padLeft(2, '0');
    return '${utc.year}-$month-$day';
  }
}

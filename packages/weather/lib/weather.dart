/// Couche météo provider-agnostic de FishMap AI.
///
/// Pipeline : un [WeatherProvider] fournit un [WeatherForecast] composé de
/// [WeatherData] normalisées ; le [WeatherMapper] les transforme en
/// `FishScoreInput` consommable par le moteur FishScore.
///
/// ```dart
/// final provider = StaticWeatherProvider.synthetic(
///   location: const GeoPoint(latitude: 41.86, longitude: 9.40),
///   from: DateTime.utc(2026, 10, 15, 0),
///   to: DateTime.utc(2026, 10, 15, 23),
/// );
/// final forecast = await provider.fetchForecast(
///   const GeoPoint(latitude: 41.86, longitude: 9.40),
///   from: DateTime.utc(2026, 10, 15, 0),
///   to: DateTime.utc(2026, 10, 15, 23),
/// );
/// final input = const WeatherMapper().toFishScoreInput(
///   forecast: forecast,
///   speciesSlug: 'loup',
///   evaluatedAt: DateTime.utc(2026, 10, 15, 19),
/// );
/// ```
library;

export 'src/mapping/spot_context.dart';
export 'src/mapping/weather_mapper.dart';
export 'src/models/geo_point.dart';
export 'src/models/weather_data.dart';
export 'src/models/weather_forecast.dart';
export 'src/providers/static_weather_provider.dart';
export 'src/providers/weather_provider.dart';
export 'src/units/weather_units.dart';

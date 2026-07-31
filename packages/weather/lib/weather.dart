/// Couche météo provider-agnostic de FishMap AI.
///
/// Architecture multi-fournisseurs : le [WeatherRepository] orchestre des
/// [WeatherProvider] interchangeables (Open-Meteo, StormGlass, OpenWeather,
/// fournisseur local…) avec repli automatique, et produit des
/// [WeatherForecast] composées de [WeatherData] normalisées.
///
/// Ce package ne dépend que de `core` — jamais d'un autre package métier. La
/// conversion vers une entrée FishScore vit dans la couche de composition
/// `scoring_pipeline`.
///
/// ```dart
/// final repository = WeatherRepository(providers: <WeatherProvider>[
///   // OpenMeteoProvider(...),        // fournisseur principal
///   StaticWeatherProvider.synthetic(  // repli hors ligne
///     location: location, from: from, to: to,
///   ),
/// ]);
///
/// final result = await repository.fetchForecast(location, from: from, to: to);
/// final forecast = result.valueOrNull?.forecast;
/// ```
library;

export 'src/cache/cached_forecast.dart';
export 'src/cache/weather_cache.dart';
export 'src/cache/weather_cache_key.dart';
export 'src/cache/weather_cache_store.dart';
export 'src/models/weather_data.dart';
export 'src/models/weather_forecast.dart';
export 'src/providers/static_weather_provider.dart';
export 'src/providers/weather_provider.dart';
export 'src/repository/weather_repository.dart';

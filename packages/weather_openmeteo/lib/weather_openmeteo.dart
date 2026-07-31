/// Adaptateur Open-Meteo pour FishMap AI.
///
/// Implémente le contrat `WeatherProvider` du package `weather` :
/// `HTTP → JSON → WeatherData`, rien d'autre. Aucune logique métier, aucune
/// connaissance du FishScore.
///
/// ```dart
/// final repository = WeatherRepository(providers: <WeatherProvider>[
///   OpenMeteoProvider(),                       // fournisseur officiel
///   StaticWeatherProvider.synthetic(...),      // repli hors ligne
/// ]);
/// ```
///
/// Ajouter un autre fournisseur (StormGlass, OpenWeather) consiste à créer un
/// paquet frère implémentant la même interface : aucun code existant n'est
/// modifié.
library;

export 'src/open_meteo_endpoints.dart';
export 'src/open_meteo_mapper.dart';
export 'src/open_meteo_provider.dart';

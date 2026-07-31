import 'dart:async';
import 'dart:convert';

import 'package:core/core.dart';
import 'package:http/http.dart' as http;
import 'package:weather/weather.dart';

import 'open_meteo_endpoints.dart';
import 'open_meteo_mapper.dart';

/// Fournisseur météo Open-Meteo.
///
/// Responsabilité unique : `HTTP → JSON → WeatherData`. Aucune logique métier,
/// aucune connaissance du FishScore.
///
/// Interroge deux services :
/// - l'API prévision (vent, rafales, direction, température de l'air, pression,
///   précipitations, couverture nuageuse) ;
/// - l'API marine (hauteur, période et direction de houle, température de la
///   mer).
///
/// L'API marine ne couvre pas tous les points du globe. Lorsqu'elle échoue,
/// le fournisseur **renvoie tout de même** les données atmosphériques : une
/// série partielle reste exploitable, le moteur FishScore renormalise et
/// abaisse la confiance. En revanche, l'échec de l'API prévision est
/// bloquant.
class OpenMeteoProvider implements WeatherProvider {
  OpenMeteoProvider({
    http.Client? httpClient,
    this.endpoints = const OpenMeteoEndpoints(),
    this.mapper = const OpenMeteoMapper(),
    this.timeout = const Duration(seconds: 10),
    this.includeMarine = true,
    Logger logger = const NoopLogger(),
  })  : _http = httpClient ?? http.Client(),
        _ownsClient = httpClient == null,
        _logger = logger;

  final http.Client _http;
  final bool _ownsClient;
  final Logger _logger;

  final OpenMeteoEndpoints endpoints;
  final OpenMeteoMapper mapper;

  /// Délai maximal accordé à chaque requête.
  final Duration timeout;

  /// Interroge aussi l'API marine (houle, température de la mer).
  final bool includeMarine;

  @override
  String get name => 'open-meteo';

  @override
  Future<WeatherForecast> fetchForecast(
    Coordinates location, {
    required DateTime from,
    required DateTime to,
  }) async {
    if (to.isBefore(from)) {
      throw const WeatherProviderException(
        'Intervalle invalide : "to" précède "from"',
        provider: 'open-meteo',
      );
    }

    final Map<String, dynamic> forecastJson = await _getJson(
      endpoints.forecast(location, from: from, to: to),
      label: 'prévision',
    );

    Map<String, dynamic>? marineJson;
    if (includeMarine) {
      try {
        marineJson = await _getJson(
          endpoints.marine(location, from: from, to: to),
          label: 'marine',
        );
      } on WeatherProviderException catch (e) {
        // Dégradation gracieuse : la houle est optionnelle.
        _logger.warning(
          'API marine indisponible, poursuite sans données de houle',
          error: e.message,
        );
      }
    }

    final List<WeatherData> samples;
    try {
      samples = mapper.toWeatherData(
        forecastJson: forecastJson,
        marineJson: marineJson,
        source: name,
      );
    } on FormatException catch (e) {
      throw WeatherProviderException(
        'Réponse Open-Meteo inexploitable : ${e.message}',
        provider: name,
        cause: e,
      );
    }

    // Le fournisseur borne à la fenêtre demandée : l'API raisonne en jours
    // pleins et renvoie donc davantage que l'intervalle utile.
    final List<WeatherData> inRange = samples
        .where((WeatherData s) =>
            !s.observedAt.isBefore(from) && !s.observedAt.isAfter(to))
        .toList(growable: false);

    return WeatherForecast(location: location, samples: inRange);
  }

  /// Exécute une requête GET et décode la réponse JSON.
  ///
  /// Traduit toute défaillance (réseau, délai, statut HTTP, JSON invalide,
  /// erreur applicative Open-Meteo) en [WeatherProviderException].
  Future<Map<String, dynamic>> _getJson(Uri uri,
      {required String label}) async {
    final http.Response response;
    try {
      response = await _http.get(uri).timeout(timeout);
    } on TimeoutException catch (e) {
      throw WeatherProviderException(
        'Délai dépassé (${timeout.inSeconds} s) sur l\'API $label',
        provider: name,
        cause: e,
      );
    } catch (e) {
      throw WeatherProviderException(
        'Échec réseau sur l\'API $label',
        provider: name,
        cause: e,
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException catch (e) {
      throw WeatherProviderException(
        'Réponse non JSON de l\'API $label',
        provider: name,
        cause: e,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw WeatherProviderException(
        'Structure inattendue renvoyée par l\'API $label',
        provider: name,
      );
    }

    // Open-Meteo signale ses erreurs applicatives dans le corps de la réponse.
    if (decoded['error'] == true) {
      final Object? reason = decoded['reason'];
      throw WeatherProviderException(
        'API $label a rejeté la requête : ${reason ?? 'raison inconnue'}',
        provider: name,
      );
    }

    if (response.statusCode != 200) {
      throw WeatherProviderException(
        'API $label a répondu ${response.statusCode}',
        provider: name,
      );
    }

    return decoded;
  }

  /// Libère le client HTTP si le fournisseur en est propriétaire.
  ///
  /// À appeler lorsqu'un client n'a pas été injecté, afin de fermer les
  /// connexions persistantes.
  void close() {
    if (_ownsClient) _http.close();
  }
}

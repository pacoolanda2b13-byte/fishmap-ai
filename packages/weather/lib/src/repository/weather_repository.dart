import 'package:core/core.dart';

import '../models/weather_forecast.dart';
import '../providers/weather_provider.dart';

/// Prévision accompagnée du fournisseur qui l'a produite.
class ProviderForecast {
  const ProviderForecast({required this.providerName, required this.forecast});

  /// Nom du fournisseur à l'origine de la prévision.
  final String providerName;

  /// Prévision normalisée.
  final WeatherForecast forecast;
}

/// Orchestre plusieurs fournisseurs météo interchangeables.
///
/// Le dépôt est la seule porte d'entrée météo de l'application : il choisit le
/// meilleur fournisseur disponible et masque les pannes individuelles.
///
/// Capacités :
/// - **repli automatique** : les fournisseurs sont essayés dans l'ordre
///   jusqu'au premier succès ;
/// - **comparaison** : [fetchFromAll] interroge tous les fournisseurs pour
///   confronter leurs réponses ;
/// - **hors ligne** : un fournisseur local (ex. `StaticWeatherProvider`) placé
///   en dernier garantit une réponse dégradée mais exploitable.
///
/// Les échecs sont retournés en [Result] plutôt que levés : l'appelant est
/// obligé de traiter le cas d'indisponibilité.
class WeatherRepository {
  WeatherRepository({
    required List<WeatherProvider> providers,
    Logger logger = const NoopLogger(),
  })  : assert(providers.isNotEmpty, 'au moins un fournisseur est requis'),
        _providers = List<WeatherProvider>.unmodifiable(providers),
        _logger = logger;

  final List<WeatherProvider> _providers;
  final Logger _logger;

  /// Fournisseurs configurés, par ordre de préférence.
  List<WeatherProvider> get providers => _providers;

  /// Récupère une prévision auprès du premier fournisseur disponible.
  ///
  /// Chaque échec est journalisé puis le fournisseur suivant est essayé. Si
  /// tous échouent, renvoie un [CompositeFailure] regroupant les causes.
  Future<Result<ProviderForecast>> fetchForecast(
    Coordinates location, {
    required DateTime from,
    required DateTime to,
  }) async {
    final List<Failure> failures = <Failure>[];

    for (final WeatherProvider provider in _providers) {
      final Result<WeatherForecast> attempt =
          await _tryProvider(provider, location, from: from, to: to);

      final WeatherForecast? forecast = attempt.valueOrNull;
      if (forecast != null) {
        if (forecast.isEmpty) {
          // Une réponse vide n'est pas exploitable : on continue.
          _logger.warning(
              'Fournisseur "${provider.name}" a renvoyé une série vide');
          failures.add(
              UnavailableFailure('Série vide renvoyée par "${provider.name}"'));
          continue;
        }
        _logger.info('Prévision fournie par "${provider.name}"');
        return Result<ProviderForecast>.success(
          ProviderForecast(providerName: provider.name, forecast: forecast),
        );
      }

      final Failure failure = attempt.failureOrNull!;
      _logger.warning(
        'Fournisseur "${provider.name}" indisponible : ${failure.code}',
        error: failure.message,
      );
      failures.add(failure);
    }

    return Result<ProviderForecast>.failure(
      CompositeFailure('Aucun fournisseur météo disponible', failures),
    );
  }

  /// Interroge **tous** les fournisseurs et renvoie ceux qui ont répondu.
  ///
  /// Sert à comparer les fournisseurs entre eux et, à terme, à fusionner
  /// plusieurs sources. La liste est vide si aucun n'a répondu.
  Future<List<ProviderForecast>> fetchFromAll(
    Coordinates location, {
    required DateTime from,
    required DateTime to,
  }) async {
    final List<ProviderForecast> results = <ProviderForecast>[];

    for (final WeatherProvider provider in _providers) {
      final Result<WeatherForecast> attempt =
          await _tryProvider(provider, location, from: from, to: to);
      final WeatherForecast? forecast = attempt.valueOrNull;
      if (forecast != null && forecast.isNotEmpty) {
        results.add(
          ProviderForecast(providerName: provider.name, forecast: forecast),
        );
      }
    }

    return results;
  }

  /// Isole un fournisseur : toute exception devient un [Failure] typé.
  Future<Result<WeatherForecast>> _tryProvider(
    WeatherProvider provider,
    Coordinates location, {
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final WeatherForecast forecast =
          await provider.fetchForecast(location, from: from, to: to);
      return Result<WeatherForecast>.success(forecast);
    } on WeatherProviderException catch (e) {
      return Result<WeatherForecast>.failure(
        UnavailableFailure(e.message, cause: e.cause),
      );
    } catch (e) {
      return Result<WeatherForecast>.failure(
        UnexpectedFailure('Échec du fournisseur "${provider.name}"', cause: e),
      );
    }
  }
}

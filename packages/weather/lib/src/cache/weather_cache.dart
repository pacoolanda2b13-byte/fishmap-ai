import 'package:core/core.dart';

import '../models/weather_forecast.dart';
import 'cached_forecast.dart';
import 'weather_cache_key.dart';
import 'weather_cache_store.dart';

/// Cache de prévisions météo.
///
/// Évite qu'une requête utilisateur déclenche systématiquement un appel au
/// fournisseur. Le cache est **totalement indépendant du fournisseur** : il ne
/// connaît ni Open-Meteo, ni aucun adaptateur ; il manipule uniquement des
/// [WeatherForecast] et délègue la persistance à un [WeatherCacheStore].
///
/// L'horloge est injectée via [TimeProvider], ce qui rend l'expiration
/// testable de façon déterministe.
class WeatherCache {
  WeatherCache({
    WeatherCacheStore? store,
    this.ttl = defaultTtl,
    TimeProvider timeProvider = const SystemTimeProvider(),
    this.precisionDegrees = WeatherCacheKey.defaultPrecisionDegrees,
    Logger logger = const NoopLogger(),
  })  : assert(ttl > Duration.zero, 'le TTL doit être positif'),
        _store = store ?? InMemoryWeatherCacheStore(),
        _time = timeProvider,
        _logger = logger;

  /// Durée de validité par défaut.
  ///
  /// Une heure correspond au pas d'échantillonnage des API météo : au-delà,
  /// une nouvelle donnée est réellement disponible.
  static const Duration defaultTtl = Duration(hours: 1);

  final WeatherCacheStore _store;
  final TimeProvider _time;
  final Logger _logger;

  /// Durée de validité des entrées.
  final Duration ttl;

  /// Précision de l'arrondi spatial des clés.
  final double precisionDegrees;

  /// Instant courant selon l'horloge injectée.
  ///
  /// Exposé pour que les appelants (le dépôt, notamment) datent leurs calculs
  /// sur la même horloge que l'expiration, et restent donc testables.
  DateTime get now => _time.nowUtc();

  /// Construit la clé correspondant à une demande.
  WeatherCacheKey keyFor(
    Coordinates location, {
    required DateTime from,
    required DateTime to,
  }) =>
      WeatherCacheKey(
        location: location,
        from: from,
        to: to,
        precisionDegrees: precisionDegrees,
      );

  /// Lit une prévision encore valide, ou `null` en cas d'absence ou de
  /// péremption.
  ///
  /// Une entrée périmée est supprimée au passage : le cache se nettoie de
  /// lui-même sans tâche de maintenance dédiée.
  /// Une défaillance du magasin est traitée comme une absence : le cache
  /// accélère les réponses, il ne conditionne pas leur production.
  Future<CachedForecast?> read(
    Coordinates location, {
    required DateTime from,
    required DateTime to,
  }) async {
    final WeatherCacheKey key = keyFor(location, from: from, to: to);

    final CachedForecast? entry;
    try {
      entry = await _store.read(key.value);
    } catch (e) {
      _logger.warning('Cache météo illisible, traité comme absent', error: e);
      return null;
    }

    if (entry == null) {
      _logger.debug('Cache météo : absent (${key.value})');
      return null;
    }

    if (entry.isExpired(_time.nowUtc())) {
      _logger.debug('Cache météo : périmé (${key.value})');
      try {
        await _store.delete(key.value);
      } catch (e) {
        _logger.warning('Éviction du cache impossible', error: e);
      }
      return null;
    }

    _logger.debug('Cache météo : servi (${key.value})');
    return entry;
  }

  /// Enregistre une prévision et renvoie l'entrée écrite.
  Future<CachedForecast> write(
    Coordinates location, {
    required DateTime from,
    required DateTime to,
    required WeatherForecast forecast,
    required String providerName,
  }) async {
    final DateTime now = _time.nowUtc();
    final CachedForecast entry = CachedForecast(
      forecast: forecast,
      providerName: providerName,
      storedAt: now,
      expiresAt: now.add(ttl),
    );
    final WeatherCacheKey key = keyFor(location, from: from, to: to);
    try {
      await _store.write(key.value, entry);
      _logger.debug('Cache météo : écrit (${key.value})');
    } catch (e) {
      // Ne pas faire échouer une réponse valide parce que le cache est en
      // panne : la donnée sera simplement recalculée au prochain appel.
      _logger.warning('Écriture du cache impossible', error: e);
    }
    return entry;
  }

  /// Invalide l'entrée correspondant à une demande précise.
  Future<void> invalidate(
    Coordinates location, {
    required DateTime from,
    required DateTime to,
  }) async {
    final WeatherCacheKey key = keyFor(location, from: from, to: to);
    await _store.delete(key.value);
    _logger.debug('Cache météo : invalidé (${key.value})');
  }

  /// Vide entièrement le cache.
  Future<void> invalidateAll() async {
    await _store.clear();
    _logger.debug('Cache météo : purgé');
  }
}

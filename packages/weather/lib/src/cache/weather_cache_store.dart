import 'dart:convert';

import 'cached_forecast.dart';

/// Magasin de persistance du cache météo.
///
/// Le magasin ne connaît **ni** les fournisseurs météo **ni** la politique
/// d'expiration : il stocke et restitue des entrées sérialisables. Les
/// implémentations réelles peuvent être en mémoire, sur disque, dans
/// PostgreSQL (table `weather_cache`) ou dans un cache distribué.
abstract interface class WeatherCacheStore {
  /// Lit l'entrée associée à [key], ou `null` si absente.
  Future<CachedForecast?> read(String key);

  /// Écrit ou remplace l'entrée associée à [key].
  Future<void> write(String key, CachedForecast entry);

  /// Supprime l'entrée associée à [key].
  Future<void> delete(String key);

  /// Vide entièrement le magasin.
  Future<void> clear();
}

/// Magasin en mémoire.
///
/// Convient au développement, aux tests et au cache de session côté mobile.
/// Une capacité maximale évite une croissance non bornée : au-delà, l'entrée
/// la plus anciennement écrite est évincée.
class InMemoryWeatherCacheStore implements WeatherCacheStore {
  InMemoryWeatherCacheStore({this.maxEntries = 256})
      : assert(maxEntries > 0, 'la capacité doit être positive');

  /// Nombre maximal d'entrées conservées.
  final int maxEntries;

  final Map<String, CachedForecast> _entries = <String, CachedForecast>{};

  /// Nombre d'entrées actuellement stockées.
  int get length => _entries.length;

  @override
  Future<CachedForecast?> read(String key) async => _entries[key];

  @override
  Future<void> write(String key, CachedForecast entry) async {
    _entries[key] = entry;
    while (_entries.length > maxEntries) {
      // Éviction de la plus ancienne écriture.
      String? oldestKey;
      DateTime? oldestAt;
      for (final MapEntry<String, CachedForecast> e in _entries.entries) {
        if (oldestAt == null || e.value.storedAt.isBefore(oldestAt)) {
          oldestAt = e.value.storedAt;
          oldestKey = e.key;
        }
      }
      if (oldestKey == null) break;
      _entries.remove(oldestKey);
    }
  }

  @override
  Future<void> delete(String key) async => _entries.remove(key);

  @override
  Future<void> clear() async => _entries.clear();
}

/// Magasin délégant la persistance à des fonctions de lecture/écriture de
/// chaînes JSON.
///
/// Permet de brancher n'importe quel support (fichier, `SharedPreferences`,
/// table PostgreSQL, KV distant) sans réimplémenter la sérialisation. C'est
/// le point d'extension utilisé côté serveur.
class SerializedWeatherCacheStore implements WeatherCacheStore {
  const SerializedWeatherCacheStore({
    required Future<String?> Function(String key) readJson,
    required Future<void> Function(String key, String json) writeJson,
    required Future<void> Function(String key) deleteKey,
    Future<void> Function()? clearAll,
  })  : _readJson = readJson,
        _writeJson = writeJson,
        _deleteKey = deleteKey,
        _clearAll = clearAll;

  final Future<String?> Function(String key) _readJson;
  final Future<void> Function(String key, String json) _writeJson;
  final Future<void> Function(String key) _deleteKey;
  final Future<void> Function()? _clearAll;

  @override
  Future<CachedForecast?> read(String key) async {
    final String? raw = await _readJson(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return CachedForecast.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } on FormatException {
      // Une entrée corrompue est traitée comme absente plutôt que fatale.
      await _deleteKey(key);
      return null;
    }
  }

  @override
  Future<void> write(String key, CachedForecast entry) =>
      _writeJson(key, jsonEncode(entry.toJson()));

  @override
  Future<void> delete(String key) => _deleteKey(key);

  @override
  Future<void> clear() async => _clearAll?.call();
}

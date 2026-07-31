import 'dart:convert';

import 'package:core/core.dart';
import 'package:test/test.dart';
import 'package:weather/weather.dart';

const Coordinates corse = Coordinates(latitude: 41.86, longitude: 9.40);
final DateTime from = DateTime.utc(2026, 10, 15, 16);
final DateTime to = DateTime.utc(2026, 10, 15, 21);

WeatherForecast forecastOf({double windSpeedKmh = 15}) => WeatherForecast(
      location: corse,
      samples: <WeatherData>[
        WeatherData(
          observedAt: DateTime.utc(2026, 10, 15, 19),
          source: 'test',
          windSpeedKmh: windSpeedKmh,
          pressureHpa: 1013,
        ),
      ],
    );

void main() {
  group('WeatherCacheKey', () {
    test('arrondit les coordonnées proches sur la même clé', () {
      final WeatherCacheKey a = WeatherCacheKey(
        location: const Coordinates(latitude: 41.861, longitude: 9.401),
        from: from,
        to: to,
      );
      final WeatherCacheKey b = WeatherCacheKey(
        location: const Coordinates(latitude: 41.874, longitude: 9.399),
        from: from,
        to: to,
      );
      expect(a, b, reason: 'moins de ~1 km d\'écart : même entrée de cache');
    });

    test('distingue des points réellement éloignés', () {
      final WeatherCacheKey solenzara = WeatherCacheKey(
        location: const Coordinates(latitude: 41.86, longitude: 9.40),
        from: from,
        to: to,
      );
      final WeatherCacheKey aleria = WeatherCacheKey(
        location: const Coordinates(latitude: 42.10, longitude: 9.51),
        from: from,
        to: to,
      );
      expect(solenzara, isNot(aleria));
    });

    test('aligne la fenêtre sur des heures pleines', () {
      final WeatherCacheKey key = WeatherCacheKey(
        location: corse,
        from: DateTime.utc(2026, 10, 15, 16, 42),
        to: DateTime.utc(2026, 10, 15, 20, 5),
      );
      expect(key.from, DateTime.utc(2026, 10, 15, 16));
      expect(key.to, DateTime.utc(2026, 10, 15, 21));
    });

    test('ne fait référence à aucun fournisseur', () {
      final WeatherCacheKey key =
          WeatherCacheKey(location: corse, from: from, to: to);
      expect(key.value.toLowerCase(), isNot(contains('meteo')));
      expect(key.value.toLowerCase(), isNot(contains('provider')));
    });
  });

  group('WeatherCache — lecture et écriture', () {
    test('cache miss sur un cache vide', () async {
      final WeatherCache cache = WeatherCache();
      expect(await cache.read(corse, from: from, to: to), isNull);
    });

    test('cache hit après écriture', () async {
      final WeatherCache cache = WeatherCache();
      await cache.write(
        corse,
        from: from,
        to: to,
        forecast: forecastOf(windSpeedKmh: 22),
        providerName: 'open-meteo',
      );

      final CachedForecast? entry = await cache.read(corse, from: from, to: to);
      expect(entry, isNotNull);
      expect(entry!.providerName, 'open-meteo');
      expect(entry.forecast.samples.single.windSpeedKmh, 22);
    });

    test('une position voisine profite de la même entrée', () async {
      final WeatherCache cache = WeatherCache();
      await cache.write(
        corse,
        from: from,
        to: to,
        forecast: forecastOf(),
        providerName: 'open-meteo',
      );

      const Coordinates nearby =
          Coordinates(latitude: 41.868, longitude: 9.404);
      expect(await cache.read(nearby, from: from, to: to), isNotNull);
    });
  });

  group('WeatherCache — expiration', () {
    test('sert l\'entrée tant que le TTL n\'est pas écoulé', () async {
      final FixedTimeProvider clock =
          FixedTimeProvider(DateTime.utc(2026, 10, 15, 12));
      final WeatherCache cache = WeatherCache(
        ttl: const Duration(hours: 1),
        timeProvider: clock,
      );

      await cache.write(
        corse,
        from: from,
        to: to,
        forecast: forecastOf(),
        providerName: 'open-meteo',
      );

      clock.advance(const Duration(minutes: 59));
      expect(await cache.read(corse, from: from, to: to), isNotNull);
    });

    test('ne sert plus l\'entrée une fois le TTL dépassé', () async {
      final FixedTimeProvider clock =
          FixedTimeProvider(DateTime.utc(2026, 10, 15, 12));
      final WeatherCache cache = WeatherCache(
        ttl: const Duration(hours: 1),
        timeProvider: clock,
      );

      await cache.write(
        corse,
        from: from,
        to: to,
        forecast: forecastOf(),
        providerName: 'open-meteo',
      );

      clock.advance(const Duration(hours: 1, seconds: 1));
      expect(await cache.read(corse, from: from, to: to), isNull);
    });

    test('l\'expiration est stricte à l\'instant exact', () async {
      final FixedTimeProvider clock =
          FixedTimeProvider(DateTime.utc(2026, 10, 15, 12));
      final WeatherCache cache =
          WeatherCache(ttl: const Duration(hours: 1), timeProvider: clock);

      await cache.write(
        corse,
        from: from,
        to: to,
        forecast: forecastOf(),
        providerName: 'open-meteo',
      );

      clock.advance(const Duration(hours: 1));
      expect(await cache.read(corse, from: from, to: to), isNull);
    });

    test('une entrée périmée est supprimée du magasin', () async {
      final FixedTimeProvider clock =
          FixedTimeProvider(DateTime.utc(2026, 10, 15, 12));
      final InMemoryWeatherCacheStore store = InMemoryWeatherCacheStore();
      final WeatherCache cache = WeatherCache(
        store: store,
        ttl: const Duration(minutes: 30),
        timeProvider: clock,
      );

      await cache.write(
        corse,
        from: from,
        to: to,
        forecast: forecastOf(),
        providerName: 'open-meteo',
      );
      expect(store.length, 1);

      clock.advance(const Duration(hours: 2));
      await cache.read(corse, from: from, to: to);
      expect(store.length, 0, reason: 'le cache se nettoie tout seul');
    });

    test('l\'âge de l\'entrée est exposé', () async {
      final FixedTimeProvider clock =
          FixedTimeProvider(DateTime.utc(2026, 10, 15, 12));
      final WeatherCache cache = WeatherCache(timeProvider: clock);

      await cache.write(
        corse,
        from: from,
        to: to,
        forecast: forecastOf(),
        providerName: 'open-meteo',
      );

      clock.advance(const Duration(minutes: 20));
      final CachedForecast entry =
          (await cache.read(corse, from: from, to: to))!;
      expect(entry.ageAt(cache.now), const Duration(minutes: 20));
    });
  });

  group('WeatherCache — invalidation', () {
    test('invalide une entrée précise', () async {
      final WeatherCache cache = WeatherCache();
      await cache.write(
        corse,
        from: from,
        to: to,
        forecast: forecastOf(),
        providerName: 'open-meteo',
      );

      await cache.invalidate(corse, from: from, to: to);
      expect(await cache.read(corse, from: from, to: to), isNull);
    });

    test('purge complète', () async {
      final InMemoryWeatherCacheStore store = InMemoryWeatherCacheStore();
      final WeatherCache cache = WeatherCache(store: store);

      await cache.write(
        corse,
        from: from,
        to: to,
        forecast: forecastOf(),
        providerName: 'open-meteo',
      );
      await cache.write(
        const Coordinates(latitude: 42.10, longitude: 9.51),
        from: from,
        to: to,
        forecast: forecastOf(),
        providerName: 'open-meteo',
      );
      expect(store.length, 2);

      await cache.invalidateAll();
      expect(store.length, 0);
    });
  });

  group('sérialisation', () {
    test('CachedForecast survit à un aller-retour JSON', () {
      final CachedForecast entry = CachedForecast(
        forecast: forecastOf(windSpeedKmh: 18.5),
        providerName: 'open-meteo',
        storedAt: DateTime.utc(2026, 10, 15, 12),
        expiresAt: DateTime.utc(2026, 10, 15, 13),
      );

      final CachedForecast back = CachedForecast.fromJson(
          jsonDecode(jsonEncode(entry.toJson())) as Map<String, dynamic>);

      expect(back.providerName, 'open-meteo');
      expect(back.storedAt, entry.storedAt);
      expect(back.expiresAt, entry.expiresAt);
      expect(back.forecast.samples.single.windSpeedKmh, 18.5);
      expect(back.forecast.location, corse);
    });

    test('SerializedWeatherCacheStore persiste via des chaînes JSON', () async {
      final Map<String, String> backing = <String, String>{};
      final WeatherCache cache = WeatherCache(
        store: SerializedWeatherCacheStore(
          readJson: (String k) async => backing[k],
          writeJson: (String k, String json) async => backing[k] = json,
          deleteKey: (String k) async => backing.remove(k),
          clearAll: () async => backing.clear(),
        ),
      );

      await cache.write(
        corse,
        from: from,
        to: to,
        forecast: forecastOf(windSpeedKmh: 31),
        providerName: 'open-meteo',
      );

      expect(backing, hasLength(1));
      // Le support ne reçoit que du JSON : il ignore tout des modèles Dart.
      expect(backing.values.single, contains('"provider_name":"open-meteo"'));

      final CachedForecast? entry = await cache.read(corse, from: from, to: to);
      expect(entry!.forecast.samples.single.windSpeedKmh, 31);
    });

    test('une entrée corrompue est traitée comme absente', () async {
      final Map<String, String> backing = <String, String>{};
      final WeatherCache cache = WeatherCache(
        store: SerializedWeatherCacheStore(
          readJson: (String k) async => backing[k],
          writeJson: (String k, String json) async => backing[k] = json,
          deleteKey: (String k) async => backing.remove(k),
        ),
      );

      final WeatherCacheKey key = cache.keyFor(corse, from: from, to: to);
      backing[key.value] = '{ ceci n\'est pas du JSON';

      expect(await cache.read(corse, from: from, to: to), isNull);
      expect(backing, isEmpty, reason: 'l\'entrée corrompue est supprimée');
    });
  });

  group('InMemoryWeatherCacheStore', () {
    test('évince la plus ancienne entrée au-delà de la capacité', () async {
      final FixedTimeProvider clock =
          FixedTimeProvider(DateTime.utc(2026, 10, 15, 12));
      final InMemoryWeatherCacheStore store =
          InMemoryWeatherCacheStore(maxEntries: 2);
      final WeatherCache cache =
          WeatherCache(store: store, timeProvider: clock);

      for (int i = 0; i < 3; i++) {
        await cache.write(
          Coordinates(latitude: 41.0 + i, longitude: 9.40),
          from: from,
          to: to,
          forecast: forecastOf(),
          providerName: 'open-meteo',
        );
        clock.advance(const Duration(seconds: 1));
      }

      expect(store.length, 2);
      // La première position écrite a été évincée.
      expect(
        await cache.read(
          const Coordinates(latitude: 41.0, longitude: 9.40),
          from: from,
          to: to,
        ),
        isNull,
      );
    });
  });
}

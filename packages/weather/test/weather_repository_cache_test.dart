import 'package:core/core.dart';
import 'package:test/test.dart';
import 'package:weather/weather.dart';

/// Fournisseur comptant ses appels, pour prouver que le cache les évite.
class CountingProvider implements WeatherProvider {
  CountingProvider({this.name = 'counting', this.windSpeedKmh = 15});

  @override
  final String name;

  final double windSpeedKmh;

  int callCount = 0;

  @override
  Future<WeatherForecast> fetchForecast(
    Coordinates location, {
    required DateTime from,
    required DateTime to,
  }) async {
    callCount++;
    return WeatherForecast(
      location: location,
      samples: <WeatherData>[
        WeatherData(
          observedAt: from,
          source: name,
          windSpeedKmh: windSpeedKmh,
          pressureHpa: 1013,
        ),
      ],
    );
  }
}

/// Fournisseur toujours en panne.
class FailingProvider implements WeatherProvider {
  FailingProvider({this.name = 'failing'});

  @override
  final String name;

  int callCount = 0;

  @override
  Future<WeatherForecast> fetchForecast(
    Coordinates location, {
    required DateTime from,
    required DateTime to,
  }) async {
    callCount++;
    throw WeatherProviderException('hors service', provider: name);
  }
}

void main() {
  const Coordinates corse = Coordinates(latitude: 41.86, longitude: 9.40);
  final DateTime from = DateTime.utc(2026, 10, 15, 16);
  final DateTime to = DateTime.utc(2026, 10, 15, 21);

  group('cache miss', () {
    test('appelle le fournisseur puis enregistre la réponse', () async {
      final CountingProvider provider = CountingProvider(name: 'open-meteo');
      final WeatherCache cache = WeatherCache();
      final WeatherRepository repository = WeatherRepository(
        providers: <WeatherProvider>[provider],
        cache: cache,
      );

      final Result<ProviderForecast> result =
          await repository.fetchForecast(corse, from: from, to: to);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.fromCache, isFalse);
      expect(provider.callCount, 1);
      // La réponse est désormais en cache.
      expect(await cache.read(corse, from: from, to: to), isNotNull);
    });
  });

  group('cache hit', () {
    test('un second appel n\'atteint pas le fournisseur', () async {
      final CountingProvider provider = CountingProvider(name: 'open-meteo');
      final WeatherRepository repository = WeatherRepository(
        providers: <WeatherProvider>[provider],
        cache: WeatherCache(),
      );

      await repository.fetchForecast(corse, from: from, to: to);
      final Result<ProviderForecast> second =
          await repository.fetchForecast(corse, from: from, to: to);

      expect(provider.callCount, 1, reason: 'Open-Meteo n\'est plus appelé');
      expect(second.valueOrNull!.fromCache, isTrue);
      expect(second.valueOrNull!.providerName, 'open-meteo');
    });

    test('la provenance reste le fournisseur d\'origine', () async {
      final WeatherRepository repository = WeatherRepository(
        providers: <WeatherProvider>[CountingProvider(name: 'open-meteo')],
        cache: WeatherCache(),
      );

      await repository.fetchForecast(corse, from: from, to: to);
      final Result<ProviderForecast> cached =
          await repository.fetchForecast(corse, from: from, to: to);

      expect(cached.valueOrNull!.providerName, 'open-meteo');
      expect(cached.valueOrNull!.cacheAge, isNotNull);
    });

    test('une position voisine profite du cache', () async {
      final CountingProvider provider = CountingProvider();
      final WeatherRepository repository = WeatherRepository(
        providers: <WeatherProvider>[provider],
        cache: WeatherCache(),
      );

      await repository.fetchForecast(corse, from: from, to: to);
      await repository.fetchForecast(
        const Coordinates(latitude: 41.867, longitude: 9.403),
        from: from,
        to: to,
      );

      expect(provider.callCount, 1);
    });

    test('les données servies sont identiques à celles enregistrées', () async {
      final WeatherRepository repository = WeatherRepository(
        providers: <WeatherProvider>[CountingProvider(windSpeedKmh: 27.5)],
        cache: WeatherCache(),
      );

      final Result<ProviderForecast> fresh =
          await repository.fetchForecast(corse, from: from, to: to);
      final Result<ProviderForecast> cached =
          await repository.fetchForecast(corse, from: from, to: to);

      expect(
        cached.valueOrNull!.forecast.samples.single.windSpeedKmh,
        fresh.valueOrNull!.forecast.samples.single.windSpeedKmh,
      );
    });
  });

  group('expiration', () {
    test('le fournisseur est rappelé une fois le TTL écoulé', () async {
      final FixedTimeProvider clock =
          FixedTimeProvider(DateTime.utc(2026, 10, 15, 12));
      final CountingProvider provider = CountingProvider();
      final WeatherRepository repository = WeatherRepository(
        providers: <WeatherProvider>[provider],
        cache: WeatherCache(
          ttl: const Duration(hours: 1),
          timeProvider: clock,
        ),
      );

      await repository.fetchForecast(corse, from: from, to: to);
      clock.advance(const Duration(minutes: 30));
      await repository.fetchForecast(corse, from: from, to: to);
      expect(provider.callCount, 1, reason: 'encore valide');

      clock.advance(const Duration(hours: 1));
      await repository.fetchForecast(corse, from: from, to: to);
      expect(provider.callCount, 2, reason: 'périmé, rafraîchi');
    });
  });

  group('invalidation', () {
    test('après invalidation, le fournisseur est rappelé', () async {
      final CountingProvider provider = CountingProvider();
      final WeatherCache cache = WeatherCache();
      final WeatherRepository repository = WeatherRepository(
        providers: <WeatherProvider>[provider],
        cache: cache,
      );

      await repository.fetchForecast(corse, from: from, to: to);
      await cache.invalidate(corse, from: from, to: to);
      await repository.fetchForecast(corse, from: from, to: to);

      expect(provider.callCount, 2);
    });

    test('forceRefresh ignore le cache et le met à jour', () async {
      final CountingProvider provider = CountingProvider();
      final WeatherRepository repository = WeatherRepository(
        providers: <WeatherProvider>[provider],
        cache: WeatherCache(),
      );

      await repository.fetchForecast(corse, from: from, to: to);
      final Result<ProviderForecast> refreshed = await repository.fetchForecast(
        corse,
        from: from,
        to: to,
        forceRefresh: true,
      );

      expect(provider.callCount, 2);
      expect(refreshed.valueOrNull!.fromCache, isFalse);

      // L'entrée rafraîchie est de nouveau servie depuis le cache.
      final Result<ProviderForecast> next =
          await repository.fetchForecast(corse, from: from, to: to);
      expect(provider.callCount, 2);
      expect(next.valueOrNull!.fromCache, isTrue);
    });
  });

  group('interaction avec le repli', () {
    test('seule la réponse réellement servie est mise en cache', () async {
      final FailingProvider primary = FailingProvider(name: 'open-meteo');
      final CountingProvider backup = CountingProvider(name: 'local');
      final WeatherRepository repository = WeatherRepository(
        providers: <WeatherProvider>[primary, backup],
        cache: WeatherCache(),
      );

      final Result<ProviderForecast> first =
          await repository.fetchForecast(corse, from: from, to: to);
      expect(first.valueOrNull!.providerName, 'local');

      final Result<ProviderForecast> second =
          await repository.fetchForecast(corse, from: from, to: to);
      expect(second.valueOrNull!.fromCache, isTrue);
      expect(second.valueOrNull!.providerName, 'local');
      // Le fournisseur principal n'est pas retenté tant que le cache est bon.
      expect(primary.callCount, 1);
    });

    test('un échec total n\'écrit rien dans le cache', () async {
      final InMemoryWeatherCacheStore store = InMemoryWeatherCacheStore();
      final WeatherRepository repository = WeatherRepository(
        providers: <WeatherProvider>[FailingProvider()],
        cache: WeatherCache(store: store),
      );

      final Result<ProviderForecast> result =
          await repository.fetchForecast(corse, from: from, to: to);

      expect(result.isFailure, isTrue);
      expect(store.length, 0);
    });
  });

  group('sans cache', () {
    test('le dépôt fonctionne à l\'identique', () async {
      final CountingProvider provider = CountingProvider();
      final WeatherRepository repository =
          WeatherRepository(providers: <WeatherProvider>[provider]);

      await repository.fetchForecast(corse, from: from, to: to);
      final Result<ProviderForecast> second =
          await repository.fetchForecast(corse, from: from, to: to);

      expect(repository.cache, isNull);
      expect(provider.callCount, 2);
      expect(second.valueOrNull!.fromCache, isFalse);
    });
  });
}

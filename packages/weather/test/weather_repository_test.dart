import 'package:core/core.dart';
import 'package:test/test.dart';
import 'package:weather/weather.dart';

/// Fournisseur qui échoue systématiquement, pour valider le repli.
class FailingProvider implements WeatherProvider {
  FailingProvider(this.name, {this.throwGeneric = false});

  @override
  final String name;

  /// Lève une erreur non typée, pour vérifier l'isolation du dépôt.
  final bool throwGeneric;

  int callCount = 0;

  @override
  Future<WeatherForecast> fetchForecast(
    Coordinates location, {
    required DateTime from,
    required DateTime to,
  }) async {
    callCount++;
    if (throwGeneric) throw StateError('panne interne');
    throw WeatherProviderException('API injoignable', provider: name);
  }
}

/// Fournisseur renvoyant une série vide (réponse inexploitable).
class EmptyProvider implements WeatherProvider {
  EmptyProvider(this.name);

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
    return WeatherForecast(location: location, samples: const <WeatherData>[]);
  }
}

/// Fournisseur simple renvoyant un échantillon identifiable.
class WorkingProvider implements WeatherProvider {
  WorkingProvider(this.name, {this.windSpeedKmh = 15});

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

void main() {
  const Coordinates corse = Coordinates(latitude: 41.86, longitude: 9.40);
  final DateTime from = DateTime.utc(2026, 10, 15, 6);
  final DateTime to = DateTime.utc(2026, 10, 15, 20);

  group('WeatherRepository — repli automatique', () {
    test('utilise le premier fournisseur qui répond', () async {
      final WorkingProvider primary = WorkingProvider('open-meteo');
      final WorkingProvider backup = WorkingProvider('stormglass');
      final WeatherRepository repo =
          WeatherRepository(providers: <WeatherProvider>[primary, backup]);

      final Result<ProviderForecast> result =
          await repo.fetchForecast(corse, from: from, to: to);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.providerName, 'open-meteo');
      // Le fournisseur de repli n'est pas sollicité inutilement.
      expect(backup.callCount, 0);
    });

    test('bascule sur le suivant quand le principal échoue', () async {
      final FailingProvider primary = FailingProvider('open-meteo');
      final WorkingProvider backup = WorkingProvider('stormglass');
      final WeatherRepository repo =
          WeatherRepository(providers: <WeatherProvider>[primary, backup]);

      final Result<ProviderForecast> result =
          await repo.fetchForecast(corse, from: from, to: to);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.providerName, 'stormglass');
      expect(primary.callCount, 1);
      expect(backup.callCount, 1);
    });

    test('isole une exception non typée d\'un fournisseur', () async {
      final FailingProvider broken =
          FailingProvider('openweather', throwGeneric: true);
      final WorkingProvider backup = WorkingProvider('local');
      final WeatherRepository repo =
          WeatherRepository(providers: <WeatherProvider>[broken, backup]);

      final Result<ProviderForecast> result =
          await repo.fetchForecast(corse, from: from, to: to);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.providerName, 'local');
    });

    test('une série vide est traitée comme indisponible', () async {
      final EmptyProvider empty = EmptyProvider('open-meteo');
      final WorkingProvider backup = WorkingProvider('local');
      final WeatherRepository repo =
          WeatherRepository(providers: <WeatherProvider>[empty, backup]);

      final Result<ProviderForecast> result =
          await repo.fetchForecast(corse, from: from, to: to);

      expect(result.valueOrNull!.providerName, 'local');
    });

    test('échec composite quand tous les fournisseurs tombent', () async {
      final WeatherRepository repo = WeatherRepository(
        providers: <WeatherProvider>[
          FailingProvider('open-meteo'),
          FailingProvider('stormglass'),
        ],
      );

      final Result<ProviderForecast> result =
          await repo.fetchForecast(corse, from: from, to: to);

      expect(result.isFailure, isTrue);
      final Failure failure = result.failureOrNull!;
      expect(failure, isA<CompositeFailure>());
      expect((failure as CompositeFailure).failures.length, 2);
    });

    test('journalise les fournisseurs en échec', () async {
      final MemoryLogger logger = MemoryLogger();
      final WeatherRepository repo = WeatherRepository(
        providers: <WeatherProvider>[
          FailingProvider('open-meteo'),
          WorkingProvider('local'),
        ],
        logger: logger,
      );

      await repo.fetchForecast(corse, from: from, to: to);

      expect(logger.hasMessageContaining('open-meteo'), isTrue);
      expect(logger.hasMessageContaining('local'), isTrue);
    });
  });

  group('WeatherRepository — comparaison de fournisseurs', () {
    test('fetchFromAll interroge tous les fournisseurs valides', () async {
      final WeatherRepository repo = WeatherRepository(
        providers: <WeatherProvider>[
          WorkingProvider('open-meteo', windSpeedKmh: 12),
          FailingProvider('stormglass'),
          WorkingProvider('openweather', windSpeedKmh: 20),
        ],
      );

      final List<ProviderForecast> all =
          await repo.fetchFromAll(corse, from: from, to: to);

      expect(all.length, 2);
      expect(
        all.map((ProviderForecast p) => p.providerName),
        <String>['open-meteo', 'openweather'],
      );
      // Les valeurs diffèrent : c'est la base de la future fusion de sources.
      expect(all.first.forecast.samples.first.windSpeedKmh, 12);
      expect(all.last.forecast.samples.first.windSpeedKmh, 20);
    });

    test('liste vide si aucun fournisseur ne répond', () async {
      final WeatherRepository repo = WeatherRepository(
        providers: <WeatherProvider>[FailingProvider('open-meteo')],
      );
      expect(await repo.fetchFromAll(corse, from: from, to: to), isEmpty);
    });
  });

  group('WeatherRepository — fonctionnement hors ligne', () {
    test('un fournisseur local en dernier garantit une réponse', () async {
      final WeatherRepository repo = WeatherRepository(
        providers: <WeatherProvider>[
          FailingProvider('open-meteo'),
          FailingProvider('stormglass'),
          StaticWeatherProvider.synthetic(
            location: corse,
            from: from,
            to: to,
          ),
        ],
      );

      final Result<ProviderForecast> result =
          await repo.fetchForecast(corse, from: from, to: to);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.providerName, 'synthetic');
      expect(result.valueOrNull!.forecast.isNotEmpty, isTrue);
    });
  });
}

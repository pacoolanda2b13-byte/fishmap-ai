import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:weather/weather.dart';
import 'package:weather_openmeteo/weather_openmeteo.dart';

String fixtureText(String name) =>
    File('test/fixtures/$name').readAsStringSync();

/// Client simulant les deux API Open-Meteo à partir des fixtures.
MockClient routedClient({
  String? forecastBody,
  int forecastStatus = 200,
  String? marineBody,
  int marineStatus = 200,
  Duration? delay,
  Object? throwOnRequest,
  void Function(Uri uri)? onRequest,
}) {
  return MockClient((http.Request request) async {
    onRequest?.call(request.url);
    if (throwOnRequest != null) throw throwOnRequest;
    if (delay != null) await Future<void>.delayed(delay);

    final bool isMarine = request.url.host.contains('marine');
    if (isMarine) {
      return http.Response(
        marineBody ?? fixtureText('marine_solenzara.json'),
        marineStatus,
      );
    }
    return http.Response(
      forecastBody ?? fixtureText('forecast_solenzara.json'),
      forecastStatus,
    );
  });
}

void main() {
  const Coordinates solenzara = Coordinates(latitude: 41.86, longitude: 9.40);
  final DateTime from = DateTime.utc(2026, 10, 15, 16);
  final DateTime to = DateTime.utc(2026, 10, 15, 21);

  group('intégration nominale', () {
    test('produit une prévision complète depuis les deux API', () async {
      final OpenMeteoProvider provider =
          OpenMeteoProvider(httpClient: routedClient());

      final WeatherForecast forecast = await provider.fetchForecast(
        solenzara,
        from: from,
        to: to,
      );

      expect(provider.name, 'open-meteo');
      expect(forecast.samples.length, 6);
      expect(forecast.location, solenzara);

      final WeatherData? at19 =
          forecast.nearest(DateTime.utc(2026, 10, 15, 19));
      expect(at19!.windSpeedKmh, 14.4);
      expect(at19.waveHeightM, 0.51);
      expect(at19.seaTemperatureC, 19.5);
    });

    test('interroge bien les deux services avec les bons paramètres', () async {
      final List<Uri> called = <Uri>[];
      final OpenMeteoProvider provider = OpenMeteoProvider(
        httpClient: routedClient(onRequest: called.add),
      );

      await provider.fetchForecast(solenzara, from: from, to: to);

      expect(called.length, 2);
      final Uri forecastUri =
          called.firstWhere((Uri u) => !u.host.contains('marine'));
      final Uri marineUri =
          called.firstWhere((Uri u) => u.host.contains('marine'));

      expect(forecastUri.host, 'api.open-meteo.com');
      expect(forecastUri.path, '/v1/forecast');
      expect(forecastUri.queryParameters['latitude'], '41.8600');
      expect(forecastUri.queryParameters['longitude'], '9.4000');
      expect(forecastUri.queryParameters['timezone'], 'UTC');
      expect(forecastUri.queryParameters['start_date'], '2026-10-15');
      expect(forecastUri.queryParameters['hourly'], contains('wind_gusts_10m'));

      expect(marineUri.host, 'marine-api.open-meteo.com');
      expect(marineUri.queryParameters['hourly'], contains('wave_height'));
      expect(
        marineUri.queryParameters['hourly'],
        contains('sea_surface_temperature'),
      );
    });

    test('borne la série à la fenêtre demandée', () async {
      final OpenMeteoProvider provider =
          OpenMeteoProvider(httpClient: routedClient());

      final WeatherForecast forecast = await provider.fetchForecast(
        solenzara,
        from: DateTime.utc(2026, 10, 15, 18),
        to: DateTime.utc(2026, 10, 15, 20),
      );

      expect(forecast.samples.length, 3);
      expect(forecast.samples.first.observedAt.hour, 18);
      expect(forecast.samples.last.observedAt.hour, 20);
    });

    test('includeMarine: false n\'appelle que l\'API prévision', () async {
      final List<Uri> called = <Uri>[];
      final OpenMeteoProvider provider = OpenMeteoProvider(
        httpClient: routedClient(onRequest: called.add),
        includeMarine: false,
      );

      final WeatherForecast forecast =
          await provider.fetchForecast(solenzara, from: from, to: to);

      expect(called.length, 1);
      expect(forecast.samples.first.waveHeightM, isNull);
      expect(forecast.samples.first.windSpeedKmh, isNotNull);
    });
  });

  group('dégradation gracieuse', () {
    test('API marine en panne : les données atmosphériques passent', () async {
      final MemoryLogger logger = MemoryLogger();
      final OpenMeteoProvider provider = OpenMeteoProvider(
        httpClient: routedClient(marineStatus: 503, marineBody: 'unavailable'),
        logger: logger,
      );

      final WeatherForecast forecast =
          await provider.fetchForecast(solenzara, from: from, to: to);

      expect(forecast.samples.length, 6);
      expect(forecast.samples.first.windSpeedKmh, isNotNull);
      expect(forecast.samples.first.waveHeightM, isNull);
      expect(logger.hasMessageContaining('marine'), isTrue);
    });

    test('API prévision en panne : échec explicite', () async {
      final OpenMeteoProvider provider = OpenMeteoProvider(
        httpClient: routedClient(forecastStatus: 500, forecastBody: '{}'),
      );

      expect(
        () => provider.fetchForecast(solenzara, from: from, to: to),
        throwsA(isA<WeatherProviderException>()),
      );
    });
  });

  group('cas d\'erreur', () {
    test('erreur applicative Open-Meteo remontée avec sa raison', () async {
      final OpenMeteoProvider provider = OpenMeteoProvider(
        httpClient: routedClient(
          forecastBody: fixtureText('error_invalid_latitude.json'),
          forecastStatus: 400,
        ),
      );

      await expectLater(
        provider.fetchForecast(solenzara, from: from, to: to),
        throwsA(
          isA<WeatherProviderException>().having(
            (WeatherProviderException e) => e.message,
            'message',
            contains('Latitude must be in range'),
          ),
        ),
      );
    });

    test('API injoignable (erreur réseau)', () async {
      final OpenMeteoProvider provider = OpenMeteoProvider(
        httpClient: routedClient(
          throwOnRequest: const SocketException('connexion refusée'),
        ),
      );

      await expectLater(
        provider.fetchForecast(solenzara, from: from, to: to),
        throwsA(
          isA<WeatherProviderException>().having(
            (WeatherProviderException e) => e.message,
            'message',
            contains('réseau'),
          ),
        ),
      );
    });

    test('délai dépassé', () async {
      final OpenMeteoProvider provider = OpenMeteoProvider(
        httpClient: routedClient(delay: const Duration(milliseconds: 200)),
        timeout: const Duration(milliseconds: 20),
      );

      await expectLater(
        provider.fetchForecast(solenzara, from: from, to: to),
        throwsA(
          isA<WeatherProviderException>().having(
            (WeatherProviderException e) => e.message,
            'message',
            contains('Délai dépassé'),
          ),
        ),
      );
    });

    test('réponse non JSON', () async {
      final OpenMeteoProvider provider = OpenMeteoProvider(
        httpClient: routedClient(forecastBody: '<html>503</html>'),
      );

      await expectLater(
        provider.fetchForecast(solenzara, from: from, to: to),
        throwsA(
          isA<WeatherProviderException>().having(
            (WeatherProviderException e) => e.message,
            'message',
            contains('non JSON'),
          ),
        ),
      );
    });

    test('JSON valide mais structure inattendue', () async {
      final OpenMeteoProvider provider = OpenMeteoProvider(
        httpClient: routedClient(forecastBody: '[]'),
      );

      await expectLater(
        provider.fetchForecast(solenzara, from: from, to: to),
        throwsA(isA<WeatherProviderException>()),
      );
    });

    test('réponse sans bloc hourly', () async {
      final OpenMeteoProvider provider = OpenMeteoProvider(
        httpClient: routedClient(forecastBody: '{"latitude": 41.8}'),
      );

      await expectLater(
        provider.fetchForecast(solenzara, from: from, to: to),
        throwsA(
          isA<WeatherProviderException>().having(
            (WeatherProviderException e) => e.message,
            'message',
            contains('inexploitable'),
          ),
        ),
      );
    });

    test('intervalle invalide rejeté avant tout appel réseau', () async {
      final List<Uri> called = <Uri>[];
      final OpenMeteoProvider provider =
          OpenMeteoProvider(httpClient: routedClient(onRequest: called.add));

      await expectLater(
        provider.fetchForecast(solenzara, from: to, to: from),
        throwsA(isA<WeatherProviderException>()),
      );
      expect(called, isEmpty);
    });
  });

  group('intégration avec WeatherRepository', () {
    test('Open-Meteo est utilisé comme fournisseur principal', () async {
      final WeatherRepository repository = WeatherRepository(
        providers: <WeatherProvider>[
          OpenMeteoProvider(httpClient: routedClient()),
          StaticWeatherProvider.synthetic(
            location: solenzara,
            from: from,
            to: to,
          ),
        ],
      );

      final Result<ProviderForecast> result =
          await repository.fetchForecast(solenzara, from: from, to: to);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.providerName, 'open-meteo');
      expect(result.valueOrNull!.forecast.samples.first.seaTemperatureC, 19.8);
    });

    test('repli sur le fournisseur local si Open-Meteo tombe', () async {
      final WeatherRepository repository = WeatherRepository(
        providers: <WeatherProvider>[
          OpenMeteoProvider(
            httpClient: routedClient(
              throwOnRequest: const SocketException('hors service'),
            ),
          ),
          StaticWeatherProvider.synthetic(
            location: solenzara,
            from: from,
            to: to,
          ),
        ],
      );

      final Result<ProviderForecast> result =
          await repository.fetchForecast(solenzara, from: from, to: to);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.providerName, 'synthetic');
    });
  });
}

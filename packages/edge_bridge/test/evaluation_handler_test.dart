import 'package:core/core.dart';
import 'package:edge_bridge/edge_bridge.dart';
import 'package:fishscore/fishscore.dart';
import 'package:test/test.dart';
import 'package:weather/weather.dart';

/// Fournisseur déterministe comptant ses appels.
class StubProvider implements WeatherProvider {
  StubProvider({this.name = 'open-meteo'});

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
    return WeatherForecast(
      location: location,
      samples: <WeatherData>[
        WeatherData(
          observedAt: DateTime.utc(2026, 10, 15, 16),
          source: name,
          windSpeedKmh: 16,
          waveHeightM: 0.6,
          seaTemperatureC: 17.5,
          pressureHpa: 1016,
        ),
        WeatherData(
          observedAt: DateTime.utc(2026, 10, 15, 19),
          source: name,
          windSpeedKmh: 15,
          gustSpeedKmh: 24,
          waveHeightM: 0.55,
          wavePeriodS: 4.6,
          seaTemperatureC: 17.4,
          pressureHpa: 1013,
        ),
      ],
    );
  }
}

class DeadProvider implements WeatherProvider {
  @override
  String get name => 'dead';

  @override
  Future<WeatherForecast> fetchForecast(
    Coordinates location, {
    required DateTime from,
    required DateTime to,
  }) async =>
      throw const WeatherProviderException('hors service');
}

EvaluateRequest requestFor({String? species}) => EvaluateRequest(
      location: const Coordinates(latitude: 41.86, longitude: 9.40),
      evaluatedAt: DateTime.utc(2026, 10, 15, 19),
      speciesSlug: species,
    );

void main() {
  group('EvaluationHandler — succès', () {
    test('évalue toutes les espèces sans filtre', () async {
      final EvaluationHandler handler = EvaluationHandler(
        weatherRepository:
            WeatherRepository(providers: <WeatherProvider>[StubProvider()]),
      );

      final Result<Map<String, dynamic>> result =
          await handler.handle(requestFor());

      final Map<String, dynamic> body = result.valueOrNull!;
      final List<dynamic> results = body['results'] as List<dynamic>;
      expect(results.length, SpeciesCatalog.all.length);
      expect(body['evaluated_at'], '2026-10-15T19:00:00.000Z');
      expect(body['location'], <String, dynamic>{'lat': 41.86, 'lng': 9.40});
    });

    test('filtre sur une espèce demandée', () async {
      final EvaluationHandler handler = EvaluationHandler(
        weatherRepository:
            WeatherRepository(providers: <WeatherProvider>[StubProvider()]),
      );

      final Result<Map<String, dynamic>> result =
          await handler.handle(requestFor(species: 'loup'));

      final List<dynamic> results =
          result.valueOrNull!['results'] as List<dynamic>;
      expect(results.length, 1);
      expect((results.single as Map<String, dynamic>)['species'], 'loup');
    });

    test('classe les résultats par score décroissant', () async {
      final EvaluationHandler handler = EvaluationHandler(
        weatherRepository:
            WeatherRepository(providers: <WeatherProvider>[StubProvider()]),
      );

      final List<dynamic> results = (await handler.handle(requestFor()))
          .valueOrNull!['results'] as List<dynamic>;
      final List<int> scores = results
          .map((dynamic r) => (r as Map<String, dynamic>)['score'] as int)
          .toList();
      final List<int> sorted = <int>[...scores]..sort((int a, int b) => b - a);
      expect(scores, sorted);
    });

    test('chaque résultat respecte le contrat de sortie', () async {
      final EvaluationHandler handler = EvaluationHandler(
        weatherRepository:
            WeatherRepository(providers: <WeatherProvider>[StubProvider()]),
      );

      final List<dynamic> results = (await handler.handle(requestFor()))
          .valueOrNull!['results'] as List<dynamic>;

      for (final dynamic raw in results) {
        final Map<String, dynamic> r = raw as Map<String, dynamic>;
        expect(r['species'], isA<String>());
        expect(r['common_name_fr'], isA<String>());
        expect(r['score'], isA<int>());
        expect(r['confidence'], isA<int>());
        expect(r['evidence_score'], isA<int>());
        expect(r['explanation'], isA<String>());
        expect(r['model_version'], isA<String>());
        final Map<String, dynamic> provenance =
            r['provenance'] as Map<String, dynamic>;
        expect(provenance['weather_provider'], 'open-meteo');
        expect(provenance['weather_from_cache'], isA<bool>());
        expect(provenance['species_confidence'], isA<String>());
      }
    });

    test('signale une météo servie depuis le cache', () async {
      final StubProvider provider = StubProvider();
      final WeatherRepository repository = WeatherRepository(
        providers: <WeatherProvider>[provider],
        cache: WeatherCache(),
      );
      final EvaluationHandler handler =
          EvaluationHandler(weatherRepository: repository);

      await handler.handle(requestFor(species: 'loup'));
      final Result<Map<String, dynamic>> second =
          await handler.handle(requestFor(species: 'loup'));

      final Map<String, dynamic> r =
          (second.valueOrNull!['results'] as List<dynamic>).single
              as Map<String, dynamic>;
      expect(
        (r['provenance'] as Map<String, dynamic>)['weather_from_cache'],
        isTrue,
      );
      expect(provider.callCount, 1, reason: 'le cache a évité un second appel');
    });

    test('une seule récupération météo sert toutes les espèces', () async {
      final StubProvider provider = StubProvider();
      final EvaluationHandler handler = EvaluationHandler(
        weatherRepository: WeatherRepository(
          providers: <WeatherProvider>[provider],
          cache: WeatherCache(),
        ),
      );

      await handler.handle(requestFor());

      expect(provider.callCount, 1,
          reason: 'les 4 espèces partagent la même prévision');
    });
  });

  group('EvaluationHandler — échecs', () {
    test('espèce inconnue renvoie NOT_FOUND', () async {
      final EvaluationHandler handler = EvaluationHandler(
        weatherRepository:
            WeatherRepository(providers: <WeatherProvider>[StubProvider()]),
      );

      final Result<Map<String, dynamic>> result =
          await handler.handle(requestFor(species: 'thon-rouge'));

      expect(result.failureOrNull!.code, 'NOT_FOUND');
    });

    test('espèce inconnue n\'appelle pas la météo', () async {
      final StubProvider provider = StubProvider();
      final EvaluationHandler handler = EvaluationHandler(
        weatherRepository:
            WeatherRepository(providers: <WeatherProvider>[provider]),
      );

      await handler.handle(requestFor(species: 'inconnue'));

      expect(provider.callCount, 0);
    });

    test('météo indisponible renvoie un échec composite', () async {
      final EvaluationHandler handler = EvaluationHandler(
        weatherRepository:
            WeatherRepository(providers: <WeatherProvider>[DeadProvider()]),
      );

      final Result<Map<String, dynamic>> result =
          await handler.handle(requestFor());

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<CompositeFailure>());
    });
  });

  group('traduction HTTP', () {
    test('associe les codes métier aux statuts attendus', () {
      final Map<Failure, int> expectations = <Failure, int>{
        const ValidationFailure('x'): 400,
        const NotFoundFailure('x'): 404,
        const TimeoutFailure('x'): 504,
        const UnavailableFailure('x'): 503,
        const NetworkFailure('x'): 503,
        CompositeFailure('x', const <Failure>[]): 503,
        const UnexpectedFailure('x'): 500,
      };

      expectations.forEach((Failure failure, int status) {
        expect(EvaluationHandler.httpStatusFor(failure), status,
            reason: failure.code);
      });
    });

    test('le corps d\'erreur suit le format du contrat API', () {
      final Map<String, dynamic> body =
          EvaluationHandler.errorBody(const NotFoundFailure('Espèce inconnue'));
      final Map<String, dynamic> error = body['error'] as Map<String, dynamic>;
      expect(error['code'], 'NOT_FOUND');
      expect(error['message'], 'Espèce inconnue');
      expect(error.containsKey('details'), isTrue);
    });
  });
}

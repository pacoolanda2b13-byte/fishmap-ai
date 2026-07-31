import 'dart:io';

import 'package:core/core.dart';
import 'package:fishmap_example/evaluate.dart';
import 'package:fishscore/fishscore.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scoring_pipeline/scoring_pipeline.dart';
import 'package:test/test.dart';
import 'package:weather/weather.dart';
import 'package:weather_openmeteo/weather_openmeteo.dart';

/// Fixtures partagées avec le paquet adaptateur : la chaîne est validée sur
/// des réponses au format réel d'Open-Meteo, sans appel réseau.
String fixtureText(String name) =>
    File('../packages/weather_openmeteo/test/fixtures/$name').readAsStringSync();

MockClient openMeteoClient({bool marineFails = false, Object? throwOnRequest}) {
  return MockClient((http.Request request) async {
    if (throwOnRequest != null) throw throwOnRequest;
    if (request.url.host.contains('marine')) {
      if (marineFails) return http.Response('unavailable', 503);
      return http.Response(fixtureText('marine_solenzara.json'), 200);
    }
    return http.Response(fixtureText('forecast_solenzara.json'), 200);
  });
}

WeatherRepository repositoryWith(MockClient client) => WeatherRepository(
      providers: <WeatherProvider>[
        OpenMeteoProvider(httpClient: client),
      ],
    );

void main() {
  const double latitude = 41.86;
  const double longitude = 9.40;
  final DateTime evaluatedAt = DateTime.utc(2026, 10, 15, 19);

  group('chaîne complète Open-Meteo → FishScore', () {
    test('produit un score pour chaque espèce MVP', () async {
      final Result<List<SpeciesEvaluation>> result = await evaluate(
        latitude: latitude,
        longitude: longitude,
        date: evaluatedAt,
        repository: repositoryWith(openMeteoClient()),
      );

      expect(result.isSuccess, isTrue);
      final List<SpeciesEvaluation> evaluations = result.valueOrNull!;
      expect(evaluations.length, SpeciesCatalog.all.length);
      expect(
        evaluations.map((SpeciesEvaluation e) => e.speciesSlug).toSet(),
        SpeciesCatalog.all.keys.toSet(),
      );
    });

    test('les scores sont triés par pertinence décroissante', () async {
      final Result<List<SpeciesEvaluation>> result = await evaluate(
        latitude: latitude,
        longitude: longitude,
        date: evaluatedAt,
        repository: repositoryWith(openMeteoClient()),
      );

      final List<int> scores =
          result.valueOrNull!.map((SpeciesEvaluation e) => e.score).toList();
      final List<int> sorted = <int>[...scores]..sort((int a, int b) => b - a);
      expect(scores, sorted);
    });

    test('chaque évaluation est complète et traçable', () async {
      final Result<List<SpeciesEvaluation>> result = await evaluate(
        latitude: latitude,
        longitude: longitude,
        date: evaluatedAt,
        repository: repositoryWith(openMeteoClient()),
      );

      for (final SpeciesEvaluation e in result.valueOrNull!) {
        expect(e.score, inInclusiveRange(0, 100));
        expect(e.confidence, inInclusiveRange(0, 100));
        expect(e.explanation, isNotEmpty);
        // La provenance cite le fournisseur météo réellement utilisé.
        expect(e.provenance, contains('open-meteo'));
        expect(e.scored.weatherProvider, 'open-meteo');
      }
    });

    test('les données météo réelles alimentent bien le score', () async {
      // Le loup en automne, au crépuscule, avec les conditions de la fixture
      // (vent 14 km/h, houle 0,51 m, eau 19,5 °C, pression en baisse).
      final Result<List<SpeciesEvaluation>> result = await evaluate(
        latitude: latitude,
        longitude: longitude,
        date: evaluatedAt,
        repository: repositoryWith(openMeteoClient()),
        spot: const SpotContext(
          spotSuitability: 80,
          bottomType: BottomType.rock,
          depthMeters: 6,
          spotQuality: DataQuality.observed,
        ),
      );

      final SpeciesEvaluation loup = result.valueOrNull!
          .firstWhere((SpeciesEvaluation e) => e.speciesSlug == 'loup');

      // Conditions favorables : le score doit être élevé et la confiance
      // correcte puisque toutes les composantes sont alimentées.
      expect(loup.score, greaterThan(60));
      expect(loup.confidence, greaterThan(50));
      // La pression baisse de 1016,4 à 1013,1 hPa dans la fixture.
      expect(
        loup.scored.result.positiveFactors.any(
          (String f) => f.toLowerCase().contains('pression'),
        ),
        isTrue,
      );
    });

    test('sans données marines, la chaîne reste exploitable', () async {
      final Result<List<SpeciesEvaluation>> result = await evaluate(
        latitude: latitude,
        longitude: longitude,
        date: evaluatedAt,
        repository: repositoryWith(openMeteoClient(marineFails: true)),
      );

      expect(result.isSuccess, isTrue);
      for (final SpeciesEvaluation e in result.valueOrNull!) {
        expect(e.score, inInclusiveRange(0, 100));
      }
      // La composante houle disparaît du calcul, sans le fausser.
      final SpeciesEvaluation any = result.valueOrNull!.first;
      final ComponentScore waves = any.scored.result.components
          .firstWhere((ComponentScore c) => c.id == 'waves');
      expect(waves.available, isFalse);
    });

    test('échec propre quand Open-Meteo est injoignable', () async {
      final Result<List<SpeciesEvaluation>> result = await evaluate(
        latitude: latitude,
        longitude: longitude,
        date: evaluatedAt,
        repository: repositoryWith(
          openMeteoClient(throwOnRequest: const SocketException('hors ligne')),
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<CompositeFailure>());
    });
  });

  group('configuration par défaut', () {
    test('le dépôt par défaut place Open-Meteo en premier', () {
      final WeatherRepository repository = defaultWeatherRepository();
      expect(repository.providers.first.name, 'open-meteo');
    });
  });
}

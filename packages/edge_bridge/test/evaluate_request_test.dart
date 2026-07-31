import 'package:core/core.dart';
import 'package:edge_bridge/edge_bridge.dart';
import 'package:test/test.dart';

void main() {
  group('EvaluateRequest — cas valides', () {
    test('accepte latitude, longitude et date', () {
      final Result<EvaluateRequest> result =
          EvaluateRequest.parse(<String, dynamic>{
        'latitude': 41.86,
        'longitude': 9.40,
        'date': '2026-10-15T19:00:00Z',
      });

      final EvaluateRequest request = result.valueOrNull!;
      expect(request.location.latitude, 41.86);
      expect(request.location.longitude, 9.40);
      expect(request.evaluatedAt, DateTime.utc(2026, 10, 15, 19));
      expect(request.speciesSlug, isNull);
    });

    test('accepte des entiers pour les coordonnées', () {
      final Result<EvaluateRequest> result = EvaluateRequest.parse(
        <String, dynamic>{'latitude': 42, 'longitude': 9},
      );
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.location.latitude, 42.0);
    });

    test('date absente : évaluation à maintenant, en UTC', () {
      final Result<EvaluateRequest> result = EvaluateRequest.parse(
        <String, dynamic>{'latitude': 41.86, 'longitude': 9.40},
      );
      expect(result.valueOrNull!.evaluatedAt.isUtc, isTrue);
    });

    test('convertit une date décalée en UTC', () {
      final Result<EvaluateRequest> result =
          EvaluateRequest.parse(<String, dynamic>{
        'latitude': 41.86,
        'longitude': 9.40,
        'date': '2026-10-15T21:00:00+02:00',
      });
      expect(result.valueOrNull!.evaluatedAt, DateTime.utc(2026, 10, 15, 19));
    });

    test('retient l\'espèce demandée', () {
      final Result<EvaluateRequest> result =
          EvaluateRequest.parse(<String, dynamic>{
        'latitude': 41.86,
        'longitude': 9.40,
        'species': 'loup',
      });
      expect(result.valueOrNull!.speciesSlug, 'loup');
    });

    test('espèce vide ou blanche équivaut à absente', () {
      for (final String raw in <String>['', '   ']) {
        final Result<EvaluateRequest> result =
            EvaluateRequest.parse(<String, dynamic>{
          'latitude': 41.86,
          'longitude': 9.40,
          'species': raw,
        });
        expect(result.valueOrNull!.speciesSlug, isNull, reason: '"$raw"');
      }
    });

    test('accepte les bornes extrêmes des coordonnées', () {
      for (final List<num> pair in <List<num>>[
        <num>[-90, -180],
        <num>[90, 180],
      ]) {
        final Result<EvaluateRequest> result = EvaluateRequest.parse(
          <String, dynamic>{'latitude': pair[0], 'longitude': pair[1]},
        );
        expect(result.isSuccess, isTrue, reason: '$pair');
      }
    });
  });

  group('EvaluateRequest — validation', () {
    void expectValidationFailure(
      Map<String, dynamic> body, {
      required String contains,
    }) {
      final Result<EvaluateRequest> result = EvaluateRequest.parse(body);
      expect(result.isFailure, isTrue, reason: '$body');
      expect(result.failureOrNull!.code, 'VALIDATION_ERROR');
      expect(result.failureOrNull!.message,
          stringContainsInOrder(<String>[contains]));
    }

    test('latitude manquante', () {
      expectValidationFailure(
        <String, dynamic>{'longitude': 9.40},
        contains: 'latitude',
      );
    });

    test('longitude manquante', () {
      expectValidationFailure(
        <String, dynamic>{'latitude': 41.86},
        contains: 'longitude',
      );
    });

    test('latitude non numérique', () {
      expectValidationFailure(
        <String, dynamic>{'latitude': 'nord', 'longitude': 9.40},
        contains: 'latitude',
      );
    });

    test('latitude hors bornes', () {
      expectValidationFailure(
        <String, dynamic>{'latitude': 91, 'longitude': 9.40},
        contains: 'latitude',
      );
    });

    test('longitude hors bornes', () {
      expectValidationFailure(
        <String, dynamic>{'latitude': 41.86, 'longitude': 181},
        contains: 'longitude',
      );
    });

    test('date non analysable', () {
      expectValidationFailure(
        <String, dynamic>{
          'latitude': 41.86,
          'longitude': 9.40,
          'date': 'demain matin',
        },
        contains: 'date',
      );
    });

    test('date d\'un type inattendu', () {
      expectValidationFailure(
        <String, dynamic>{'latitude': 41.86, 'longitude': 9.40, 'date': 1234},
        contains: 'date',
      );
    });

    test('espèce d\'un type inattendu', () {
      expectValidationFailure(
        <String, dynamic>{'latitude': 41.86, 'longitude': 9.40, 'species': 42},
        contains: 'species',
      );
    });
  });
}

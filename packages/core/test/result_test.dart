import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  group('Result', () {
    test('success expose la valeur', () {
      const Result<int> r = Result<int>.success(42);
      expect(r.isSuccess, isTrue);
      expect(r.isFailure, isFalse);
      expect(r.valueOrNull, 42);
      expect(r.failureOrNull, isNull);
    });

    test('failure expose l\'échec', () {
      const Result<int> r =
          Result<int>.failure(NetworkFailure('API injoignable'));
      expect(r.isFailure, isTrue);
      expect(r.valueOrNull, isNull);
      expect(r.failureOrNull, isA<NetworkFailure>());
      expect(r.failureOrNull!.code, 'NETWORK_ERROR');
    });

    test('fold réduit les deux branches', () {
      const Result<int> ok = Result<int>.success(2);
      const Result<int> ko = Result<int>.failure(TimeoutFailure('trop long'));
      expect(
        ok.fold(onSuccess: (int v) => v * 10, onFailure: (_) => -1),
        20,
      );
      expect(
        ko.fold(onSuccess: (int v) => v * 10, onFailure: (_) => -1),
        -1,
      );
    });

    test('map transforme le succès et propage l\'échec', () {
      const Result<int> ok = Result<int>.success(3);
      expect(ok.map((int v) => 'v=$v').valueOrNull, 'v=3');

      const Result<int> ko = Result<int>.failure(NotFoundFailure('absent'));
      final Result<String> mapped = ko.map((int v) => 'v=$v');
      expect(mapped.isFailure, isTrue);
      expect(mapped.failureOrNull!.code, 'NOT_FOUND');
    });

    test('flatMap enchaîne des opérations faillibles', () {
      Result<int> half(int v) => v.isEven
          ? Result<int>.success(v ~/ 2)
          : const Result<int>.failure(ValidationFailure('impair'));

      expect(const Result<int>.success(8).flatMap(half).valueOrNull, 4);
      expect(const Result<int>.success(3).flatMap(half).isFailure, isTrue);
    });

    test('getOrElse fournit un repli', () {
      const Result<int> ko = Result<int>.failure(UnavailableFailure('vide'));
      expect(ko.getOrElse((_) => 7), 7);
    });
  });

  group('Failure', () {
    test('CompositeFailure agrège les codes', () {
      final CompositeFailure f = CompositeFailure(
        'tous les fournisseurs ont échoué',
        const <Failure>[
          NetworkFailure('a'),
          TimeoutFailure('b'),
        ],
      );
      expect(f.failures.length, 2);
      expect(f.message, contains('NETWORK_ERROR'));
      expect(f.message, contains('TIMEOUT'));
    });
  });
}

import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  group('AppConfig', () {
    const AppConfig config = AppConfig(<String, String>{
      'API_URL': 'https://example.test',
      'MAX_RADIUS_KM': '50',
      'FEATURE_X': 'true',
      'BROKEN_INT': 'abc',
    });

    test('require renvoie la valeur ou lève', () {
      expect(config.require('API_URL'), 'https://example.test');
      expect(() => config.require('MISSING'), throwsA(isA<ConfigException>()));
    });

    test('getInt parse ou lève sur valeur invalide', () {
      expect(config.getInt('MAX_RADIUS_KM', defaultValue: 10), 50);
      expect(config.getInt('MISSING', defaultValue: 10), 10);
      expect(
        () => config.getInt('BROKEN_INT', defaultValue: 0),
        throwsA(isA<ConfigException>()),
      );
    });

    test('getBool comprend les formes usuelles', () {
      expect(config.getBool('FEATURE_X', defaultValue: false), isTrue);
      expect(config.getBool('MISSING', defaultValue: false), isFalse);
    });
  });

  group('TimeProvider', () {
    test('FixedTimeProvider est pilotable', () {
      final FixedTimeProvider clock =
          FixedTimeProvider(DateTime.utc(2026, 10, 15, 7));
      expect(clock.nowUtc(), DateTime.utc(2026, 10, 15, 7));
      clock.advance(const Duration(hours: 2));
      expect(clock.nowUtc(), DateTime.utc(2026, 10, 15, 9));
    });

    test('SystemTimeProvider renvoie de l\'UTC', () {
      expect(const SystemTimeProvider().nowUtc().isUtc, isTrue);
    });
  });

  group('Logger', () {
    test('ConsoleLogger respecte le niveau minimal', () {
      final List<String> lines = <String>[];
      final ConsoleLogger logger =
          ConsoleLogger(minLevel: LogLevel.warning, output: lines.add);
      logger.debug('caché');
      logger.info('caché aussi');
      logger.warning('visible');
      logger.error('visible', error: 'boom');
      expect(lines.length, 2);
      expect(lines.first, contains('[WARNING]'));
      expect(lines.last, contains('boom'));
    });

    test('MemoryLogger capture les entrées', () {
      final MemoryLogger logger = MemoryLogger();
      logger.info('fournisseur open-meteo utilisé');
      expect(logger.hasMessageContaining('open-meteo'), isTrue);
      expect(logger.records.single.level, LogLevel.info);
    });
  });

  group('Units', () {
    test('conversions clés', () {
      expect(Units.msToKmh(10), closeTo(36, 0.0001));
      expect(Units.knotsToKmh(10), closeTo(18.52, 0.0001));
      expect(Units.kelvinToCelsius(300), closeTo(26.85, 0.0001));
      expect(Units.fahrenheitToCelsius(50), closeTo(10, 0.0001));
      expect(Units.paToHpa(101325), closeTo(1013.25, 0.0001));
      expect(Units.feetToMeters(10), closeTo(3.048, 0.0001));
    });
  });
}

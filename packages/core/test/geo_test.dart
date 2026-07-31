import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  group('Coordinates', () {
    test('distance Solenzara → Aléria plausible', () {
      const Coordinates solenzara =
          Coordinates(latitude: 41.86, longitude: 9.40);
      const Coordinates aleria = Coordinates(latitude: 42.10, longitude: 9.51);
      final Distance d = solenzara.distanceTo(aleria);
      expect(d.kilometers, greaterThan(20));
      expect(d.kilometers, lessThan(40));
    });

    test('distance vers soi-même nulle', () {
      const Coordinates p = Coordinates(latitude: 42, longitude: 9);
      expect(p.distanceTo(p).meters, closeTo(0, 0.001));
    });

    test('égalité par valeur et JSON round-trip', () {
      const Coordinates p = Coordinates(latitude: 41.86, longitude: 9.40);
      expect(Coordinates.fromJson(p.toJson()), p);
    });
  });

  group('Distance', () {
    test('conversions et comparaisons', () {
      final Distance d = Distance.kilometers(1.5);
      expect(d.meters, 1500);
      expect(d > Distance.meters(1000), isTrue);
      expect(d <= Distance.kilometers(1.5), isTrue);
      expect(Distance.zero < d, isTrue);
    });

    test('addition et tri', () {
      final Distance sum = Distance.meters(400) + Distance.meters(600);
      expect(sum, Distance.kilometers(1));
      final List<Distance> list = <Distance>[
        Distance.kilometers(2),
        Distance.meters(500),
      ]..sort();
      expect(list.first.meters, 500);
    });

    test('affichage adapté à l\'échelle', () {
      expect(Distance.meters(650).toString(), '650 m');
      expect(Distance.kilometers(12.345).toString(), '12.35 km');
    });
  });
}

import 'package:fishscore/src/scoring/scoring_math.dart';
import 'package:test/test.dart';

void main() {
  group('ScoringMath.plateau', () {
    test('vaut 100 dans la plage idéale', () {
      expect(
        ScoringMath.plateau(
            value: 0.5, idealMin: 0.3, idealMax: 0.8, falloff: 1),
        100,
      );
    });

    test('décroît linéairement hors de la plage', () {
      final double note = ScoringMath.plateau(
          value: 1.3, idealMin: 0.3, idealMax: 0.8, falloff: 1);
      expect(note, closeTo(50, 0.001));
    });

    test('tombe à 0 au-delà du falloff', () {
      expect(
        ScoringMath.plateau(
            value: 2.0, idealMin: 0.3, idealMax: 0.8, falloff: 1),
        0,
      );
    });
  });

  group('ScoringMath.lowerIsBetter', () {
    test('100 en dessous du seuil best', () {
      expect(ScoringMath.lowerIsBetter(value: 5, best: 20, worst: 40), 100);
    });
    test('0 au-delà du seuil worst', () {
      expect(ScoringMath.lowerIsBetter(value: 50, best: 20, worst: 40), 0);
    });
    test('interpolation au milieu', () {
      expect(
        ScoringMath.lowerIsBetter(value: 30, best: 20, worst: 40),
        closeTo(50, 0.001),
      );
    });
  });

  group('ScoringMath.saturating', () {
    test('0 sans signal', () {
      expect(ScoringMath.saturating(count: 0, halfway: 6), 0);
    });
    test('50 au point halfway', () {
      expect(ScoringMath.saturating(count: 6, halfway: 6), closeTo(50, 0.001));
    });
    test('tend vers 100 mais reste borné', () {
      expect(ScoringMath.saturating(count: 1000, halfway: 6),
          lessThanOrEqualTo(100));
    });
  });

  group('ScoringMath.freshnessDecay', () {
    test('1 à l\'instant présent', () {
      expect(ScoringMath.freshnessDecay(ageHours: 0, halfLifeHours: 12), 1);
    });
    test('0.5 après une demi-vie', () {
      expect(
        ScoringMath.freshnessDecay(ageHours: 12, halfLifeHours: 12),
        closeTo(0.5, 0.0001),
      );
    });
  });

  group('ScoringMath.angularDistance', () {
    test('prend le plus court chemin', () {
      expect(ScoringMath.angularDistance(350, 10), closeTo(20, 0.001));
      expect(ScoringMath.angularDistance(0, 180), closeTo(180, 0.001));
    });
  });
}

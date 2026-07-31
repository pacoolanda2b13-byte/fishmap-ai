import 'dart:math' as math;

/// Fonctions utilitaires déterministes pour transformer des grandeurs
/// physiques en notes comprises entre 0 et 100.
class ScoringMath {
  const ScoringMath._();

  /// Limite [value] à l'intervalle \[min, max].
  static double clampDouble(double value, double min, double max) =>
      value < min ? min : (value > max ? max : value);

  /// Note à partir d'une plage idéale plate avec décroissance linéaire.
  ///
  /// La note vaut 100 lorsque [value] est dans \[idealMin, idealMax], puis
  /// décroît linéairement jusqu'à 0 sur une largeur [falloff] de part et
  /// d'autre de la plage idéale.
  static double plateau({
    required double value,
    required double idealMin,
    required double idealMax,
    required double falloff,
  }) {
    assert(idealMin <= idealMax);
    assert(falloff > 0);
    if (value >= idealMin && value <= idealMax) return 100;
    final double distance =
        value < idealMin ? idealMin - value : value - idealMax;
    final double ratio = 1 - (distance / falloff);
    return clampDouble(ratio * 100, 0, 100);
  }

  /// Note "moins c'est mieux" : 100 sous [best], 0 au-delà de [worst].
  static double lowerIsBetter({
    required double value,
    required double best,
    required double worst,
  }) {
    assert(best < worst);
    if (value <= best) return 100;
    if (value >= worst) return 0;
    return clampDouble((worst - value) / (worst - best) * 100, 0, 100);
  }

  /// Note "plus c'est mieux" : 0 sous [worst], 100 au-delà de [best].
  static double higherIsBetter({
    required double value,
    required double worst,
    required double best,
  }) {
    assert(worst < best);
    if (value <= worst) return 0;
    if (value >= best) return 100;
    return clampDouble((value - worst) / (best - worst) * 100, 0, 100);
  }

  /// Courbe de saturation : rendements décroissants vers 100 quand [count]
  /// augmente. [halfway] est le nombre de signaux pour lequel la note vaut 50.
  static double saturating({required num count, required double halfway}) {
    assert(halfway > 0);
    if (count <= 0) return 0;
    return clampDouble(count / (count + halfway) * 100, 0, 100);
  }

  /// Décroissance exponentielle d'un facteur de fraîcheur (1 → 0) en fonction
  /// d'un âge et d'une demi-vie exprimés dans la même unité.
  static double freshnessDecay(
      {required double ageHours, required double halfLifeHours}) {
    assert(halfLifeHours > 0);
    if (ageHours <= 0) return 1;
    return math.pow(0.5, ageHours / halfLifeHours).toDouble();
  }

  /// Distance angulaire minimale (0-180°) entre deux caps en degrés.
  static double angularDistance(double a, double b) {
    final double diff = (a - b).abs() % 360;
    return diff > 180 ? 360 - diff : diff;
  }
}

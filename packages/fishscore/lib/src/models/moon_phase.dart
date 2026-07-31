import 'dart:math' as math;

/// Représente la phase lunaire au moment de l'évaluation.
///
/// [illumination] est la fraction éclairée du disque lunaire, entre 0
/// (nouvelle lune) et 1 (pleine lune). Le moteur reste volontairement
/// prudent : l'influence de la lune est une hypothèse et son poids est faible.
class MoonPhase {
  const MoonPhase({required this.illumination})
      : assert(illumination >= 0 && illumination <= 1,
            'illumination must be within 0..1');

  /// Fraction éclairée du disque lunaire (0 = nouvelle, 1 = pleine).
  final double illumination;

  /// Nouvelle lune (disque non éclairé).
  static const MoonPhase newMoon = MoonPhase(illumination: 0);

  /// Pleine lune (disque totalement éclairé).
  static const MoonPhase fullMoon = MoonPhase(illumination: 1);

  /// Premier ou dernier quartier (demi-disque éclairé).
  static const MoonPhase quarter = MoonPhase(illumination: 0.5);

  /// Vrai lorsque la lune est proche de la nouvelle ou de la pleine lune,
  /// périodes de marées de vive-eau réputées plus actives.
  bool get isSpringTide => illumination <= 0.1 || illumination >= 0.9;

  /// Distance normalisée (0..1) au pic de vive-eau le plus proche.
  ///
  /// 0 correspond exactement à une nouvelle ou pleine lune, 1 à un quartier.
  double get springTideProximity {
    final double distanceToPeak = math.min(illumination, 1 - illumination);
    return 1 - (distanceToPeak / 0.5);
  }
}

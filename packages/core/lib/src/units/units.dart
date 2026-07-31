/// Conversions vers les unités canoniques de FishMap AI.
///
/// Unités canoniques : vitesse en km/h, longueur en mètres, période en
/// secondes, température en degrés Celsius, pression en hectopascals.
/// Les adaptateurs de fournisseurs convertissent leurs unités natives ici,
/// afin que les modèles du projet restent toujours normalisés.
class Units {
  const Units._();

  /// Mètres par seconde → kilomètres par heure.
  static double msToKmh(double metersPerSecond) => metersPerSecond * 3.6;

  /// Kilomètres par heure → mètres par seconde.
  static double kmhToMs(double kmh) => kmh / 3.6;

  /// Nœuds → kilomètres par heure.
  static double knotsToKmh(double knots) => knots * 1.852;

  /// Kilomètres par heure → nœuds.
  static double kmhToKnots(double kmh) => kmh / 1.852;

  /// Kelvin → degrés Celsius.
  static double kelvinToCelsius(double kelvin) => kelvin - 273.15;

  /// Degrés Fahrenheit → degrés Celsius.
  static double fahrenheitToCelsius(double fahrenheit) =>
      (fahrenheit - 32) * 5 / 9;

  /// Pascals → hectopascals.
  static double paToHpa(double pascals) => pascals / 100;

  /// Pouces de mercure → hectopascals.
  static double inHgToHpa(double inHg) => inHg * 33.8639;

  /// Pieds → mètres.
  static double feetToMeters(double feet) => feet * 0.3048;

  /// Milles nautiques → kilomètres.
  static double nauticalMilesToKm(double nm) => nm * 1.852;
}

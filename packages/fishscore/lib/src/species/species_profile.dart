import 'package:meta/meta.dart';

import '../models/enums.dart';

/// Plage horaire fermée \[startHour, endHour] en heures locales (0-23).
///
/// Peut traverser minuit lorsque [startHour] est supérieur à [endHour]
/// (ex. 21h → 2h).
@immutable
class HourWindow {
  const HourWindow(this.startHour, this.endHour)
      : assert(startHour >= 0 && startHour <= 23),
        assert(endHour >= 0 && endHour <= 23);

  final int startHour;
  final int endHour;

  /// Vrai si [hour] appartient à la fenêtre (bornes incluses).
  bool contains(int hour) {
    if (startHour <= endHour) {
      return hour >= startHour && hour <= endHour;
    }
    // Fenêtre traversant minuit.
    return hour >= startHour || hour <= endHour;
  }
}

/// Préférences de température et de saison d'une espèce.
@immutable
class ThermalPreference {
  const ThermalPreference({
    required this.idealMinC,
    required this.idealMaxC,
    required this.toleranceC,
    required this.seasonScores,
  });

  /// Bornes de la plage de température d'eau idéale.
  final double idealMinC;
  final double idealMaxC;

  /// Largeur de décroissance de part et d'autre de la plage idéale.
  final double toleranceC;

  /// Note de saison (0-100) par saison.
  final Map<Season, int> seasonScores;

  int seasonScore(Season season) => seasonScores[season] ?? 50;
}

/// Profil de calibration d'une espèce pour le moteur FishScore.
///
/// Les valeurs sont une première calibration prudente pour la zone
/// Solenzara–Aléria. Elles constituent des hypothèses tant qu'elles ne sont
/// pas confirmées par des sources fiables ou un volume suffisant
/// d'observations terrain.
@immutable
class SpeciesProfile {
  const SpeciesProfile({
    required this.slug,
    required this.commonNameFr,
    required this.windIdealMaxKmh,
    required this.windTolerableMaxKmh,
    required this.waveIdealMinM,
    required this.waveIdealMaxM,
    required this.waveFalloffM,
    required this.primeHours,
    required this.goodHours,
    required this.baselineHourScore,
    required this.thermal,
    required this.preferredBottoms,
    required this.depthIdealMinM,
    required this.depthIdealMaxM,
    required this.depthFalloffM,
    required this.favorsSpringTide,
    this.weightOverrides = const {},
  });

  /// Identifiant stable de l'espèce.
  final String slug;

  /// Nom commun français.
  final String commonNameFr;

  /// Vent (km/h) jusqu'auquel les conditions restent idéales.
  final double windIdealMaxKmh;

  /// Vent (km/h) au-delà duquel la note de vent tombe à zéro.
  final double windTolerableMaxKmh;

  /// Bornes de houle (m) considérées comme idéales.
  final double waveIdealMinM;
  final double waveIdealMaxM;

  /// Largeur de décroissance de la note de houle hors de la plage idéale.
  final double waveFalloffM;

  /// Fenêtres horaires les plus favorables (note 100).
  final List<HourWindow> primeHours;

  /// Fenêtres horaires favorables (note intermédiaire).
  final List<HourWindow> goodHours;

  /// Note attribuée aux heures hors fenêtres favorables.
  final int baselineHourScore;

  /// Préférences thermiques et saisonnières.
  final ThermalPreference thermal;

  /// Fonds préférés et note de compatibilité associée (0-100).
  final Map<BottomType, int> preferredBottoms;

  /// Plage de profondeur idéale (m).
  final double depthIdealMinM;
  final double depthIdealMaxM;
  final double depthFalloffM;

  /// Vrai si l'espèce est réputée plus active en vive-eau (hypothèse).
  final bool favorsSpringTide;

  /// Surcharges de poids de composantes propres à l'espèce (identifiant → poids).
  final Map<String, double> weightOverrides;

  /// Note horaire (0-100) pour une heure locale donnée.
  int hourScore(int hour) {
    if (primeHours.any((HourWindow w) => w.contains(hour))) return 100;
    if (goodHours.any((HourWindow w) => w.contains(hour))) return 70;
    return baselineHourScore;
  }

  /// Note de fond (0-100) pour un type de fond donné.
  int bottomScore(BottomType bottom) {
    if (bottom == BottomType.unknown) return 50;
    return preferredBottoms[bottom] ?? 35;
  }
}

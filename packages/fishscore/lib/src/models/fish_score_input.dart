import 'package:meta/meta.dart';

import 'enums.dart';
import 'local_history.dart';
import 'moon_phase.dart';

/// Ensemble des entrées nécessaires à une évaluation FishScore.
///
/// Tous les champs météo/marins sont optionnels : le moteur renormalise les
/// poids sur les composantes réellement disponibles et abaisse la confiance
/// lorsque des données manquent.
@immutable
class FishScoreInput {
  const FishScoreInput({
    required this.speciesSlug,
    required this.evaluatedAt,
    this.spotSuitability,
    this.bottomType = BottomType.unknown,
    this.depthMeters,
    this.windSpeedKmh,
    this.gustSpeedKmh,
    this.waveHeightM,
    this.wavePeriodS,
    this.pressureHpa,
    this.pressureTrendHpaPer3h,
    this.seaTemperatureC,
    this.airTemperatureC,
    this.moonPhase,
    this.history = const LocalHistory(),
    this.spotQuality = DataQuality.estimated,
    this.weatherObservedAt,
    Season? season,
  }) : _season = season;

  /// Identifiant de l'espèce ciblée (ex. `barracuda`, `loup`).
  final String speciesSlug;

  /// Instant pour lequel les conditions sont évaluées (UTC recommandé).
  final DateTime evaluatedAt;

  /// Compatibilité connue du spot pour l'espèce (0-100), si renseignée.
  final int? spotSuitability;

  /// Nature du fond au niveau du spot.
  final BottomType bottomType;

  /// Profondeur estimée au spot, en mètres.
  final double? depthMeters;

  /// Vitesse du vent en km/h.
  final double? windSpeedKmh;

  /// Vitesse des rafales en km/h.
  final double? gustSpeedKmh;

  /// Hauteur de houle significative en mètres.
  final double? waveHeightM;

  /// Période de houle en secondes.
  final double? wavePeriodS;

  /// Pression atmosphérique en hectopascals.
  final double? pressureHpa;

  /// Tendance de pression sur 3 heures (hPa), négative si en baisse.
  final double? pressureTrendHpaPer3h;

  /// Température de l'eau en degrés Celsius.
  final double? seaTemperatureC;

  /// Température de l'air en degrés Celsius.
  final double? airTemperatureC;

  /// Phase lunaire au moment de l'évaluation.
  final MoonPhase? moonPhase;

  /// Historique local et personnel pour ce couple spot/espèce.
  final LocalHistory history;

  /// Qualité de la source décrivant le spot.
  final DataQuality spotQuality;

  /// Date d'observation de la donnée météo, pour estimer sa fraîcheur.
  final DateTime? weatherObservedAt;

  final Season? _season;

  /// Saison de l'évaluation, déduite de [evaluatedAt] si non fournie.
  Season get season => _season ?? Season.fromMonth(evaluatedAt.month);

  /// Heure locale de l'évaluation, entre 0 et 23.
  int get hourOfDay => evaluatedAt.hour;

  /// Âge de la donnée météo par rapport à l'évaluation, si connu.
  Duration? get weatherAge {
    final DateTime? observed = weatherObservedAt;
    if (observed == null) return null;
    final Duration age = evaluatedAt.difference(observed);
    return age.isNegative ? Duration.zero : age;
  }
}

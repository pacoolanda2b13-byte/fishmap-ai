import 'package:fishscore/fishscore.dart';
import 'package:meta/meta.dart';

/// Contexte non météo d'un spot, nécessaire pour assembler une entrée
/// FishScore complète.
///
/// Sépare clairement les données du spot (compatibilité, fond, profondeur,
/// qualité de source, historique) des données météo, afin que la composition
/// ne mélange pas les deux responsabilités.
@immutable
class SpotContext {
  const SpotContext({
    this.spotSuitability,
    this.bottomType = BottomType.unknown,
    this.depthMeters,
    this.spotQuality = DataQuality.estimated,
    this.history = const LocalHistory(),
  });

  /// Compatibilité connue du spot pour l'espèce (0-100).
  final int? spotSuitability;

  /// Nature du fond au niveau du spot.
  final BottomType bottomType;

  /// Profondeur estimée au spot, en mètres.
  final double? depthMeters;

  /// Qualité de la source décrivant le spot.
  final DataQuality spotQuality;

  /// Historique local et personnel pour le couple spot/espèce.
  final LocalHistory history;
}

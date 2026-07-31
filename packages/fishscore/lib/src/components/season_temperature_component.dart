import '../models/fish_score_input.dart';
import '../scoring/scoring_math.dart';
import '../species/species_profile.dart';
import 'score_component.dart';

/// Évalue l'adéquation saison + température de l'eau.
///
/// La saison est toujours disponible (déduite de la date) ; la température de
/// l'eau affine la note lorsqu'elle est connue.
class SeasonTemperatureComponent implements ScoreComponent {
  const SeasonTemperatureComponent();

  @override
  String get id => 'season_temperature';

  @override
  String get label => 'Saison et température';

  @override
  double get defaultWeight => 0.15;

  @override
  ComponentEvaluation? evaluate(FishScoreInput input, SpeciesProfile species) {
    final double seasonNote =
        species.thermal.seasonScore(input.season).toDouble();

    final double? seaTemp = input.seaTemperatureC;
    double note;
    if (seaTemp != null) {
      final double tempNote = ScoringMath.plateau(
        value: seaTemp,
        idealMin: species.thermal.idealMinC,
        idealMax: species.thermal.idealMaxC,
        falloff: species.thermal.toleranceC,
      );
      // La température de l'eau prime lorsqu'elle est mesurée.
      note = 0.4 * seasonNote + 0.6 * tempNote;
    } else {
      note = seasonNote;
    }

    final int score = note.round();
    return ComponentEvaluation(
      score,
      positiveFactor:
          score >= 70 ? 'Période de l\'année favorable à l\'espèce' : null,
      negativeFactor: score <= 40 ? 'Saison peu favorable à l\'espèce' : null,
    );
  }
}

import '../models/fish_score_input.dart';
import '../scoring/scoring_math.dart';
import '../species/species_profile.dart';
import 'score_component.dart';

/// Évalue l'effet du vent (et des rafales) sur les conditions de pêche.
class WindComponent implements ScoreComponent {
  const WindComponent();

  @override
  String get id => 'wind';

  @override
  String get label => 'Vent';

  @override
  double get defaultWeight => 0.15;

  @override
  ComponentEvaluation? evaluate(FishScoreInput input, SpeciesProfile species) {
    final double? wind = input.windSpeedKmh;
    if (wind == null) return null;

    double note = ScoringMath.lowerIsBetter(
      value: wind,
      best: species.windIdealMaxKmh,
      worst: species.windTolerableMaxKmh,
    );

    // Les rafales fortes dégradent le confort et la lisibilité de l'eau.
    final double? gust = input.gustSpeedKmh;
    if (gust != null && gust > species.windTolerableMaxKmh) {
      note *= 0.7;
    }

    final int score = note.round();
    return ComponentEvaluation(
      score,
      positiveFactor:
          score >= 70 ? 'Vent compatible avec l\'exposition du spot' : null,
      negativeFactor: score <= 40 ? 'Vent trop soutenu' : null,
    );
  }
}

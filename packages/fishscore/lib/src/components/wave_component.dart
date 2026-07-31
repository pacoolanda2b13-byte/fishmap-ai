import '../models/fish_score_input.dart';
import '../scoring/scoring_math.dart';
import '../species/species_profile.dart';
import 'score_component.dart';

/// Évalue la houle : certaines espèces apprécient une eau légèrement agitée,
/// d'autres une mer calme.
class WaveComponent implements ScoreComponent {
  const WaveComponent();

  @override
  String get id => 'waves';

  @override
  String get label => 'Houle';

  @override
  double get defaultWeight => 0.15;

  @override
  ComponentEvaluation? evaluate(FishScoreInput input, SpeciesProfile species) {
    final double? wave = input.waveHeightM;
    if (wave == null) return null;

    final double note = ScoringMath.plateau(
      value: wave,
      idealMin: species.waveIdealMinM,
      idealMax: species.waveIdealMaxM,
      falloff: species.waveFalloffM,
    );

    final int score = note.round();
    final bool tooBig = wave > species.waveIdealMaxM;
    return ComponentEvaluation(
      score,
      positiveFactor: score >= 70 ? 'Houle favorable pour l\'espèce' : null,
      negativeFactor: score <= 40
          ? (tooBig ? 'Mer trop formée' : 'Mer trop plate pour l\'activité')
          : null,
    );
  }
}

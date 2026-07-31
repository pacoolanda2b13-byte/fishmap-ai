import '../models/fish_score_input.dart';
import '../scoring/scoring_math.dart';
import '../species/species_profile.dart';
import 'score_component.dart';

/// Évalue l'historique local et personnel pour le couple spot/espèce.
///
/// N'utilise que des données agrégées : le taux de réussite quand il est
/// connu, sinon le volume de signaux disponibles. Reste prudent tant que le
/// volume d'observations est faible.
class HistoryComponent implements ScoreComponent {
  const HistoryComponent();

  @override
  String get id => 'history';

  @override
  String get label => 'Historique local';

  @override
  double get defaultWeight => 0.10;

  @override
  ComponentEvaluation? evaluate(FishScoreInput input, SpeciesProfile species) {
    final history = input.history;
    if (history.isEmpty) return null;

    double note;
    final double? successRate = history.successRate;
    if (successRate != null) {
      // On rapproche la note de 50 tant que l'échantillon est petit.
      final double sampleWeight =
          ScoringMath.clampDouble(history.totalSignals / 8, 0, 1);
      note = 50 + (successRate * 100 - 50) * sampleWeight;
    } else {
      // Sans taux de réussite, seul le volume d'activité informe la note.
      note = 40 +
          ScoringMath.saturating(count: history.totalSignals, halfway: 6) * 0.4;
    }

    final int score = note.round();
    return ComponentEvaluation(
      score,
      positiveFactor: score >= 70 ? 'Bon historique local sur ce couple' : null,
      negativeFactor: score <= 40 ? 'Historique local encore limité' : null,
    );
  }
}

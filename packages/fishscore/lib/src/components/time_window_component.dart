import '../models/fish_score_input.dart';
import '../species/species_profile.dart';
import 'score_component.dart';

/// Évalue l'heure de la sortie selon les fenêtres d'activité de l'espèce
/// (aube, crépuscule, nuit pour les prédateurs).
class TimeWindowComponent implements ScoreComponent {
  const TimeWindowComponent();

  @override
  String get id => 'time_window';

  @override
  String get label => 'Créneau horaire';

  @override
  double get defaultWeight => 0.15;

  @override
  ComponentEvaluation? evaluate(FishScoreInput input, SpeciesProfile species) {
    final int score = species.hourScore(input.hourOfDay);
    return ComponentEvaluation(
      score,
      positiveFactor:
          score >= 70 ? 'Créneau favorable pour l\'espèce ciblée' : null,
      negativeFactor: score <= 40 ? 'Heure peu propice à l\'activité' : null,
    );
  }
}

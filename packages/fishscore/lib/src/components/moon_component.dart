import '../models/fish_score_input.dart';
import '../species/species_profile.dart';
import 'score_component.dart';

/// Évalue l'influence de la phase lunaire (poids faible, hypothèse à valider).
///
/// Pour les espèces réputées plus actives en vive-eau, la proximité d'une
/// nouvelle ou pleine lune est favorable. Pour les autres, l'effet reste
/// volontairement neutre.
class MoonComponent implements ScoreComponent {
  const MoonComponent();

  @override
  String get id => 'moon';

  @override
  String get label => 'Lune';

  @override
  double get defaultWeight => 0.05;

  @override
  ComponentEvaluation? evaluate(FishScoreInput input, SpeciesProfile species) {
    final moon = input.moonPhase;
    if (moon == null) return null;

    final double note;
    if (species.favorsSpringTide) {
      note = 40 + moon.springTideProximity * 55;
    } else {
      // Effet faible : légère préférence pour les marées de morte-eau.
      note = 50 + (1 - moon.springTideProximity) * 15;
    }

    final int score = note.round();
    return ComponentEvaluation(
      score,
      positiveFactor: score >= 75 && species.favorsSpringTide
          ? 'Marées de vive-eau favorables'
          : null,
      negativeFactor: null,
    );
  }
}

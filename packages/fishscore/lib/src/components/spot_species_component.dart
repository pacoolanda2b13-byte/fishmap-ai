import '../models/enums.dart';
import '../models/fish_score_input.dart';
import '../scoring/scoring_math.dart';
import '../species/species_profile.dart';
import 'score_component.dart';

/// Compatibilité du spot pour l'espèce ciblée.
///
/// Combine la compatibilité connue du spot (si renseignée), la nature du fond
/// et la profondeur, en s'appuyant sur le profil de l'espèce.
class SpotSpeciesComponent implements ScoreComponent {
  const SpotSpeciesComponent();

  @override
  String get id => 'spot_species';

  @override
  String get label => 'Compatibilité spot / espèce';

  @override
  double get defaultWeight => 0.25;

  @override
  ComponentEvaluation? evaluate(FishScoreInput input, SpeciesProfile species) {
    final List<double> notes = <double>[];

    final int? suitability = input.spotSuitability;
    if (suitability != null) {
      notes.add(suitability.toDouble());
    }

    if (input.bottomType != BottomType.unknown) {
      notes.add(species.bottomScore(input.bottomType).toDouble());
    }

    final double? depth = input.depthMeters;
    if (depth != null) {
      notes.add(ScoringMath.plateau(
        value: depth,
        idealMin: species.depthIdealMinM,
        idealMax: species.depthIdealMaxM,
        falloff: species.depthFalloffM,
      ));
    }

    if (notes.isEmpty) return null;

    final double average = notes.reduce((a, b) => a + b) / notes.length;
    final int score = average.round();

    return ComponentEvaluation(
      score,
      positiveFactor: score >= 70
          ? 'Spot bien adapté au ${species.commonNameFr.toLowerCase()}'
          : null,
      negativeFactor: score <= 40
          ? 'Spot peu favorable au ${species.commonNameFr.toLowerCase()}'
          : null,
    );
  }
}

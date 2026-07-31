/// FishScore — moteur de scoring explicable de FishMap AI.
///
/// Point d'entrée public du package. Exemple :
///
/// ```dart
/// final engine = FishScoreEngine();
/// final result = engine.evaluate(FishScoreInput(
///   speciesSlug: 'loup',
///   evaluatedAt: DateTime.utc(2026, 10, 15, 7),
///   windSpeedKmh: 18,
///   waveHeightM: 0.6,
///   seaTemperatureC: 17,
/// ));
/// print('${result.score}/100 — ${result.level.labelFr}');
/// ```
library;

export 'src/components/score_component.dart'
    show ComponentEvaluation, ScoreComponent;
export 'src/engine/fish_score_engine.dart'
    show FishScoreEngine, UnknownSpeciesException;
export 'src/models/enums.dart';
export 'src/models/fish_score_input.dart';
export 'src/models/fish_score_result.dart';
export 'src/models/knowledge.dart';
export 'src/models/local_history.dart';
export 'src/models/moon_phase.dart';
export 'src/species/species_catalog.dart';
export 'src/species/species_profile.dart';

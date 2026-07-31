// Démonstration du moteur FishScore.
//
// Exécuter avec : dart run example/fishscore_example.dart
import 'package:fishscore/fishscore.dart';

void main() {
  final FishScoreEngine engine = FishScoreEngine();

  // Une sortie loup, au crépuscule d'automne, avec de bonnes conditions.
  final FishScoreInput input = FishScoreInput(
    speciesSlug: 'loup',
    evaluatedAt: DateTime.utc(2026, 10, 15, 19),
    spotSuitability: 78,
    bottomType: BottomType.rock,
    depthMeters: 5,
    windSpeedKmh: 16,
    waveHeightM: 0.7,
    pressureTrendHpaPer3h: -2.0,
    seaTemperatureC: 17.5,
    moonPhase: MoonPhase.newMoon,
    history: const LocalHistory(observationCount: 6, userCatchCount: 3),
    spotQuality: DataQuality.observed,
    weatherObservedAt: DateTime.utc(2026, 10, 15, 18, 30),
  );

  final FishScoreResult result = engine.evaluate(input);
  print('FishScore : ${result.score}/100 (${result.level.labelFr})');
  print('Confiance : ${result.confidence}/100');
  print('Explication : ${result.explanation}');
  print('Atouts : ${result.positiveFactors}');
  print('Réserves : ${result.negativeFactors}');

  // Meilleur créneau sur la journée.
  final FishScoreResult best = engine.evaluateBestWindow(
    input,
    from: DateTime.utc(2026, 10, 15, 4),
    to: DateTime.utc(2026, 10, 15, 23),
  );
  final BestWindow? window = best.bestWindow;
  if (window != null) {
    print('Meilleur créneau : ${window.start.hour}h–${window.end.hour}h '
        '(score ${window.score})');
  }
}

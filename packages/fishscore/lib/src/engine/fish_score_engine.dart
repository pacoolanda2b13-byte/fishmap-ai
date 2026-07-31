import '../components/history_component.dart';
import '../components/moon_component.dart';
import '../components/score_component.dart';
import '../components/season_temperature_component.dart';
import '../components/spot_species_component.dart';
import '../components/time_window_component.dart';
import '../components/wave_component.dart';
import '../components/wind_component.dart';
import '../models/enums.dart';
import '../models/fish_score_input.dart';
import '../models/fish_score_result.dart';
import '../scoring/scoring_math.dart';
import '../species/species_catalog.dart';
import '../species/species_profile.dart';

/// Levée lorsque le slug d'espèce fourni ne correspond à aucun profil connu.
class UnknownSpeciesException implements Exception {
  const UnknownSpeciesException(this.slug);
  final String slug;
  @override
  String toString() => 'UnknownSpeciesException: espèce inconnue "$slug"';
}

/// Moteur de scoring FishScore v1.
///
/// Le moteur est déterministe : les mêmes entrées produisent toujours la même
/// sortie. Il est aussi extensible : la liste des composantes et le catalogue
/// d'espèces peuvent être remplacés pour faire évoluer le modèle sans changer
/// le reste de l'application.
class FishScoreEngine {
  FishScoreEngine({
    List<ScoreComponent>? components,
    Map<String, SpeciesProfile>? speciesProfiles,
    this.modelVersion = defaultModelVersion,
  })  : components = components ?? _defaultComponents,
        speciesProfiles = speciesProfiles ?? SpeciesCatalog.all;

  /// Version du modèle par défaut, alignée sur la spécification FishScore v1.
  static const String defaultModelVersion = 'fishscore-v1.0.0';

  /// Composantes pondérées standard, dans l'ordre d'importance.
  static const List<ScoreComponent> _defaultComponents = <ScoreComponent>[
    SpotSpeciesComponent(),
    WindComponent(),
    WaveComponent(),
    TimeWindowComponent(),
    SeasonTemperatureComponent(),
    HistoryComponent(),
    MoonComponent(),
  ];

  /// Limite (±) du modificateur de pression appliqué au score.
  static const double _maxPressureModifier = 0.06;

  final List<ScoreComponent> components;
  final Map<String, SpeciesProfile> speciesProfiles;
  final String modelVersion;

  /// Évalue une combinaison spot / espèce / créneau et renvoie un résultat
  /// explicable.
  ///
  /// Lève [UnknownSpeciesException] si l'espèce est inconnue.
  FishScoreResult evaluate(FishScoreInput input) {
    final SpeciesProfile? species = speciesProfiles[input.speciesSlug];
    if (species == null) {
      throw UnknownSpeciesException(input.speciesSlug);
    }
    return _evaluateWith(input, species);
  }

  FishScoreResult _evaluateWith(FishScoreInput input, SpeciesProfile species) {
    final List<_Evaluated> evaluated = <_Evaluated>[];
    double availableWeight = 0;
    double weightedSum = 0;

    for (final ScoreComponent component in components) {
      final double weight = _weightFor(component, species);
      final ComponentEvaluation? evaluation =
          component.evaluate(input, species);
      evaluated.add(_Evaluated(component, weight, evaluation));
      if (evaluation != null) {
        availableWeight += weight;
        weightedSum += evaluation.score * weight;
      }
    }

    // Renormalisation sur les composantes disponibles.
    final double baseScore =
        availableWeight > 0 ? weightedSum / availableWeight : 0;

    // Modificateur de pression, borné et déterministe.
    final _PressureSignal pressure = _pressureSignal(input);
    final double adjusted = baseScore * (1 + pressure.modifier);
    final int score = adjusted.round().clamp(0, 100);

    final List<ComponentScore> componentScores = <ComponentScore>[
      for (final _Evaluated e in evaluated)
        ComponentScore(
          id: e.component.id,
          label: e.component.label,
          score: e.evaluation?.score,
          weight: availableWeight > 0 && e.evaluation != null
              ? e.weight / availableWeight
              : 0,
          available: e.evaluation != null,
        ),
    ];

    final int confidence = _confidence(input, evaluated, availableWeight);

    final _Factors factors = _collectFactors(evaluated, pressure);

    final String explanation = _buildExplanation(
      species: species,
      score: score,
      confidence: confidence,
      factors: factors,
    );

    return FishScoreResult(
      score: score,
      confidence: confidence,
      modelVersion: modelVersion,
      positiveFactors: factors.positive,
      negativeFactors: factors.negative,
      components: componentScores,
      explanation: explanation,
    );
  }

  double _weightFor(ScoreComponent component, SpeciesProfile species) =>
      species.weightOverrides[component.id] ?? component.defaultWeight;

  _PressureSignal _pressureSignal(FishScoreInput input) {
    final double? trend = input.pressureTrendHpaPer3h;
    if (trend == null) {
      return const _PressureSignal(modifier: 0);
    }
    // Pression en baisse : favorable. En hausse : défavorable.
    final double modifier = ScoringMath.clampDouble(
      -trend * 0.02,
      -_maxPressureModifier,
      _maxPressureModifier,
    );
    String? positive;
    String? negative;
    if (trend <= -1.5) {
      positive = 'Pression en baisse, activité souvent meilleure';
    } else if (trend >= 1.5) {
      negative = 'Pression en hausse, activité souvent réduite';
    }
    return _PressureSignal(
      modifier: modifier,
      positiveFactor: positive,
      negativeFactor: negative,
    );
  }

  int _confidence(
    FishScoreInput input,
    List<_Evaluated> evaluated,
    double availableWeight,
  ) {
    // Couverture : fraction pondérée des composantes disponibles.
    final double totalWeight = evaluated.fold<double>(
      0,
      (double acc, _Evaluated e) => acc + e.weight,
    );
    final double coverage = totalWeight > 0 ? availableWeight / totalWeight : 0;

    // Fraîcheur météo.
    final double freshness = _weatherFreshness(input);

    // Qualité de la source du spot.
    final double sourceQuality = input.spotQuality.confidenceFactor;

    // Quantité d'observations locales.
    final double observations =
        ScoringMath.saturating(count: input.history.totalSignals, halfway: 6) /
            100;

    final double confidence = 0.40 * coverage +
        0.20 * freshness +
        0.20 * sourceQuality +
        0.20 * observations;

    return (confidence * 100).round().clamp(0, 100);
  }

  double _weatherFreshness(FishScoreInput input) {
    final Duration? age = input.weatherAge;
    if (age != null) {
      return ScoringMath.freshnessDecay(
        ageHours: age.inMinutes / 60,
        halfLifeHours: 12,
      );
    }
    final bool hasWeather = input.windSpeedKmh != null ||
        input.waveHeightM != null ||
        input.seaTemperatureC != null ||
        input.pressureHpa != null;
    return hasWeather ? 0.4 : 0;
  }

  _Factors _collectFactors(
    List<_Evaluated> evaluated,
    _PressureSignal pressure,
  ) {
    final List<String> positive = <String>[];
    final List<String> negative = <String>[];

    if (pressure.positiveFactor != null) positive.add(pressure.positiveFactor!);
    if (pressure.negativeFactor != null) negative.add(pressure.negativeFactor!);

    for (final _Evaluated e in evaluated) {
      final ComponentEvaluation? ev = e.evaluation;
      if (ev == null) continue;
      final String? pos = ev.positiveFactor;
      final String? neg = ev.negativeFactor;
      if (pos != null && positive.length < 3) positive.add(pos);
      if (neg != null && negative.length < 3) negative.add(neg);
    }

    return _Factors(
      positive: positive.take(3).toList(growable: false),
      negative: negative.take(3).toList(growable: false),
    );
  }

  String _buildExplanation({
    required SpeciesProfile species,
    required int score,
    required int confidence,
    required _Factors factors,
  }) {
    final ScoreLevel level = ScoreLevel.fromScore(score);
    final StringBuffer buffer = StringBuffer()
      ..write('Niveau ${level.labelFr.toLowerCase()} pour le '
          '${species.commonNameFr.toLowerCase()} (score $score/100). ');

    if (factors.positive.isNotEmpty) {
      buffer.write('Atouts : ${factors.positive.join(', ')}. ');
    }
    if (factors.negative.isNotEmpty) {
      buffer.write('Réserves : ${factors.negative.join(', ')}. ');
    }
    if (confidence < 40) {
      buffer.write('Données limitées : estimation à confirmer.');
    }
    return buffer.toString().trim();
  }

  /// Recherche le meilleur créneau horaire sur un intervalle.
  ///
  /// Balaye [from] à [to] par pas de [step] en réévaluant l'heure. Renvoie le
  /// résultat du meilleur instant, enrichi d'un [BestWindow] couvrant les
  /// instants contigus dont le score reste dans [windowTolerance] du maximum.
  FishScoreResult evaluateBestWindow(
    FishScoreInput baseInput, {
    required DateTime from,
    required DateTime to,
    Duration step = const Duration(minutes: 30),
    int windowTolerance = 10,
  }) {
    assert(!to.isBefore(from), 'to must not be before from');
    assert(step.inMinutes > 0, 'step must be positive');

    final List<_TimedResult> samples = <_TimedResult>[];
    DateTime cursor = from;
    while (!cursor.isAfter(to)) {
      final FishScoreInput at = _withEvaluatedAt(baseInput, cursor);
      samples.add(_TimedResult(cursor, evaluate(at)));
      cursor = cursor.add(step);
    }

    if (samples.isEmpty) {
      return evaluate(_withEvaluatedAt(baseInput, from));
    }

    _TimedResult best = samples.first;
    for (final _TimedResult sample in samples) {
      if (sample.result.score > best.result.score) best = sample;
    }

    // Étend la fenêtre autour du maximum tant que le score reste proche.
    final int threshold = best.result.score - windowTolerance;
    final int bestIndex = samples.indexOf(best);
    DateTime start = best.time;
    DateTime end = best.time;
    for (int i = bestIndex; i >= 0; i--) {
      if (samples[i].result.score >= threshold) {
        start = samples[i].time;
      } else {
        break;
      }
    }
    for (int i = bestIndex; i < samples.length; i++) {
      if (samples[i].result.score >= threshold) {
        end = samples[i].time;
      } else {
        break;
      }
    }

    final BestWindow window = BestWindow(
      start: start,
      end: end.add(step),
      score: best.result.score,
    );

    final FishScoreResult r = best.result;
    return FishScoreResult(
      score: r.score,
      confidence: r.confidence,
      modelVersion: r.modelVersion,
      positiveFactors: r.positiveFactors,
      negativeFactors: r.negativeFactors,
      components: r.components,
      explanation: r.explanation,
      bestWindow: window,
    );
  }

  FishScoreInput _withEvaluatedAt(FishScoreInput input, DateTime at) {
    return FishScoreInput(
      speciesSlug: input.speciesSlug,
      evaluatedAt: at,
      spotSuitability: input.spotSuitability,
      bottomType: input.bottomType,
      depthMeters: input.depthMeters,
      windSpeedKmh: input.windSpeedKmh,
      gustSpeedKmh: input.gustSpeedKmh,
      waveHeightM: input.waveHeightM,
      wavePeriodS: input.wavePeriodS,
      pressureHpa: input.pressureHpa,
      pressureTrendHpaPer3h: input.pressureTrendHpaPer3h,
      seaTemperatureC: input.seaTemperatureC,
      airTemperatureC: input.airTemperatureC,
      moonPhase: input.moonPhase,
      history: input.history,
      spotQuality: input.spotQuality,
      weatherObservedAt: input.weatherObservedAt,
    );
  }
}

class _Evaluated {
  const _Evaluated(this.component, this.weight, this.evaluation);
  final ScoreComponent component;
  final double weight;
  final ComponentEvaluation? evaluation;
}

class _PressureSignal {
  const _PressureSignal({
    required this.modifier,
    this.positiveFactor,
    this.negativeFactor,
  });
  final double modifier;
  final String? positiveFactor;
  final String? negativeFactor;
}

class _Factors {
  const _Factors({required this.positive, required this.negative});
  final List<String> positive;
  final List<String> negative;
}

class _TimedResult {
  const _TimedResult(this.time, this.result);
  final DateTime time;
  final FishScoreResult result;
}

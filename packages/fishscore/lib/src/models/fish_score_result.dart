import 'package:meta/meta.dart';

import 'enums.dart';

/// Détail d'une composante ayant contribué au score.
@immutable
class ComponentScore {
  const ComponentScore({
    required this.id,
    required this.label,
    required this.score,
    required this.weight,
    required this.available,
  });

  /// Identifiant technique (ex. `wind`, `spot_species`).
  final String id;

  /// Libellé lisible (français) de la composante.
  final String label;

  /// Note de la composante (0-100), ou `null` si la donnée est absente.
  final int? score;

  /// Poids effectif appliqué après renormalisation (0..1).
  final double weight;

  /// Vrai si la donnée nécessaire à cette composante était disponible.
  final bool available;
}

/// Créneau recommandé, produit par un balayage temporel.
@immutable
class BestWindow {
  const BestWindow({
    required this.start,
    required this.end,
    required this.score,
  });

  /// Début du créneau.
  final DateTime start;

  /// Fin du créneau.
  final DateTime end;

  /// Meilleur score atteint sur le créneau.
  final int score;
}

/// Résultat explicable d'une évaluation FishScore.
///
/// Le score compare des créneaux et des spots ; il ne représente jamais une
/// probabilité de capture et ne doit pas être présenté comme une garantie.
@immutable
class FishScoreResult {
  const FishScoreResult({
    required this.score,
    required this.confidence,
    required this.modelVersion,
    required this.positiveFactors,
    required this.negativeFactors,
    required this.components,
    required this.explanation,
    this.bestWindow,
  });

  /// Score global entre 0 et 100.
  final int score;

  /// Confiance du modèle entre 0 et 100 selon la qualité des données.
  final int confidence;

  /// Version du modèle, pour rendre les résultats reproductibles.
  final String modelVersion;

  /// Facteurs favorables (au maximum trois).
  final List<String> positiveFactors;

  /// Facteurs défavorables (au maximum trois).
  final List<String> negativeFactors;

  /// Détail par composante.
  final List<ComponentScore> components;

  /// Explication textuelle prête pour l'affichage.
  final String explanation;

  /// Créneau recommandé, si un balayage temporel a été demandé.
  final BestWindow? bestWindow;

  /// Niveau qualitatif dérivé du score.
  ScoreLevel get level => ScoreLevel.fromScore(score);

  /// Vrai lorsque la confiance est trop faible pour être exploitée sans réserve.
  bool get hasLimitedData => confidence < 40;

  /// Composantes indexées par identifiant, pour un accès direct.
  Map<String, int?> get componentScores => {
        for (final ComponentScore c in components) c.id: c.score,
      };

  /// Représentation JSON alignée sur le contrat FishScore v1.
  Map<String, dynamic> toJson() => {
        'score': score,
        'confidence': confidence,
        'level': level.name,
        'model_version': modelVersion,
        'positive_factors': positiveFactors,
        'negative_factors': negativeFactors,
        'component_scores': {
          for (final ComponentScore c in components)
            if (c.available) c.id: c.score,
        },
        'explanation': explanation,
        if (bestWindow != null)
          'best_window': {
            'start': bestWindow!.start.toIso8601String(),
            'end': bestWindow!.end.toIso8601String(),
            'score': bestWindow!.score,
          },
      };
}

import '../models/fish_score_input.dart';
import '../species/species_profile.dart';

/// Évaluation produite par une composante du score.
class ComponentEvaluation {
  ComponentEvaluation(this.score, {this.positiveFactor, this.negativeFactor})
      : assert(score >= 0 && score <= 100);

  /// Note de la composante, entre 0 et 100.
  final int score;

  /// Argument favorable à afficher lorsque la composante est bonne.
  final String? positiveFactor;

  /// Argument défavorable à afficher lorsque la composante est mauvaise.
  final String? negativeFactor;
}

/// Contrat d'une composante du moteur FishScore.
///
/// Une composante transforme une partie des conditions en note 0-100. Elle
/// retourne `null` lorsque la donnée nécessaire est absente : le moteur
/// renormalise alors les poids sur les composantes disponibles.
abstract interface class ScoreComponent {
  /// Identifiant technique stable (ex. `wind`).
  String get id;

  /// Libellé lisible en français.
  String get label;

  /// Poids de base dans le score global (0..1). Les poids sont renormalisés.
  double get defaultWeight;

  /// Évalue la composante, ou retourne `null` si la donnée est indisponible.
  ComponentEvaluation? evaluate(FishScoreInput input, SpeciesProfile species);
}

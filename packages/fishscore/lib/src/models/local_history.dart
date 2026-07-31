import 'package:meta/meta.dart';

/// Historique agrégé pour un couple spot/espèce.
///
/// Sépare les observations locales (toutes sources confondues) et l'historique
/// personnel de l'utilisateur. Aucune donnée nominative d'autrui n'est utilisée :
/// seules des valeurs agrégées et anonymisées sont attendues ici.
@immutable
class LocalHistory {
  const LocalHistory({
    this.observationCount = 0,
    this.userCatchCount = 0,
    this.userSessionCount = 0,
    this.successRate,
  })  : assert(observationCount >= 0),
        assert(userCatchCount >= 0),
        assert(userSessionCount >= 0),
        assert(successRate == null || (successRate >= 0 && successRate <= 1));

  /// Nombre d'observations agrégées (captures signalées, relevés terrain).
  final int observationCount;

  /// Nombre de captures enregistrées par l'utilisateur sur ce couple.
  final int userCatchCount;

  /// Nombre de sorties de l'utilisateur sur ce couple.
  final int userSessionCount;

  /// Taux de réussite observé (captures / sorties), entre 0 et 1, si connu.
  final double? successRate;

  /// Vrai lorsqu'aucune donnée d'historique n'est disponible.
  bool get isEmpty =>
      observationCount == 0 &&
      userCatchCount == 0 &&
      userSessionCount == 0 &&
      successRate == null;

  /// Volume total de signaux disponibles, utilisé pour pondérer la confiance.
  int get totalSignals => observationCount + userCatchCount + userSessionCount;
}

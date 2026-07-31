/// Briques communes de FishMap AI.
///
/// Règle d'architecture : les packages métier (`fishscore`, `weather`, …) ne
/// dépendent que de `core`, jamais entre eux. `core` ne contient donc aucune
/// logique métier — uniquement des primitives réutilisables.
library;

export 'src/config/app_config.dart';
export 'src/errors/app_exception.dart';
export 'src/errors/failure.dart';
export 'src/geo/coordinates.dart';
export 'src/geo/distance.dart';
export 'src/logging/logger.dart';
export 'src/result/result.dart';
export 'src/time/time_provider.dart';
export 'src/units/units.dart';

/// Exception de base de FishMap AI.
///
/// À réserver aux erreurs de programmation ou aux situations irrécupérables.
/// Les échecs métier attendus passent par `Failure` + `Result`.
class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() =>
      '$runtimeType: $message${cause == null ? '' : ' (cause: $cause)'}';
}

/// Configuration manquante ou invalide.
class ConfigException extends AppException {
  const ConfigException(super.message, {super.cause});
}

/// Donnée invalide détectée à une frontière du système.
class ValidationException extends AppException {
  const ValidationException(super.message, {super.cause});
}

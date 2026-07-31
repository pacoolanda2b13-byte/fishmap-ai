import 'package:meta/meta.dart';

/// Échec métier explicite, transporté par `Result`.
///
/// Contrairement à une exception, un [Failure] est une valeur : il se propage
/// dans les types de retour, se compare et se journalise sans interrompre le
/// flux. Les codes sont stables et utilisables côté API.
@immutable
abstract class Failure {
  const Failure({required this.code, required this.message, this.cause});

  /// Code stable, en SCREAMING_SNAKE_CASE (ex. `NETWORK_ERROR`).
  final String code;

  /// Message lisible destiné aux journaux et au débogage.
  final String message;

  /// Cause d'origine éventuelle (exception, autre échec…).
  final Object? cause;

  @override
  String toString() =>
      '$runtimeType($code: $message${cause == null ? '' : ', cause: $cause'})';
}

/// Échec réseau ou fournisseur distant injoignable.
class NetworkFailure extends Failure {
  const NetworkFailure(String message, {super.cause})
      : super(code: 'NETWORK_ERROR', message: message);
}

/// Délai dépassé.
class TimeoutFailure extends Failure {
  const TimeoutFailure(String message, {super.cause})
      : super(code: 'TIMEOUT', message: message);
}

/// Donnée d'entrée invalide.
class ValidationFailure extends Failure {
  const ValidationFailure(String message, {super.cause})
      : super(code: 'VALIDATION_ERROR', message: message);
}

/// Ressource introuvable.
class NotFoundFailure extends Failure {
  const NotFoundFailure(String message, {super.cause})
      : super(code: 'NOT_FOUND', message: message);
}

/// Donnée indisponible (service dégradé, cache vide, fournisseur muet).
class UnavailableFailure extends Failure {
  const UnavailableFailure(String message, {super.cause})
      : super(code: 'UNAVAILABLE', message: message);
}

/// Échec inattendu, non typé.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure(String message, {super.cause})
      : super(code: 'UNEXPECTED', message: message);
}

/// Agrégat de plusieurs échecs (ex. tous les fournisseurs ont échoué).
class CompositeFailure extends Failure {
  CompositeFailure(String message, this.failures)
      : super(
          code: 'COMPOSITE',
          message:
              '$message (${failures.map((Failure f) => f.code).join(', ')})',
        );

  /// Échecs individuels, dans l'ordre où ils se sont produits.
  final List<Failure> failures;
}

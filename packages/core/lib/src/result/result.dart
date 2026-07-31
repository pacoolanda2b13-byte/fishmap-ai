import '../errors/failure.dart';

/// Résultat explicite d'une opération : succès porteur d'une valeur, ou échec
/// porteur d'un [Failure].
///
/// Utilisé par toutes les frontières susceptibles d'échouer (réseau, parsing,
/// stockage) afin que l'appelant soit obligé de considérer le cas d'échec.
sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(Failure failure) = FailureResult<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is FailureResult<T>;

  /// Valeur en cas de succès, sinon `null`.
  T? get valueOrNull => switch (this) {
        Success<T>(:final T value) => value,
        FailureResult<T>() => null,
      };

  /// Échec le cas échéant, sinon `null`.
  Failure? get failureOrNull => switch (this) {
        Success<T>() => null,
        FailureResult<T>(:final Failure failure) => failure,
      };

  /// Réduit le résultat en une seule valeur.
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure failure) onFailure,
  }) =>
      switch (this) {
        Success<T>(:final T value) => onSuccess(value),
        FailureResult<T>(:final Failure failure) => onFailure(failure),
      };

  /// Transforme la valeur en cas de succès, propage l'échec sinon.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Success<T>(:final T value) => Result<R>.success(transform(value)),
        FailureResult<T>(:final Failure failure) => Result<R>.failure(failure),
      };

  /// Enchaîne une opération pouvant elle-même échouer.
  Result<R> flatMap<R>(Result<R> Function(T value) transform) => switch (this) {
        Success<T>(:final T value) => transform(value),
        FailureResult<T>(:final Failure failure) => Result<R>.failure(failure),
      };

  /// Valeur en cas de succès, sinon le produit de [orElse].
  T getOrElse(T Function(Failure failure) orElse) => switch (this) {
        Success<T>(:final T value) => value,
        FailureResult<T>(:final Failure failure) => orElse(failure),
      };
}

/// Succès porteur d'une valeur.
final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;

  @override
  String toString() => 'Success($value)';
}

/// Échec porteur d'un [Failure].
final class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);
  final Failure failure;

  @override
  String toString() => 'FailureResult($failure)';
}

/// Fournit l'heure courante.
///
/// Injecter un [TimeProvider] plutôt qu'appeler `DateTime.now()` rend le code
/// dépendant du temps testable et déterministe.
abstract interface class TimeProvider {
  /// Instant courant en UTC.
  DateTime nowUtc();
}

/// Horloge système réelle.
class SystemTimeProvider implements TimeProvider {
  const SystemTimeProvider();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

/// Horloge fixe et pilotable, pour les tests.
class FixedTimeProvider implements TimeProvider {
  FixedTimeProvider(DateTime instant) : _current = instant.toUtc();

  DateTime _current;

  @override
  DateTime nowUtc() => _current;

  /// Avance l'horloge de [duration].
  void advance(Duration duration) {
    _current = _current.add(duration);
  }

  /// Positionne l'horloge à [instant].
  void set(DateTime instant) {
    _current = instant.toUtc();
  }
}

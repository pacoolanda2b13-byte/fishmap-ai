/// Niveaux de journalisation, du plus verbeux au plus grave.
enum LogLevel {
  debug,
  info,
  warning,
  error;

  bool operator >=(LogLevel other) => index >= other.index;
}

/// Contrat de journalisation de FishMap AI.
///
/// Règle de confidentialité : ne jamais journaliser de coordonnées exactes,
/// de jetons ni de données personnelles. Les implémentations reçoivent des
/// messages déjà expurgés.
abstract class Logger {
  const Logger();

  void log(LogLevel level, String message, {Object? error});

  void debug(String message) => log(LogLevel.debug, message);
  void info(String message) => log(LogLevel.info, message);
  void warning(String message, {Object? error}) =>
      log(LogLevel.warning, message, error: error);
  void error(String message, {Object? error}) =>
      log(LogLevel.error, message, error: error);
}

/// Logger silencieux (défaut sûr pour les bibliothèques).
class NoopLogger extends Logger {
  const NoopLogger();

  @override
  void log(LogLevel level, String message, {Object? error}) {}
}

/// Logger console simple, avec niveau minimal et sortie injectable.
class ConsoleLogger extends Logger {
  ConsoleLogger({this.minLevel = LogLevel.info, void Function(String)? output})
      : _output = output ?? _printOutput;

  final LogLevel minLevel;
  final void Function(String) _output;

  static void _printOutput(String line) {
    // ignore: avoid_print — sortie console voulue pour ce logger.
    print(line);
  }

  @override
  void log(LogLevel level, String message, {Object? error}) {
    if (!(level >= minLevel)) return;
    final String suffix = error == null ? '' : ' | $error';
    _output('[${level.name.toUpperCase()}] $message$suffix');
  }
}

/// Logger en mémoire, destiné aux tests.
class MemoryLogger extends Logger {
  MemoryLogger();

  final List<LogRecord> records = <LogRecord>[];

  @override
  void log(LogLevel level, String message, {Object? error}) {
    records.add(LogRecord(level, message, error: error));
  }

  bool hasMessageContaining(String fragment) =>
      records.any((LogRecord r) => r.message.contains(fragment));
}

/// Entrée de journal capturée par [MemoryLogger].
class LogRecord {
  const LogRecord(this.level, this.message, {this.error});
  final LogLevel level;
  final String message;
  final Object? error;
}

/**
 * Journalisation structurée (une ligne JSON par événement).
 *
 * Règle de confidentialité du projet : aucune coordonnée exacte, aucun jeton,
 * aucune donnée personnelle ne doit apparaître dans les journaux. Les
 * coordonnées sont donc arrondies avant d'être tracées.
 */

export type LogLevel = "debug" | "info" | "warn" | "error";

export interface LogFields {
  [key: string]: unknown;
}

export interface Logger {
  log(level: LogLevel, message: string, fields?: LogFields): void;
  debug(message: string, fields?: LogFields): void;
  info(message: string, fields?: LogFields): void;
  warn(message: string, fields?: LogFields): void;
  error(message: string, fields?: LogFields): void;
}

/** Arrondit une coordonnée à ~1 km, pour ne jamais journaliser un point exact. */
export function coarseCoordinate(value: number): number {
  return Math.round(value * 100) / 100;
}

/** Journalise en JSON sur la sortie standard. */
export function createLogger(
  requestId: string,
  sink: (line: string) => void = console.log,
): Logger {
  const emit = (level: LogLevel, message: string, fields?: LogFields): void => {
    sink(JSON.stringify({
      timestamp: new Date().toISOString(),
      level,
      request_id: requestId,
      message,
      ...fields,
    }));
  };

  return {
    log: emit,
    debug: (message, fields) => emit("debug", message, fields),
    info: (message, fields) => emit("info", message, fields),
    warn: (message, fields) => emit("warn", message, fields),
    error: (message, fields) => emit("error", message, fields),
  };
}

/**
 * Assertions minimales pour les tests Deno.
 *
 * Volontairement sans dépendance externe : les tests restent exécutables hors
 * ligne et dans un environnement CI dont l'accès réseau est restreint.
 */

export class AssertionError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "AssertionError";
  }
}

/** Échoue si [condition] est fausse. */
export function assert(
  condition: unknown,
  message = "assertion échouée",
): asserts condition {
  if (!condition) throw new AssertionError(message);
}

/** Échoue si [actual] et [expected] diffèrent (comparaison structurelle). */
export function assertEquals<T>(actual: T, expected: T, message?: string): void {
  const a = JSON.stringify(actual);
  const b = JSON.stringify(expected);
  if (a !== b) {
    throw new AssertionError(
      `${message ? message + " — " : ""}attendu ${b}, obtenu ${a}`,
    );
  }
}

/** Échoue si [value] est `null` ou `undefined`. */
export function assertExists<T>(
  value: T,
  message = "valeur absente",
): asserts value is NonNullable<T> {
  if (value === null || value === undefined) {
    throw new AssertionError(message);
  }
}

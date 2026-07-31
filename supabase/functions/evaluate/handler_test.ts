/**
 * Tests du gestionnaire `POST /evaluate`.
 *
 * Le pont Dart réel est exercé — seules les entrées/sorties sont simulées :
 * les réponses Open-Meteo proviennent des fixtures du paquet adaptateur, et le
 * cache est une simple table en mémoire. La chaîne complète est donc validée
 * sans réseau ni base de données.
 */

import { assert, assertEquals, assertExists } from "../_shared/assert.ts";
import { createHandler, type HandlerDeps } from "./handler.ts";

const fixtureDir = "../../../packages/weather_openmeteo/test/fixtures";

const forecastFixture = await Deno.readTextFile(
  new URL(`${fixtureDir}/forecast_solenzara.json`, import.meta.url),
);
const marineFixture = await Deno.readTextFile(
  new URL(`${fixtureDir}/marine_solenzara.json`, import.meta.url),
);

interface Harness {
  handler: (request: Request) => Promise<Response>;
  cache: Map<string, string>;
  logs: string[];
  upstreamUrls: string[];
}

function harness(overrides: Partial<HandlerDeps> = {}): Harness {
  const cache = new Map<string, string>();
  const logs: string[] = [];
  const upstreamUrls: string[] = [];

  const deps: HandlerDeps = {
    cacheTtlSeconds: 3600,
    cacheRead: (key) => Promise.resolve(cache.get(key) ?? null),
    cacheWrite: (key, json) => {
      cache.set(key, json);
      return Promise.resolve();
    },
    httpGet: (url) => {
      upstreamUrls.push(url);
      const body = url.includes("marine") ? marineFixture : forecastFixture;
      return Promise.resolve(JSON.stringify({ status: 200, body }));
    },
    createLogger: (requestId) => ({
      log: (level, message, fields) =>
        logs.push(JSON.stringify({ level, requestId, message, ...fields })),
      debug: (m, f) => logs.push(JSON.stringify({ level: "debug", m, ...f })),
      info: (m, f) => logs.push(JSON.stringify({ level: "info", m, ...f })),
      warn: (m, f) => logs.push(JSON.stringify({ level: "warn", m, ...f })),
      error: (m, f) => logs.push(JSON.stringify({ level: "error", m, ...f })),
    }),
    newRequestId: () => "test-request-id",
    ...overrides,
  };

  return { handler: createHandler(deps), cache, logs, upstreamUrls };
}

function post(body: unknown): Request {
  return new Request("http://localhost/evaluate", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: typeof body === "string" ? body : JSON.stringify(body),
  });
}

const validBody = {
  latitude: 41.86,
  longitude: 9.4,
  date: "2026-10-15T19:00:00Z",
};

// ---------------------------------------------------------------- CORS

Deno.test("CORS — la requête préalable renvoie 204 avec les en-têtes", async () => {
  const { handler } = harness();
  const response = await handler(
    new Request("http://localhost/evaluate", { method: "OPTIONS" }),
  );

  assertEquals(response.status, 204);
  assertEquals(response.headers.get("Access-Control-Allow-Methods"), "POST, OPTIONS");
  assertExists(response.headers.get("Access-Control-Allow-Origin"));
});

Deno.test("CORS — les réponses portent les en-têtes", async () => {
  const { handler } = harness();
  const response = await handler(post(validBody));

  assertExists(response.headers.get("Access-Control-Allow-Origin"));
  assertEquals(response.headers.get("Content-Type"), "application/json");
  await response.body?.cancel();
});

// ------------------------------------------------------------- Méthodes

Deno.test("refuse les méthodes autres que POST", async () => {
  const { handler } = harness();
  for (const method of ["GET", "PUT", "DELETE"]) {
    const response = await handler(
      new Request("http://localhost/evaluate", { method }),
    );
    assertEquals(response.status, 405, method);
    const body = await response.json();
    assertEquals(body.error.code, "METHOD_NOT_ALLOWED");
  }
});

// ------------------------------------------------------------ Validation

Deno.test("rejette un corps vide", async () => {
  const { handler } = harness();
  const response = await handler(post(""));

  assertEquals(response.status, 400);
  const body = await response.json();
  assertEquals(body.error.code, "VALIDATION_ERROR");
});

Deno.test("rejette un corps JSON invalide", async () => {
  const { handler } = harness();
  const response = await handler(post("{ ceci n'est pas du JSON"));

  assertEquals(response.status, 400);
  const body = await response.json();
  assertEquals(body.error.code, "VALIDATION_ERROR");
});

Deno.test("la validation métier vient du pont Dart", async () => {
  const { handler } = harness();

  const missing = await handler(post({ longitude: 9.4 }));
  assertEquals(missing.status, 400);
  const missingBody = await missing.json();
  assertEquals(missingBody.error.code, "VALIDATION_ERROR");
  assert(missingBody.error.message.includes("latitude"));

  const outOfRange = await handler(post({ latitude: 200, longitude: 9.4 }));
  assertEquals(outOfRange.status, 400);
  await outOfRange.body?.cancel();
});

Deno.test("espèce inconnue renvoie 404", async () => {
  const { handler } = harness();
  const response = await handler(post({ ...validBody, species: "thon-rouge" }));

  assertEquals(response.status, 404);
  const body = await response.json();
  assertEquals(body.error.code, "NOT_FOUND");
});

// ----------------------------------------------------------- Cas nominal

Deno.test("évalue toutes les espèces à partir des données Open-Meteo", async () => {
  const { handler, upstreamUrls } = harness();
  const response = await handler(post(validBody));

  assertEquals(response.status, 200);
  const body = await response.json();

  assertEquals(body.location, { lat: 41.86, lng: 9.4 });
  assertEquals(body.evaluated_at, "2026-10-15T19:00:00.000Z");
  assert(body.results.length >= 4, "les espèces MVP sont évaluées");

  // Les deux API Open-Meteo ont bien été interrogées.
  assert(upstreamUrls.some((u) => u.includes("api.open-meteo.com")));
  assert(upstreamUrls.some((u) => u.includes("marine-api.open-meteo.com")));
});

Deno.test("chaque résultat respecte le contrat FishScore", async () => {
  const { handler } = harness();
  const response = await handler(post(validBody));
  const body = await response.json();

  for (const result of body.results) {
    assertEquals(typeof result.species, "string");
    assertEquals(typeof result.score, "number");
    assertEquals(typeof result.confidence, "number");
    assertEquals(typeof result.evidence_score, "number");
    assertEquals(typeof result.explanation, "string");
    assertEquals(typeof result.model_version, "string");
    assert(result.score >= 0 && result.score <= 100);
    assert(result.confidence >= 0 && result.confidence <= 100);
    assertEquals(result.provenance.weather_provider, "open-meteo");
    assertExists(result.provenance.species_confidence);
  }
});

Deno.test("les résultats sont classés par score décroissant", async () => {
  const { handler } = harness();
  const response = await handler(post(validBody));
  const body = await response.json();

  const scores = body.results.map((r: { score: number }) => r.score);
  const sorted = [...scores].sort((a: number, b: number) => b - a);
  assertEquals(scores, sorted);
});

Deno.test("filtre sur une espèce", async () => {
  const { handler } = harness();
  const response = await handler(post({ ...validBody, species: "loup" }));
  const body = await response.json();

  assertEquals(body.results.length, 1);
  assertEquals(body.results[0].species, "loup");
});

// --------------------------------------------------------------- Cache

Deno.test("cache miss puis hit : le fournisseur n'est plus appelé", async () => {
  const { handler, cache, upstreamUrls } = harness();

  await (await handler(post(validBody))).body?.cancel();
  const callsAfterFirst = upstreamUrls.length;
  assert(callsAfterFirst > 0, "premier appel : cache vide");
  assert(cache.size > 0, "la réponse est enregistrée");

  await (await handler(post(validBody))).body?.cancel();
  assertEquals(
    upstreamUrls.length,
    callsAfterFirst,
    "second appel : servi depuis le cache",
  );
});

Deno.test("la réponse indique une météo issue du cache", async () => {
  const { handler } = harness();

  await (await handler(post({ ...validBody, species: "loup" }))).body?.cancel();
  const second = await handler(post({ ...validBody, species: "loup" }));
  const body = await second.json();

  assertEquals(body.results[0].provenance.weather_from_cache, true);
});

Deno.test("le TTL est respecté : une entrée périmée est ignorée", async () => {
  const cache = new Map<string, string>();
  const upstreamUrls: string[] = [];

  const { handler } = harness({
    // TTL nul : l'entrée écrite est immédiatement périmée.
    cacheTtlSeconds: 0,
    cacheRead: (key) => Promise.resolve(cache.get(key) ?? null),
    cacheWrite: (key, json) => {
      cache.set(key, json);
      return Promise.resolve();
    },
    httpGet: (url) => {
      upstreamUrls.push(url);
      const body = url.includes("marine") ? marineFixture : forecastFixture;
      return Promise.resolve(JSON.stringify({ status: 200, body }));
    },
  });

  await (await handler(post(validBody))).body?.cancel();
  const afterFirst = upstreamUrls.length;
  await (await handler(post(validBody))).body?.cancel();

  assert(
    upstreamUrls.length > afterFirst,
    "entrée périmée : le fournisseur est rappelé",
  );
});

Deno.test("une position voisine profite du cache", async () => {
  const { handler, upstreamUrls } = harness();

  await (await handler(post(validBody))).body?.cancel();
  const afterFirst = upstreamUrls.length;

  // ~500 m plus loin : même clé de cache.
  await (await handler(post({ ...validBody, latitude: 41.864 }))).body?.cancel();
  assertEquals(upstreamUrls.length, afterFirst);
});

// -------------------------------------------------------------- Erreurs

Deno.test("fournisseur injoignable : 503 sans exception qui fuit", async () => {
  const { handler } = harness({
    httpGet: () => Promise.reject(new Error("connexion refusée")),
  });

  const response = await handler(post(validBody));
  assertEquals(response.status, 503);
  const body = await response.json();
  assertExists(body.error.code);
});

Deno.test("cache en panne : la requête aboutit quand même", async () => {
  const { handler, upstreamUrls } = harness({
    cacheRead: () => Promise.reject(new Error("base indisponible")),
    cacheWrite: () => Promise.reject(new Error("base indisponible")),
  });

  const response = await handler(post(validBody));

  // Le cache est un optimisateur, pas une dépendance critique : sa panne
  // dégrade les performances, jamais la disponibilité.
  assertEquals(response.status, 200);
  const body = await response.json();
  assert(body.results.length >= 4);
  assert(upstreamUrls.length > 0, "le fournisseur prend le relais");
});

Deno.test("réponse Open-Meteo illisible : erreur maîtrisée", async () => {
  const { handler } = harness({
    httpGet: () =>
      Promise.resolve(JSON.stringify({ status: 200, body: "<html>502</html>" })),
  });

  const response = await handler(post(validBody));
  assert(response.status >= 400, "l'erreur est signalée");
  const body = await response.json();
  assertExists(body.error);
});

// ----------------------------------------------------------------- Logs

Deno.test("journalise en JSON structuré sans coordonnée exacte", async () => {
  const { handler, logs } = harness();
  await (await handler(post({ ...validBody, latitude: 41.8637291 }))).body
    ?.cancel();

  assert(logs.length > 0, "au moins un événement journalisé");
  const parsed = logs.map((line) => JSON.parse(line));
  const served = parsed.find((entry) => entry.level === "info");
  assertExists(served, "l'issue de la requête est journalisée");

  assertEquals(typeof served.duration_ms, "number");
  assertEquals(typeof served.cache_hits, "number");
  assertEquals(typeof served.upstream_calls, "number");
  // La latitude est arrondie : jamais de position exacte dans les journaux.
  assertEquals(served.latitude, 41.86);
});

Deno.test("un refus est journalisé en avertissement", async () => {
  const { handler, logs } = harness();
  await (await handler(post({ longitude: 9.4 }))).body?.cancel();

  const parsed = logs.map((line) => JSON.parse(line));
  assert(parsed.some((entry) => entry.level === "warn"));
});

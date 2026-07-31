/**
 * Gestionnaire HTTP de `POST /evaluate`.
 *
 * Responsabilités **strictement** limitées au transport :
 * 1. répondre aux requêtes préalables CORS ;
 * 2. rejeter les méthodes et corps invalides ;
 * 3. fournir au pont Dart les entrées/sorties (HTTP sortant, cache) ;
 * 4. renvoyer la réponse JSON produite par le pont.
 *
 * Aucune règle métier n'est implémentée ici : validation des paramètres,
 * consultation du cache, repli entre fournisseurs, mapping météo et calcul
 * FishScore sont tous exécutés par le pont Dart.
 */

import { jsonResponse, preflightResponse } from "../_shared/cors.ts";
import {
  type CacheRead,
  type CacheWrite,
  callBridge,
  type HttpGet,
} from "../_shared/bridge.ts";
import { coarseCoordinate, createLogger, type Logger } from "../_shared/logger.ts";

/** Dépendances injectables, pour rendre le gestionnaire testable. */
export interface HandlerDeps {
  cacheRead: CacheRead;
  cacheWrite: CacheWrite;
  httpGet: HttpGet;
  cacheTtlSeconds: number;
  createLogger?: (requestId: string) => Logger;
  newRequestId?: () => string;
}

/** Corps d'erreur, au format du contrat API. */
function errorBody(code: string, message: string): unknown {
  return { error: { code, message, details: null } };
}

export function createHandler(
  deps: HandlerDeps,
): (request: Request) => Promise<Response> {
  const makeLogger = deps.createLogger ?? createLogger;
  const newId = deps.newRequestId ?? (() => crypto.randomUUID());

  return async function handle(request: Request): Promise<Response> {
    if (request.method === "OPTIONS") {
      return preflightResponse();
    }

    const requestId = newId();
    const logger = makeLogger(requestId);
    const startedAt = Date.now();

    if (request.method !== "POST") {
      logger.warn("méthode refusée", { method: request.method });
      return jsonResponse(
        errorBody("METHOD_NOT_ALLOWED", "Seul POST est accepté"),
        405,
      );
    }

    let rawBody: string;
    try {
      rawBody = await request.text();
    } catch (error) {
      logger.error("corps illisible", { error: String(error) });
      return jsonResponse(
        errorBody("VALIDATION_ERROR", "Corps de requête illisible"),
        400,
      );
    }

    if (rawBody.trim() === "") {
      logger.warn("corps vide");
      return jsonResponse(
        errorBody("VALIDATION_ERROR", "Corps de requête vide"),
        400,
      );
    }

    // Le contenu du corps n'est pas interprété ici : le pont Dart le valide.
    // On vérifie seulement qu'il s'agit de JSON, pour distinguer une erreur de
    // transport d'une erreur métier.
    try {
      JSON.parse(rawBody);
    } catch (_error) {
      logger.warn("corps JSON invalide");
      return jsonResponse(
        errorBody("VALIDATION_ERROR", "Corps de requête JSON invalide"),
        400,
      );
    }

    let cacheHits = 0;
    let cacheWrites = 0;
    let upstreamCalls = 0;

    try {
      const response = await callBridge(rawBody, {
        cacheTtlSeconds: deps.cacheTtlSeconds,
        httpGet: async (url) => {
          upstreamCalls++;
          return await deps.httpGet(url);
        },
        cacheRead: async (key) => {
          const value = await deps.cacheRead(key);
          if (value !== null) cacheHits++;
          return value;
        },
        cacheWrite: async (key, json) => {
          cacheWrites++;
          await deps.cacheWrite(key, json);
        },
      });

      logRequestOutcome(logger, {
        rawBody,
        status: response.status,
        startedAt,
        cacheHits,
        cacheWrites,
        upstreamCalls,
      });

      return jsonResponse(response.body, response.status);
    } catch (error) {
      logger.error("échec inattendu", {
        error: String(error),
        duration_ms: Date.now() - startedAt,
      });
      return jsonResponse(
        errorBody("UNEXPECTED", "Erreur interne lors de l'évaluation"),
        500,
      );
    }
  };
}

/** Journalise l'issue d'une requête, coordonnées volontairement arrondies. */
function logRequestOutcome(logger: Logger, context: {
  rawBody: string;
  status: number;
  startedAt: number;
  cacheHits: number;
  cacheWrites: number;
  upstreamCalls: number;
}): void {
  let latitude: number | undefined;
  let longitude: number | undefined;
  let species: unknown;
  try {
    const parsed = JSON.parse(context.rawBody) as Record<string, unknown>;
    if (typeof parsed.latitude === "number") {
      latitude = coarseCoordinate(parsed.latitude);
    }
    if (typeof parsed.longitude === "number") {
      longitude = coarseCoordinate(parsed.longitude);
    }
    species = parsed.species;
  } catch (_error) {
    // Corps déjà validé en amont ; on ne journalise simplement rien de plus.
  }

  const fields = {
    status: context.status,
    duration_ms: Date.now() - context.startedAt,
    cache_hits: context.cacheHits,
    cache_writes: context.cacheWrites,
    upstream_calls: context.upstreamCalls,
    latitude,
    longitude,
    species,
  };

  if (context.status >= 500) {
    logger.error("évaluation en échec", fields);
  } else if (context.status >= 400) {
    logger.warn("évaluation refusée", fields);
  } else {
    logger.info("évaluation servie", fields);
  }
}

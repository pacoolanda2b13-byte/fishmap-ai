/**
 * Accès au pont Dart compilé.
 *
 * Tout le calcul — validation métier, cache, repli entre fournisseurs,
 * mapping météo et FishScore — vit dans `bridge.js`, produit par
 * `packages/edge_bridge`. TypeScript ne fournit que les entrées/sorties, ce
 * qui évite de dupliquer la moindre règle métier côté Deno.
 */

import "./bridge.js";

/** Récupère une donnée du cache, ou `null` si absente ou périmée. */
export type CacheRead = (key: string) => Promise<string | null>;

/** Écrit une entrée sérialisée dans le cache. */
export type CacheWrite = (key: string, json: string) => Promise<void>;

/**
 * Exécute une requête GET.
 *
 * Renvoie une chaîne JSON `{"status": number, "body": string}` : un échange
 * par chaînes évite toute conversion de types complexe entre Dart et JS.
 */
export type HttpGet = (url: string) => Promise<string>;

/** Réponse produite par le pont : statut HTTP et corps déjà construits. */
export interface BridgeResponse {
  status: number;
  body: unknown;
}

type BridgeFunction = (
  requestJson: string,
  httpGet: HttpGet,
  cacheRead: CacheRead,
  cacheWrite: CacheWrite,
  cacheTtlSeconds: number,
) => Promise<string>;

/**
 * Appelle le pont Dart.
 *
 * @throws si `bridge.js` n'a pas été construit — voir
 * `tool/build_edge_bridge.sh`.
 */
export async function callBridge(
  requestJson: string,
  deps: {
    httpGet: HttpGet;
    cacheRead: CacheRead;
    cacheWrite: CacheWrite;
    cacheTtlSeconds: number;
  },
): Promise<BridgeResponse> {
  const bridge = (globalThis as Record<string, unknown>).fishmapEvaluate as
    | BridgeFunction
    | undefined;

  if (typeof bridge !== "function") {
    throw new Error(
      "Pont Dart introuvable : exécuter tool/build_edge_bridge.sh avant le déploiement",
    );
  }

  const raw = await bridge(
    requestJson,
    deps.httpGet,
    deps.cacheRead,
    deps.cacheWrite,
    deps.cacheTtlSeconds,
  );

  return JSON.parse(raw) as BridgeResponse;
}

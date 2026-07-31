/**
 * `POST /evaluate` — évaluation FishScore pour un point et un instant.
 *
 * Entrée :
 * ```json
 * { "latitude": 41.86, "longitude": 9.40,
 *   "date": "2026-10-15T19:00:00Z", "species": "loup" }
 * ```
 * `date` et `species` sont facultatifs : sans `date`, l'instant courant est
 * utilisé ; sans `species`, toutes les espèces actives sont évaluées.
 *
 * Sortie : score, confiance, evidence_score, explication et provenance pour
 * chaque espèce, classées par pertinence décroissante.
 *
 * Le calcul est intégralement délégué au pont Dart compilé : ce fichier ne
 * fait que câbler les entrées/sorties réelles (PostgreSQL, réseau).
 */

import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import { createHandler } from "./handler.ts";

/** Durée de validité des entrées de cache, en secondes. */
const cacheTtlSeconds = Number(Deno.env.get("WEATHER_CACHE_TTL_SECONDS") ?? 3600);

/** Délai maximal accordé à un appel au fournisseur météo. */
const upstreamTimeoutMs = Number(Deno.env.get("UPSTREAM_TIMEOUT_MS") ?? 10000);

function createServiceClient(): SupabaseClient {
  const url = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!url || !serviceRoleKey) {
    throw new Error(
      "SUPABASE_URL et SUPABASE_SERVICE_ROLE_KEY doivent être définis",
    );
  }

  // La table weather_cache est protégée par RLS sans politique permissive :
  // seul le rôle de service peut la lire et l'écrire.
  return createClient(url, serviceRoleKey, {
    auth: { persistSession: false },
  });
}

const supabase = createServiceClient();

const handler = createHandler({
  cacheTtlSeconds,

  /** Lit une entrée encore valide. La péremption est aussi vérifiée en Dart. */
  cacheRead: async (key) => {
    const { data, error } = await supabase
      .from("weather_cache")
      .select("payload")
      .eq("cache_key", key)
      .gt("expires_at", new Date().toISOString())
      .maybeSingle();

    if (error || !data) return null;
    return JSON.stringify(data.payload);
  },

  /**
   * Écrit une entrée.
   *
   * Les colonnes indexées (`provider_name`, `stored_at`, `expires_at`) sont
   * extraites de la charge utile produite par Dart : c'est une projection de
   * stockage, pas une règle métier.
   */
  cacheWrite: async (key, json) => {
    const payload = JSON.parse(json) as {
      provider_name: string;
      stored_at: string;
      expires_at: string;
    };

    await supabase.from("weather_cache").upsert({
      cache_key: key,
      provider_name: payload.provider_name,
      payload,
      stored_at: payload.stored_at,
      expires_at: payload.expires_at,
    }, { onConflict: "cache_key" });
  },

  /** Exécute l'appel sortant vers le fournisseur météo. */
  httpGet: async (url) => {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), upstreamTimeoutMs);
    try {
      const response = await fetch(url, { signal: controller.signal });
      const body = await response.text();
      return JSON.stringify({ status: response.status, body });
    } finally {
      clearTimeout(timer);
    }
  },
});

Deno.serve(handler);

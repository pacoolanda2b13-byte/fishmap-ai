/**
 * En-têtes CORS partagés par les fonctions FishMap AI.
 *
 * Le client Flutter appelle l'API depuis une origine web en développement et
 * depuis l'application native en production ; les requêtes préalables
 * (preflight) doivent donc être acceptées.
 */

/** Origines autorisées, ou `*` si la variable d'environnement est absente. */
const allowedOrigin = Deno.env.get("CORS_ALLOWED_ORIGIN") ?? "*";

export const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": allowedOrigin,
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Max-Age": "86400",
};

/** Réponse à une requête préalable CORS. */
export function preflightResponse(): Response {
  return new Response(null, { status: 204, headers: corsHeaders });
}

/** Construit une réponse JSON avec les en-têtes CORS. */
export function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

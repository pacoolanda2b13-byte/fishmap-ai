# Edge Functions

Fonctions serveur Supabase (Deno / TypeScript).

## Principe : aucune logique métier en TypeScript

Les Edge Functions tournent sous Deno alors que toute la logique FishMap est en
Dart. Plutôt que de réimplémenter FishScore en TypeScript — ce qui recréerait
la double source de vérité proscrite par le projet — la chaîne Dart est
**compilée en JavaScript** et TypeScript ne fournit que les entrées/sorties.

```
        Client Flutter
              │  POST /evaluate
              ▼
    ┌───────────────────────┐
    │ handler.ts            │  CORS · méthode · corps · journaux
    └──────────┬────────────┘
               │ corps brut + rappels d'E/S
               ▼
    ┌───────────────────────┐
    │ bridge.js (Dart)      │  validation · cache · repli · mapping · FishScore
    └───┬───────────────┬───┘
        │ cacheRead     │ httpGet
        │ cacheWrite    │
        ▼               ▼
   weather_cache    Open-Meteo
   (PostgreSQL)
```

TypeScript se limite donc à : recevoir la requête, vérifier la méthode et le
format du corps, fournir un `fetch` et un accès au cache, renvoyer le JSON.
**La validation des paramètres elle-même vient de Dart** : c'est le pont qui
produit les erreurs `VALIDATION_ERROR`.

## Construire le pont

`_shared/bridge.js` est un **artefact de construction**, absent du dépôt.

```bash
./tool/build_edge_bridge.sh
```

À exécuter avant tout déploiement et avant les tests.

## `POST /evaluate`

### Requête

```json
{
  "latitude": 41.86,
  "longitude": 9.40,
  "date": "2026-10-15T19:00:00Z",
  "species": "loup"
}
```

`date` (défaut : maintenant) et `species` (défaut : toutes les espèces) sont
facultatifs.

### Réponse `200`

```json
{
  "evaluated_at": "2026-10-15T19:00:00.000Z",
  "location": { "lat": 41.86, "lng": 9.4 },
  "results": [
    {
      "species": "loup",
      "common_name_fr": "Loup",
      "score": 78,
      "level": "good",
      "confidence": 62,
      "evidence_score": 20,
      "explanation": "Niveau bon pour le loup (score 78/100)…",
      "positive_factors": ["…"],
      "negative_factors": ["…"],
      "component_scores": { "wind": 88, "waves": 100, "…": 0 },
      "model_version": "fishscore-v1.0.0",
      "limited_data": false,
      "provenance": {
        "summary": "Météo : open-meteo. Connaissances : …",
        "weather_provider": "open-meteo",
        "weather_from_cache": true,
        "species_confidence": "hypothesis",
        "knowledge_summary": "…"
      }
    }
  ]
}
```

Les résultats sont classés par score décroissant : le premier est la
recommandation.

### Erreurs

| Statut | Code | Cause |
|---:|---|---|
| 400 | `VALIDATION_ERROR` | corps vide, JSON invalide, paramètre manquant ou hors bornes |
| 404 | `NOT_FOUND` | espèce inconnue |
| 405 | `METHOD_NOT_ALLOWED` | méthode autre que POST |
| 503 | `COMPOSITE` / `UNAVAILABLE` | aucun fournisseur météo disponible |
| 504 | `TIMEOUT` | délai dépassé côté fournisseur |
| 500 | `UNEXPECTED` | erreur interne |

Format : `{ "error": { "code": "...", "message": "...", "details": null } }`.

## Variables d'environnement

| Variable | Défaut | Rôle |
|---|---|---|
| `SUPABASE_URL` | — | fournie par le runtime Supabase |
| `SUPABASE_SERVICE_ROLE_KEY` | — | fournie par le runtime ; seul rôle autorisé sur `weather_cache` |
| `WEATHER_CACHE_TTL_SECONDS` | `3600` | durée de validité du cache |
| `UPSTREAM_TIMEOUT_MS` | `10000` | délai maximal par appel météo |
| `CORS_ALLOWED_ORIGIN` | `*` | origine autorisée ; à restreindre en production |

Aucun secret n'est stocké dans le dépôt.

## Développement

```bash
./tool/build_edge_bridge.sh        # obligatoire
cd supabase/functions
deno fmt && deno lint
deno test --allow-read --allow-env evaluate/handler_test.ts
```

Les tests exercent le **vrai pont compilé** sur les fixtures Open-Meteo : ni
réseau ni base de données ne sont requis.

## Déployer

```bash
./tool/build_edge_bridge.sh
supabase functions deploy evaluate
```

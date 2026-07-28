# FishMap AI — Contrat API MVP

Version: 0.1

## Principes

- API JSON sur HTTPS.
- Authentification via Supabase Auth et jeton JWT.
- Toutes les dates sont en ISO 8601 UTC.
- Les coordonnées privées ne sont jamais renvoyées sans autorisation.
- Les erreurs suivent un format stable.

## Format d’erreur

```json
{
  "error": {
    "code": "SPOT_NOT_FOUND",
    "message": "Spot introuvable",
    "details": null,
    "request_id": "uuid"
  }
}
```

## Endpoints MVP

### GET /v1/species
Retourne les espèces actives et leurs paramètres d’affichage.

### GET /v1/spots
Paramètres: `lat`, `lng`, `radius_km`, `species_id`, `technique`, `limit`.

Règles:
- rayon maximal MVP: 50 km ;
- spots publics uniquement pour un utilisateur non propriétaire ;
- coordonnées éventuellement arrondies selon le niveau de confidentialité.

### GET /v1/spots/{id}
Retourne la fiche d’un spot accessible, ses caractéristiques, espèces compatibles et informations de sécurité.

### POST /v1/session-plans
Entrée minimale:

```json
{
  "species_id": "uuid",
  "origin": {"lat": 42.05, "lng": 9.50},
  "desired_start_at": "2026-08-01T04:30:00Z",
  "max_distance_km": 30,
  "technique": "shore_lure"
}
```

Sortie:
- spot principal ;
- jusqu’à deux alternatives ;
- FishScore et niveau de confiance ;
- facteurs favorables et défavorables ;
- résumé météo ;
- matériel conseillé ;
- avertissements de sécurité.

### POST /v1/fish-scores/evaluate
Calcule un score explicable sans l’enregistrer automatiquement.

### GET /v1/session-plans/{id}
Accessible uniquement au propriétaire.

### POST /v1/catches
Crée une capture dans le journal personnel.

### PATCH /v1/catches/{id}
Modifie une capture appartenant à l’utilisateur.

### DELETE /v1/catches/{id}
Supprime une capture appartenant à l’utilisateur.

### POST /v1/favorites/{spot_id}
Ajoute un spot accessible aux favoris.

### DELETE /v1/favorites/{spot_id}
Retire le spot des favoris.

## Codes métier initiaux

- `AUTH_REQUIRED`
- `FORBIDDEN`
- `VALIDATION_ERROR`
- `SPOT_NOT_FOUND`
- `SPECIES_NOT_FOUND`
- `INSUFFICIENT_DATA`
- `WEATHER_UNAVAILABLE`
- `FISHSCORE_UNAVAILABLE`
- `RATE_LIMITED`

## Limites MVP

- 60 lectures par minute et par utilisateur ;
- 20 générations de plan par heure ;
- 5 Mo maximum par photo avant traitement ;
- pagination par curseur pour les listes.

## Versionnement

Les changements incompatibles créent une nouvelle version `/v2`. Les ajouts de champs facultatifs restent compatibles avec `/v1`.

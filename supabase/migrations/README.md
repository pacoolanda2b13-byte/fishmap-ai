# Migrations Supabase

Migrations versionnées, appliquées dans l'ordre lexicographique de leur nom.

## Convention

```
<AAAAMMJJHHMMSS>_<description_courte>.sql
```

Une migration est **immuable** une fois poussée : pour corriger, on en ajoute
une nouvelle. Chaque fichier doit être rejouable sur une base vierge et ne
jamais contenir de secret.

## Migrations

| Version | Contenu |
|---|---|
| `20260101000000_initial_schema` | schéma initial : profils, espèces, spots (PostGIS), plans de session, captures, favoris, exécutions FishScore, RLS |
| `20260201000000_weather_cache` | cache de prévisions météo (TTL, purge, RLS restrictive) |

## Appliquer

```bash
supabase db reset          # rejoue toutes les migrations en local
supabase db push           # applique les migrations manquantes à distance
supabase migration new <nom>
```

## Tests de schéma

`supabase/tests/` contient des contrôles de contrat exécutables sur une base
migrée (colonnes attendues, contraintes, politiques RLS).

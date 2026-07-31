-- FishMap AI — cache de prévisions météo
--
-- Support serveur du `WeatherCache` du package `weather`. Évite qu'une requête
-- utilisateur déclenche systématiquement un appel au fournisseur.
--
-- La clé est calculée côté application (coordonnées arrondies à ~5 km, fenêtre
-- alignée sur l'heure) : la base ne fait que stocker et servir. Elle ne connaît
-- donc aucun fournisseur.

create table public.weather_cache (
  cache_key text primary key,
  provider_name text not null,
  payload jsonb not null,
  stored_at timestamptz not null default now(),
  expires_at timestamptz not null,
  check (expires_at > stored_at)
);

comment on table public.weather_cache is
  'Cache de prévisions météo. cache_key est calculée par l''application.';
comment on column public.weather_cache.provider_name is
  'Fournisseur ayant produit la donnée, conservé pour la traçabilité.';
comment on column public.weather_cache.payload is
  'Entrée sérialisée (CachedForecast) telle qu''écrite par le package weather.';

-- Purge et lecture s'appuient toutes deux sur la péremption.
create index weather_cache_expires_at_idx on public.weather_cache(expires_at);

alter table public.weather_cache enable row level security;

-- Aucune politique permissive : le cache n'est accessible qu'au rôle de
-- service, utilisé par les fonctions serveur. Les clients n'y touchent jamais.

-- Supprime les entrées périmées. À appeler périodiquement (pg_cron ou tâche
-- planifiée) ; la lecture applicative évince déjà les entrées qu'elle croise.
create or replace function public.purge_expired_weather_cache()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  deleted_count integer;
begin
  delete from public.weather_cache where expires_at <= now();
  get diagnostics deleted_count = row_count;
  return deleted_count;
end;
$$;

comment on function public.purge_expired_weather_cache() is
  'Supprime les entrées de cache périmées et renvoie leur nombre.';

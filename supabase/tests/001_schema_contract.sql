-- FishMap AI — contrôles de contrat du schéma
-- À exécuter après les migrations dans une base de test Supabase/PostgreSQL.

begin;

-- Extensions indispensables
select 1 / count(*) from pg_extension where extname = 'postgis';

-- Tables indispensables
select 1 / count(*) from information_schema.tables where table_schema = 'public' and table_name = 'profiles';
select 1 / count(*) from information_schema.tables where table_schema = 'public' and table_name = 'species';
select 1 / count(*) from information_schema.tables where table_schema = 'public' and table_name = 'spots';
select 1 / count(*) from information_schema.tables where table_schema = 'public' and table_name = 'weather_snapshots';
select 1 / count(*) from information_schema.tables where table_schema = 'public' and table_name = 'fish_scores';
select 1 / count(*) from information_schema.tables where table_schema = 'public' and table_name = 'session_plans';
select 1 / count(*) from information_schema.tables where table_schema = 'public' and table_name = 'catches';
select 1 / count(*) from information_schema.tables where table_schema = 'public' and table_name = 'favorites';

-- RLS doit être activée sur les données personnelles.
do $$
declare
  missing_rls text;
begin
  select string_agg(c.relname, ', ')
  into missing_rls
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname in ('profiles', 'session_plans', 'catches', 'favorites')
    and c.relrowsecurity = false;

  if missing_rls is not null then
    raise exception 'RLS absente sur: %', missing_rls;
  end if;
end $$;

-- Les scores doivent rester bornés lorsqu'ils existent.
do $$
begin
  if exists (
    select 1 from public.fish_scores
    where score < 0 or score > 100
  ) then
    raise exception 'FishScore hors intervalle 0..100';
  end if;
end $$;

-- Aucune capture privée ne doit être anonyme.
do $$
begin
  if exists (
    select 1 from public.catches
    where user_id is null
  ) then
    raise exception 'Capture sans propriétaire';
  end if;
end $$;

rollback;

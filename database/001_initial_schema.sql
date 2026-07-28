-- FishMap AI — schéma initial MVP
-- Cible : Supabase PostgreSQL + PostGIS

create extension if not exists pgcrypto;
create extension if not exists postgis;

create type public.visibility_level as enum ('private', 'approximate', 'public');
create type public.spot_status as enum ('draft', 'verified', 'rejected', 'archived');
create type public.session_status as enum ('draft', 'planned', 'active', 'completed', 'cancelled');
create type public.data_quality as enum ('estimated', 'observed', 'verified');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text check (char_length(display_name) between 2 and 60),
  experience_level smallint not null default 1 check (experience_level between 1 and 5),
  preferred_shore_fishing boolean not null default true,
  default_visibility public.visibility_level not null default 'private',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.species (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  common_name_fr text not null,
  scientific_name text,
  active boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table public.techniques (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name_fr text not null,
  created_at timestamptz not null default now()
);

create table public.spots (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references public.profiles(id) on delete set null,
  name text not null check (char_length(name) between 2 and 120),
  description text,
  exact_location geography(point, 4326) not null,
  public_location geography(point, 4326),
  visibility public.visibility_level not null default 'private',
  status public.spot_status not null default 'draft',
  shore_access boolean not null default true,
  access_notes text,
  hazards text,
  source_quality public.data_quality not null default 'estimated',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  verified_at timestamptz,
  check (visibility <> 'public' or public_location is not null)
);

create index spots_exact_location_gix on public.spots using gist (exact_location);
create index spots_public_location_gix on public.spots using gist (public_location);
create index spots_status_idx on public.spots(status);
create index spots_owner_idx on public.spots(owner_id);

create table public.spot_species (
  spot_id uuid not null references public.spots(id) on delete cascade,
  species_id uuid not null references public.species(id) on delete cascade,
  suitability smallint not null default 50 check (suitability between 0 and 100),
  evidence_count integer not null default 0 check (evidence_count >= 0),
  notes text,
  primary key (spot_id, species_id)
);

create table public.weather_snapshots (
  id uuid primary key default gen_random_uuid(),
  location geography(point, 4326) not null,
  observed_for timestamptz not null,
  provider text not null,
  wind_speed_kmh numeric(6,2),
  wind_direction_deg smallint check (wind_direction_deg between 0 and 359),
  gust_speed_kmh numeric(6,2),
  wave_height_m numeric(5,2),
  wave_period_s numeric(5,2),
  sea_temperature_c numeric(5,2),
  air_temperature_c numeric(5,2),
  pressure_hpa numeric(7,2),
  precipitation_mm numeric(7,2),
  raw_payload jsonb not null default '{}'::jsonb,
  fetched_at timestamptz not null default now()
);

create index weather_location_gix on public.weather_snapshots using gist(location);
create index weather_observed_for_idx on public.weather_snapshots(observed_for desc);

create table public.session_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  target_species_id uuid references public.species(id) on delete set null,
  status public.session_status not null default 'draft',
  planned_start timestamptz not null,
  planned_end timestamptz,
  summary text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (planned_end is null or planned_end > planned_start)
);

create index session_plans_user_idx on public.session_plans(user_id, planned_start desc);

create table public.session_plan_spots (
  session_plan_id uuid not null references public.session_plans(id) on delete cascade,
  spot_id uuid not null references public.spots(id) on delete restrict,
  priority smallint not null check (priority between 1 and 3),
  planned_arrival timestamptz,
  notes text,
  primary key (session_plan_id, spot_id),
  unique (session_plan_id, priority)
);

create table public.fishscore_runs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete set null,
  spot_id uuid not null references public.spots(id) on delete cascade,
  species_id uuid not null references public.species(id) on delete cascade,
  weather_snapshot_id uuid references public.weather_snapshots(id) on delete set null,
  score smallint not null check (score between 0 and 100),
  confidence smallint not null check (confidence between 0 and 100),
  model_version text not null,
  positive_factors jsonb not null default '[]'::jsonb,
  negative_factors jsonb not null default '[]'::jsonb,
  component_scores jsonb not null default '{}'::jsonb,
  calculated_for timestamptz not null,
  created_at timestamptz not null default now()
);

create index fishscore_lookup_idx on public.fishscore_runs(spot_id, species_id, calculated_for desc);

create table public.catches (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  species_id uuid references public.species(id) on delete set null,
  spot_id uuid references public.spots(id) on delete set null,
  caught_at timestamptz not null,
  exact_location geography(point, 4326),
  visibility public.visibility_level not null default 'private',
  length_cm numeric(6,2) check (length_cm is null or length_cm > 0),
  weight_kg numeric(6,3) check (weight_kg is null or weight_kg > 0),
  lure_or_bait text,
  released boolean,
  photo_path text,
  notes text,
  created_at timestamptz not null default now()
);

create index catches_user_idx on public.catches(user_id, caught_at desc);
create index catches_location_gix on public.catches using gist(exact_location);

create table public.favorites (
  user_id uuid not null references public.profiles(id) on delete cascade,
  spot_id uuid not null references public.spots(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, spot_id)
);

insert into public.species (slug, common_name_fr, scientific_name) values
('barracuda', 'Barracuda', 'Sphyraena viridensis'),
('dorade-royale', 'Dorade royale', 'Sparus aurata'),
('loup', 'Loup', 'Dicentrarchus labrax'),
('liche', 'Liche amie', 'Lichia amia')
on conflict (slug) do nothing;

insert into public.techniques (slug, name_fr) values
('leurres-durs', 'Leurres durs'),
('leurres-souples', 'Leurres souples'),
('surfcasting', 'Surfcasting'),
('appats-naturels', 'Appâts naturels')
on conflict (slug) do nothing;

alter table public.profiles enable row level security;
alter table public.spots enable row level security;
alter table public.session_plans enable row level security;
alter table public.fishscore_runs enable row level security;
alter table public.catches enable row level security;
alter table public.favorites enable row level security;

create policy profiles_self_select on public.profiles for select using (auth.uid() = id);
create policy profiles_self_update on public.profiles for update using (auth.uid() = id);

create policy spots_public_or_owner_select on public.spots for select using (
  visibility = 'public' or owner_id = auth.uid()
);
create policy spots_owner_insert on public.spots for insert with check (owner_id = auth.uid());
create policy spots_owner_update on public.spots for update using (owner_id = auth.uid());
create policy spots_owner_delete on public.spots for delete using (owner_id = auth.uid());

create policy sessions_owner_all on public.session_plans for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy catches_owner_all on public.catches for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy favorites_owner_all on public.favorites for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy fishscore_owner_select on public.fishscore_runs for select using (user_id = auth.uid() or user_id is null);

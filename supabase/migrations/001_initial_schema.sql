-- MedTrack Supabase schema (Phases 2–10)
-- Apply in Supabase SQL editor or via CLI migrations.

create extension if not exists "pgcrypto";

create table if not exists profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  name text not null default '',
  date_of_birth timestamptz,
  blood_type text,
  allergies jsonb not null default '[]'::jsonb,
  role text not null default 'patient',
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

alter table profiles enable row level security;

create policy "Users read own profile"
  on profiles for select using (auth.uid() = user_id);

create policy "Users update own profile"
  on profiles for update using (auth.uid() = user_id);

create table if not exists sync_entities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  entity_type text not null,
  entity_id text not null,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  unique (user_id, entity_type, entity_id)
);

alter table sync_entities enable row level security;

create policy "Users sync own entities"
  on sync_entities for all using (auth.uid() = user_id);

create table if not exists family_links (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid references profiles(id),
  caregiver_id uuid references profiles(id),
  invite_code text,
  permissions jsonb not null default '{}'::jsonb,
  expires_at timestamptz,
  revoked_at timestamptz,
  updated_at timestamptz not null default now()
);

alter table family_links enable row level security;

create table if not exists dose_logs (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references profiles(id),
  medicine_id text,
  scheduled_at timestamptz,
  status text,
  updated_at timestamptz not null default now()
);

alter table dose_logs enable row level security;

-- Storage bucket for report images (create in dashboard):
-- reports bucket with RLS: user can read/write own folder user_id/*

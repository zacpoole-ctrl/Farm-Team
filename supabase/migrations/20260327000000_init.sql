-- ============================================================
-- LOEG Farm Team League — Supabase Schema
-- Run this entire file in your Supabase SQL Editor
-- Dashboard → SQL Editor → New Query → paste → Run
-- ============================================================


-- ============================================================
-- 1. LEAGUE STATE
--    Single-row table holding all owner/roster/PTBN data.
--    The whole leagueData object is stored as JSONB.
-- ============================================================
create table if not exists public.league_state (
  id         integer primary key default 1,          -- always row 1
  data       jsonb    not null,
  updated_at timestamptz not null default now(),
  updated_by text
);

-- Seed with empty placeholder (app will upsert real data on first save)
insert into public.league_state (id, data)
values (1, '{"owners":[]}'::jsonb)
on conflict (id) do nothing;


-- ============================================================
-- 2. ACTIVITY LOG
--    Append-only event stream. New entries added by the app,
--    never modified.
-- ============================================================
create table if not exists public.activity_log (
  id         bigserial primary key,
  ts         timestamptz not null default now(),
  type       text        not null,   -- 'trade' | 'draft' | 'roster' | ...
  actor      text        not null,
  details    text        not null
);

-- Index for fast reverse-chronological fetch
create index if not exists activity_log_ts_idx on public.activity_log (ts desc);


-- ============================================================
-- 3. TRADE PROPOSALS
--    Pending and resolved trade proposals.
-- ============================================================
create table if not exists public.trade_proposals (
  id          bigint primary key,                -- client-generated timestamp ID
  ts          timestamptz not null default now(),
  proposed_by text        not null,
  status      text        not null default 'pending',  -- 'pending' | 'approved' | 'rejected'
  side1       jsonb       not null,   -- {ownerId, ownerName, items:[{type,label,idx}]}
  side2       jsonb       not null,
  resolved_by text,
  resolved_ts timestamptz
);

create index if not exists trade_proposals_status_idx on public.trade_proposals (status);


-- ============================================================
-- 4. APP USERS
--    League member accounts. role: 'admin' | 'user'
--    ownerId links to leagueData.owners[].id
-- ============================================================
create table if not exists public.app_users (
  username   text primary key,
  password   text        not null,   -- plain text for now (upgrade to hashed later)
  email      text        not null default '',
  role       text        not null default 'user',
  owner_id   integer,                -- nullable — links to leagueData owner id
  created_at timestamptz not null default now()
);

-- Seed default admin accounts
insert into public.app_users (username, password, email, role, owner_id)
values
  ('admin',    'admin2026', '', 'admin', null),
  ('zacpoole', 'admin',     '', 'admin', 11)
on conflict (username) do nothing;


-- ============================================================
-- 5. ROW LEVEL SECURITY (RLS)
--    Allow the anon/service_role key full access.
--    The app handles its own auth logic — RLS here just
--    prevents random public writes if you ever expose the key.
--
--    IMPORTANT: In Supabase dashboard, go to each table →
--    "RLS" tab → Enable RLS, then these policies apply.
--    If you leave RLS disabled, the policies below are ignored
--    but the tables are still accessible via the anon key.
-- ============================================================

alter table public.league_state    enable row level security;
alter table public.activity_log    enable row level security;
alter table public.trade_proposals enable row level security;
alter table public.app_users       enable row level security;

-- Permissive read/write for anon key (browser app)
-- Tighten these once you add Supabase Auth in a future upgrade

create policy "anon full access league_state"
  on public.league_state for all
  to anon using (true) with check (true);

create policy "anon full access activity_log"
  on public.activity_log for all
  to anon using (true) with check (true);

create policy "anon full access trade_proposals"
  on public.trade_proposals for all
  to anon using (true) with check (true);

create policy "anon full access app_users"
  on public.app_users for all
  to anon using (true) with check (true);


-- ============================================================
-- 6. REALTIME
--    Enable realtime for live sync across all league members.
-- ============================================================

alter publication supabase_realtime add table public.league_state;
alter publication supabase_realtime add table public.activity_log;
alter publication supabase_realtime add table public.trade_proposals;
alter publication supabase_realtime add table public.app_users;

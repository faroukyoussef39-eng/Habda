-- Run once in the Supabase SQL editor.
-- Game state lives in these two tables. RLS is on with no policies, so only the
-- Vercel function (using the secret key, which bypasses RLS) can read them;
-- browsers can never see the real answer before the reveal.

create table if not exists public.rooms (
  pin        text primary key,
  version    integer     not null,          -- optimistic-concurrency counter
  state      jsonb       not null,          -- RoomState from api/_lib/engine.ts
  updated_at timestamptz not null default now()
);

create table if not exists public.presence (
  pin       text   not null references public.rooms (pin) on delete cascade,
  player_id text   not null,
  seen      bigint not null,                -- epoch ms of the player's last request
  primary key (pin, player_id)
);

alter table public.rooms    enable row level security;
alter table public.presence enable row level security;

-- Questions added or edited from the in-app admin panel. A row whose id matches a
-- built-in question (api/_lib/questions.ts) overrides it; deleting the row restores it.
create table if not exists public.custom_questions (
  id         text primary key,
  data       jsonb       not null,              -- Question from api/_lib/engine.ts
  updated_at timestamptz not null default now()
);

alter table public.custom_questions enable row level security;

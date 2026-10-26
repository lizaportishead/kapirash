-- Облачная копия того, что пользователь накопил в приложении: одна строка на аккаунт.
-- Выполнить один раз в Supabase → SQL Editor.

create table public.user_data (
  user_id uuid primary key default auth.uid() references auth.users on delete cascade,
  words jsonb not null default '[]',
  liked jsonb not null default '[]',
  history jsonb not null default '[]',
  positions jsonb not null default '{}',
  progress jsonb not null default '{}',
  level text,
  interests jsonb not null default '[]',
  survey_done boolean not null default false,
  updated_at timestamptz not null default now()
);

alter table public.user_data enable row level security;

-- Каждый видит и меняет только свою строку.
create policy "own row" on public.user_data
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

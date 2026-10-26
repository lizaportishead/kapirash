-- Анкета после онбординга (уровень, интересы) хранится в облаке, чтобы не спрашивать её на каждом устройстве.
-- Выполнить один раз в Supabase → SQL Editor.

alter table public.user_data
  add column if not exists level text,
  add column if not exists interests jsonb not null default '[]',
  add column if not exists survey_done boolean not null default false;

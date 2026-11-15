-- Свои рассказы владельца: приложение кладёт сюда текст, словарь к нему готовит Claude по заявке
-- (tools/my_stories). Выполнить один раз в Supabase → SQL Editor.

create table public.my_stories (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  author text not null default '',
  level text not null default '',
  body text not null,             -- чистый текст, абзацы разделены пустой строкой, латиницей
  pages int not null default 0,   -- сколько страниц получилось (для лимита и подсказки)
  dict jsonb not null default '{}'::jsonb,   -- { "слово": ["перевод", "пометка"] } по-русски
  dict_en jsonb,                             -- то же по-английски; пусто — показываем русский
  status text not null default 'queued' check (status in ('queued', 'processing', 'ready', 'failed')),
  error text,
  created_at timestamptz not null default now(),
  finished_at timestamptz
);

alter table public.my_stories enable row level security;

-- Видит, добавляет и удаляет только владелец. Заявки разбирает Claude с секретным ключом: RLS он обходит.
create policy "owner" on public.my_stories
  for all to authenticated
  using ((auth.jwt() ->> 'email') in ('ilovekurm@gmail.com', 'iamkurm@gmail.com'))
  with check ((auth.jwt() ->> 'email') in ('ilovekurm@gmail.com', 'iamkurm@gmail.com'));

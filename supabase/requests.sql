-- Очередь своих роликов: приложение пишет заявку, воркер в GitHub Actions (tools/worker) готовит субтитры
-- и кладёт <id>.sr.vtt, <id>.ru.vtt, <id>.dict.json в бакет subs. Выполнить один раз в Supabase → SQL Editor.

create table public.video_requests (
  id text primary key, -- id ролика на YouTube
  title text not null default '',
  channel text not null default '',
  status text not null default 'queued' check (status in ('queued', 'processing', 'ready', 'failed')),
  error text,
  created_at timestamptz not null default now(),
  finished_at timestamptz
);

alter table public.video_requests enable row level security;

-- Заявки видит и меняет только владелец. Воркер ходит с секретным ключом и RLS обходит.
create policy "owner" on public.video_requests
  for all to authenticated
  using ((auth.jwt() ->> 'email') in ('ilovekurm@gmail.com', 'iamkurm@gmail.com'))
  with check ((auth.jwt() ->> 'email') in ('ilovekurm@gmail.com', 'iamkurm@gmail.com'));

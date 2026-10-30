-- Счётчики запросов для лимитов в Edge Functions (translate, tts, feedback).
-- Выполнить один раз в Supabase → SQL Editor.

create table if not exists public.rate_hits (
  key text not null,
  window_start timestamptz not null,
  n int not null default 0,
  primary key (key, window_start)
);

-- Политик нет: таблицу читает и пишет только функция ниже и секретный ключ.
alter table public.rate_hits enable row level security;

-- Прибавляет единицу к счётчику ключа в текущем окне и отвечает, укладывается ли он в лимит.
create or replace function public.rate_check(p_key text, p_limit int, p_window_seconds int)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  w timestamptz := to_timestamp(floor(extract(epoch from now()) / p_window_seconds) * p_window_seconds);
  c int;
begin
  if random() < 0.01 then
    delete from public.rate_hits where window_start < now() - interval '1 day';
  end if;
  insert into public.rate_hits as r (key, window_start, n) values (p_key, w, 1)
    on conflict (key, window_start) do update set n = r.n + 1
    returning r.n into c;
  return c <= p_limit;
end;
$$;

revoke all on function public.rate_check(text, int, int) from public, anon, authenticated;
grant execute on function public.rate_check(text, int, int) to service_role;

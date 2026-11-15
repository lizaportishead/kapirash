-- Место в рейтинге: по количеству выполненных заданий (блоков квиза), затем по числу просмотренных роликов.
-- Выполнить один раз в Supabase → SQL Editor.

alter table public.user_data
  add column if not exists tasks_done int not null default 0;

-- Счётчик только растёт: новое устройство с пустой историей не обнулит рейтинг.
create or replace function public.set_tasks_done(n int)
returns void
language sql
security invoker
as $$
  update public.user_data
     set tasks_done = greatest(tasks_done, n)
   where user_id = (select auth.uid());
$$;

-- Моё место и число участников. Порядок: больше заданий выше, при равенстве — больше просмотренных роликов.
-- В рейтинге все зарегистрированные пользователи.
-- security definer: строки других пользователей закрыты RLS, наружу выходят только два числа.
create or replace function public.my_rank()
returns table (rank int, total int)
language sql
security definer
set search_path = public
as $$
  with p as (
    select user_id, tasks_done as t, jsonb_array_length(history) as v
      from public.user_data
  )
  select
    (1 + (select count(*) from p o where o.t > me.t or (o.t = me.t and o.v > me.v)))::int,
    (select count(*) from p)::int
  from p me
  where me.user_id = (select auth.uid());
$$;

revoke all on function public.my_rank() from public, anon;
grant execute on function public.my_rank() to authenticated;
grant execute on function public.set_tasks_done(int) to authenticated;

-- Таблица лидеров: все пользователи (до 500). Сначала по выполненным заданиям, затем по просмотренным роликам.
-- Имена сокращены («Liza M.»), отдаются ещё ссылка на фото из Google-аккаунта; почты наружу не выходят; без имени в аккаунте — «Kapiraš #1234».
-- Добавилась колонка avatar, а тип результата create or replace не меняет, поэтому сначала drop.
drop function if exists public.leaderboard(int);

create function public.leaderboard(lim int default 200)
returns table (rank int, name text, avatar text, videos int, tasks int, level text, is_me boolean)
language sql
security definer
set search_path = public
as $$
  select
    (rank() over (order by u.tasks_done desc, jsonb_array_length(u.history) desc))::int,
    coalesce(
      nullif(
        split_part(trim(a.raw_user_meta_data ->> 'full_name'), ' ', 1)
        || case when position(' ' in trim(a.raw_user_meta_data ->> 'full_name')) > 0
                then ' ' || upper(left(split_part(trim(a.raw_user_meta_data ->> 'full_name'), ' ', 2), 1)) || '.'
                else '' end,
        ''),
      'Kapiraš #' || right(u.user_id::text, 4)),
    coalesce(a.raw_user_meta_data ->> 'avatar_url', a.raw_user_meta_data ->> 'picture'),
    jsonb_array_length(u.history)::int,
    u.tasks_done,
    u.level,
    u.user_id = (select auth.uid())
  from public.user_data u
  join auth.users a on a.id = u.user_id
  order by u.tasks_done desc, jsonb_array_length(u.history) desc, u.user_id
  limit least(lim, 500);
$$;

-- Таблицу видят все, в том числе без входа (is_me у них всегда false).
revoke all on function public.leaderboard(int) from public;
grant execute on function public.leaderboard(int) to anon, authenticated;

-- Место в рейтинге: считается по количеству выполненных заданий (блоков квиза).
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

-- Моё место и число участников (в рейтинге те, у кого есть хотя бы одно задание).
-- security definer: строки других пользователей закрыты RLS, наружу выходят только два числа.
create or replace function public.my_rank()
returns table (rank int, total int)
language sql
security definer
set search_path = public
as $$
  select
    (1 + (select count(*) from public.user_data u
           where u.tasks_done > me.tasks_done))::int,
    (select count(*) from public.user_data where tasks_done > 0)::int
  from public.user_data me
  where me.user_id = (select auth.uid()) and me.tasks_done > 0;
$$;

revoke all on function public.my_rank() from public, anon;
grant execute on function public.my_rank() to authenticated;
grant execute on function public.set_tasks_done(int) to authenticated;

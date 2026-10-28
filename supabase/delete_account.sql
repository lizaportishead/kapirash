-- Удаление своего аккаунта из приложения (Профиль → «Удалить аккаунт»).
-- Строка user_data удаляется каскадом (references auth.users on delete cascade).
-- Выполнить один раз в Supabase → SQL Editor.

create or replace function public.delete_my_account()
returns void
language sql
security definer
set search_path = ''
as $$
  delete from auth.users where id = (select auth.uid());
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;

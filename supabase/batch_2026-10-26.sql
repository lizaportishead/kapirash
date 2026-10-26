-- Партия 2026-10-26. Выполнить один раз в Supabase → SQL Editor. Безопасно повторять.
-- Файлы субтитров из supabase/upload_2026-10-26/ нужно загрузить в бакет subs.

insert into public.creators (name, handle, avatar_id) values
  ('Andrija i Andjelka', 'andrijaiandjelkaofficial', null)
on conflict (name) do nothing;

insert into public.videos (id, title, channel, topic, level, duration) values
  ('TLVUjSOUWXk', 'Andrija i Andjelka - Uputstvo za mazenje zene', 'Andrija i Andjelka', 'Юмор', 'B1', '1:49'),
  ('vBFoKok2AwA', 'Andrija i Andjelka - Pakao zvani porodicni izlet', 'Andrija i Andjelka', 'Юмор', 'B2', '3:37'),
  ('l-t7PyL2cbg', 'Andrija i Andjelka - Ko je foka, a ko gorila?', 'Andrija i Andjelka', 'Юмор', 'B1', '2:10'),
  ('K2fyqgV-x2A', 'Andrija i Andjelka - Muska pomoc u kuhinji', 'Andrija i Andjelka', 'Юмор', 'B1', '1:25')
on conflict (id) do nothing;

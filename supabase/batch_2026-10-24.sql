-- Партия 2026-10-24. Выполнить один раз в Supabase → SQL Editor. Безопасно повторять.
-- Файлы субтитров (<id>.sr.vtt, <id>.ru.vtt, <id>.dict.json) из supabase/upload_2026-10-24/ нужно загрузить в бакет subs.

insert into public.creators (name, handle, avatar_id) values
  ('Fresh Blekbuk Serije', 'FreshBlekbukSerije', null)
on conflict (name) do nothing;

insert into public.videos (id, title, channel, topic, level, duration) values
  ('bjN_HyuFWj0', 'Mamini Sinovi | Epizoda 1 (Domaća Serija)HD', 'Fresh Blekbuk Serije', 'Юмор', 'C1', '26:31')
on conflict (id) do nothing;

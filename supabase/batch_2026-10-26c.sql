-- Партия 2026-10-26 (стендап). Выполнить один раз в Supabase → SQL Editor. Безопасно повторять.
-- Файлы субтитров из supabase/upload_2026-10-26c/ нужно загрузить в бакет subs.

insert into public.creators (name, handle, avatar_id) values
  ('Standuprs', 'standuprs', null)
on conflict (name) do nothing;

insert into public.videos (id, title, channel, topic, level, duration) values
  ('KzUV2G3IOm4', 'Srđan Dinčić - StandUpFest 2020', 'Standuprs', 'Юмор', 'B2', '18:40')
on conflict (id) do nothing;

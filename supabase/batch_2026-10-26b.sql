-- Партия 2026-10-26 (вторая). Выполнить один раз в Supabase → SQL Editor. Безопасно повторять.
-- Файлы субтитров из supabase/upload_2026-10-26b/ нужно загрузить в бакет subs.

insert into public.creators (name, handle, avatar_id) values
  ('Andrija i Andjelka', 'andrijaiandjelkaofficial', null)
on conflict (name) do nothing;

insert into public.videos (id, title, channel, topic, level, duration) values
  ('J_HSdmFaFh8', 'Andrija i Andjelka - Taj odvratni zdravi hleb', 'Andrija i Andjelka', 'Юмор', 'B1', '1:28'),
  ('5BeV5VW_m04', 'Andrija i Andjelka - Bolest kupovanja parfema', 'Andrija i Andjelka', 'Юмор', 'B1', '1:15'),
  ('mbgspHORxH0', 'Ljubav i iskrenost i svi drugi recepti za sreću !', 'Andrija i Andjelka', 'Юмор', 'B1', '0:54'),
  ('c1Wocy8ldKM', 'Andrija i Andjelka - Daj pravi toplomer!', 'Andrija i Andjelka', 'Юмор', 'B1', '0:33')
on conflict (id) do nothing;

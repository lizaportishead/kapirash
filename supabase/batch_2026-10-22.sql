-- Партия 2026-10-22. Выполнить один раз в Supabase → SQL Editor. Безопасно повторять.
-- Файлы субтитров (<id>.sr.vtt, <id>.ru.vtt, <id>.dict.json) из supabase/upload_2026-10-22/ нужно загрузить в бакет subs.

insert into public.creators (name, handle, avatar_id) values
  ('Radna akcija sa Tamarom', 'RadnaAkcijaSaTamarom', null)
on conflict (name) do nothing;

insert into public.videos (id, title, channel, topic, level, duration) values
  ('it3nCG6JtYw', 'Izveštaj sa terena 27.04. - Radna akcija sa Tamarom', 'Radna akcija sa Tamarom', 'Быт', 'B1', '4:02'),
  ('aMBnmigQgQw', 'RADNA AKCIJA SA TAMAROM *Sa terena | Kako brzo i lako zapaliti peć, šporet ili kamin? KORAK PO KORAK', 'Radna akcija sa Tamarom', 'Быт', 'B1', '3:48')
on conflict (id) do nothing;

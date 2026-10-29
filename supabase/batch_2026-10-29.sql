-- Tina Grabez: 30 dana bez šećera. Файлы из supabase/upload_2026-10-29/ загружаются в бакет subs.
insert into public.creators (name, handle, avatar_id) values
  ('Tina Grabez', 'tinagrabez', null)
on conflict (name) do nothing;

insert into public.videos (id, title, channel, topic, level, duration) values
  ('RCWmyQdrqRo', '30 DANA BEZ ŠEĆERA I OVO SE DESILO.', 'Tina Grabez', 'Здоровье', 'B1', '9:46')
on conflict (id) do nothing;

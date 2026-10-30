-- Gruberka: TEMU HAUL. Файлы из supabase/upload_2026-10-27/ загружаются в бакет subs.
insert into public.creators (name, handle, avatar_id) values
  ('Gruberka', 'gruuberka', null)
on conflict (name) do nothing;

insert into public.videos (id, title, channel, topic, level, duration) values
  ('Wmld3EoXEnY', 'TEMU HAUL - šta sam sve kupila?!', 'Gruberka', 'Быт', 'B1', '17:11')
on conflict (id) do nothing;

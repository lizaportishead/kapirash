-- Mala sirena (Simsala Grim) и Robert Dacešin. Файлы из supabase/upload_2026-10-28/ загружаются в бакет subs.
insert into public.creators (name, handle, avatar_id) values
  ('Crtani filmovi na srpskom', 'crtani-filmovi-na-srpskom', null),
  ('Robert Dacešin', 'robertdacesin', null)
on conflict (name) do nothing;

insert into public.videos (id, title, channel, topic, level, duration) values
  ('Qb-JTu0gl6k', 'Mala sirena - Simsala Grim', 'Crtani filmovi na srpskom', 'Культура', 'A2', '26:00'),
  ('xlb_hJPiOGU', 'Kako sam naučio 5 stranih jezika BEZ KURSEVA?', 'Robert Dacešin', 'Наука', 'B1', '15:03')
on conflict (id) do nothing;

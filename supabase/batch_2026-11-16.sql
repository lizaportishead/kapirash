-- Mamini Sinovi, эпизоды 4–6. Файлы из supabase/upload_2026-11-16/ загружаются в бакет subs.
insert into public.creators (name, handle, avatar_id) values
  ('Fresh Blekbuk Serije', 'FreshBlekbukSerije', null)
on conflict (name) do nothing;

insert into public.videos (id, title, channel, topic, level, duration) values
  ('Haw-E4vxBYg', 'Mamini Sinovi | Epizoda 4 (Domaća Serija)HD', 'Fresh Blekbuk Serije', 'Юмор', 'C1', '26:02'),
  ('f1qsclLQyzQ', 'Mamini Sinovi | Epizoda 5 (Domaća Serija)HD', 'Fresh Blekbuk Serije', 'Юмор', 'C1', '25:48'),
  ('vE6iiAVoD3c', 'Mamini Sinovi | Epizoda 6 (Domaća Serija)HD', 'Fresh Blekbuk Serije', 'Юмор', 'C1', '28:37')
on conflict (id) do nothing;

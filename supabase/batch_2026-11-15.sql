-- Mamini Sinovi, эпизоды 2 и 3. Файлы из supabase/upload_2026-11-15/ загружаются в бакет subs.
insert into public.creators (name, handle, avatar_id) values
  ('Fresh Blekbuk Serije', 'FreshBlekbukSerije', null)
on conflict (name) do nothing;

insert into public.videos (id, title, channel, topic, level, duration) values
  ('K_nn3jYg2_Y', 'Mamini Sinovi | Epizoda 2 (Domaća Serija)HD', 'Fresh Blekbuk Serije', 'Юмор', 'C1', '26:25'),
  ('lxG7zm8exaM', 'Mamini Sinovi | Epizoda 3 (Domaća Serija)HD', 'Fresh Blekbuk Serije', 'Юмор', 'C1', '28:27')
on conflict (id) do nothing;

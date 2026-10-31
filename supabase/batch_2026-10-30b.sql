-- Danijela Ostojić: Zašto anksioznost nije bolest? Файлы из supabase/upload_2026-10-30b/ загружаются в бакет subs.
insert into public.creators (name, handle, avatar_id) values
  ('Balkanska Uvjerenja by Danijela', 'danijelaostojic.psiholog', null)
on conflict (name) do nothing;

insert into public.videos (id, title, channel, topic, level, duration) values
  ('VAI5GxslifI', 'Zašto anksioznost nije bolest?', 'Balkanska Uvjerenja by Danijela', 'Психология', 'B2', '11:25')
on conflict (id) do nothing;

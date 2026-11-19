-- Клипы TikTok (10 шт.), 2026-11-19. Файлы из supabase/upload_2026-11-19/ идут в бакет subs.

insert into public.creators (name, handle, avatar_id) values
  ('Aveilora', null, null),
  ('BalkanBet', null, null),
  ('Gagi Vujadinović', null, null),
  ('Luka Averić', null, null),
  ('Željko Malenović', null, null)
on conflict (name) do nothing;

insert into public.videos (id, title, channel, topic, level, duration, kind) values
  ('7709554796931321106', 'Majka i ChatGPT', 'Željko Malenović', 'Юмор', 'B1', '0:24', 'tiktok'),
  ('7706903451451641106', 'Tanko rezana salama', 'Željko Malenović', 'Юмор', 'B1', '0:29', 'tiktok'),
  ('7702504712997768468', 'Test poverenja', 'Gagi Vujadinović', 'Юмор', 'B1', '1:56', 'tiktok'),
  ('7705476511423352085', 'Poruka za bivšeg dečka', 'Gagi Vujadinović', 'Юмор', 'B1', '0:22', 'tiktok'),
  ('7703990028006870293', 'Mali poklon za Aleksandru', 'Luka Averić', 'Общество', 'B1', '1:00', 'tiktok'),
  ('7702768555548314901', 'Novac na drvetu', 'Luka Averić', 'Эксперименты', 'B1', '0:27', 'tiktok'),
  ('7709123974646517012', 'Pogodi seriju', 'BalkanBet', 'Культура', 'B1', '1:11', 'tiktok'),
  ('7698688609523649813', 'Tablice BČ', 'BalkanBet', 'Авто', 'B1', '0:41', 'tiktok'),
  ('7688788596018498823', 'Put do američke porodice', 'Aveilora', 'Путешествия', 'B1', '1:56', 'tiktok'),
  ('7707712402485202184', 'Ćelava za Pitbulla', 'Aveilora', 'Юмор', 'B1', '1:03', 'tiktok')
on conflict (id) do nothing;

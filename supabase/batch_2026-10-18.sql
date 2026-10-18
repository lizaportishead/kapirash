-- Партия из 10 роликов (2026-10-18). Выполнить один раз в Supabase → SQL Editor.
-- Безопасно запускать повторно: уже существующие строки пропускаются.
-- Файлы субтитров (<id>.sr.vtt, <id>.ru.vtt, <id>.dict.json) нужно отдельно загрузить в бакет subs.

insert into public.creators (name, handle, avatar_id) values
  ('Nova Ekonomija', null, null),
  ('Nije Dosadna Nauka', null, null),
  ('Gajbotron', null, null),
  ('Lične Finansije', null, null),
  ('Istorija Srba', null, null),
  ('Nove misli', null, null),
  ('DMN', null, null),
  ('Zdravo Tanja', null, null),
  ('Vladimir Stanković', null, null),
  ('Izokrenuta Učionica', null, null)
on conflict (name) do nothing;

insert into public.videos (id, title, channel, topic, level, duration) values
  ('j-yOsWAZQlg', 'Srbija u spirali duga: Zašto niko neće naše dinare, a banke dižu kamate?', 'Nova Ekonomija', 'Деньги', 'C1', '9:40'),
  ('0pOGRsOG_zs', 'Kvantna Mehanika: 100 Godina Otkrića koja su Promenila Stvarnost', 'Nije Dosadna Nauka', 'Наука', 'C1', '25:19'),
  ('Kk-iKBNS250', 'MALA ŠKOLA SVEMIRA: ep.1 - GDE SMO MI U SVEMIRU?', 'Gajbotron', 'Наука', 'B2', '13:24'),
  ('0M49CiJW6OQ', 'Kako da napraviš svoj PORTFOLIO? | Portfolio strategija | Jezgro i sateliti (Core & Satellite)', 'Lične Finansije', 'Деньги', 'C1', '9:27'),
  ('7z1OP5z03EY', 'PRVA SRPSKA KRALJEVINA: Stefan Vojislav i kruna iz Rima', 'Istorija Srba', 'История', 'B2', '11:00'),
  ('UlNXx5V5_04', 'Carl Gustav Jung / SLUČAJNOST NE POSTOJI', 'Nove misli', 'Психология', 'B2', '9:23'),
  ('aATqeedFD2U', 'Najisplativiji od svih Samsung telefona - Samsung Galaxy A56 recenzija', 'DMN', 'IT', 'B2', '9:16'),
  ('ta4_7-GrAL0', 'ISHRANA KOD HASHIMOTA | Saveti nutricioniste', 'Zdravo Tanja', 'Здоровье', 'C1', '15:54'),
  ('Su6oB9ZJB8U', 'Nauči 90% Claude-a za manje od 10 minuta', 'Vladimir Stanković', 'IT', 'B2', '8:20'),
  ('wZb4X0JnC6w', 'Izokrenuta učionica - Deoba ćelije - Mitoza', 'Izokrenuta Učionica', 'Наука', 'B2', '10:28')
on conflict (id) do nothing;

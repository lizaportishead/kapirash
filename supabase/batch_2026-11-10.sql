-- Pivokosa: палачинки (Fast food kod kuće) и Masa Memedovic: буваљак в Панчево. Файлы из supabase/upload_2026-11-10/ загружаются в бакет subs.
insert into public.creators (name, handle, avatar_id) values
  ('Pivokosa', 'Pivokosa', null),
  ('Masa Memedovic', 'mashamemedovic', null),
  ('Izazovi avanturu', 'IzazoviAvanturu', null)
on conflict (name) do nothing;

insert into public.videos (id, title, channel, topic, level, duration) values
  ('go1BfhN6-Zk', 'Da li mogu da napravim PALAČINKU SA KREMOM I PLAZMOM bolje od palačinkarnice', 'Pivokosa', 'Еда', 'B1', '19:05'),
  ('OmQjgITIkh8', 'BUVLJAK U PANČEVU: PRONAŠLA SAM TORBU KOJU SAM BACILA?!', 'Masa Memedovic', 'Быт', 'B2', '26:19'),
  ('VzEA84tcOHY', 'U NAPUŠTENOM selu izgradio OAZU za ODMOR | Beg iz GRADA | Konji mu spasili ŽIVOT', 'Izazovi avanturu', 'Путешествия', 'B2', '30:12'),
  ('ZUNhp8TGMho', 'Zašto Srbija nestaje?', 'Ozbiljne teme', 'Общество', 'B2', '24:22')
on conflict (id) do nothing;

-- Партия 2026-10-19. Выполнить один раз в Supabase → SQL Editor. Безопасно повторять.
-- Файлы субтитров (<id>.sr.vtt, <id>.ru.vtt, <id>.dict.json) из supabase/upload_2026-10-19/ нужно загрузить в бакет subs.

insert into public.creators (name, handle, avatar_id) values
  ('Vredno priče', null, null),
  ('Agelast', null, null)
on conflict (name) do nothing;

insert into public.videos (id, title, channel, topic, level, duration) values
  ('pZKCi5CwagI', 'Vredno priče 19 - Na Drini ćuprija / Ivo Andrić (gost: Tihomir Brajović)', 'Vredno priče', 'Культура', 'C1', '6:33'),
  ('xTPZzVR5Z78', 'Šta su ekstremofili i gde ih sve nalazimo?', 'Agelast', 'Наука', 'C1', '13:42'),
  ('mLF8k4uKI7Y', 'Šta možemo da očekujemo od izbora?', 'Agelast', 'Политика', 'C1', '15:30'),
  ('tf2sQBH0FG0', 'Da li postoji život na Veneri?', 'Agelast', 'Наука', 'C1', '13:29'),
  ('Qmkg5WLYESQ', 'Tajne službe, prisluškivanja i ubistva — Vuk Cvijić, novinar i urednik', 'Agelast', 'Политика', 'C1', '9:56'),
  ('ZK1Bqyu_zu0', 'Kako drveće i gljive komuniciraju?', 'Agelast', 'Наука', 'C1', '7:21')
on conflict (id) do nothing;

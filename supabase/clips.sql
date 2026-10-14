-- Клипы из TikTok в каталоге. Выполнить один раз в Supabase → SQL Editor, после catalog.sql.

-- Откуда ролик: пусто — YouTube, 'tiktok' — вертикальный клип (id — номер ролика в TikTok).
alter table public.videos add column kind text not null default '';

insert into public.creators (name, handle, avatar_id) values
  ('Realno', null, null),
  ('Elena', null, null),
  ('milli', null, null),
  ('Aleksandra Tepavac', null, null),
  ('Ema Pumpalović', null, null),
  ('Lelina kuhinjica', null, null),
  ('Ljudi Beograda', null, null),
  ('Nespretna domaćica', null, null),
  ('Poklopac i lonac', null, null),
  ('Tragom horizonta', null, null),
  ('Đole · Pametni kutak', null, null);

insert into public.videos (id, title, channel, topic, level, duration, kind) values
  ('7663466480683519265', 'Najgora pljačka u karijeri', 'Realno', 'Юмор', 'B1', '1:04', 'tiktok'),
  ('7684326403902360852', 'Koliko smo sada lepše', 'Elena', 'Красота', 'B1', '2:12', 'tiktok'),
  ('7691370106257034504', 'Prvi alpaka kafe u Srbiji', 'milli', 'Путешествия', 'B1', '0:45', 'tiktok'),
  ('7695697222444387604', 'Zgrada koja izgleda kao Toblerone', 'Ljudi Beograda', 'Город', 'B1', '0:44', 'tiktok'),
  ('7691647020758502662', 'Sto godina pijace Zeleni venac', 'Ljudi Beograda', 'Город', 'B1', '0:50', 'tiktok'),
  ('7691254334730226964', 'Topolska 18: adresa dve kultne serije', 'Ljudi Beograda', 'Культура', 'B1', '1:02', 'tiktok'),
  ('7636300414652026120', 'Ledene kocke', 'Nespretna domaćica', 'Еда', 'B1', '0:38', 'tiktok'),
  ('7685347257029348626', 'Najmekša proja', 'Lelina kuhinjica', 'Еда', 'B1', '0:30', 'tiktok'),
  ('7640223671985900818', 'Domaće ćufte u paradajz sosu', 'Poklopac i lonac', 'Еда', 'B1', '0:33', 'tiktok'),
  ('7694709604017507591', 'Teorija nevidljive žice', 'Đole · Pametni kutak', 'Психология', 'B1', '0:46', 'tiktok'),
  ('7495076935429672247', 'Savršeni jednodnevni izlet u Srbiji', 'Tragom horizonta', 'Путешествия', 'B1', '0:40', 'tiktok'),
  ('7627473268941016341', 'Tortilja pita iz rerne', 'Ema Pumpalović', 'Еда', 'B1', '0:34', 'tiktok'),
  ('7485479524428156166', 'Život u studentskom domu', 'Aleksandra Tepavac', 'Быт', 'B1', '0:38', 'tiktok');

-- Клипу, которого нет в сборке приложения, кроме субтитров нужна обложка в бакете subs: <id>.jpg.

-- Клипы TikTok (23 шт.). Нужна колонка kind (supabase/clips.sql). Безопасно повторять.
-- Файлы из supabase/upload_2026-10-26d/ загружаются в бакет subs.

insert into public.creators (name, handle, avatar_id) values
  ('Aleksandra Tepavac', null, null),
  ('Elena', null, null),
  ('Ema Pumpalović', null, null),
  ('Kurir', null, null),
  ('Lelina kuhinjica', null, null),
  ('Ljudi Beograda', null, null),
  ('Nespretna domaćica', null, null),
  ('Poklopac i lonac', null, null),
  ('Realno', null, null),
  ('Tragom horizonta', null, null),
  ('milli', null, null),
  ('Đole · Pametni kutak', null, null)
on conflict (name) do nothing;

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
  ('7485479524428156166', 'Život u studentskom domu', 'Aleksandra Tepavac', 'Быт', 'B1', '0:38', 'tiktok'),
  ('7689023631938129159', 'Gomboca palačinke iz rerne', 'Lelina kuhinjica', 'Еда', 'B1', '0:42', 'tiktok'),
  ('7695332427220159752', 'Torta za svaki rođendan', 'Lelina kuhinjica', 'Еда', 'B1', '0:34', 'tiktok'),
  ('7696534609059679509', 'Četiri nove linije do Expo 2027', 'Ljudi Beograda', 'Город', 'B2', '0:43', 'tiktok'),
  ('7697327345908075797', 'Počela grejna sezona u Beogradu', 'Ljudi Beograda', 'Город', 'B2', '0:32', 'tiktok'),
  ('7697533215891803444', 'Tajna stepenastih solitera Novog Beograda', 'Ljudi Beograda', 'Город', 'B2', '0:34', 'tiktok'),
  ('7698296977792060692', 'Misterija bloka 27', 'Ljudi Beograda', 'Город', 'B2', '0:35', 'tiktok'),
  ('7698687294261284117', 'Nova pravila za bašte kafića', 'Ljudi Beograda', 'Город', 'B2', '0:30', 'tiktok'),
  ('7699850836767198484', 'Kome pripada Kuća cveća?', 'Ljudi Beograda', 'Город', 'B1', '0:18', 'tiktok'),
  ('7700954111319149844', 'Časni krst stiže u Beograd', 'Ljudi Beograda', 'Культура', 'B2', '0:29', 'tiktok'),
  ('7700962796871208193', 'Sveta Petka: šta se ne radi', 'Kurir', 'Культура', 'B2', '0:33', 'tiktok')
on conflict (id) do nothing;

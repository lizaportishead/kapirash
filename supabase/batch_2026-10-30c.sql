-- Ozbiljne teme: Zašto zastave Srbije i Rusije liče? и Drugi svetski rat. Файлы из supabase/upload_2026-10-30c/ загружаются в бакет subs.
insert into public.creators (name, handle, avatar_id) values
  ('Ozbiljne teme', 'OzbiljneTeme', null)
on conflict (name) do nothing;

insert into public.videos (id, title, channel, topic, level, duration) values
  ('qHotWt4TFUI', 'Zašto zastave SRBIJE i RUSIJE liče?', 'Ozbiljne teme', 'История', 'B2', '24:47'),
  ('EZ21rAA7WYE', 'DRUGI SVETSKI RAT | KAKO I ZAŠTO JE POČEO?', 'Ozbiljne teme', 'История', 'B2', '17:25')
on conflict (id) do nothing;

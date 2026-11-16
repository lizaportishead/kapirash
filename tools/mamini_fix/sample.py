import sys,re,os
from faster_whisper import WhisperModel
from faster_whisper.audio import decode_audio
from faster_whisper.vad import get_speech_timestamps, VadOptions
def t(s):
    h,m,x=s.split(':');return int(h)*3600+int(m)*60+float(x)
m=WhisperModel("large-v3-turbo",device="cpu",compute_type="int8")
for f in sys.argv[1:]:
    vid=os.path.basename(f).split('.')[0]
    a=decode_audio(f,sampling_rate=16000)
    sp=[(s['start']/16000,s['end']/16000) for s in get_speech_timestamps(a,VadOptions(threshold=0.6,min_speech_duration_ms=500,min_silence_duration_ms=500))]
    cues=[(t(x),t(y)) for x,y in re.findall(r'(\d+:\d+:\d+\.\d+) --> (\d+:\d+:\d+\.\d+)',open(f'app/assets/{vid}.sr.vtt').read())]
    gaps=[]
    for s,e in sp:
        if e-s<4: continue
        if not any(min(e,b+1)-max(s,a1-1)>0 for a1,b in cues): gaps.append((s,e))
    gaps.sort(key=lambda g:g[0]-g[1])
    print('==',vid,'uncovered speech spans>=4s:',len(gaps),flush=True)
    for s,e in sorted(gaps[:4]):
        segs,_=m.transcribe(a[int(s*16000):int(min(e,s+25)*16000)],language='sr',vad_filter=False,condition_on_previous_text=False,beam_size=1)
        txt=' '.join(x.text.strip() for x in segs)
        print(f'  {s:.0f}-{e:.0f}s: {txt[:150]}',flush=True)

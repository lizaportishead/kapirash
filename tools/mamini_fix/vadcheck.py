import sys,re,os,json,glob
from faster_whisper.audio import decode_audio
from faster_whisper.vad import get_speech_timestamps, VadOptions
def t(s):
    h,m,x=s.split(':');return int(h)*3600+int(m)*60+float(x)
res=[]
for f in sys.argv[1:]:
    vid=os.path.basename(f).split('.')[0]
    a=decode_audio(f,sampling_rate=16000)
    dur=len(a)/16000
    sp=get_speech_timestamps(a,VadOptions(threshold=0.6,min_speech_duration_ms=500,min_silence_duration_ms=500))
    sp=[(s['start']/16000,s['end']/16000) for s in sp]
    cues=[(t(x),t(y)) for x,y in re.findall(r'(\d+:\d+:\d+\.\d+) --> (\d+:\d+:\d+\.\d+)',open(f'app/assets/{vid}.sr.vtt').read())]
    miss=0;tot=0
    for s,e in sp:
        tot+=e-s
        # uncovered portion of this speech span
        cov=0
        for a1,b1 in cues:
            o=min(e,b1+1.0)-max(s,a1-1.0)
            if o>0: cov+=o
        miss+=max(0,(e-s)-cov)
    r=dict(id=vid,dur=round(dur),speech=round(tot/dur,2),missing=round(miss/dur,3),missing_s=round(miss))
    print(r,flush=True); res.append(r)
json.dump(res,open('tools/mamini_fix/vad_%s.json'%os.getpid(),'w'))

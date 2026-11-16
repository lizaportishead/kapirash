import sys,json
from faster_whisper import WhisperModel
A='/private/tmp/claude-501/-Users-elizavetamatveeva--claude-spares-spare-uskiet/8d08f207-2e3c-4db2-9be5-013909a297d4/scratchpad/audio/'
reg=json.load(open('tools/mamini_fix/regions.json'))
m=WhisperModel("large-v3",device="cpu",compute_type="int8")
for vid in sys.argv[1:]:
    clips=",".join(f"{a:.1f},{b:.1f}" for a,b in reg[vid])
    segs,_=m.transcribe(A+vid+".m4a",language="sr",vad_filter=False,condition_on_previous_text=False,beam_size=5,clip_timestamps=clips,
        initial_prompt="Domaća serija Mamini sinovi. Ekavica, razgovorni srpski.")
    out=[[round(s.start,2),round(s.end,2),s.text.strip(),round(s.no_speech_prob,2)] for s in segs]
    json.dump(out,open(f"tools/mamini_fix/{vid}.v3.json","w"),ensure_ascii=False); print(vid,len(out),flush=True)

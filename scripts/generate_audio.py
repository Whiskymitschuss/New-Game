"""Original deterministic synthesized audio. No third-party sound recordings."""
import math, random, struct, wave
from pathlib import Path
OUT=Path(__file__).resolve().parents[1]/'assets/audio'
OUT.mkdir(exist_ok=True,parents=True)
RATE=22050
rng=random.Random(734219)
def save(name, duration, fn):
    with wave.open(str(OUT/(name+'.wav')),'wb') as w:
        w.setparams((1,2,RATE,0,'NONE','not compressed'))
        w.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,fn(i/RATE)))*22000)) for i in range(int(duration*RATE))))
for idx in range(12):
    freq=80+idx*29
    save('gun'+str(idx),.18,lambda t,f=freq: (rng.uniform(-1,1)*.45+math.sin(2*math.pi*(f*t-90*t*t))*.45)*math.exp(-t*34))
for name,freq,duration in [('click',700,.07),('drop',360,.18),('multiply',920,.15),('collect',1100,.1),('upgrade',540,.7),('hit',95,.2),('zombie',73,.32),('special',180,.6),('warning',440,.5)]:
    save(name,duration,lambda t,f=freq,d=duration: (math.sin(2*math.pi*(f*t+f*.8*t*t))*.65+math.sin(2*math.pi*f*1.5*t)*.15)*max(0,1-t/d)**2)
for name,notes,bpm in [('menu',[110,164.81,146.83,130.81],88),('battle',[110,110,130.81,98],116),('boss',[82.41,87.31,82.41,77.78],128),('victory',[261.63,329.63,392,523.25],100),('defeat',[146.83,130.81,110,82.41],65)]:
    beat=60/bpm;duration=beat*16
    def music(t,ns=notes,b=beat):
        step=int(t/b);phase=t%b;f=ns[(step//4)%4]
        bass=math.sin(2*math.pi*f*t)*math.exp(-phase*5)*.35
        arp=math.sin(2*math.pi*f*[2,3,4,3][step%4]*t)*math.exp(-phase*8)*.14
        kick=math.sin(2*math.pi*(58*phase-30*phase*phase))*math.exp(-phase*24)*.28 if step%2==0 else 0
        return (bass+arp+kick)*min(1,t/.03,(duration-t)/.03)
    save(name,duration,music)
print('Generated 26 original PCM audio assets.')

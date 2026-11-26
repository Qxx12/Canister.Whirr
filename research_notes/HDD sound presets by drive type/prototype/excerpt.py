import sys, wave, numpy as np
import os
R=os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..') + '/'  # research_notes/
K=R+'Realistic HDD sound synthesis/recordings/freesound_Klerrp_OldHDDs_CC0/'
N=R+'HDD sound presets by drive type/recordings/'
C=R+'Realistic HDD sound synthesis/recordings/'
# name: (file, start or None to auto-pick, length)
jobs={
 'ref_vintage1993':(K+'155882.wav',None,8),
 'ref_desktop2000':(K+'166638.wav',None,8),
 'ref_woody2000':(K+'167420.wav',21.0,8),
 'ref_desktop2005':(K+'167422.wav',None,8),
 'ref_thunk2007':(K+'167421.wav',13.0,8),
 'ref_quiet2010s':(K+'166639.wav',None,8),
 'ref_server10k':(K+'182366.wav',4.0,8),
 'ref_server15k':(K+'182364.wav',26.0,8),
 'ref_stepper1987':(N+'475216_7872308.wav',126.0,8),
 'ref_laptop2007':(N+'143917_2015227.wav',12.0,8),
 'ref_failing':(C+'commons_WD_bad_heads_click_of_death.wav',None,8),
}
def load(p):
    w=wave.open(p); sr=w.getframerate(); ch=w.getnchannels()
    x=np.frombuffer(w.readframes(w.getnframes()),np.int16).astype(float)/32768
    return x.reshape(-1,ch).mean(1), sr
for name,(p,start,L) in jobs.items():
    if len(sys.argv)>1 and name not in sys.argv[1:]: continue
    x,sr=load(p)
    if start is None:
        # busiest window: most onsets 12 dB over the median 1 ms envelope (diff ~ high-pass)
        d=np.diff(x); f=sr//1000; n=len(d)//f
        e=20*np.log10(np.sqrt((d[:n*f].reshape(n,f)**2).mean(1))+1e-9)
        on=np.where((e[1:]>np.median(e)+12)&(e[:-1]<=np.median(e)+12))[0]
        best,bs=0,0
        for s in np.arange(min(8,len(x)/sr*0.25),max(9,len(x)/sr-L-12),0.5):
            c=((on>=s*1000)&(on<(s+L)*1000)).sum()
            if c>best: best,bs=c,s
        start=bs
    seg=x[int(start*sr):int((start+L)*sr)].copy()
    fade=int(0.15*sr); seg[:fade]*=np.linspace(0,1,fade); seg[-fade:]*=np.linspace(1,0,fade)
    p999=np.percentile(np.abs(seg),99.9); seg*=10**(-9/20)/max(p999,1e-9); seg=np.clip(seg,-0.99,0.99)
    w=wave.open(f'refs/{name}.wav','wb'); w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr)
    w.writeframes((seg*32767).astype('<i2').tobytes()); w.close()
    print(name, p.split('/')[-1], 'start', start)

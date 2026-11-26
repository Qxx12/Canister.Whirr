# Short-time look at a passage: per frame (win ms Hann, hop ms) the level in bands (dB re the passage's
# median frame in that band) and the strongest spectral peaks above the passage's median spectrum.
# Usage: python3 -I run.py stft_peek.py <wav> t0 t1 [win=10] [hop=5] [npk=2] [lo=150] [hi=10000] [ref=t0-t1]
import sys, numpy as np
from hdd_analyze import load
args=dict(a.split('=',1) for a in sys.argv[4:]); x,sr=load(sys.argv[1]); t0=float(sys.argv[2]); t1=float(sys.argv[3])
win=float(args.get('win',10)); hop=float(args.get('hop',5)); npk=int(args.get('npk',2)); lo=float(args.get('lo',150)); hi=float(args.get('hi',10000))
W=int(sr*win/1000); H=int(sr*hop/1000); nf=8192; f=np.fft.rfftfreq(nf,1/sr); w=np.hanning(W)
def frames(a,b):
    return np.array([np.abs(np.fft.rfft(x[s:s+W]*w,nf))**2 for s in range(int(a*sr),int(b*sr)-W,H)])
S=frames(t0,t1); 
if 'ref' in args:
    ra,rb=map(float,args['ref'].split('-')); med=np.median(frames(ra,rb),0)
else: med=np.median(S,0)
D=10*np.log10(S+1e-20)-10*np.log10(med+1e-20)
bands=[(20,150),(150,400),(400,1000),(1000,3000),(3000,8000),(8000,16000)]
BL=np.array([[10*np.log10(S[i][(f>=a)&(f<b)].sum()+1e-20) for a,b in bands] for i in range(len(S))]); BL-=np.median(BL,0)
m=(f>=lo)&(f<hi)
print("t(s) | band dB re median: <150 150-400 400-1k 1-3k 3-8k 8-16k | peaks Hz(+dB over median spectrum)")
for i in range(len(S)):
    d=np.where(m,D[i],-99); idx=[]
    for j in np.argsort(-d):
        if d[j]<6: break
        if all(abs(f[j]-f[k])>max(60,0.08*f[j]) for k in idx): idx.append(j)
        if len(idx)>=npk: break
    print(f"{t0+i*hop/1000:8.3f} | "+" ".join(f"{v:+4.0f}" for v in BL[i])+" | "+" ".join(f"{f[j]:.0f}(+{D[i][j]:.0f})" for j in idx))

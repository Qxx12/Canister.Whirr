# Activity bed: long-term spectrum (0.5 s Hann, 4x zero-pad) of the seek ranges vs the idle ranges.
# Lists the strongest tonal peaks of the seek-range spectrum with their rise over idle and prominence.
# Usage: python3 -I run.py bed.py <wav> idle=.. seek=.. [lo=60] [hi=2000] [rpm=N]
import sys, numpy as np
from hdd_analyze import load, db
args=dict(a.split('=',1) for a in sys.argv[2:]); x,sr=load(sys.argv[1])
R=lambda s:[tuple(map(float,r.split('-'))) for r in s.split(',')]
L=int(sr*0.5); nf=4*L; f=np.fft.rfftfreq(nf,1/sr)
def spec(rs):
    acc=0;k=0
    for a,b in rs:
        seg=x[int(a*sr):int(b*sr)]
        for s in range(0,len(seg)-L,L//2): acc=acc+np.abs(np.fft.rfft(seg[s:s+L]*np.hanning(L),nf))**2; k+=1
    return acc/k
Pi=db(spec(R(args['idle']))); Ps=db(spec(R(args['seek']))); lo=float(args.get('lo',60)); hi=float(args.get('hi',2000)); fr0=float(args.get('rpm',0))/60
m=(f>=lo)&(f<hi); idx=[i for i in np.where(m)[0] if Ps[i]==Ps[i-6:i+7].max()]
prom=lambda i: Ps[i]-np.median(Ps[(f>f[i]-60)&(f<f[i]+60)])
idx=sorted(idx,key=lambda i:-Ps[i])[:14]; mx=Ps[m].max()
print(sys.argv[1].split('/')[-1], f"seek-range spectrum peaks {lo:.0f}-{hi:.0f} Hz: Hz(dB re max, rise over idle, prominence)")
print("  "+" ".join(f"{f[i]:.1f}{'' if not fr0 else f'[x{f[i]/fr0:.2f}]'}({Ps[i]-mx:.0f},{Ps[i]-Pi[i]:+.0f},p{prom(i):.0f})" for i in sorted(idx)))
for a,b in [(60,150),(150,300),(300,600),(600,1000),(1000,2000),(2000,5000),(5000,10000),(10000,16000)]:
    mm=(f>=a)&(f<b); print(f"   band {a}-{b}: seek-vs-idle {db((10**(Ps[mm]/10)).sum())-db((10**(Pi[mm]/10)).sum()):+.1f} dB")

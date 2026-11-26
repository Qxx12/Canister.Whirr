# Stepper seek gestures: detect gestures on a band envelope, then resolve the impulse train inside each one.
# Gesture detector: lo..hi band, 1 ms power envelope smoothed over `smooth` ms, > idle median + thr dB, gaps <= merge ms merged.
# Impulses: local maxima of the (unsmoothed, 0.5 ms) band envelope >= pk dB over idle median, >= mind ms apart, inside the gesture.
# Usage: python3 -I run.py stepper_gestures.py <wav> idle=.. seek=.. [lo=800] [hi=1700] [thr=8] [smooth=3] [merge=12] [pk=8] [mind=2.5] [list=1]
import sys, numpy as np
from hdd_analyze import load
a=dict(v.split('=',1) for v in sys.argv[2:]); x,sr=load(sys.argv[1]); N=len(x)
R=lambda s:[tuple(map(float,r.split('-'))) for r in s.split(',')]
lo=float(a.get('lo',800)); hi=float(a.get('hi',1700)); thr=float(a.get('thr',8)); sw=int(a.get('smooth',3)); merge=int(a.get('merge',12))
pkdb=float(a.get('pk',8)); mind=float(a.get('mind',2.5))
X=np.fft.rfft(x); f=np.fft.rfftfreq(N,1/sr); X[(f<lo)|(f>=hi)]=0; y=np.fft.irfft(X,N)
n1=int(sr*0.001); nn=N//n1; pw=(y[:nn*n1].reshape(nn,n1)**2).mean(1); ps=np.convolve(pw,np.ones(sw)/sw,'same'); e=10*np.log10(ps+1e-20)
nh=int(sr*0.0005); nh2=N//nh; eh=10*np.log10((y[:nh2*nh].reshape(nh2,nh)**2).mean(1)+1e-20)
im=np.zeros(nn,bool); sm=np.zeros(nn,bool)
for p,q in R(a['idle']): im[int(p*sr/n1):int(q*sr/n1)]=True
for p,q in R(a['seek']): sm[int(p*sr/n1):int(q*sr/n1)]=True
fl=np.median(e[im]); imh=np.zeros(nh2,bool); imh[:2*nn]=np.repeat(im,2)[:nh2]; flh=np.median(eh[imh]); on=(e>fl+thr)&sm; ev=[]; i=0
while i<nn:
    if on[i]:
        j=i; last=i
        while j<nn and j-last<=merge:
            if on[j]: last=j
            j+=1
        ev.append((i,last+1)); i=last+1
    else: i+=1
md=int(round(mind/0.5)); rows=[]
for s,b in ev:
    seg=eh[2*s-4:2*b+4]-flh; pk=[k for k in range(1,len(seg)-1) if seg[k]>=pkdb and seg[k]==seg[max(0,k-md):k+md+1].max()]
    t=(np.array(pk)-4)*0.5; rows.append((s,b,e[s:b].max()-fl,t))
tot=sum(q-p for p,q in R(a['seek'])); d=np.array([b-s for s,b,_,_ in rows]); npk=np.array([len(t) for *_,t in rows])
print(f"idle band median {fl:.1f} dBFS; gestures n={len(rows)} ({len(rows)/tot:.2f}/s over {tot:.0f} s)")
print(" duration p10/50/90 ms", np.percentile(d,[10,50,90]).round(0).tolist(), "; impulses/gesture p10/50/90", np.percentile(npk,[10,50,90]).round(0).tolist())
print(" impulses-per-gesture histogram:", " ".join(f"{k}:{(npk==k).sum()}" for k in range(0,max(npk)+1) if (npk==k).sum()))
allint=np.concatenate([np.diff(t) for *_,t in rows if len(t)>1]) if any(len(t)>1 for *_,t in rows) else np.array([])
if len(allint): print(" all within-gesture impulse intervals ms p10/25/50/75/90:", np.percentile(allint,[10,25,50,75,90]).round(2).tolist())
o=np.array([s for s,*_ in rows]); 
if len(o)>2: print(" gesture IOI ms p10/50/90:", np.percentile(np.diff(o),[10,50,90]).round(0).tolist())
if a.get('list','1')=='1':
    for s,b,p,t in rows: print(f"  {s*n1/sr:9.3f} {b-s:4d} ms +{p:4.1f} dB  n={len(t):2d}  first={(s*n1/sr+(t[0]/1000 if len(t) else 0)):.4f}  intervals: "+" ".join(f"{v:.1f}" for v in np.diff(t)))

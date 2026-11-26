# Event list per band: 1 ms RMS envelope of each band, onset = > idle-median + thr dB, merged across gaps <= merge ms.
# Prints each event (start s, duration ms, peak dB over idle-band) per band, interleaved in time, plus duration stats.
# Usage: python3 -I run.py bandevents.py <wav> idle=t0-t1[,..] seek=t0-t1[,..] bands=400-3000,8000-16000 [thr=10] [merge=5] [list=1] [smooth=1]
# smooth = moving average of the 1 ms power envelope over that many ms before thresholding (default 1 = none).
import sys, numpy as np
from hdd_analyze import load
a=dict(v.split('=',1) for v in sys.argv[2:]); x,sr=load(sys.argv[1]); N=len(x)
R=lambda s:[tuple(map(float,r.split('-'))) for r in s.split(',')]
X=np.fft.rfft(x); f=np.fft.rfftfreq(N,1/sr); n1=int(sr*0.001); nn=N//n1
thr=float(a.get('thr',10)); merge=int(a.get('merge',5))
im=np.zeros(nn,bool); sm=np.zeros(nn,bool)
for p,q in R(a['idle']): im[int(p*sr/n1):int(q*sr/n1)]=True
for p,q in R(a['seek']): sm[int(p*sr/n1):int(q*sr/n1)]=True
allev=[]
for bi,(lo,hi) in enumerate(R(a.get('bands','400-3000,8000-16000'))):
    Y=X.copy(); Y[(f<lo)|(f>=hi)]=0; y=np.fft.irfft(Y,N); pw=(y[:nn*n1].reshape(nn,n1)**2).mean(1); sw=int(a.get('smooth',1))
    if sw>1: pw=np.convolve(pw,np.ones(sw)/sw,'same')
    e=10*np.log10(pw+1e-20)
    fl=np.median(e[im]); on=(e>fl+thr)&sm; ev=[]; i=0
    while i<nn:
        if on[i]:
            j=i; last=i
            while j<nn and j-last<=merge:
                if on[j]: last=j
                j+=1
            ev.append((i,last+1,e[i:last+1].max()-fl)); i=last+1
        else: i+=1
    d=np.array([b-s for s,b,_ in ev]); o=np.array([s for s,b,_ in ev]); tot=sum(q-p for p,q in R(a['seek']))
    print(f"band {lo:.0f}-{hi:.0f}: idle {fl:.1f} dBFS, n={len(ev)} ({len(ev)/tot:.2f}/s); dur p10/50/90 {np.percentile(d,[10,50,90]).round(0).tolist()} ms; IOI p10/50/90 {np.percentile(np.diff(o),[10,50,90]).round(0).tolist() if len(o)>2 else '-'} ms; peak p10/50/90 {np.percentile([p for _,_,p in ev],[10,50,90]).round(1).tolist()} dB")
    print(f"   dur histogram (ms): "+" ".join(f"{lo_}-{hi_}:{((d>=lo_)&(d<hi_)).sum()}" for lo_,hi_ in [(0,5),(5,10),(10,20),(20,30),(30,40),(40,50),(50,60),(60,80),(80,100),(100,150),(150,9999)]))
    allev+= [(s,b,p,bi) for s,b,p in ev]
if a.get('list','1')=='1':
    for s,b,p,bi in sorted(allev): print(f"  {'AB'[bi] if bi<2 else bi} {s*n1/sr:9.3f} {b-s:4d} ms +{p:.0f}")

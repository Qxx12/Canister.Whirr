# Cluster-level timing: same onset detector as hdd_batch.py (idle-env median + thr dB, 300 Hz+ 1 ms env) but bursts
# closer than merge ms are merged into one "gesture". Reports gesture rate, IOI p10/50/90, gesture length p10/50/90.
# Usage: python3 -I run.py clusters.py <wav> idle=.. seek=.. [merge=50] [thr=12]
import sys, numpy as np
from hdd_analyze import load
args=dict(a.split('=',1) for a in sys.argv[2:]); x,sr=load(sys.argv[1]); N=len(x)
R=lambda s:[tuple(map(float,r.split('-'))) for r in s.split(',')]
X=np.fft.rfft(x); f=np.fft.rfftfreq(N,1/sr); X[(f<300)|(f>min(16000,sr/2-1))]=0; h=np.fft.irfft(X,N)
n=int(sr*0.001); nn=N//n; e=10*np.log10((h[:nn*n].reshape(nn,n)**2).mean(1)+1e-20)
im=np.zeros(nn,bool); sm=np.zeros(nn,bool)
for a,b in R(args['idle']): im[int(a*1000):int(b*1000)]=True
for a,b in R(args['seek']): sm[int(a*1000):int(b*1000)]=True
thr=float(args.get('thr',12)); on=(e>np.median(e[im])+thr)&sm
for merge in [int(v) for v in args.get('merge','15,50').split(',')]:
    ev=[];i=0
    while i<nn:
        if on[i]:
            j=i;last=i
            while j<nn and j-last<=merge:
                if on[j]: last=j
                j+=1
            ev.append((i,last+1)); i=last+1
        else: i+=1
    o=np.array([a for a,b in ev]); d=np.array([b-a for a,b in ev]); ioi=np.diff(o)
    tot=sum(b-a for a,b in R(args['seek']))
    print(f" {sys.argv[1].split('/')[-1]} merge {merge} ms: n={len(ev)} rate={len(ev)/tot:.1f}/s IOI p10/50/90={np.percentile(ioi,[10,50,90]).round(0).tolist()} length p10/50/90={np.percentile(d,[10,50,90]).round(0).tolist()} ms")

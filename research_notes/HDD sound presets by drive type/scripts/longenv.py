# Diagnostic: energy-averaged narrowband (Gaussian) envelopes 0-150 ms after onsets that have >= gap ms
# before the next detected onset and >= 15 ms quiet before; compares tail with the pre-onset and idle levels.
# Usage: python3 -I run.py longenv.py <wav> idle=.. seek=.. freqs=f1,f2,.. [gap=150] [thr=12]
import sys, numpy as np
from hdd_analyze import load
args=dict(a.split('=',1) for a in sys.argv[2:]); p=sys.argv[1]; x,sr=load(p); N=len(x)
X=np.fft.rfft(x); f=np.fft.rfftfreq(N,1/sr); n1=int(sr*0.001)
R=lambda s:[tuple(map(float,r.split('-'))) for r in s.split(',')]
idleR=R(args['idle']); seekR=R(args['seek']); gap=int(args.get('gap',150)); thr=float(args.get('thr',12))
def env(y): nn=len(y)//n1; return 10*np.log10((y[:nn*n1].reshape(nn,n1)**2).mean(1)+1e-20)
Y=X.copy(); Y[(f<300)|(f>min(16000,sr/2-1))]=0; e=env(np.fft.irfft(Y,N)); nn=len(e)
im=np.zeros(nn,bool); sm=np.zeros(nn,bool)
for a,b in idleR: im[int(a*1000):int(b*1000)]=True
for a,b in seekR: sm[int(a*1000):int(b*1000)]=True
on=(e>np.median(e[im])+thr)&sm; ons=[i for i in range(20,nn) if on[i] and not on[i-15:i].any()]
sel=[o for k,o in enumerate(ons) if (k+1==len(ons) or ons[k+1]-o>=gap) and o+160<nn and sm[o:o+gap].all()]
print(f"{p.split('/')[-1]}: onsets {len(ons)}, with >= {gap} ms clear after: {len(sel)}")
for fc in [float(v) for v in args['freqs'].split(',')]:
    fw=max(40.0,fc/25) if fc>=500 else max(30.0,fc/6); s=fw/2.355
    y=np.fft.irfft(X*np.exp(-0.5*((f-fc)/s)**2),N); ye=env(y)
    E=np.mean([10**(ye[o-20:o+150]/10) for o in sel],0); Ed=10*np.log10(E); pk=Ed[20:45].max()
    idle=np.median(ye[im]); pre=Ed[2:16].mean()
    print(f" {fc:6.0f} Hz: pre-onset {pre-pk:+.0f}, idle {idle-pk:+.0f} dB re peak; env 0..150 ms step 5:"," ".join(f"{v:.0f}" for v in (Ed[20::5]-pk)))

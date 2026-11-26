# Impulse-train view of one passage: band-passed (lo..hi) envelope at res ms; prints the envelope as a
# compact dB strip, the local impulse peaks (>= pk dB over the passage's 20th-percentile level, separated
# by >= mind ms) with their inter-impulse intervals, and the envelope autocorrelation peaks (periodicity).
# Usage: python3 -I run.py steps.py <wav> t0 t1 [lo=300] [hi=16000] [res=0.5] [pk=6] [mind=1.0] [strip=1]
import sys, numpy as np
from hdd_analyze import load
a=dict(v.split('=',1) for v in sys.argv[4:]); x,sr=load(sys.argv[1]); t0=float(sys.argv[2]); t1=float(sys.argv[3])
lo=float(a.get('lo',300)); hi=float(a.get('hi',16000)); res=float(a.get('res',0.5)); pkdb=float(a.get('pk',6)); mind=float(a.get('mind',1.0))
pad=int(0.2*sr); s0=max(0,int(t0*sr)-pad); s1=min(len(x),int(t1*sr)+pad); y=x[s0:s1]
Y=np.fft.rfft(y); f=np.fft.rfftfreq(len(y),1/sr); Y[(f<lo)|(f>=hi)]=0; y=np.fft.irfft(Y,len(y))[int(t0*sr)-s0:int(t1*sr)-s0]
n=max(1,int(sr*res/1000)); nn=len(y)//n; e=10*np.log10((y[:nn*n].reshape(nn,n)**2).mean(1)+1e-20)
base=np.percentile(e,20); d=e-base
if a.get('strip','1')=='1':
    print(f"envelope dB over p20 ({base:.1f} dBFS), {res} ms per char, digit = dB/3 (0-9):")
    for k in range(0,nn,100):
        print(f" {t0+k*res/1000:9.4f} "+"".join(str(int(min(9,max(0,v/3)))) for v in d[k:k+100]))
md=max(1,int(round(mind/res))); pk=[i for i in range(1,nn-1) if d[i]>=pkdb and d[i]==d[max(0,i-md):i+md+1].max()]
t=np.array(pk)*res
print(f"impulses (>= {pkdb} dB over p20, >= {mind} ms apart): n={len(pk)}")
if len(pk)>1:
    ii=np.diff(t); print(" times ms:", " ".join(f"{v:.1f}" for v in t)); print(" intervals ms:", " ".join(f"{v:.1f}" for v in ii))
    print(f" interval p10/50/90 = {np.percentile(ii,10):.2f}/{np.median(ii):.2f}/{np.percentile(ii,90):.2f} ms -> rate {1000/np.median(ii):.0f}/s")
lin=10**(d/10); lin=lin-lin.mean(); ac=np.correlate(lin,lin,'full')[nn-1:]; ac/=ac[0]
lags=[i for i in range(2,min(nn-1,int(60/res))) if ac[i]==ac[max(0,i-2):i+3].max() and ac[i]>0.1]
print(" envelope autocorr peaks (lag ms: r):", " ".join(f"{i*res:.1f}:{ac[i]:.2f}" for i in lags[:8]))

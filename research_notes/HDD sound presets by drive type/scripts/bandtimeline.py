# Band-level timeline: 0.5 s blocks, RMS dBFS of each band and crest (p99 - median of the band's 1 ms envelope).
# Usage: python3 -I run.py bandtimeline.py <wav> [bands=40-300,700-3000,3000-16000] [blk=0.5]
import sys, numpy as np
from hdd_analyze import load
a=dict(v.split('=',1) for v in sys.argv[2:]); x,sr=load(sys.argv[1]); N=len(x); blk=float(a.get('blk',0.5))
bands=[tuple(map(float,b.split('-'))) for b in a.get('bands','40-300,700-3000,3000-16000').split(',')]
X=np.fft.rfft(x); f=np.fft.rfftfreq(N,1/sr); n1=int(sr*0.001); B=int(blk*1000); E=[]
for lo,hi in bands:
    Y=X.copy(); Y[(f<lo)|(f>=hi)]=0; y=np.fft.irfft(Y,N); nn=N//n1; E.append(10*np.log10((y[:nn*n1].reshape(nn,n1)**2).mean(1)+1e-20))
print("t: "+" | ".join(f"{lo:.0f}-{hi:.0f} dB/crest" for lo,hi in bands))
rows=[]
for i in range(len(E[0])//B):
    s=f"{i*blk:5.1f}:"+",".join(f"{10*np.log10(np.mean(10**(e[i*B:(i+1)*B]/10))):4.0f}/{np.percentile(e[i*B:(i+1)*B],99)-np.median(e[i*B:(i+1)*B]):2.0f}" for e in E)
    rows.append(s)
for k in range(0,len(rows),6): print("  "+"  ".join(rows[k:k+6]))

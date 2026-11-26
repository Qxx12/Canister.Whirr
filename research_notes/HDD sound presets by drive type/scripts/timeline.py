# 0.5 s block timeline: full-band RMS dBFS / crest (p99 - median of 1 ms 300 Hz+ envelope), as in hdd_batch.py
import sys, numpy as np
from hdd_analyze import load
def bp(x,sr,lo,hi):
    X=np.fft.rfft(x); f=np.fft.rfftfreq(len(x),1/sr); X[(f<lo)|(f>=hi)]=0; return np.fft.irfft(X,len(x))
for p in sys.argv[1:]:
    x,sr=load(p); h=bp(x,sr,300,min(sr/2,16000)); n=int(sr*0.001); nn=len(h)//n
    e=20*np.log10(np.sqrt((h[:nn*n].reshape(nn,n)**2).mean(1))+1e-12); B=500; nb=nn//B
    print(f"### {p.split('/')[-1]} sr={sr} dur={len(x)/sr:.1f}s")
    rows=[]
    for i in range(nb):
        l=10*np.log10(np.mean(x[i*B*n:(i+1)*B*n]**2)+1e-12); c=np.percentile(e[i*B:(i+1)*B],99)-np.median(e[i*B:(i+1)*B])
        rows.append(f"{i*0.5:5.1f}:{l:4.0f}/{c:2.0f}")
    for k in range(0,len(rows),10): print("  "+" ".join(rows[k:k+10]))

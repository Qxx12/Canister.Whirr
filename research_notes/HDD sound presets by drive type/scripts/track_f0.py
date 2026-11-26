# Track the strongest spectral peak in lo..hi Hz in successive blocks (Hann, zero-padded) -> spindle speed during spin-up/-down.
# Usage: python3 -I run.py track_f0.py <wav> t0 t1 [lo=20] [hi=80] [blk=0.5] [mult=1]   (prints f and f*60/mult as rpm)
import sys, numpy as np
from hdd_analyze import load
a=dict(v.split('=',1) for v in sys.argv[4:]); x,sr=load(sys.argv[1]); t0=float(sys.argv[2]); t1=float(sys.argv[3])
lo=float(a.get('lo',20)); hi=float(a.get('hi',80)); blk=float(a.get('blk',0.5)); mult=float(a.get('mult',1))
L=int(blk*sr); nf=1<<18; f=np.fft.rfftfreq(nf,1/sr); m=(f>=lo)&(f<hi); out=[]
for t in np.arange(t0,t1-blk+1e-9,blk):
    P=np.abs(np.fft.rfft(x[int(t*sr):int(t*sr)+L]*np.hanning(L),nf))**2; Pd=10*np.log10(P+1e-20); i=np.where(m)[0][np.argmax(Pd[m])]
    out.append(f"{t:6.1f}:{f[i]:6.1f}Hz({Pd[i]-np.median(Pd[m]):.0f})")
for k in range(0,len(out),8): print("  "+" ".join(out[k:k+8]))

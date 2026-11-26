# Band shares of the event excess (event-window power minus idle power), counting only bins where the event window is
# >= mindb above idle (so masked bands where the bed dominates contribute nothing), unweighted and A-weighted.
# Usage: python3 -I run.py excess_shares.py <wav> idle=t0-t1 times=<file> [w0=-2] [w1=28] [mindb=3]
import sys, numpy as np
from hdd_analyze import load
a=dict(v.split('=',1) for v in sys.argv[2:]); x,sr=load(sys.argv[1]); T=[float(l.split()[0]) for l in open(a['times']) if l.strip()]
i0,i1=map(float,a['idle'].split('-')); w0=float(a.get('w0',-2)); w1=float(a.get('w1',28)); md=float(a.get('mindb',3))
L=int((w1-w0)/1000*sr); win=np.hanning(L); nf=1<<14; fr=np.fft.rfftfreq(nf,1/sr)
P=np.mean([np.abs(np.fft.rfft(x[int(t*sr+w0/1000*sr):int(t*sr+w0/1000*sr)+L]*win,nf))**2 for t in T],0)
Pi=np.mean([np.abs(np.fft.rfft(x[s:s+L]*win,nf))**2 for s in range(int(i0*sr),int(i1*sr)-L,L//2)],0)
k=np.ones(9)/9; Ps=np.convolve(P,k,'same'); Pis=np.convolve(Pi,k,'same')
ex=np.where(Ps>Pis*10**(md/10),Ps-Pis,0); f2=np.maximum(fr,1)**2
aw=((12194**2*f2**2)/((f2+20.6**2)*np.sqrt((f2+107.7**2)*(f2+737.9**2))*(f2+12194**2)))**2
def sh(v):
    t=v[fr>=20].sum(); return " ".join(f"{lo}-{hi}:{100*v[(fr>=lo)&(fr<hi)].sum()/max(t,1e-30):.0f}%" for lo,hi in [(20,300),(300,1000),(1000,5000),(5000,int(sr/2))])
print(f"n={len(T)}, window {w0:.0f}..{w1:.0f} ms, bins >= +{md:.0f} dB over idle: unweighted {sh(ex)} | A-wtd {sh(ex*aw)}")

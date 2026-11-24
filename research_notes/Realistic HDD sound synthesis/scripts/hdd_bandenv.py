import sys, numpy as np
sys.path.insert(0, sys.argv[0].rsplit('/',1)[0])
from hdd_analyze import load, db
def bp(x,sr,lo,hi):
    X=np.fft.rfft(x); f=np.fft.rfftfreq(len(x),1/sr); X[(f<lo)|(f>=hi)]=0; return np.fft.irfft(X,len(x))
def aw(f):
    f2=f**2; ra=(12194**2*f2**2)/((f2+20.6**2)*np.sqrt((f2+107.7**2)*(f2+737.9**2))*(f2+12194**2)); return 20*np.log10(np.maximum(ra,1e-12))+2.0
for arg in sys.argv[1:]:
    p,t0,t1=arg.split('@'); x,sr=load(p); x=x[int(float(t0)*sr):int(float(t1)*sr)]
    n=int(sr*0.001); h=bp(x,sr,300,min(16000,sr/2)); nn=len(h)//n
    e=20*np.log10(np.sqrt((h[:nn*n].reshape(nn,n)**2).mean(1))+1e-12); med=np.median(e)
    on=e>med+12; ons=[i for i in range(3,nn-60) if on[i] and not on[i-1:i].any() and not on[max(0,i-15):i].any()]
    bands=[(150,400),(400,1000),(1000,5000),(5000,min(16000,sr/2-1))]
    print(f"\n## {p.split('/')[-1]} [{t0}-{t1}s] isolated onsets (>=15ms quiet before) n={len(ons)}")
    for lo,hi in bands:
        if lo>=sr/2: continue
        y=bp(x,sr,lo,hi); E=np.zeros(60); 
        for o in ons: seg=y[(o-2)*n:(o+58)*n]; E+=(seg.reshape(60,n)**2).mean(1)
        Ed=10*np.log10(E/len(ons)+1e-20); base=10*np.log10(np.mean([np.mean(y[(o-14)*n:(o-4)*n]**2) for o in ons])+1e-20)
        k=np.argmax(Ed); pkv=Ed[k]
        t10=next((i-k for i in range(k,60) if Ed[i]<pkv-10),None); t20=next((i-k for i in range(k,60) if Ed[i]<pkv-20),None)
        print(f"  {lo:>5}-{hi:<5}Hz: peak {pkv-base:+.1f} dB over pre-onset, at {k-2} ms after onset; -10dB after {t10} ms, -20dB after {t20} ms; env(ms 0..30 step 3): "+" ".join(f"{v:.0f}" for v in (Ed-pkv)[2:33:3]))
    # A-weighted share of event-minus-pre spectrum
    W=int(0.02*sr); nfft=8192; f=np.fft.rfftfreq(nfft,1/sr); Pe=0; Pb=0
    for o in ons:
        Pe=Pe+np.abs(np.fft.rfft(x[(o-1)*n:(o-1)*n+W]*np.hanning(W),nfft))**2
        Pb=Pb+np.abs(np.fft.rfft(x[(o-25)*n:(o-25)*n+W]*np.hanning(W),nfft))**2
    ex=np.maximum(Pe-Pb,0); exA=ex*10**(aw(np.maximum(f,1))/10)
    def share(v):
        t=v[f>=20].sum(); return " ".join(f"{a}-{b}:{100*v[(f>=a)&(f<b)].sum()/t:.0f}%" for a,b in [(20,300),(300,1000),(1000,5000),(5000,int(sr/2))])
    print("  excess energy unweighted:",share(ex)); print("  excess energy A-weighted:",share(exA))
    print(f"  event(20ms) vs pre-onset(20ms) level: {db(Pe.sum())-db(Pb.sum()):+.1f} dB unweighted, {db((Pe*10**(aw(np.maximum(f,1))/10)).sum())-db((Pb*10**(aw(np.maximum(f,1))/10)).sum()):+.1f} dBA")

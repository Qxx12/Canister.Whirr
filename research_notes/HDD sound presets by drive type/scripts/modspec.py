# Periodicity inside one gesture: (a) spectrum of the segment (Hann, zero-padded) in dB over the idle
# spectrum, top peaks; (b) modulation spectrum of the lo..hi band envelope (0.1 ms res), top peaks 40-3000 Hz;
# (c) cepstrum peak of the segment (quefrency 0.3-20 ms) -> pitch of a harmonic/impulse train.
# Usage: python3 -I run.py modspec.py <wav> idle=t0-t1 seg=t0-t1[,t0-t1..] [lo=300] [hi=3000]
import sys, numpy as np
from hdd_analyze import load
a=dict(v.split('=',1) for v in sys.argv[2:]); x,sr=load(sys.argv[1])
R=lambda s:[tuple(map(float,r.split('-'))) for r in s.split(',')]
lo=float(a.get('lo',300)); hi=float(a.get('hi',3000)); nf=1<<16; f=np.fft.rfftfreq(nf,1/sr)
i0,i1=R(a['idle'])[0]; L=int(0.04*sr)
idl=np.mean([np.abs(np.fft.rfft(x[s:s+L]*np.hanning(L),nf))**2 for s in range(int(i0*sr),int(i1*sr)-L,L)],0)
def peaks(v,fr,flo,fhi,n,mind):
    m=np.where((fr>=flo)&(fr<fhi))[0]; idx=[i for i in m if v[i]==v[max(0,i-3):i+4].max()]; out=[]
    for i in sorted(idx,key=lambda i:-v[i]):
        if all(abs(fr[i]-fr[j])>mind for j in out): out.append(i)
        if len(out)>=n: break
    return sorted(out)
for t0,t1 in R(a['seg']):
    s=x[int(t0*sr):int(t1*sr)]; Ls=len(s); w=np.hanning(Ls)
    P=np.abs(np.fft.rfft(s*w,nf))**2*(L/Ls)  # scale to the idle window length (energy per window)
    D=10*np.log10(P+1e-20)-10*np.log10(idl+1e-20)
    pk=peaks(D,f,150,6000,12,25)
    print(f"seg {t0:.3f}-{t1:.3f} ({1000*(t1-t0):.0f} ms): spectrum peaks Hz(+dB over idle):"," ".join(f"{f[i]:.0f}(+{D[i]:.0f})" for i in pk))
    S=np.fft.rfft(s); fs=np.fft.rfftfreq(Ls,1/sr); S[(fs<lo)|(fs>=hi)]=0; y=np.fft.irfft(S,Ls)
    n=int(sr*0.0001); nn=Ls//n; env=(y[:nn*n].reshape(nn,n)**2).mean(1); env=env-env.mean()
    M=np.abs(np.fft.rfft(env*np.hanning(nn),1<<14))**2; fm=np.fft.rfftfreq(1<<14,n/sr); Md=10*np.log10(M+1e-30); Md-=Md[(fm>40)&(fm<3000)].max()
    pm=peaks(Md,fm,40,3000,8,20)
    print("   envelope modulation peaks Hz(dB re max):"," ".join(f"{fm[i]:.0f}({Md[i]:.0f})" for i in pm))
    c=np.fft.irfft(np.log(np.abs(np.fft.rfft(s*w,nf))+1e-9)); q=np.arange(len(c))/sr*1000
    m=(q>0.3)&(q<20); j=np.where(m)[0][np.argmax(c[m])]; 
    top=sorted(np.where(m)[0],key=lambda k:-c[k])[:1]
    print(f"   cepstrum peak quefrency {q[j]:.2f} ms (-> {1000/q[j]:.0f} Hz), height {c[j]/np.std(c[m]):.1f} sd")

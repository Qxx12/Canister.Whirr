import sys, numpy as np
sys.path.insert(0, sys.argv[0].rsplit('/',1)[0])
from hdd_analyze import load, db, peaks, centroid, smooth
def bandfilt(x,sr,lo,hi):
    X=np.fft.rfft(x); f=np.fft.rfftfreq(len(x),1/sr); X[(f<lo)|(f>=hi)]=0; return np.fft.irfft(X,len(x))
p=sys.argv[1]; x,sr=load(p)
if len(sys.argv)>3: x=x[int(float(sys.argv[2])*sr):int(float(sys.argv[3])*sr)]
print("=====",p.split('/')[-1])
N=int(0.02*sr); nf=len(x)//N; fr=x[:nf*N].reshape(nf,N); e=10*np.log10((fr**2).mean(1)+1e-20)
lo=e<=np.percentile(e,15); hi=e>=np.percentile(e,90)
nfft=8192; win=np.hanning(N)
S=np.abs(np.fft.rfft(fr*win,nfft,axis=1))**2; f=np.fft.rfftfreq(nfft,1/sr)
Pb=smooth(S[lo].mean(0),9); Pe=smooth(S[hi].mean(0),9)
print(f"levels: quiet15% mean {e[lo].mean():.1f} dBFS, loud10% mean {e[hi].mean():.1f} dBFS, diff {e[hi].mean()-e[lo].mean():.1f} dB (20ms frames)")
print("BACKGROUND peaks:",peaks(f,Pb,8,lo=30,mind=40))
ex=np.maximum(Pe-Pb,1e-20)
print("EXCESS (loud minus quiet) centroid %.0f Hz; peaks:"%centroid(f,ex,40),peaks(f,ex,8,lo=40,mind=100))
cs=[63,100,160,250,400,630,1000,1600,2500,4000,6300,10000]
row=[]
for c in cs:
    if c*1.12<sr/2:
        m=(f>=c/1.12)&(f<c*1.12); row.append((c,round(db(Pe[m].mean())-db(Pb[m].mean()),1),round(db(ex[m].mean())-db(ex[f>40].max()),1)))
print("1/3oct: (fc, loud-vs-quiet dB, excess dB re its max):",row)
tot=ex[f>=20].sum()
for a,b in [(20,300),(300,1000),(1000,5000),(5000,sr/2)]:
    m=(f>=a)&(f<b); print(f"  excess energy {a}-{int(b)} Hz: {100*ex[m].sum()/tot:.1f}%")
# band envelopes for strongest events
fl=max(1,int(sr*0.0005))
bands=[(20,300),(300,1000),(1000,5000)]
B=[bandfilt(x,sr,a,b) for a,b in bands]
full=bandfilt(x,sr,300,sr/2)
n1=int(sr*0.001); nn=len(full)//n1; env=20*np.log10(np.sqrt((full[:nn*n1].reshape(nn,n1)**2).mean(1))+1e-12)
order=np.argsort(env)[::-1]; picked=[]
for i in order:
    if all(abs(i-j)>60 for j in picked): picked.append(i)
    if len(picked)>=4: break
for k in sorted(picked):
    s=max(0,(k-5)*n1); print(f" event @ {s/sr:.3f}s; per-band 1ms RMS dB (rel. each band's own peak), 0..40ms:")
    for (a,b),y in zip(bands,B):
        seg=y[s:s+40*n1]; r=20*np.log10(np.sqrt((seg[:len(seg)//n1*n1].reshape(-1,n1)**2).mean(1))+1e-12)
        print(f"   {a:>4}-{b:<4}Hz abs {r.max():6.1f}dBFS:", " ".join(f"{v:4.0f}" for v in (r-r.max())[:40]))

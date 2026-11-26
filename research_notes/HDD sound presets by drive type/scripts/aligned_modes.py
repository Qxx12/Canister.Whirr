# Mode list from events aligned on given times (e.g. impulse peaks found by stepper_gestures.py), same decay method as
# preset_measure.py: Gaussian narrowband envelope (FWHM max(40 Hz, f/25); f/6 below 500 Hz), energy-averaged over events,
# 1 ms frames; hold = ms until -3 dB; T60 from a line fit from the -3 dB point to max(pre+3, peak-25) dB; Q = pi f T60/6.91.
# Peaks are picked from the averaged excess spectrum (window w0..w1 ms after the alignment time, minus idle).
# Usage: python3 -I run.py aligned_modes.py <wav> idle=t0-t1 times=<file> [w0=-2] [w1=38] [nmodes=16] [post=150] [freqs=f1,f2..] [fmin=120] [fmax=12000]
import sys, numpy as np
from hdd_analyze import load
a=dict(v.split('=',1) for v in sys.argv[2:]); x,sr=load(sys.argv[1]); N=len(x)
T=[float(l.split()[0]) for l in open(a['times']) if l.strip()]; i0,i1=map(float,a['idle'].split('-'))
w0=float(a.get('w0',-2)); w1=float(a.get('w1',38)); post=int(a.get('post',150)); nm=int(a.get('nmodes',16)); fmin=float(a.get('fmin',120)); fmax=float(a.get('fmax',12000))
L=int((w1-w0)/1000*sr); win=np.hanning(L); nf=1<<15; fr=np.fft.rfftfreq(nf,1/sr)
P=np.mean([np.abs(np.fft.rfft(x[int(t*sr+w0/1000*sr):int(t*sr+w0/1000*sr)+L]*win,nf))**2 for t in T],0)
Pi=np.mean([np.abs(np.fft.rfft(x[s:s+L]*win,nf))**2 for s in range(int(i0*sr),int(i1*sr)-L,L//2)],0)
ex=np.maximum(P-Pi,1e-20); D=10*np.log10(ex); A=lambda f2:(12194**2*f2**2)/((f2+20.6**2)*np.sqrt((f2+107.7**2)*(f2+737.9**2))*(f2+12194**2))
aw=A(np.maximum(fr,1)**2)**2
def sh(v):
    t=v[fr>=20].sum(); return " ".join(f"{lo}-{hi}:{100*v[(fr>=lo)&(fr<hi)].sum()/t:.0f}%" for lo,hi in [(20,300),(300,1000),(1000,5000),(5000,sr/2)])
print(f"n={len(T)} events; excess (window {w0:.0f}..{w1:.0f} ms minus idle) unweighted {sh(ex)} | A-wtd {sh(ex*aw)}")
print(f" window vs idle: {10*np.log10(P.sum()/Pi.sum()):+.1f} dB, {10*np.log10((P*aw).sum()/(Pi*aw).sum()):+.1f} dBA; octave:"," ".join(f"{c}:{10*np.log10(P[(fr>=c/1.41)&(fr<c*1.41)].sum()/Pi[(fr>=c/1.41)&(fr<c*1.41)].sum()):+.0f}" for c in [63,125,250,500,1000,2000,4000,8000,12500]))
if 'freqs' in a: sel=[float(v) for v in a['freqs'].split(',')]
else:
    Dr=10*np.log10(P+1e-20)-10*np.log10(Pi+1e-20); m=np.where((fr>=fmin)&(fr<fmax))[0]
    idx=[i for i in m if Dr[i]==Dr[max(0,i-6):i+7].max() and Dr[i]>3]; sel=[]
    for i in sorted(idx,key=lambda i:-D[i]):
        if all(abs(fr[i]-s)>max(30,0.03*fr[i]) for s in sel): sel.append(fr[i])
        if len(sel)>=nm: break
X=np.fft.rfft(x); f=np.fft.rfftfreq(N,1/sr); n1=sr/1000.0
rows=[]
for fc in sorted(sel):
    fw=max(40.0,fc/25) if fc>=500 else max(30.0,fc/6); s=fw/2.355; y=np.fft.irfft(X*np.exp(-0.5*((f-fc)/s)**2),N)**2
    E=np.mean([[y[int(t*sr+k*n1):int(t*sr+(k+1)*n1)].mean() for k in range(-15,post)] for t in T],0); Ed=10*np.log10(E+1e-20)
    idle=10*np.log10(np.median([y[int(q):int(q+n1)].mean() for q in np.arange(i0*sr,i1*sr-n1,n1*7)])+1e-20)
    pre=Ed[1:11].mean(); kk=15+int(np.argmax(Ed[15:60])); pk=Ed[kk]
    h3=next((j for j in range(kk,len(Ed)) if Ed[j]<pk-3),None); t10=next((j-kk for j in range(kk,len(Ed)) if Ed[j]<pk-10),None)
    Tq=np.nan
    if h3 is not None:
        stopv=max(pre+3,pk-25); st=next((j for j in range(h3,len(Ed)) if Ed[j]<stopv),len(Ed))
        if st-h3>=3:
            sl=np.polyfit(np.arange(h3,st),Ed[h3:st],1)[0]
            if sl<0: Tq=-60/sl
    Ta=np.nan  # alternative fit ignoring the pre-onset floor: from the -3 dB point to the first frame below peak-12 dB
    if h3 is not None:
        st=next((j for j in range(h3,len(Ed)) if Ed[j]<pk-12),None)
        if st is not None and st-h3>=3:
            sl=np.polyfit(np.arange(h3,st+1),Ed[h3:st+1],1)[0]
            if sl<0: Ta=-60/sl
    rows.append((fc,pk,pk-idle,pk-pre,kk-15,(h3-kk) if h3 else None,t10,Tq,Ta))
ref=max(r[1] for r in rows)
print("    hz | dB re max | over idle / over pre | pk delay ms | hold ms | -10dB ms | T60 ms -> Q | alt T60(-3..-12 dB) -> Q")
for fc,pk,oi,op,dl,hold,t10,Tq,Ta in rows:
    print(f"  {fc:6.0f} | {pk-ref:6.1f} | +{oi:.0f} / +{op:.0f} | {dl:3d} | {hold} | {t10} | {Tq:5.0f} -> Q {np.pi*fc*Tq/1000/6.91:6.1f} | {Ta:5.0f} -> Q {np.pi*fc*Ta/1000/6.91:6.1f}")

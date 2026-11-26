# Synchronous (energy) average of many gestures aligned on a list of times: band envelopes at 0.5 ms from -pre to +post ms,
# printed as dB re each band's peak; plus the averaged spectrum (dB over idle) in chosen windows relative to the alignment time.
# Usage: python3 -I run.py gesture_avg.py <wav> idle=t0-t1 times=<file with one time (s) per line> [pre=10] [post=120]
#        [bands=300-800,800-1250,1250-1700,1700-4000,4000-16000,60-300] [wins=0:4,5:30,60:100] [step=1]
import sys, numpy as np
from hdd_analyze import load
a=dict(v.split('=',1) for v in sys.argv[2:]); x,sr=load(sys.argv[1]); N=len(x)
T=[float(l.split()[0]) for l in open(a['times']) if l.strip()]; pre=int(a.get('pre',10)); post=int(a.get('post',120)); step=float(a.get('step',1))
i0,i1=map(float,a['idle'].split('-'))
bands=[tuple(map(float,b.split('-'))) for b in a.get('bands','60-300,300-800,800-1250,1250-1700,1700-4000,4000-16000').split(',')]
X=np.fft.rfft(x); f=np.fft.rfftfreq(N,1/sr); h=sr*0.0005
print(f"n={len(T)} aligned gestures; env in dB re band peak (and band peak over idle median), every {step} ms from -{pre} ms:")
for lo,hi in bands:
    Y=X.copy(); Y[(f<lo)|(f>=hi)]=0; y=np.fft.irfft(Y,N)**2
    E=np.mean([[y[int(t*sr+k*h):int(t*sr+(k+1)*h)].mean() for k in range(-2*pre,2*post)] for t in T],0)
    idle=np.median([y[int(s):int(s+h)].mean() for s in np.arange(i0*sr,i1*sr-h,h)])
    Ed=10*np.log10(E+1e-20); pk=Ed.max(); kk=int(np.argmax(Ed))
    print(f" {lo:5.0f}-{hi:5.0f} Hz: peak +{pk-10*np.log10(idle):.1f} dB over idle median at {(kk-2*pre)/2:.1f} ms; idle at {10*np.log10(idle)-pk:.0f} dB re peak")
    sel=Ed[::int(2*step)]-pk; print("   "+" ".join(f"{v:.0f}" for v in sel))
nf=1<<14; fr=np.fft.rfftfreq(nf,1/sr)
for wdef in a.get('wins','0:4,5:30,60:100').split(','):
    w0,w1=map(float,wdef.split(':')); L=int((w1-w0)/1000*sr); win=np.hanning(L)
    P=np.mean([np.abs(np.fft.rfft(x[int(t*sr+w0/1000*sr):int(t*sr+w0/1000*sr)+L]*win,nf))**2 for t in T],0)
    Pi=np.mean([np.abs(np.fft.rfft(x[s:s+L]*win,nf))**2 for s in range(int(i0*sr),int(i1*sr)-L,L)],0)
    D=10*np.log10(P+1e-20)-10*np.log10(Pi+1e-20); m=(fr>=150)&(fr<12000)
    idx=[i for i in np.where(m)[0] if D[i]==D[max(0,i-4):i+5].max()]; out=[]
    for i in sorted(idx,key=lambda i:-D[i]):
        if all(abs(fr[i]-fr[j])>max(40,0.04*fr[i]) for j in out): out.append(i)
        if len(out)>=14: break
    oct_=" ".join(f"{c}:{10*np.log10(P[(fr>=c/1.41)&(fr<c*1.41)].sum()/Pi[(fr>=c/1.41)&(fr<c*1.41)].sum()):+.0f}" for c in [125,250,500,1000,2000,4000,8000])
    print(f" window {w0:.0f}-{w1:.0f} ms: octave dB over idle {oct_}\n   peaks Hz(+dB over idle): "+" ".join(f"{fr[i]:.0f}(+{D[i]:.0f})" for i in sorted(out)))

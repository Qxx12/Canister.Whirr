import wave, numpy as np, sys
def load(p):
    w=wave.open(p); return np.frombuffer(w.readframes(w.getnframes()),np.int16)/32768
names=sys.argv[1:]
cent=[125*2**(k/3) for k in range(0,21)]  # 125 Hz .. 12.7 kHz third-octaves
print("drive".ljust(24),"maxΔband dB","meanΔ","env corr","rmsΔ dB")
for n in names:
    a=load(f'render/{__import__("os").environ.get("OUT","out")}/{n}.wav'); b=load(f'bench/js_out/{n}.wav'); m=min(len(a),len(b)); a,b=a[:m],b[:m]
    def bands(x):
        N=4096; fr=np.fft.rfftfreq(N,1/48000); P=np.zeros(len(fr)); 
        for s in range(0,len(x)-N,N//2): P+=np.abs(np.fft.rfft(x[s:s+N]*np.hanning(N)))**2
        return np.array([10*np.log10(P[(fr>=c/2**(1/6))&(fr<c*2**(1/6))].sum()+1e-12) for c in cent])
    A,B=bands(a),bands(b); A-=A.max(); B-=B.max(); keep=A>-30
    d=(B-A)[keep]
    f=480; ea=np.sqrt(np.convolve(a**2,np.ones(f)/f,'valid')[::f]); eb=np.sqrt(np.convolve(b**2,np.ones(f)/f,'valid')[::f])
    la,lb=20*np.log10(ea+1e-6),20*np.log10(eb+1e-6)
    corr=np.corrcoef(la,lb)[0,1]
    print(n.ljust(24), f"{np.abs(d).max():6.1f}", f"{d.mean():6.1f}", f"{corr:8.3f}", f"{20*np.log10(np.sqrt((b**2).mean())/np.sqrt((a**2).mean())):6.1f}")

import sys, wave, numpy as np
def load(p):
    w=wave.open(p); sr=w.getframerate(); n=w.getnframes(); ch=w.getnchannels()
    x=np.frombuffer(w.readframes(n),dtype='<i2').astype(np.float64)/32768.0
    x=x.reshape(-1,ch).mean(1); return x,sr
def db(v): return 10*np.log10(np.maximum(v,1e-20))
def welch(x,sr,nfft=4096):
    hop=nfft//2; win=np.hanning(nfft); acc=0;k=0
    for i in range(0,len(x)-nfft,hop):
        acc=acc+np.abs(np.fft.rfft(x[i:i+nfft]*win))**2;k+=1
    return np.fft.rfftfreq(nfft,1/sr),acc/max(k,1)
def bands(f,P,edges):
    tot=P[(f>=20)].sum(); out=[]
    for lo,hi in edges:
        m=(f>=lo)&(f<hi); out.append((lo,hi,100*P[m].sum()/tot))
    return out
def centroid(f,P,lo=20): m=f>=lo; return (f[m]*P[m]).sum()/P[m].sum()
def peaks(f,P,n=6,lo=40,mind=150):
    Pd=db(P); idx=[i for i in range(2,len(P)-2) if f[i]>=lo and Pd[i]==Pd[i-2:i+3].max()]
    idx=sorted(idx,key=lambda i:-Pd[i]); sel=[]
    for i in idx:
        if all(abs(f[i]-f[j])>mind for j in sel): sel.append(i)
        if len(sel)>=n: break
    mx=Pd[f>=lo].max(); return [(round(f[i]),round(Pd[i]-mx,1)) for i in sel]
def bw10(f,P,lo=40):
    Pd=db(P); m=f>=lo; i0=np.argmax(np.where(m,Pd,-1e9)); thr=Pd[i0]-10
    a=i0
    while a>0 and Pd[a]>thr: a-=1
    b=i0
    while b<len(P)-1 and Pd[b]>thr: b+=1
    return round(f[i0]),round(f[a]),round(f[b])
def smooth(P,k=5): return np.convolve(P,np.ones(k)/k,mode='same')
def analyze(p, t0=None, t1=None, thr_db=10.0, hp=0):
    x,sr=load(p)
    if t0 is not None: x=x[int(t0*sr):int(t1*sr) if t1 else None]
    print(f"\n===== {p.split('/')[-1]}  sr={sr} dur={len(x)/sr:.2f}s")
    f,P=welch(x,sr)
    print("Long-term spectrum: centroid %.0f Hz"%centroid(f,P))
    edges=[(20,150),(150,300),(300,1000),(1000,2500),(2500,5000),(5000,sr/2)]
    print("  band energy %:",[(a,int(b),round(c,1)) for a,b,c in bands(f,P,edges)])
    print("  peaks (Hz, dB re max):",peaks(f,smooth(P),8))
    # envelope 1 ms RMS
    if hp:
        X=np.fft.rfft(x); fr=np.fft.rfftfreq(len(x),1/sr); X[fr<hp]=0; xe=np.fft.irfft(X,len(x))
    else: xe=x
    fl=max(1,int(sr*0.001)); nf=len(xe)//fl
    e=np.sqrt((xe[:nf*fl].reshape(nf,fl)**2).mean(1)+1e-20); edb=20*np.log10(e)
    floor=np.percentile(edb,10); med=np.percentile(edb,50); p99=np.percentile(edb,99.5)
    print(f"  1ms env dBFS: p10(floor)={floor:.1f} median={med:.1f} p99.5={p99:.1f} max={edb.max():.1f}")
    # overall levels in 50 ms windows
    fl2=int(sr*0.05); n2=len(x)//fl2; e2=20*np.log10(np.sqrt((x[:n2*fl2].reshape(n2,fl2)**2).mean(1))+1e-12)
    print(f"  50ms RMS dBFS: p5={np.percentile(e2,5):.1f} p50={np.percentile(e2,50):.1f} p95={np.percentile(e2,95):.1f}")
    # events
    on=edb>floor+thr_db; ev=[]; i=0
    while i<nf:
        if on[i]:
            j=i
            while j<nf and (on[j] or (j+1<nf and on[j+1]) or (j+2<nf and on[j+2])): j+=1
            ev.append((i,j)); i=j
        else: i+=1
    ev=[(a,b) for a,b in ev if b-a>=1]
    print(f"  events (>{thr_db} dB over floor, 1ms frames, gap-merge 2ms): {len(ev)}")
    if not ev: return
    durs=np.array([b-a for a,b in ev]); pk=np.array([edb[a:b].max() for a,b in ev])
    onsets=np.array([a for a,b in ev])/1000.0
    att=[]; dec=[]
    for a,b in ev:
        k=a+np.argmax(edb[a:b]); att.append(k-a)
        # decay: frames from peak until env drops 20 dB below peak or reaches floor+3
        tgt=max(edb[k]-20,floor+3); m=k
        while m<nf-1 and edb[m]>tgt: m+=1
        drop=edb[k]-edb[m]; 
        if drop>0 and m>k: dec.append(60*(m-k)/drop)  # extrapolated T60 ms
    q=lambda v: np.percentile(v,[10,50,90]).round(1).tolist()
    print("  duration ms p10/50/90:",q(durs),"  peak-over-floor dB:",q(pk-floor))
    print("  attack (onset->peak) ms:",q(att),"  extrapolated T60 ms:",q(dec) if dec else None)
    if len(onsets)>2:
        ioi=np.diff(onsets)*1000; print("  inter-onset ms p10/25/50/75/90:",np.percentile(ioi,[10,25,50,75,90]).round(1).tolist(), " rate/s=%.1f"%(len(onsets)/(len(x)/sr)))
    # event-averaged spectrum: 20 ms window from 1 ms pre-onset, minus floor spectrum
    W=int(0.02*sr); nfft=8192; acc=0; cnt=0
    for a,b in ev:
        s=int((a-1)*fl); seg=x[max(0,s):max(0,s)+W]
        if len(seg)<W: continue
        seg=seg*np.hanning(W); acc=acc+np.abs(np.fft.rfft(seg,nfft))**2; cnt+=1
    fe=np.fft.rfftfreq(nfft,1/sr); Pe=smooth(acc/cnt,9)
    print(f"  EVENT spectrum (n={cnt}, 20ms win): centroid {centroid(fe,Pe):.0f} Hz")
    print("   band %:",[(a,int(b),round(c,1)) for a,b,c in bands(fe,Pe,edges)])
    print("   peaks:",peaks(fe,Pe,8))
    print("   main peak & -10dB edges:",bw10(fe,Pe))
    # 1/3-octave-ish profile
    cs=[100,160,250,400,630,1000,1600,2500,4000,6300,10000]
    Pd=db(Pe); mx=Pd[fe>40].max(); prof=[]
    for c in cs:
        if c*1.12<sr/2:
            m=(fe>=c/1.12)&(fe<c*1.12); prof.append((c,round(db(Pe[m].mean())-mx,1)))
    print("   1/3-oct profile dB re peak bin:",prof)
    return ev,edb,floor
if __name__=="__main__":
    p=sys.argv[1]; t0=float(sys.argv[2]) if len(sys.argv)>2 else None; t1=float(sys.argv[3]) if len(sys.argv)>3 else None
    thr=float(sys.argv[4]) if len(sys.argv)>4 else 10.0
    analyze(p,t0,t1,thr)

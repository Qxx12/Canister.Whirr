import sys, numpy as np
sys.path.insert(0, sys.argv[0].rsplit('/',1)[0])
from hdd_analyze import load, db, smooth, centroid
def bp(x,sr,lo,hi):
    X=np.fft.rfft(x); f=np.fft.rfftfreq(len(x),1/sr); X[(f<lo)|(f>=hi)]=0; return np.fft.irfft(X,len(x))
def pk(f,P,n=6,lo=40,mind=120):
    Pd=db(P); idx=[i for i in range(3,len(P)-3) if f[i]>=lo and Pd[i]==Pd[i-3:i+4].max()]
    idx=sorted(idx,key=lambda i:-Pd[i]); sel=[]
    for i in idx:
        if all(abs(f[i]-f[j])>mind for j in sel): sel.append(i)
        if len(sel)>=n: break
    mx=Pd[f>=lo].max(); return " ".join(f"{f[i]:.0f}({Pd[i]-mx:.0f})" for i in sel)
for p in sys.argv[1:]:
    x,sr=load(p); name=p.split('/')[-1]
    h=bp(x,sr,300,min(sr/2,16000)); n=int(sr*0.001); nn=len(h)//n
    e=20*np.log10(np.sqrt((h[:nn*n].reshape(nn,n)**2).mean(1))+1e-12)
    B=500; nb=nn//B
    lvl=np.array([10*np.log10(np.mean(x[i*B*n:(i+1)*B*n]**2)+1e-12) for i in range(nb)])
    crest=np.array([np.percentile(e[i*B:(i+1)*B],99)-np.median(e[i*B:(i+1)*B]) for i in range(nb)])
    floor=np.percentile(lvl,2)
    tl=" ".join(f"{l:.0f}/{c:.0f}" for l,c in zip(lvl,crest))
    spin=lvl>floor+5; seek=(crest>=10)&spin; idle=(crest<7)&spin&(np.abs(lvl-np.median(lvl[spin]))<4)
    print(f"\n### {name} sr={sr} dur={len(x)/sr:.1f}s  room-floor(p5 0.5s)={floor:.1f} dBFS")
    pass
    if seek.sum()<2 or idle.sum()<2: print("  insufficient seek/idle blocks", seek.sum(), idle.sum()); continue
    # spindle tone in idle
    nf=int(sr*0.5); f=np.fft.rfftfreq(nf*4,1/sr)
    def blockspec(mask):
        acc=0
        for i in np.where(mask)[0]: acc=acc+np.abs(np.fft.rfft(x[i*nf:(i+1)*nf]*np.hanning(nf),nf*4))**2
        return acc/mask.sum()
    Pi=blockspec(idle); Ps=blockspec(seek)
    print(f"  idle blocks={idle.sum()} level={np.mean(lvl[idle]):.1f} dBFS; seek blocks={seek.sum()} level={np.mean(lvl[seek]):.1f} dBFS (avg RMS diff {np.mean(lvl[seek])-np.mean(lvl[idle]):.1f} dB)")
    print("  IDLE peaks Hz(dB):",pk(f,smooth(Pi,3),8,lo=40,mind=15))
    # events within seek blocks
    ef=e.copy(); m=np.zeros(nn,bool)
    for i in np.where(seek)[0]: m[i*B:(i+1)*B]=True
    idle_env=np.concatenate([e[i*B:(i+1)*B] for i in np.where(idle)[0]]); ifl=np.median(idle_env)
    on=(e>ifl+12)&m; ev=[];i=0
    while i<nn:
        if on[i]:
            j=i; last=i
            while j<nn and j-last<=3:
                if on[j]: last=j
                j+=1
            ev.append((i,last+1)); i=last+1
        else: i+=1
    if len(ev)<3: print("  few events"); continue
    d=np.array([b-a for a,b in ev]); o=np.array([a for a,b in ev]); pkv=np.array([e[a:b].max() for a,b in ev])
    ioi=np.diff(o); ioi=ioi[ioi<400]
    dec=[]
    for a,b in ev:
        k=a+np.argmax(e[a:b]); t=max(e[k]-20,ifl+3); q=k
        while q<nn-1 and e[q]>t: q+=1
        if q>k and e[k]-e[q]>0: dec.append(60*(q-k)/(e[k]-e[q]))
    pr=lambda v: "/".join(f"{z:.0f}" for z in np.percentile(v,[10,50,90]))
    print(f"  events(>idle-env-median+12dB, 300Hz+ 1ms env, 3ms merge): n={len(ev)} rate={len(ev)/(seek.sum()*0.5):.1f}/s in seek blocks; dur ms {pr(d)}; peak over idle env {pr(pkv-ifl)} dB; IOI(<400ms) ms {pr(ioi) if len(ioi) else '-'}; T60-extrap ms {pr(dec) if dec else '-'}")
    W=int(0.02*sr); nfft=8192; acc=0; cnt=0
    for a,b in ev:
        s=(a-1)*n; seg=x[s:s+W]
        if s>0 and len(seg)==W: acc=acc+np.abs(np.fft.rfft(seg*np.hanning(W),nfft))**2; cnt+=1
    fe=np.fft.rfftfreq(nfft,1/sr); Pe=smooth(acc/cnt,7)
    # idle reference in same window size
    acc2=0;c2=0
    for i in np.where(idle)[0]:
        for s in range(i*nf, (i+1)*nf-W, W): acc2=acc2+np.abs(np.fft.rfft(x[s:s+W]*np.hanning(W),nfft))**2; c2+=1
    Pid=smooth(acc2/c2,7); ex=np.maximum(Pe-Pid,1e-20)
    tot=ex[fe>=20].sum(); fr=lambda a,b: 100*ex[(fe>=a)&(fe<b)].sum()/tot
    print(f"  EVENT-minus-IDLE spectrum: centroid {centroid(fe,ex,40):.0f} Hz; energy <300:{fr(20,300):.0f}% 300-1k:{fr(300,1000):.0f}% 1-5k:{fr(1000,5000):.0f}% 5-16k:{fr(5000,16000):.0f}%")
    print("   peaks Hz(dB re max):",pk(fe,ex,8,lo=40,mind=150))
    cs=[63,125,250,500,1000,2000,4000,8000,12500]
    print("   octave bands event-vs-idle dB:"," ".join(f"{c}:{db(Pe[(fe>=c/1.41)&(fe<c*1.41)].mean())-db(Pid[(fe>=c/1.41)&(fe<c*1.41)].mean()):+.0f}" for c in cs if c*1.41<sr/2))
    print("   octave bands excess shape dB re max:"," ".join(f"{c}:{db(ex[(fe>=c/1.41)&(fe<c*1.41)].mean())-max(db(ex[(fe>=cc/1.41)&(fe<cc*1.41)].mean()) for cc in cs if cc*1.41<sr/2):.0f}" for c in cs if c*1.41<sr/2))

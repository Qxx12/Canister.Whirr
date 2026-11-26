import sys, numpy as np
sys.path.insert(0, sys.argv[0].rsplit('/',1)[0])
from hdd_analyze import load, db, smooth
def bp(x,sr,lo,hi):
    X=np.fft.rfft(x); f=np.fft.rfftfreq(len(x),1/sr); X[(f<lo)|(f>=hi)]=0; return np.fft.irfft(X,len(x))
def bw3(f,P,fc,span=0.5):
    Pd=db(P); m=(f>fc*(1-span))&(f<fc*(1+span)); i0=np.where(m)[0][np.argmax(Pd[m])]; t=Pd[i0]-3
    a=i0
    while Pd[a]>t: a-=1
    b=i0
    while Pd[b]>t: b+=1
    return f[i0], f[b]-f[a], f[i0]/max(f[b]-f[a],1e-9)
def ringdecay(x,sr,fc,width,onsets,win=0.06):
    y=bp(x,sr,fc-width/2,fc+width/2); n=int(sr*0.001); out=[]
    for t in onsets:
        s=int(t*sr); seg=y[s:s+int(win*sr)]
        if len(seg)<int(win*sr): continue
        e=20*np.log10(np.sqrt((seg[:len(seg)//n*n].reshape(-1,n)**2).mean(1))+1e-12)
        k=np.argmax(e[:10]); tail=e[k:k+40]; tt=np.arange(len(tail))
        # fit first 15 ms or until floor
        L=min(len(tail),15); sl=np.polyfit(tt[:L],tail[:L],1)[0]
        if sl<0: out.append(-60/sl)
    return np.percentile(out,[25,50,75]).round(0).tolist() if out else None
mode=sys.argv[1]; p=sys.argv[2]; x,sr=load(p)
print("=====",p.split('/')[-1],sr,len(x)/sr)
if mode=="seek":
    # onsets via 300Hz+ 1ms envelope
    h=bp(x,sr,300,sr/2); n=int(sr*0.001); nn=len(h)//n; e=20*np.log10(np.sqrt((h[:nn*n].reshape(nn,n)**2).mean(1))+1e-12)
    fl=np.percentile(e,10)
    for thr,gap in [(10,2),(15,5),(15,15)]:
        on=e>fl+thr; ev=[];i=0
        while i<nn:
            if on[i]:
                j=i; last=i
                while j<nn and j-last<=gap:
                    if on[j]: last=j
                    j+=1
                ev.append((i,last+1)); i=last+1
            else: i+=1
        d=np.array([b-a for a,b in ev]); o=np.array([a for a,b in ev])/1000
        ioi=np.diff(o)*1000
        print(f" thr+{thr}dB gap{gap}ms: n={len(ev)} rate={len(ev)/(len(x)/sr):.1f}/s dur p10/50/90={np.percentile(d,[10,50,90]).tolist()} IOI p10/50/90={np.percentile(ioi,[10,50,90]).round(0).tolist()}")
    on=e>fl+15; onsets=[i/1000 for i in range(1,nn) if on[i] and not on[i-1]]
    f=np.fft.rfftfreq(16384,1/sr); acc=0
    for t in onsets:
        s=int(t*sr)-int(0.001*sr); seg=x[max(s,0):max(s,0)+int(0.03*sr)]
        if len(seg)==int(0.03*sr): acc=acc+np.abs(np.fft.rfft(seg*np.hanning(len(seg)),16384))**2
    P=smooth(acc,5)
    for fc in [float(v) for v in sys.argv[3].split(',')]:
        pk,bw,q=bw3(f,P,fc,0.08); rd=ringdecay(x,sr,pk,max(bw*2,100),onsets)
        print(f"  peak ~{pk:.0f} Hz: -3dB BW {bw:.0f} Hz (Q~{q:.1f}); band ring-down T60 ms p25/50/75={rd}")
    # fine envelope of 3 strongest onsets at 0.25 ms
    m=max(1,int(sr*0.00025)); hh=h
    strongest=sorted(onsets,key=lambda t:-np.abs(h[int(t*sr):int(t*sr)+int(0.005*sr)]).max())[:3]
    for t in sorted(strongest):
        s=int((t-0.002)*sr); seg=hh[s:s+int(0.03*sr)]; r=20*np.log10(np.sqrt((seg[:len(seg)//m*m].reshape(-1,m)**2).mean(1))+1e-12)
        print(f"  @{t:.3f}s 0.25ms env (dB re peak), 30ms:"," ".join(f"{v:.0f}" for v in (r-r.max())))
elif mode=="spin":
    n=int(sr*0.25); nn=len(x)//n; e=20*np.log10(np.sqrt((x[:nn*n].reshape(nn,n)**2).mean(1))+1e-12)
    print(" 250ms RMS dBFS timeline:"," ".join(f"{v:.0f}" for v in e))
    nfft=int(sr*1.0); f=np.fft.rfftfreq(nfft,1/sr)
    for t in [float(v) for v in sys.argv[3].split(',')]:
        s=int(t*sr); seg=x[s:s+nfft]
        if len(seg)<nfft: continue
        P=smooth(np.abs(np.fft.rfft(seg*np.hanning(nfft)))**2,3); Pd=db(P); mx=Pd[f>20].max()
        idx=[i for i in range(3,len(P)-3) if f[i]>20 and Pd[i]==Pd[i-3:i+4].max()]; idx=sorted(idx,key=lambda i:-Pd[i])[:8]
        tot=P[f>20].sum(); fr=lambda a,b: 100*P[(f>=a)&(f<b)].sum()/tot
        print(f" t={t}s level {10*np.log10((seg**2).mean()):.1f} dBFS peaks:",[(round(f[i],1),round(Pd[i]-mx,1)) for i in sorted(idx)], f" <300:{fr(20,300):.0f}% 300-1k:{fr(300,1000):.0f}% 1-5k:{fr(1000,5000):.0f}% >5k:{fr(5000,sr/2):.0f}%")

# Waveform PNG (numpy + zlib only): min/max per pixel column of the lo..hi band-passed signal, one strip per band.
# Usage: python3 -I run.py wave_png.py <wav> t0 t1 out.png [bands=300-16000,300-1500,1500-6000] [w=1000] [h=120] [tick=1]
import sys, zlib, struct, numpy as np
from hdd_analyze import load
a=dict(v.split('=',1) for v in sys.argv[5:]); x,sr=load(sys.argv[1]); t0=float(sys.argv[2]); t1=float(sys.argv[3]); out=sys.argv[4]
Wd=int(a.get('w',1000)); H=int(a.get('h',120)); tick=float(a.get('tick',1))
bands=[tuple(map(float,b.split('-'))) for b in a.get('bands','300-16000,300-1500,1500-6000').split(',')]
pad=int(0.1*sr); s0=max(0,int(t0*sr)-pad); seg=x[s0:int(t1*sr)+pad]; F=np.fft.rfft(seg); f=np.fft.rfftfreq(len(seg),1/sr)
strips=[]
for lo,hi in bands:
    G=F.copy(); G[(f<lo)|(f>=hi)]=0; y=np.fft.irfft(G,len(seg))[int(t0*sr)-s0:int(t1*sr)-s0]
    y=y/(np.percentile(np.abs(y),99.9)+1e-12); n=len(y); img=np.zeros((H,Wd,3),np.uint8)
    for c in range(Wd):
        p=y[c*n//Wd:max(c*n//Wd+1,(c+1)*n//Wd)]; lo_=int((1-np.clip(p.max(),-1,1))*(H-1)/2); hi_=int((1-np.clip(p.min(),-1,1))*(H-1)/2)
        img[lo_:hi_+1,c]=[230,230,90]
    img[H//2,:,:]=np.maximum(img[H//2,:,:],60)
    span=(t1-t0)*1000
    for k in np.arange(0,span,tick):
        c=int(k/span*Wd); L=14 if int(round(k/tick))%10==0 else 5; img[:L,c]=[0,255,0]
    strips.append(img); strips.append(np.full((4,Wd,3),255,np.uint8))
rgb=np.concatenate(strips,0); Hh=rgb.shape[0]
raw=b''.join(b'\x00'+rgb[r].tobytes() for r in range(Hh))
def chunk(t,d): return struct.pack('>I',len(d))+t+d+struct.pack('>I',zlib.crc32(t+d)&0xffffffff)
open(out,'wb').write(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',Wd,Hh,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(raw,9))+chunk(b'IEND',b''))
print(out)

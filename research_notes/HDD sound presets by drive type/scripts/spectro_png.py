# Spectrogram PNG (numpy + zlib only). Usage:
# python3 -I run.py spectro_png.py <wav> t0 t1 out.png [win=5] [hop=0.5] [fmax=8000] [fmin=0] [range=50] [h=400] [tick=10] [log=0] [ref=t0-t1]
# ref: subtract (in dB) the median spectrum of that range (whitens stationary tones/bed); colour then spans 0..range dB above it.
# Each column = one hop; rows = frequency (top = fmax). Bright = loud. Tick marks on the top 6 rows every `tick` ms
# (longer every 10 ticks); horizontal guide pixels every 1 kHz (every octave if log=1) on the left 8 columns.
import sys, zlib, struct, numpy as np
from hdd_analyze import load
a=dict(v.split('=',1) for v in sys.argv[5:]); x,sr=load(sys.argv[1]); t0=float(sys.argv[2]); t1=float(sys.argv[3]); out=sys.argv[4]
win=float(a.get('win',5)); hop=float(a.get('hop',0.5)); fmax=float(a.get('fmax',8000)); fmin=float(a.get('fmin',0)); rng=float(a.get('range',50)); H=int(a.get('h',400)); tick=float(a.get('tick',10)); lg=a.get('log','0')=='1'
W=int(sr*win/1000); hp=max(1,int(sr*hop/1000)); nf=max(4096,1<<int(np.ceil(np.log2(W*4)))); f=np.fft.rfftfreq(nf,1/sr); w=np.hanning(W)
xp=np.concatenate([np.zeros(W),x,np.zeros(W)]); cols=[np.abs(np.fft.rfft(xp[W+s:W+s+W]*w,nf))**2 for s in range(int(t0*sr)-W//2,int(t1*sr)-W//2,hp)]
S=10*np.log10(np.array(cols).T+1e-20)
if 'ref' in a:
    ra,rb=map(float,a['ref'].split('-')); Rm=np.median(np.array([np.abs(np.fft.rfft(xp[W+s:W+s+W]*w,nf))**2 for s in range(int(ra*sr),int(rb*sr)-W,max(hp,W//2))]),0)
    S=S-10*np.log10(Rm+1e-20)[:,None]
if lg: fr=np.geomspace(max(fmin,30),fmax,H)
else: fr=np.linspace(fmin,fmax,H)
idx=np.searchsorted(f,fr).clip(0,len(f)-1); img=S[idx][::-1]
top=rng if 'ref' in a else np.percentile(img,99.7); img=np.clip((img-(top-rng))/rng,0,1)
# colormap: black-blue-red-yellow-white
c=np.stack([np.clip(3*img-1,0,1),np.clip(3*img-2,0,1)*0.9+np.clip(1.5*img-0.5,0,1)*0.1,np.clip(1.5-np.abs(3*img-1.5),0,1)*0.8+np.clip(3*img-2,0,1)],-1)
rgb=(c*255).astype(np.uint8)
ncol=rgb.shape[1]
for k in range(0,ncol,max(1,int(round(tick/hop)))):
    L=12 if (k//max(1,int(round(tick/hop))))%10==0 else 5; rgb[:L,k]=[0,255,0]
if lg: guides=[g for g in [62.5,125,250,500,1000,2000,4000,8000,16000] if fmin<=g<=fmax]
else: guides=list(np.arange(1000,fmax+1,1000))
for g in guides:
    r=H-1-int(np.argmin(np.abs(fr-g))); rgb[r,:8]=[255,255,255]
raw=b''.join(b'\x00'+rgb[r].tobytes() for r in range(H))
def chunk(t,d): return struct.pack('>I',len(d))+t+d+struct.pack('>I',zlib.crc32(t+d)&0xffffffff)
open(out,'wb').write(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',ncol,H,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(raw,9))+chunk(b'IEND',b''))
print(out, ncol, 'x', H)

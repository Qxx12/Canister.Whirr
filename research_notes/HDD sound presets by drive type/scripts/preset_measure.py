# Preset-ready measurements for one recording (numpy only).
# Usage: python3 -I run.py preset_measure.py <wav> idle=t0-t1[,t0-t1] seek=t0-t1[,t0-t1] [rpm=N] [nmodes=13] [thr=12]
# Detector settings match hdd_batch.py (300 Hz+ 1 ms RMS envelope, onset > idle-envelope median + 12 dB,
# 3 ms gap merge) so rates / IOIs / peak-over-idle are comparable with real_recordings_analysis.md.
# New here: per-mode decay measured on a Gaussian narrowband envelope (no sinc side lobes, so the late
# slope is the true decay rate, not the filter's), Q = pi*f*T60/6.91, and initial ring amplitude per mode.
import sys, numpy as np
from hdd_analyze import load, db, smooth

def aw(f):
    f2 = f**2
    ra = (12194**2*f2**2)/((f2+20.6**2)*np.sqrt((f2+107.7**2)*(f2+737.9**2))*(f2+12194**2))
    return 20*np.log10(np.maximum(ra, 1e-12))+2.0

def bp(X, f, lo, hi, n):
    Y = X.copy(); Y[(f < lo) | (f >= hi)] = 0; return np.fft.irfft(Y, n)

def gauss_bp(X, f, fc, fwhm, n):
    s = fwhm/2.355; return np.fft.irfft(X*np.exp(-0.5*((f-fc)/s)**2), n)

def env_db(y, n1):
    nn = len(y)//n1; return 10*np.log10((y[:nn*n1].reshape(nn, n1)**2).mean(1)+1e-20)

def ranges(s): return [tuple(float(v) for v in r.split('-')) for r in s.split(',')] if s else []

def mask_from(ranges_, nn, fps=1000):
    m = np.zeros(nn, bool)
    for a, b in ranges_: m[int(a*fps):int(b*fps)] = True
    return m

def pr(v, fmt="{:.0f}"): return "/".join(fmt.format(z) for z in np.percentile(v, [10, 50, 90]))

def fit_decay(edb, start, floor_db, maxlen, mindrop=6):
    """Fit a line to edb[start:...] until it hits floor_db+3 or maxlen frames. Returns (slope dB/ms, intercept, frames)."""
    seg = edb[start:start+maxlen]
    stop = len(seg)
    for i, v in enumerate(seg):
        if v < floor_db+3: stop = i; break
    if stop < 4: return None
    t = np.arange(stop); sl, ic = np.polyfit(t, seg[:stop], 1)
    if sl >= 0 or (seg[0]-seg[stop-1]) < mindrop: return None
    return sl, ic, stop

args = dict(a.split('=', 1) for a in sys.argv[2:])
p = sys.argv[1]; x, sr = load(p); N = len(x); name = p.split('/')[-1]
X = np.fft.rfft(x); f = np.fft.rfftfreq(N, 1/sr)
nyq = sr/2; top = min(16000, nyq-1)
n1 = int(sr*0.001)
idleR = ranges(args.get('idle')); seekR = ranges(args.get('seek'))
rpm = float(args.get('rpm', 0)); nmodes = int(args.get('nmodes', 13)); thr = float(args.get('thr', 12))
print(f"===== {name} sr={sr} dur={N/sr:.1f}s idle={idleR} seek={seekR} rpm={rpm}")

# ---------- idle bed ----------
idle_x = np.concatenate([x[int(a*sr):int(b*sr)] for a, b in idleR])
L = int(sr*1.0); nf = 4*L; fi = np.fft.rfftfreq(nf, 1/sr); acc = 0; k = 0
for s in range(0, len(idle_x)-L, L//2):
    acc = acc+np.abs(np.fft.rfft(idle_x[s:s+L]*np.hanning(L), nf))**2; k += 1
Pi = acc/k; Pid = db(Pi)
def pick(lo, hi, n, mind):
    m = (fi >= lo) & (fi < hi); idx = [i for i in np.where(m)[0][3:-3] if Pid[i] == Pid[i-3:i+4].max()]
    idx = sorted(idx, key=lambda i: -Pid[i]); sel = []
    for i in idx:
        if all(abs(fi[i]-fi[j]) > mind for j in sel): sel.append(i)
        if len(sel) >= n: break
    return sel
mxI = Pid[fi > 30].max()
# prominence: peak vs median of +-60 Hz neighbourhood (tonal vs broadband)
def prom(i):
    m = (fi > fi[i]-80) & (fi < fi[i]+80); return Pid[i]-np.median(Pid[m])
lo_pk = pick(30, 1000, 10, 12); hi_pk = pick(1000, top, 12, 60)
fr0 = rpm/60 if rpm else None
def harm(fq): return f" (x{fq/fr0:.2f})" if fr0 else ""
print(f" IDLE level {10*np.log10(np.mean(idle_x**2)):.1f} dBFS; A-wtd {10*np.log10((Pi*10**(aw(np.maximum(fi,1))/10)).sum()/(Pi.sum())*np.mean(idle_x**2)):.1f} dBFS(A)")
tot = Pi[fi >= 20].sum(); totA = (Pi*10**(aw(np.maximum(fi, 1))/10))[fi >= 20].sum()
sh = lambda P, T: " ".join(f"{a}-{int(b)}:{100*P[(fi>=a)&(fi<b)].sum()/T:.0f}%" for a, b in [(20, 300), (300, 1000), (1000, 5000), (5000, nyq)])
print("  idle energy unweighted:", sh(Pi, tot), "| A-wtd:", sh(Pi*10**(aw(np.maximum(fi, 1))/10), totA))
print("  idle tones <1k Hz(dB re idle max, prominence dB):", " ".join(f"{fi[i]:.1f}{harm(fi[i])}({Pid[i]-mxI:.0f},p{prom(i):.0f})" for i in sorted(lo_pk)))
print("  idle tones >1k Hz(dB re idle max, prominence dB):", " ".join(f"{fi[i]:.0f}{harm(fi[i])}({Pid[i]-mxI:.0f},p{prom(i):.0f})" for i in sorted(hi_pk)))
if fr0:
    print("  spindle harmonics k*rpm/60 (dB re idle max, prominence):", " ".join(
        f"{kk}:{fi[np.argmax(np.where(np.abs(fi-kk*fr0)<3,Pid,-1e9))]:.1f}Hz({Pid[np.argmax(np.where(np.abs(fi-kk*fr0)<3,Pid,-1e9))]-mxI:.0f},p{prom(np.argmax(np.where(np.abs(fi-kk*fr0)<3,Pid,-1e9))):.0f})" for kk in range(1, 9)))

# ---------- events (hdd_batch detector) ----------
h = bp(X, f, 300, top, N); e = env_db(h, n1); nn = len(e)
im = mask_from(idleR, nn); sm = mask_from(seekR, nn)
ifl = np.median(e[im]); on = (e > ifl+thr) & sm; ev = []; i = 0
while i < nn:
    if on[i]:
        j = i; last = i
        while j < nn and j-last <= 3:
            if on[j]: last = j
            j += 1
        ev.append((i, last+1)); i = last+1
    else: i += 1
seek_s = sum(b-a for a, b in seekR)
d = np.array([b-a for a, b in ev]); o = np.array([a for a, b in ev]); pkv = np.array([e[a:b].max() for a, b in ev])
ioi = np.diff(o); ioi400 = ioi[ioi < 400]
dec = []
for a, b in ev:
    kk = a+np.argmax(e[a:b]); t = max(e[kk]-20, ifl+3); q = kk
    while q < nn-1 and e[q] > t: q += 1
    if q > kk and e[kk]-e[q] > 0: dec.append(60*(q-kk)/(e[kk]-e[q]))
print(f" EVENTS (>idle env median {ifl:.1f}+{thr:.0f} dB, 300Hz+ 1ms, 3ms merge): n={len(ev)} rate={len(ev)/seek_s:.1f}/s over {seek_s:.1f}s of seek ranges")
print(f"  dur ms {pr(d)}; peak over idle env dB {pr(pkv-ifl)}; IOI(all) ms {pr(ioi)}; IOI(<400) ms {pr(ioi400)}; T60-extrap(hdd_batch) ms {pr(dec)}")
# full-band peak vs idle full-band 1 ms
ef = env_db(x, n1); print(f"  full-band 1ms: idle median {np.median(ef[im]):.1f} dBFS, event peaks {pr(np.array([ef[a:b+3].max() for a,b in ev]))} dBFS -> over idle {pr(np.array([ef[a:b+3].max() for a,b in ev])-np.median(ef[im]))} dB")
# seek-range 0.5 s RMS vs idle
blk = [10*np.log10(np.mean(x[int(s*sr):int((s+0.5)*sr)]**2)) for a, b in seekR for s in np.arange(a, b-0.5, 0.5)]
print(f"  0.5s RMS in seek ranges {np.mean(blk):.1f} dBFS vs idle {10*np.log10(np.mean(idle_x**2)):.1f} -> {np.mean(blk)-10*np.log10(np.mean(idle_x**2)):+.1f} dB")

# isolated onsets for decay work: >=15 ms below threshold before, next onset >= 45 ms later
ons = [a for a, b in ev]
iso = [ons[k] for k in range(len(ons)) if ons[k] > 30 and not on[max(0, ons[k]-15):ons[k]].any()
       and (k+1 == len(ons) or ons[k+1]-ons[k] >= 45) and ons[k]+80 < nn]
print(f"  isolated onsets (>=15ms quiet before, >=45ms to next) n={len(iso)}")

# ---------- broadband / band envelopes ----------
def band_report(lo, hi, label):
    y = bp(X, f, lo, hi, N); E = np.zeros(70); base = []
    for o_ in iso:
        seg = y[(o_-2)*n1:(o_+68)*n1]; E += (seg.reshape(70, n1)**2).mean(1)
        base.append(np.mean(y[(o_-14)*n1:(o_-4)*n1]**2))
    Ed = 10*np.log10(E/len(iso)+1e-20); bg = 10*np.log10(np.mean(base)+1e-20)
    yi = env_db(y, n1); bgi = np.median(yi[im])  # idle level in band
    kk = np.argmax(Ed[:20]); pk_ = Ed[kk]
    t10 = next((i-kk for i in range(kk, 70) if Ed[i] < pk_-10), None); t20 = next((i-kk for i in range(kk, 70) if Ed[i] < pk_-20), None)
    fd = fit_decay(Ed, kk, max(bg, bgi), 45)
    T60 = -60/fd[0] if fd else None
    # late slope: from the -10 dB point onwards (tail)
    fl = fit_decay(Ed, kk+t10, max(bg, bgi), 40, mindrop=3) if t10 is not None else None
    print(f"  {label:>11}: peak {pk_-bgi:+.1f} dB over idle-band, at {kk-2} ms; -10dB {t10} ms, -20dB {t20} ms; T60 fit {T60 and round(T60)} ms; tail T60 {fl and round(-60/fl[0])} ms; env 0..45ms step3:", " ".join(f"{v:.0f}" for v in (Ed-pk_)[2:48:3]))
    return pk_-bgi
print(" BAND ENVELOPES (energy-avg over isolated onsets, dB re band peak):")
bands = [(300, top, "300-16k"), (150, 400, "150-400"), (400, 1000, "400-1k"), (1000, 5000, "1-5k"), (5000, top, "5-16k")]
for lo, hi, lab in bands:
    if lo < nyq: band_report(lo, hi, lab)

# ---------- excess spectrum (event minus idle), 30 ms window ----------
W = int(0.03*sr); nfft = 16384; fe = np.fft.rfftfreq(nfft, 1/sr); acc = 0; cnt = 0
for a, b in ev:
    s = (a-1)*n1; seg = x[s:s+W]
    if s > 0 and len(seg) == W: acc = acc+np.abs(np.fft.rfft(seg*np.hanning(W), nfft))**2; cnt += 1
Pe = smooth(acc/cnt, 5); acc2 = 0; c2 = 0
for s in range(0, len(idle_x)-W, W): acc2 = acc2+np.abs(np.fft.rfft(idle_x[s:s+W]*np.hanning(W), nfft))**2; c2 += 1
Pb = smooth(acc2/c2, 5); ex = np.maximum(Pe-Pb, 1e-20); exd = db(ex)
A = 10**(aw(np.maximum(fe, 1))/10); exA = ex*A
def sh2(v):
    t = v[fe >= 20].sum(); return " ".join(f"{a}-{int(b)}:{100*v[(fe>=a)&(fe<b)].sum()/t:.0f}%" for a, b in [(20, 300), (300, 1000), (1000, 5000), (5000, nyq)])
print(f" EXCESS (events n={cnt}, 30ms win, minus idle): unweighted {sh2(ex)} | A-wtd {sh2(exA)}")
print(f"  event-window vs idle: {db(Pe.sum())-db(Pb.sum()):+.1f} dB, {db((Pe*A).sum())-db((Pb*A).sum()):+.1f} dBA (A-wtd idle-to-event-30ms)")
cs = [63, 125, 250, 500, 1000, 2000, 4000, 8000, 12500]
print("  octave event-vs-idle dB:", " ".join(f"{c}:{db(Pe[(fe>=c/1.41)&(fe<c*1.41)].mean())-db(Pb[(fe>=c/1.41)&(fe<c*1.41)].mean()):+.0f}" for c in cs if c*1.41 < nyq))
mx = exd[fe > 120].max()
def pickex(lo, hi, nmax, rng):
    m = (fe >= lo) & (fe < hi); mloc = exd[m].max()
    idx = [i for i in np.where(m)[0] if i > 4 and exd[i] == exd[i-4:i+5].max()]
    idx = sorted(idx, key=lambda i: -exd[i]); out = []
    for i in idx:
        if exd[i] < mloc-rng: break
        if all(abs(fe[i]-fe[j]) > max(50, 0.035*fe[i]) for j in out): out.append(i)
        if len(out) >= nmax: break
    return out
# tiers: up to 3 thump candidates 120-300 Hz (within 15 dB of that tier's max), 5 in 300-1000 Hz (20 dB), 14 in 1 kHz-top (22 dB)
sel = pickex(120, 300, 3, 15) + pickex(300, 1000, 5, 20) + pickex(1000, top, 14, 22)

# ---------- per-mode narrowband decay ----------
# Uses onsets with >= 15 ms quiet before and >= GAP ms (default 80) before the next detected onset.
# Per mode (Gaussian band, FWHM max(40 Hz, f/25); f/6 below 500 Hz): energy-averaged envelope, then
#   hold  = ms from the envelope peak until it first falls 3 dB below the peak (the strike train / burst),
#   decay = straight-line fit from that -3 dB point down to the first frame at max(pre-onset+3, peak-25) dB
#           -> T60 and Q = pi f T60 / 6.91.  "pre" is the band level 14..4 ms before onset (activity floor).
# Cross-check: per-event spectral -3 dB width in a 50 ms Hann window starting 10 ms after onset (window-limited
# to about Q_max = f/29 Hz).
GAP = int(args.get('gap', 80))
iso2 = [ons[k] for k in range(len(ons)) if ons[k] > 30 and not on[max(0, ons[k]-15):ons[k]].any()
        and (k+1 == len(ons) or ons[k+1]-ons[k] >= GAP) and ons[k]+GAP+5 < nn and sm[ons[k]:ons[k]+GAP].all()]
print(f" MODES (n isolated onsets with >= {GAP} ms clear after = {len(iso2)}):")
print("     hz | exc.spec dB | env pk dB re max (over idle / over pre) | pk dly ms | hold ms | -10dB ms | decay T60 ms -> Q | tail specQ (win-limit)")
rows = []
Wt = int(0.05*sr); nft = 65536; ft = np.fft.rfftfreq(nft, 1/sr)
tailspec = [np.abs(np.fft.rfft(x[(o_+10)*n1:(o_+10)*n1+Wt]*np.hanning(Wt), nft))**2 for o_ in iso2]
for i in sel:
    fc = fe[i]
    fwhm = max(40.0, fc/25) if fc >= 500 else max(30.0, fc/6)
    y = gauss_bp(X, f, fc, fwhm, N)
    yi = env_db(y, n1); bgi = np.median(yi[im])
    E = np.mean([10**(yi[o_-15:o_+GAP]/10) for o_ in iso2], 0); Ed = 10*np.log10(E)  # index 15 = onset
    pre = Ed[1:11].mean()
    kk = 15+int(np.argmax(Ed[15:40])); pk_ = Ed[kk]
    h3 = next((j for j in range(kk, len(Ed)) if Ed[j] < pk_-3), None)
    t10 = next((j-kk for j in range(kk, len(Ed)) if Ed[j] < pk_-10), None)
    T = np.nan
    if h3 is not None:
        stopv = max(pre+3, pk_-25)
        st_ = next((j for j in range(h3, len(Ed)) if Ed[j] < stopv), len(Ed))
        if st_-h3 >= 3:
            sl = np.polyfit(np.arange(h3, st_), Ed[h3:st_], 1)[0]
            if sl < 0: T = -60/sl
    Tf = np.nan  # fallback for short clicks on a busy floor: fit from the peak+1 to max(pre+2, peak-20)
    stopv = max(pre+2, pk_-20); st_ = next((j for j in range(kk+1, len(Ed)) if Ed[j] < stopv), None)
    if st_ is not None and st_-kk-1 >= 2:
        sl = np.polyfit(np.arange(kk+1, st_+1), Ed[kk+1:st_+1], 1)[0]
        if sl < 0: Tf = -60/sl
    qs = []
    for P in tailspec:
        Pd = db(P); m = np.abs(ft-fc) < max(25, fc*0.02)
        j = np.where(m)[0][np.argmax(Pd[m])]; t3 = Pd[j]-3; a = j; b = j
        while Pd[a] > t3: a -= 1
        while Pd[b] > t3: b += 1
        qs.append(ft[j]/max(ft[b]-ft[a], 1e-9))
    rows.append((fc, exd[i]-mx, pk_, pk_-bgi, pk_-pre, kk-15, (h3-kk) if h3 else None, t10, T, np.median(qs), Tf))
ref = max(r[2] for r in rows)
for fc, sd, pk_, oi, op, dl, hold, t10, T, qsm, Tf in sorted(rows, key=lambda r: r[0]):
    Q = np.pi*fc*(T/1000)/6.91; Qf_ = np.pi*fc*(Tf/1000)/6.91
    print(f"   {fc:6.0f} | {sd:6.1f} | {pk_-ref:6.1f} (+{oi:.0f} / +{op:.0f}) | {dl:3d} | {hold} | {t10} | {T:5.0f} -> Q {Q:6.1f} | from-peak T60 {Tf:5.0f} -> Q {Qf_:6.1f} | {qsm:4.0f} ({fc/29:.0f})")

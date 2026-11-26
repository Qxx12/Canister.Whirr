# Measured acoustic signatures: Maxtor Atlas 10K V, Fujitsu Allegro 15k, Samsung SV1022D, Samsung T166 (+ failure clips), as Whirr preset numbers

Method and caveats (apply to every number below). All measurements are my own analysis of recordings already on disk in `research_notes/Realistic HDD sound synthesis/recordings/`. The four targets are CC0 recordings by Klerrp, available here only as lossy ~128 kbps MP3 previews converted to 44.1 kHz WAV. Microphone, distance, mounting and room are undocumented, so treat every number as "this recording of this drive", not as a drive specification. The analysis used numpy only (scipy is not installed). Scripts are in `research_notes/HDD sound presets by drive type/scripts/`; run them as `python3 -I run.py <script> ...`. `run.py` adds the user site-packages that `-I` drops. The scripts are `preset_measure.py` (main), `longenv.py`, `bed.py`, `clusters.py` and `timeline.py`, plus unchanged copies of the earlier `hdd_*.py` scripts.

Event detection is the same as `hdd_batch.py` in the earlier note, so rates and levels are comparable: a 300 Hz to 16 kHz, 1 ms RMS envelope; an onset is anything more than 12 dB above the median idle envelope, with a 3 ms gap merge. Idle and seek ranges were picked by hand from a 0.5 s level/crest timeline. The earlier automatic split had failed on the Fujitsu 15k. The ranges are listed per drive so the runs can be repeated.

What is new compared with `real_recordings_analysis.md`:
1. Q is derived from the decay of a Gaussian narrowband envelope, Q = π·f·T60/6.91. The Gaussian filter has no sinc side lobes, so its late slope is the mode's decay, not the filter's. The fit runs from the first −3 dB point after the peak down to max(pre-onset level + 3 dB, peak − 25 dB). The envelope is energy-averaged over isolated onsets: at least 15 ms quiet before the onset and at least 80 ms (45 ms for the SV1022D) before the next one.
2. A cross-check: the spectral Q of each mode in single events, from a 50 ms window starting 10 ms after onset. This is capped by the window at about f/29 Hz.
3. "hold" is the time a band stays within 3 dB of its peak, which captures the multi-strike burst.
4. "dB" is the energy-averaged narrowband envelope peak relative to the strongest mode, which is what `Mode.db` means in `SoundBank.swift`: the initial ring amplitude relative to the strongest mode ([SoundBank.swift DrivePreset/Mode](/Users/zihangqi/Workspace/Canister.Whirr/Sources/Whirr/SoundBank.swift)).

Recording pages: [182366 Maxtor Atlas 10K V](https://freesound.org/people/Klerrp/sounds/182366/), [182364 Fujitsu MBA3300RC](https://freesound.org/people/Klerrp/sounds/182364/), [167420 Samsung SV1022D](https://freesound.org/people/Klerrp/sounds/167420/), [167421 Samsung HD501LJ T166](https://freesound.org/people/Klerrp/sounds/167421/), [Klerrp "Old HDDs" pack, CC0](https://freesound.org/people/Klerrp/packs/8850/).

## 1. Dominant seek resonances and decay-derived Q (preset-ready mode lists)

### Takeaway
Measured from decay, the kHz seek resonances are far higher-Q than the earlier note's Q≈15-35. That earlier figure came from spectral widths in 20-30 ms windows, which cap measurable Q at about f/50-72 Hz, so it was mostly a window limit.
- The two server drives (Atlas 10K, Allegro 15k) and the Deskstar ring with Q≈150-300 at 3.5-6.5 kHz (T60 ≈ 75-160 ms).
- The 2000-era SV1022D has a genuinely short, damped 3.4-4.9 kHz click (Q≈40-75, T60 20-50 ms) over a strong sustained 200-700 Hz writing rumble.
- The 2007 T166 is dominated by a late 207 Hz thump (Q≈20-26, peaking about 20 ms after onset). Its kHz modes are high-Q but 20-30 dB weaker.

### Cited Findings

**Why the Q values differ from the earlier note (method finding)**
- Earlier Q values came from −3 dB widths of event spectra in 20 ms (hdd_analyze/hdd_batch) or 30 ms windows. A Hann window's −3 dB main-lobe width is about 1.44/T, i.e. 72 Hz for 20 ms, so measurable Q is capped near f/72. That cap is 36 at 2.6 kHz. Thump Q≈4-5 at 200-280 Hz is also at the cap (about 4 for a 20 ms window at 280 Hz). Per-event tail spectra in a 50 ms window here sit at 70-95% of the f/29 cap for every kHz mode of the Atlas, Allegro and Deskstar, which is consistent with Q well above the earlier values — own analysis, `preset_measure.py` ("tail specQ (win-limit)" column) on [182366](https://freesound.org/people/Klerrp/sounds/182366/), [182364](https://freesound.org/people/Klerrp/sounds/182364/), [Commons Deskstar](https://commons.wikimedia.org/wiki/File:Sound_of_defective_IBM_Deskstar.ogg)
- Decay-derived T60 includes any excitation that continues after the strike: multi-strike seeks, settle, track-following. So these Q values are upper-bound estimates of the free ring. In the Atlas, the 4.6-6.5 kHz bands hold within about 3-5 dB of peak for about 15-20 ms, then fall at roughly 0.6-0.8 dB/ms. That is a burst followed by a decay, not one exponential — own analysis, `longenv.py` on [182366](https://freesound.org/people/Klerrp/sounds/182366/)

**182366 Maxtor Atlas 10K V (2006, 10,000 rpm server).** Ranges: idle 13.5-19.5 s, seek 4.0-13.0 s, 22 onsets with at least 80 ms clear.
- Excess (event minus idle) A-weighted shares: <300 Hz 2%, 300 Hz-1 kHz 17%, 1-5 kHz 59%, >5 kHz 23%. Unweighted: 23/22/37/18%. Octave rise over idle: +6 (63 Hz), +9, +10, +19 (500 Hz), +13, +17, +15 (4 kHz), +16 (8 kHz), +1 (12.5 kHz) dB — [182366](https://freesound.org/people/Klerrp/sounds/182366/), own analysis
- Mode table. Columns are Hz | dB re strongest | peak delay after onset | hold | decay T60 → Q. The other columns of the script output are in the reproducible output:
  - 6481 | 0 | 2 ms | 3 ms | 77 ms → Q≈226
  - 5984 | −1.7 | 1 | 3 | 82 → 224
  - 5669 | −7.2 | 0 | 3 | 148 → 380 (spectral cap 195; use ≈250-300)
  - 5311 | −8.3 | 0 | 2 | 159 → 384 (use ≈250-300)
  - 5122 | −8.8 | 5 | 2 | 120 → 280
  - 4888 | −6.4 | 2 | 12 | 75 → 168
  - 4638 | −6.2 | 1 | 3 | 106 → 223
  - 2264 | −10.9 | 10 | 13 | 158 → 163
  - 2021 | −2.4 | 10 | 14 | 103 → 95
  - 1838 | −11.5 | 10 | 14 | 90 → 76
  - 1392 | −11.5 | 19 | 18 | 158 → 100
  - 1257 | −8.4 | 12 | 13 | 139 → 80
  - 1147 | −10.5 | 11 | 12 | 136 → 71
  - 1001 | −9.2 | 17 | 14 | 115 → 52
  - 743 | −17 | 16 | 17 | 107 → 36
  - 390 | −6.9 | 11 | 20 | 213 → 38
  - 199 | −4.8 | 24 | 25 | 144 → 13
  - 129 | −1.6 | 21 | — | no decay fit (Q unresolved; spectral ≥4)

  — [182366](https://freesound.org/people/Klerrp/sounds/182366/), own analysis (`preset_measure.py`)
- Two-strike structure: the 4.6-6.5 kHz cluster peaks 0-5 ms after onset, the 1.0-2.3 kHz modes peak 10-19 ms after onset, and the 390 Hz and 129-199 Hz bands peak 11-24 ms after onset. In the 5-16 kHz band envelope, the first 5 dB drops within 3 ms (a fast, low-Q attack component). The level then holds near −3 to −6 dB until about 18 ms and reaches −10 dB at 20 ms — [182366](https://freesound.org/people/Klerrp/sounds/182366/), own analysis
- Thump: no classic short thump. A low swell at 129-199 Hz peaks 21-24 ms after onset, holds about 25 ms and decays with T60 ≈ 144 ms (199 Hz → Q≈13). It is −5 dB in envelope terms but only 2% of A-weighted excess energy — [182366](https://freesound.org/people/Klerrp/sounds/182366/), own analysis

**182364 Fujitsu Allegro 10LX MBA3300RC (2008, 15,000 rpm server, writing).** Ranges: idle 17.0-25.4, 81.6-85.4 and 86.0-87.4 s; seek 10.5-13.5, 25.5-30.4, 31.0-31.9 and 73.5-81.4 s; 26 onsets with at least 80 ms clear.
- Excess A-weighted shares: <300 Hz 0%, 300 Hz-1 kHz 10%, 1-5 kHz 80%, >5 kHz 10%. Octave rise over idle: +0 (63 Hz), +1, +4 (250 Hz), +16 (500 Hz), +17 (1 kHz), +11, +13 (4 kHz), +6 (8 kHz), +3 dB — [182364](https://freesound.org/people/Klerrp/sounds/182364/), own analysis
- Mode table (Hz | dB | delay | hold | T60 → Q):
  - 3604 | 0 | 2 | 9 | 113 → 186
  - 6121 | −1.7 | 4 | 4 | 75 → 209
  - 6342 | −5.0 | 8 | 4 | 100 → 289
  - 4751 | −5.0 | 6 | 4 | 85 → 183
  - 3749 | −5.4 | 2 | 5 | 110 → 188
  - 3426 | −5.9 | 10 | 6 | 78 → 122
  - 4296 | −6.9 | 12 | 4 | 136 → 265
  - 2519 | −9.3 | 2 | 7 | 69 → 79
  - 2371 | −10.0 | 15 | 10 | 223 → 241
  - 2204 | −10.5 | 2 | 17 | 128 → 129
  - 1876 | −14.9 | 7 | 17 | 130 → 111
  - 1408 | −10.3 | 3 | 10 | 105 → 67
  - 1284 | −5.6 | 4 | 13 | unresolved (first-pass per-event fit 271 ms → Q≈158)
  - 1144 | −6.3 | 7 | 14 | unresolved (per-event 171 ms → Q≈89)
  - 1012 | −10.4 | 6 | 13 | unresolved (per-event 162 ms → Q≈74)
  - 406 | −9.2 | 11 | 16 | 149 → 28
  - 336 | −7.3 | 17 | 8 | 97 → 15
  - 205 | −14.4 | 20 | — | unresolved

  The 1.0-1.3 kHz modes stand only +4 to +7 dB over the pre-onset level, because the writing bed fills that band, so their decays are low-confidence — [182364](https://freesound.org/people/Klerrp/sounds/182364/), own analysis
- Thump: none worth modelling. The 150-400 Hz band rises only +7 dB over idle, and excess A-weighted energy below 300 Hz is 0% — [182364](https://freesound.org/people/Klerrp/sounds/182364/), own analysis
- Heavy-load texture: from 32 to 73 s the drive writes continuously. 0.5 s RMS is −21 to −22 dBFS against −34.3 idle (+12-13 dB), with low crest (about 6 dB). Bands 300 Hz-5 kHz are +17 to +21 dB over idle, and the peaks are at 533 Hz (+33 dB) and 1.00-1.30 kHz (+21 to +31 dB). At a +20 dB detection threshold there are 20.3 bursts/s (IOI p10/50/90 = 6/26/126 ms) and 12.2 gestures/s at a 15 ms merge — [182364](https://freesound.org/people/Klerrp/sounds/182364/), own analysis (`bed.py`, `clusters.py`)

**167420 Samsung SV1022D (2000, 5400 rpm, ball bearing, writing): refined mode list.** Ranges: idle 6.0-8.0, 8.5-12.4 and 15.0-18.0 s; seek 21.0-29.4, 30.0-33.4, 34.0-39.4 and 40.0-67.0 s; 222 onsets with at least 45 ms clear.
- Excess A-weighted shares: <300 Hz 8%, 300 Hz-1 kHz 41%, 1-5 kHz 47%, >5 kHz 4%. Unweighted: 39/43/16/2%. Octave rise over idle: +29 dB at 250 Hz, +12 at 500, +13 at 1 kHz, +1 at 2 kHz, +11 at 4 kHz. This differs from the earlier note's 78% A-weighted in 300 Hz-1 kHz, which used a different idle reference and window — [167420](https://freesound.org/people/Klerrp/sounds/167420/), own analysis
- Event-locked click modes (Hz | dB | hold | from-peak T60 → Q):
  - 4064 | 0 | 3 ms | 21 ms → 39
  - 4258 | −7.8 | 3 | 23 → 45
  - 4471 | −8.5 | 3 | 33 → 68
  - 3733 | −9.7 | 3 | 33 → 56
  - 4721 | −10.2 | 3 | 27 → 59
  - 4893 | −10.8 | 3 | 34 → 75
  - 3383 | −14.3 | 5 | 49 → 75
  - 1943 | −15.2 | 7 | 101 → 89 (low confidence)
  - 1187 | −20 | — | 175 → 95 (low confidence)

  All peak 0-3 ms after onset — [167420](https://freesound.org/people/Klerrp/sounds/167420/), own analysis
- Low "woody" part (196, 353, 455 and 684 Hz) at 0, −4.3, −4.3 and −11.5 dB in envelope terms. These are mostly not event-locked: each onset raises them only +2 to +3 dB over the pre-onset level, while the whole writing passage raises the 150-300 Hz band +26 dB over idle and 300 Hz-1 kHz +10 dB. The seek-range spectrum shows broad humps at 187-207 Hz (+32 to +43 dB over idle) and 332-361 Hz (+34 to +42 dB), with low prominence (8-14 dB). These are re-excited resonances, not steady tones. Decay is unresolved because events are only about 30 ms apart. The low part decays slower than that spacing, so T60 ≳ 100 ms, which implies Q ≳ 9 at 196 Hz and ≳ 16 at 353 Hz (inference from that bound) — [167420](https://freesound.org/people/Klerrp/sounds/167420/), own analysis (`bed.py`)
- Band envelopes: the 1-5 kHz band falls −5 dB at 3 ms and −13 dB by 6 ms, then sits on the bed. The 150-400 Hz band peaks at 7 ms and is −10 dB at 36 ms — [167420](https://freesound.org/people/Klerrp/sounds/167420/), own analysis

**167421 Samsung HD501LJ T166 (2007, 7200 rpm, 3 platters, writing): refined mode list.** Ranges: idle 9.5-12.9, 17.0-18.0, 19.5-21.0, 24.0-25.0, 25.5-28.0 and 34.5-35.9 s; seek 7.5-9.4, 13.0-16.9, 21.0-23.9, 28.0-30.4 and 32.5-34.4 s; 20 onsets with at least 80 ms clear.
- Excess A-weighted shares: <300 Hz 61%, 300 Hz-1 kHz 27%, 1-5 kHz 10%, >5 kHz 2%. Unweighted <300 Hz is 87%. Octave rise over idle: +7 (125 Hz), +25 (250 Hz), +17 (500 Hz), +2 (1 kHz), +9, +10, +11 (8 kHz). The earlier note had 41/22/33% A-weighted, so the share of the kHz click depends on which passages are analysed — [167421](https://freesound.org/people/Klerrp/sounds/167421/), own analysis
- Thump: 207 Hz, the strongest component (+40 dB over idle, +9 dB over pre-onset). It peaks 20 ms after onset, is −10 dB 30 ms after the peak, and has a decay T60 of 213-280 ms (Q≈20-26). The 150-400 Hz band stays within about 4 dB of its peak from about 9 to 33 ms. Second low mode: 377 Hz at −4.1 dB, peaking at 21 ms, hold 16 ms, T60 162-176 ms (Q≈28-30) — [167421](https://freesound.org/people/Klerrp/sounds/167421/), own analysis
- kHz modes (Hz | dB re the 207 Hz thump | T60 → Q):
  - 4877 | −25.5 | 137-142 → 303-315
  - 5429 | −25.6 | Q unresolved (≥160 spectral)
  - 5082 | −26.8 | 46 → 106
  - 4500 | −29.2 | 153-172 → 313-352
  - 2307 | −30.1 | 204 → 214
  - 2910 | −30.7 | 208-289 → 275-380
  - 2592 | −32.5 | 106 → 125
  - 1674 | −32.8 | 187 → 142
  - 6767 | −36.2 | 39 → 120
  - 576 | −24.6 | 228 → 60
  - 474 | −19.6 | low confidence

  The 5-16 kHz band peaks at 1 ms and is −10 dB by 5 ms (a fast tick), but its narrow modes keep ringing more than 10 dB down — [167421](https://freesound.org/people/Klerrp/sounds/167421/), own analysis

**Commons failure clips (for a possible "failing drive" preset)**
- *WD102AA "Scratched area read retries"* (CC0 per Commons; 24 kHz, so nothing above 12 kHz). Ranges: seek 2.5-4.4, 7.5-9.4 and 13.0-14.9 s.
  - Rhythm: bursts at 47/s, IOI p10/50/90 = 8/16/19 ms (a very regular retry tick of about 60 Hz). They group into 51 ms gestures (15 ms merge), and those into about 260 ms groups about 367 ms apart. Retry episodes last about 2 s and recur about every 5 s.
  - Modes: 280 Hz at 0 dB, with no delay (peaks at 1 ms, −10 dB at 17 ms). Then 2098 Hz (−6 dB, T60 97 ms → Q≈92), 349 Hz (−5.6), 1096 Hz (−10.7), 715 Hz (−11), 1159-1469 Hz (−13 to −17, T60 93-136 ms → Q≈62-80) and 2265 Hz (−19, Q≈36-46).
  - The 1-5 kHz band reaches −10 dB at 6 ms. Excess A-weighted shares: 12/23/65/0%. Peaks over the idle envelope 13/15/17 dB.
  
  — [Commons WD102AA](https://commons.wikimedia.org/wiki/File:WD102AA_Scratched_area_read_retries.ogg), own analysis
- *"WD bad heads click of death"* (public domain per Commons; 22.05 kHz).
  - Timing: clicking runs of about 5 s separated by about 0.5-1 s pauses. Each 509-511 ms cycle (p10-p90) holds two clicks about 162 ms apart. Each click is a 67-80 ms cluster of sub-bursts.
  - Level: +31.7 dBA over idle in a 30 ms window; the 1-5 kHz band peaks +42 dB over idle. Excess A-weighted shares: 0/2/88/10%.
  - Modes: a sharp 4.5-5.6 kHz crack (4741 Hz 0 dB, 4542 −0.8, 5234 −4.9, 5644 −4.9, 2257 −6.0, 2373 −6.5, 3316 −11) with T60 13-34 ms → Q≈30-45. Over it rings a long 1.02-1.11 kHz tone at −2.6 to −2.8 dB, which holds 13-18 ms and needs 30-150 ms to reach −10 dB. The earlier note measured that ring at 130-220 ms T60 ([real_recordings_analysis.md](/Users/zihangqi/Workspace/Canister.Whirr/research_notes/Realistic%20HDD%20sound%20synthesis/real_recordings_analysis.md)), which implies Q ≈ 65-110 at 1.11 kHz.
  - Idle in this clip is mostly sub-300 Hz noise (−16 dBFS unweighted but −43.9 dBFS A-weighted).
  
  — [Commons WD click of death](https://commons.wikimedia.org/wiki/File:WD_bad_heads_click_of_death.ogg), own analysis
- *"Sound of defective IBM Deskstar"* (**CC BY-SA 3.0**: attribution and share-alike apply to the recording; model and rpm not stated).
  - Rhythm: sparse gestures at 1.2-1.5/s, IOI median 580-740 ms (p10 145-330, p90 about 1140 ms), each 23-45 ms long.
  - Brightest clip analysed: excess A-weighted shares 0/2/40/58%, and the octave rise over idle is +18 to +21 dB at 4-12.5 kHz.
  - Modes: 5612 Hz (0 dB, peaks 15 ms after onset), 4457 (−4.9, Q≈330-360), 4624 (−5.4, Q≈325), 5327 (−7.5, Q≈270-340), 5932 (−9.1, Q≈400-570), 4867 (−10.6, Q≈470), 6185 (−10.9), 6414 (−11.7), 4124 (−11.8), 2318 (−12.9, Q≈70-78), 2420 (−14.4, Q≈200-280), 1453 (−15.5, Q≈55-67), 1130-1330 (−17.5 to −18, Q≈80-110) and 576 Hz (−16, Q≈25-34).
  - Levels: event peaks +20 dB over the idle envelope (median), while 0.5 s RMS rises only +1.1 dB. The 5-16 kHz band reaches −10 dB at 27 ms.
  
  — [Commons Deskstar](https://commons.wikimedia.org/wiki/File:Sound_of_defective_IBM_Deskstar.ogg), own analysis

### Inferences
Suggested presets in the `SoundBank.swift` format, built from the tables above. dB is relative to the strongest mode. Q values are rounded and capped near 300, because higher values are at or beyond what the measurement can resolve. These are starting points to tune by ear.

```swift
// 10k rpm server (Maxtor Atlas 10K V): bright 4.6-6.5 kHz ring (Q~220-300, T60 75-150 ms),
// a second 1-2.3 kHz strike ~10 ms later, faint late low swell.
modes: [
    Mode(hz: 6_480, q: 225, db: 0),    Mode(hz: 5_985, q: 225, db: -2),
    Mode(hz: 4_890, q: 170, db: -6),   Mode(hz: 4_640, q: 220, db: -6),
    Mode(hz: 5_670, q: 280, db: -7),   Mode(hz: 5_310, q: 280, db: -8),
    Mode(hz: 5_120, q: 250, db: -9),   Mode(hz: 2_020, q: 95, db: -2),   // peaks ~10 ms late (strike B/C)
    Mode(hz: 1_255, q: 80, db: -8),    Mode(hz: 1_000, q: 50, db: -9),
    Mode(hz: 2_265, q: 150, db: -11),  Mode(hz: 1_840, q: 75, db: -12),
    Mode(hz: 390, q: 38, db: -7),
],
thump: Thump(hz: 199, q: 13, db: -5, delay: 0.012...0.022)   // optional; ~2% of A-weighted energy

// 15k rpm server (Fujitsu MBA3300RC): 3.4-3.75 kHz centre with 1.0-1.3 kHz body, high-Q 4.3-6.3 kHz partials, no thump.
modes: [
    Mode(hz: 3_605, q: 185, db: 0),    Mode(hz: 6_120, q: 210, db: -2),
    Mode(hz: 1_145, q: 90, db: -4),    Mode(hz: 4_750, q: 185, db: -5),
    Mode(hz: 6_340, q: 280, db: -5),   Mode(hz: 3_750, q: 190, db: -5),
    Mode(hz: 1_285, q: 150, db: -6),   Mode(hz: 3_425, q: 120, db: -6),
    Mode(hz: 4_295, q: 260, db: -7),   Mode(hz: 336, q: 15, db: -7),
    Mode(hz: 2_520, q: 80, db: -9),    Mode(hz: 1_010, q: 75, db: -10),
    Mode(hz: 2_205, q: 130, db: -10),
],  // thump: nil

// 2000 5400 rpm (Samsung SV1022D): short damped 3.4-4.9 kHz click over a woody 200-700 Hz body.
modes: [
    Mode(hz: 4_065, q: 40, db: 0),     Mode(hz: 4_260, q: 45, db: -8),
    Mode(hz: 4_470, q: 65, db: -8),    Mode(hz: 3_735, q: 55, db: -10),
    Mode(hz: 4_720, q: 60, db: -10),   Mode(hz: 4_895, q: 75, db: -11),
    Mode(hz: 3_385, q: 75, db: -14),   Mode(hz: 1_945, q: 60, db: -15),
    Mode(hz: 353, q: 20, db: -4),      Mode(hz: 455, q: 25, db: -4),     // Q are lower-bound estimates
    Mode(hz: 684, q: 30, db: -11),
],
thump: Thump(hz: 196, q: 10, db: 0, delay: 0.006...0.012)   // peaks ~7-12 ms; mostly a sustained writing rumble

// 2007 7200 rpm (Samsung T166): dominant late 207 Hz thump, a 377 Hz knock, faint high-Q kHz ticks.
modes: [
    Mode(hz: 377, q: 28, db: 0),       Mode(hz: 576, q: 60, db: -20),
    Mode(hz: 474, q: 40, db: -16),     Mode(hz: 4_875, q: 300, db: -21),
    Mode(hz: 5_430, q: 250, db: -21),  Mode(hz: 5_080, q: 105, db: -23),
    Mode(hz: 4_500, q: 300, db: -25),  Mode(hz: 2_305, q: 210, db: -26),
    Mode(hz: 2_910, q: 275, db: -27),  Mode(hz: 2_590, q: 125, db: -28),
    Mode(hz: 1_675, q: 140, db: -29),
],
thump: Thump(hz: 207, q: 22, db: 4, delay: 0.012...0.020)   // the drive's loudest component

// Failing drive (built from the CC0/PD clips only): WD102AA retry tick (16 ms IOI, 280 Hz + 1.1/2.1 kHz)
// alternating with click-of-death double-clicks (162 ms apart, 509 ms cycle; 4.5-5.6 kHz Q~35 crack + 1.1 kHz Q~65-110 ring).
modes: [
    Mode(hz: 4_740, q: 40, db: 0),     Mode(hz: 4_540, q: 35, db: -1),
    Mode(hz: 1_108, q: 80, db: -3),    Mode(hz: 1_020, q: 60, db: -3),
    Mode(hz: 5_235, q: 30, db: -5),    Mode(hz: 5_645, q: 35, db: -5),
    Mode(hz: 2_098, q: 90, db: -6),    Mode(hz: 2_260, q: 75, db: -6),
    Mode(hz: 2_375, q: 35, db: -7),    Mode(hz: 3_315, q: 35, db: -11),
],
thump: Thump(hz: 280, q: 8, db: -2, delay: 0.000...0.003)  // WD102AA's low knock is not delayed
```

- Q for the 129-207 Hz components came out at 13-26 from decay, much higher than the earlier spectral 4-5, which was window-limited. Existing presets with thump Q 4.5 (vintage1993) may decay faster than the real drives. Q 4.5 at 264 Hz gives T60 ≈ 37 ms; the measured T166 thump has T60 ≈ 210-280 ms. Not checked against the Conner recording here.
- With Q≈200-300 at 5-6 kHz and seek gestures every 20-80 ms, the server modes never fully decay during busy periods. This plausibly explains why the earlier note found the Atlas's broadband T60 (112-116 ms) and −10 dB time (43 ms) to be the longest of the pack.
- The "hold" times (Atlas 12-20 ms for 1-2.3 kHz modes; Fujitsu 9-17 ms at 1.1-3.6 kHz) look like the existing multi-strike gesture (strikes A/B/C over 10-20 ms) rather than a property of the resonators. The Atlas 1-2.3 kHz modes peak about 10 ms after the 5-6.5 kHz cluster, which supports exciting different mode groups on different strikes.

### Gaps
- Free-ring Q cannot be separated from continued excitation (settle, track-following) in these recordings. The Q values above are effective decay Q's of what is heard, and likely upper bounds.
- SV1022D low modes and the Fujitsu 1.0-1.3 kHz modes: decay is unresolved, because the activity bed is within 2-7 dB of the peaks. Their Q values are lower bounds or estimates.
- Lossy previews: MP3 smearing could slightly broaden or narrow lines and affect frequencies above about 15 kHz. The originals (Freesound login required) were not used.
- Seek-time datasheet parameters (track-to-track, average, full-stroke) for the Atlas 10K V and MBA3300RC were not researched (web research skipped). The preset timing fields still need values.

## 2. Server drives (10k / 15k): distinct seek character, spindle fundamental and whine tones

### Takeaway
- Both server drives ring far longer than the 2000-era Samsung (Q≈150-300 against 40-75 in the kHz modes).
- The Atlas 10K is clearly brighter: 23% of A-weighted seek energy above 5 kHz, against 2-10% for the others in this note, and only the Deskstar is brighter.
- The Allegro 15k is not especially bright. It centres on 3.4-3.75 kHz with a 1.0-1.3 kHz body (80% of A-weighted energy in 1-5 kHz), and its distinguishing feature is the dense, roaring heavy-write texture.
- Both idle beds are a nearly pure rpm/60 fundamental (166.8 Hz and 250.0 Hz) plus high-frequency whine combs locked to rotation harmonics: the Atlas near 14 kHz (84× rotation) and the Allegro at 6.0 kHz (24×) and 7.0 kHz (28×).

### Cited Findings
- **Atlas 10K V idle tones.**
  - Fundamental 166.8 Hz (rpm/60 = 166.7), the strongest low tone (prominence 28 dB). Harmonics 2-8 are weak (−26 to −36 dB re idle max, prominence ≤5 dB).
  - A non-harmonic 95.5 Hz tone at −6 dB (prominence 22) is of unknown source.
  - HF whine: the strongest idle peak overall is 14,004 Hz (84.0× rotation, 0 dB, prominence 41 dB). It is part of a 500 Hz-spaced comb (3× rotation): 10,002 (60×, −13), 11,003 (66×, −18), 12,003 (72×, −14), 13,003 (78×, −10), 13,503 (81×, −9), 14,504 (87×, −6), 15,004 (90×, −17) and 15,504 (93×, −7) Hz.
  - Mid tones at 3,001 (18.0×, −18) and 3,168 (19.0×, −11) Hz, and 1,090 Hz (−18).
  - Idle A-weighted shares: <300 Hz 4%, 300 Hz-1 kHz 9%, 1-5 kHz 51%, >5 kHz 36%.
  
  — [182366](https://freesound.org/people/Klerrp/sounds/182366/), own analysis
- **Allegro MBA3300RC 15k idle tones.**
  - Fundamental 250.0 Hz (0 dB, prominence 29). Harmonics 2-5 are weak (−24 to −38 dB), and the 6th is 1,499 Hz (−15 dB, prominence 18).
  - Whine tones: 5,997 Hz (24.0×, −5 dB, prominence 29), 6,997 (28×, −14), 4,498 (18×, −23), 4,748 (19×, −21), 6,747 (27×), 7,497 (30×), 8,996 (36×), 9,246 (37×), 14,993 (60×, −13) and 15,742 (63×, −14) Hz.
  - A strong non-harmonic 90.0 Hz tone (−2 dB, prominence 28) equals 5400 rpm/60. It may come from another drive or fan in the recording setup (inference; not stated on the page).
  - Idle A-weighted shares: 7/3/45/44%.
  
  — [182364](https://freesound.org/people/Klerrp/sounds/182364/), own analysis
- **Comparison: idle tones at 24× rotation** also appear in the two Samsungs.
  - SV1022D: fundamental 90.2 Hz, the 5th harmonic 452.5 Hz is strong (−11 dB, prominence 43), and whine at 2,167 Hz (24.0×, −8 dB, prominence 37) with its multiples 10,836 (−11), 13,003 (−17) and 15,171 Hz (−19). Idle A-weighted shares 2/10/62/27%.
  - T166: fundamental 120.5 Hz, harmonics 241 Hz (−11) and 482 Hz (−21), and faint whine at 2,894 Hz (24.1×, −33) and 14,469 Hz (120.6×, −35). Idle A-weighted shares 16/30/50/5%.
  
  — [167420](https://freesound.org/people/Klerrp/sounds/167420/), [167421](https://freesound.org/people/Klerrp/sounds/167421/), own analysis
- **Brightness (excess A-weighted share above 5 kHz):** Atlas 23%, Allegro 15k 10%, SV1022D 4%, T166 2%; Deskstar (failing) 58%. The earlier note had the Atlas at 41% >5 kHz with a 20 ms window and different ranges, and the WD1600JD at 28% — own analysis; [real_recordings_analysis.md](/Users/zihangqi/Workspace/Canister.Whirr/research_notes/Realistic%20HDD%20sound%20synthesis/real_recordings_analysis.md)
- **Ring length (kHz-mode decay T60):** Atlas 75-160 ms, Allegro 15k 69-223 ms, T166 (weak modes) 137-290 ms, SV1022D 21-49 ms — own analysis (tables in section 1)
- **Activity rumble in the servers:** the Atlas seek ranges raise 60-150 Hz by +10 dB and 5-10 kHz by +16 dB over idle, with broad humps at 114-153 and 194-205 Hz (+20 to +27 dB). The Allegro raises nothing below 300 Hz (+0 to +1 dB) and 300 Hz-5 kHz by +9 to +12 dB — [182366](https://freesound.org/people/Klerrp/sounds/182366/), [182364](https://freesound.org/people/Klerrp/sounds/182364/), own analysis (`bed.py`)

### Inferences
- The 24× rotation tone in four of these drives (Allegro, both Samsungs, and the T166 faintly) is consistent with spindle-motor commutation: a 3-phase motor with 8 poles makes 4 × 6 = 24 commutation steps per revolution. This is an inference from the arithmetic, not a sourced fact. An idle-bed generator could use rpm/60 plus a whine partial at 24 × rpm/60, plus drive-specific extras such as 84× for the Atlas.
- For Whirr's built-in-speaker output, the Atlas's 14 kHz whine and 10-15.5 kHz comb are at the edge of audibility and of the default `lowPassHz` of 8 kHz. If a 10k preset wants that "server whine", it needs a separate idle-bed tone with the low-pass raised, not more modes.
- Suggested one-line descriptions:
  - **Atlas 10K V:** the brightest and longest-ringing healthy drive here, a fast metallic "tsing-tick" at 5-6.5 kHz followed about 10 ms later by a 2 kHz knock, over a high whine.
  - **Allegro 15k:** a mid-bright 3.6 kHz ringing click with a 1.1 kHz body; under heavy writing it becomes a continuous dense chatter-roar.
  - **SV1022D:** the driest and woodiest, short 4 kHz ticks over a hollow 200-450 Hz writing rumble.
  - **T166:** mostly a late, booming 207 Hz "thunk" with faint glassy high-Q ticks.
  - **Deskstar (failing):** sparse, very bright, bell-like 4.5-6 kHz pings.
  - **WD102AA:** a buzzy 60 Hz-rate knock train.
  - **Click of death:** loud double cracks with a 1.1 kHz ring every half second.

### Gaps
- The source of the 90 Hz (Allegro clip) and 95.5 Hz (Atlas clip) tones is unknown. They could be the recording rig.
- Motor pole and slot counts for these drives were not researched, so the 24× and 84× interpretation is not verified.
- MP3 previews may attenuate content above about 16 kHz, so the HF whine above 15 kHz is under-represented.

## 3. Idle bed levels relative to seek peaks, seek rate and rhythm

### Takeaway
- Individual seek bursts peak 13-17 dB (median) above the idle envelope in all four target drives, matching the earlier 13-16 dB.
- 0.5 s RMS rises only +3.7 dB (SV1022D) to +8 dB (T166) over idle in seek passages, and +12-13 dB in the Allegro's continuous heavy write.
- Burst rates are 8.6-25.6/s with median IOIs of 17-44 ms. Gesture-level rates (15 ms merge) are 4-12/s.

### Cited Findings
Idle level (dBFS unweighted / A-weighted) and event-peak statistics (p10/50/90) per drive. Detector: 300 Hz+ 1 ms envelope, +12 dB over the idle median, 3 ms merge.
- **Atlas 10K:**
  - Idle −39.2 / −43.1 dBA.
  - Peak over idle envelope 13/15/18 dB; full-band 1 ms peaks 12/15/17 dB over the full-band idle median.
  - A 30 ms event window is +10.6 dB / +13.1 dBA over idle; seek-range 0.5 s RMS is +7.4 dB.
  - Rate 25.6 bursts/s, IOI 6/17/82 ms, burst duration 1/5/15 ms. Gestures (15 ms merge): 11.1/s, IOI 37/85/173 ms, length 10/20/26 ms. With a 50 ms merge, the IOI p10/p50 is 82/87 ms, a near-periodic seek pattern of about 85 ms.
  - Time to −10 dB (energy-averaged, isolated onsets): 300 Hz-16 kHz 35 ms, 1-5 kHz 35 ms, 5-16 kHz 20 ms. Per-event extrapolated T60 (hdd_batch method) 70/128/427 ms.
  
  — [182366](https://freesound.org/people/Klerrp/sounds/182366/), own analysis
- **Allegro 15k (seek ranges):**
  - Idle −34.3 / −37.4 dBA.
  - Peak over idle envelope 12/14/19 dB; full-band peaks 11/13/17 dB.
  - A 30 ms window is +8.9 dB / +11.6 dBA; 0.5 s RMS +5.0 dB.
  - Rate 14.8/s, IOI 6/33/198 ms, duration 1/4/22 ms. Gestures: 8.3/s, IOI 32/66/278 ms, length 1/10/32 ms.
  - Time to −10 dB: 1-5 kHz 29 ms, 5-16 kHz 40 ms. In 300 Hz-16 kHz the envelope plateaus at −8 to −9 dB on the write bed. Per-event T60 54/95/405 ms.
  - Heavy write (32-73 s): RMS +12-13 dB over idle, crest only about 6 dB.
  
  — [182364](https://freesound.org/people/Klerrp/sounds/182364/), own analysis
- **SV1022D:**
  - Idle −34.0 / −38.7 dBA.
  - Peak over idle envelope 12/14/16 dB; full-band peaks 9/11/14 dB.
  - A 30 ms window is +6.1 dB / +6.8 dBA; 0.5 s RMS +3.7 dB.
  - Rate 17.0/s, IOI 10/30/116 ms, duration 1/2/5 ms. Gestures: 11.9/s, IOI 20/56/143 ms.
  - Time to −10 dB: 300 Hz-16 kHz 23 ms, 1-5 kHz 5 ms. Per-event T60 18/30/116 ms. The earlier note gave IOI 10/39/119 ms over a different range.
  
  — [167420](https://freesound.org/people/Klerrp/sounds/167420/), own analysis
- **T166:**
  - Idle −32.5 / −40.4 dBA.
  - Peak over idle envelope 13/17/21 dB; full-band peaks 10/21/23 dB. Full-band peaks are high because of the thump.
  - A 30 ms window is +15.0 dB / +14.3 dBA; 0.5 s RMS +8.0 dB.
  - Rate 8.6/s, IOI 8/44/325 ms, duration 1/17/46 ms. Gestures: 4.1/s, IOI 71/190/545 ms, length 6/45/86 ms.
  - Time to −10 dB: 300 Hz-16 kHz 51 ms (peak at 13 ms), 150-400 Hz 29 ms after its 14 ms peak, 5-16 kHz 5 ms. Per-event T60 33/116/249 ms. The earlier note gave IOI 8/34/199 ms.
  
  — [167421](https://freesound.org/people/Klerrp/sounds/167421/), own analysis
- **Failure clips:**
  - WD102AA: idle −29.9 dBFS / −36.1 dBA, peaks 13/15/17 dB over idle, +9.3 dBA event window, RMS +5.5 dB.
  - Click of death: +31.7 dBA event window, 1-5 kHz +42 dB over idle.
  - Deskstar: idle −24.3 / −30.2 dBA, peaks 13/20/22 dB, +15.6 dBA event window but RMS only +1.1 dB (sparse events).
  
  — [Commons WD102AA](https://commons.wikimedia.org/wiki/File:WD102AA_Scratched_area_read_retries.ogg), [Commons WD click](https://commons.wikimedia.org/wiki/File:WD_bad_heads_click_of_death.ogg), [Commons Deskstar](https://commons.wikimedia.org/wiki/File:Sound_of_defective_IBM_Deskstar.ogg), own analysis

### Inferences
- Across drives, seek bursts sit at about +13-17 dB (median) over the idle bed, and A-weighted 30 ms windows at +7 to +14 dBA. A preset could set the idle-bed gain about 14-15 dB below the median seek-peak level, with drive-specific spread (p90 up to +18 to +23 dB).
- Rhythm targets for "writing" presets: burst IOI medians of 17 ms (10k server) to 30-44 ms (desktop), heavy-tailed (p90 82-325 ms), and gesture rates of about 4-12/s. A failing preset should use metronomic timing instead: a 16 ms retry tick, or a 509 ms double-click cycle with the clicks 162 ms apart. That regularity is the cue that separates failure from normal seeking.
- Under heavy load (Allegro 32-73 s) a drive becomes a continuous bed about 12 dB louder than idle with little crest. "Bigger bursts under heavy load" may need a sustained band-limited chatter layer (300 Hz-5 kHz, peaks near 0.5 and 1.0-1.3 kHz for this drive) as well as more frequent gestures.

### Gaps
- Absolute SPL is unknown (no calibration), so only relative levels are given.
- Idle and seek ranges were chosen by hand. Numbers shift by a few ms or dB with range choice, as the differences from the earlier note's IOIs show (T166 median 44 vs 34 ms).
- I could not label which events are short-stroke and which are full-stroke, so I did not measure how level depends on seek distance.
- Deskstar is CC BY-SA 3.0. Parameters measured from it are numbers, not audio, but if any Deskstar audio were shipped or adapted, attribution and share-alike would apply. The failing-drive preset above is built only from the CC0 WD102AA and public-domain click-of-death measurements, per the earlier note's license records.

# Measured acoustic signatures: Seagate ST-277N stepper, Fujitsu MHV2200BT and Toshiba MK5055GSX 2.5" laptop drives, Toshiba MQ01UBD100 USB portable (contact mic), as Whirr preset numbers

Method and caveats (these apply to every number below).

**Sources and limits**
- All numbers come from my own analysis of four recordings on disk in `research_notes/HDD sound presets by drive type/recordings/`. Each is an MP3 preview (about 128 kbps) converted to mono 44.1 kHz 16-bit WAV.
- Microphone, distance, mounting and room are undocumented. The USB drive was recorded with a contact mic, so it hears structure-borne vibration, not airborne sound.
- No calibration exists, so all levels are relative.
- Treat every number as "this recording of this drive", not as a drive specification.

**Recording pages**
- [475216 Seagate ST-277N, jodybruchon, CC0](https://freesound.org/people/jodybruchon/sounds/475216/)
- [143917 Fujitsu MHV2200BT, Klerrp, CC0](https://freesound.org/people/Klerrp/sounds/143917/)
- [143269 Toshiba MK5055GSX, Klerrp, CC0](https://freesound.org/people/Klerrp/sounds/143269/)
- [401271 Toshiba MQ01UBD100 USB, eardeer, CC BY 4.0](https://freesound.org/people/eardeer/sounds/401271/). Attribution applies if any of its audio is shipped.

**Tools**
- Analysis used numpy only. Scripts are in `scripts/` and run as `python3 -I run.py <script> ...`.
- Reused: `preset_measure.py` / `preset_measure2.py`, `timeline.py`, `bed.py`.
- New in this pass:
  - `stft_peek.py`, `steps.py`, `modspec.py`: short-time peaks, impulse timing, periodicity.
  - `bandevents.py`: per-band event detector with optional smoothing.
  - `stepper_gestures.py`: gesture detector plus the impulse train inside each gesture.
  - `gesture_avg.py`: synchronous energy average of aligned gestures.
  - `aligned_modes.py`: the same Gaussian-narrowband decay → Q method as `preset_measure.py`, run on aligned event times.
  - `excess_shares.py`: band shares counting only bins at least 3 dB above the bed.
  - `track_f0.py`: spindle speed.
  - `bandtimeline.py`.
  - `spectro_png.py`, `wave_png.py`: numpy-only PNG spectrograms and waveforms, optionally whitened against an idle range.

**Three method deviations from `measured_server_and_samsung_recordings.md`. Read these before comparing numbers.**
1. **The standard detector (300 Hz+ 1 ms envelope, +12 dB over the idle median) does not work on these four recordings.**
   - Stepper: its bed is loud (−22.6 dBFS) and tonal. `preset_measure2.py` found 0 events in a clearly active passage.
   - Laptop drives: no idle exists (they write from spin-up to spin-down). The 0.7-3 kHz spindle/air noise fills the band, with a 1 ms crest of only 6-8 dB, which is what Gaussian noise gives.
   - I therefore detected in the band where each drive's events stand out: stepper 800-1700 Hz (3 ms smoothing, +8 dB, 12 ms merge); Fujitsu 3-16 kHz; USB 150-700 Hz.
   - The "idle" reference is the quietest bed available. For the laptops that is the writing bed, not a true idle.
   - Rates, IOIs and "peak over idle" are therefore **not** strictly comparable with the earlier notes' 300 Hz+ numbers.
2. **Q is decay-derived exactly as in the earlier note**: Gaussian band, energy average over isolated aligned events, fit from −3 dB down to max(pre+3, peak−25) dB, Q = π·f·T60/6.91.
   - The busy beds often stop that fit early. I added an alternative fit from −3 to −12 dB that ignores the pre-onset floor, labelled "alt".
3. **Timing bug found in the inherited scripts.** `hdd_batch.py`, `preset_measure.py`, `longenv.py` and `clusters.py` index ranges as `int(t*1000)` on 44-sample frames, which are 0.998 ms at 44.1 kHz.
   - Hand-picked ranges therefore drift by 0.23%: 0.14 s at 60 s and 0.9 s at 390 s.
   - Durations and IOIs are unaffected (0.2%). Range masks on long files are affected.
   - `preset_measure2.py` and all new scripts map times with the true frame rate. Earlier notes used files of 60 s or less, so their ranges were off by at most about 0.14 s.

## 1. Stepper (Seagate ST-277N, 475216): what a stepper seek is, structurally, and a synthesis recipe

### Takeaway
In this recording, a stepper seek is a train of discrete impulses at a nearly fixed 5.5 ms spacing (about 174-182 impulses/s). Each impulse rings a 0.9-1.43 kHz cluster of moderately damped modes (Q≈20-40).
- **Short seeks:** 4-5 impulses.
- **Typical seeks:** 6 impulses, a fixed core of 5.5, 5.5, 5.5, 6.5 and 7.0 ms (30 ms).
- **Long seeks:** 8-10 impulses (54-66 ms), with a slowing tail of 10.5 and 13.5 ms or 10.5, 7 and 7 ms.
- **No ramp-up:** the train starts at full rate.
- **No kHz pitch sweep:** there is no "fweep" chirp in the 0.2-16 kHz content. The only pitch movement is the impulse rate falling in the last 2-4 intervals, from about 154 to about 74 Hz.
- **Single-track steps** are single, darker "tok" impulses centred on about 0.45-0.6 kHz. During sequential access they recur every 300-350 ms.
- **Power-up:** spindle ramp of about 7 s with overshoot, about 6 s of continuous 5.75 ms impulse buzz, a 180-250 ms rattle of about 30-42 impulses (recalibration), then a busy burst of single steps.
- **Power-down:** about 2.4 s of stepping during spin-down (auto-park), louder than any seek.

### Cited Findings
All findings in this section are my own analysis of [475216](https://freesound.org/people/jodybruchon/sounds/475216/). Datasheet figures are quoted from [vintage_stepper_and_voice_coil.md](/Users/zihangqi/Workspace/Canister.Whirr/research_notes/HDD%20sound%20presets%20by%20drive%20type/vintage_stepper_and_voice_coil.md), which cites the [ST251N/ST277N Product Manual, Mar 1987](https://ftp.mirrorservice.org/sites/www.bitsavers.org/pdf/seagate/scsi/36034-001B_ST251N_ST277N_Product_Manual_Mar87.pdf): 820 cylinders, 3600 rpm, 8 ms track-to-track, 40 ms average and 95 ms full stroke (maximums).

**Recording map (390.4 s)**

| Time (s) | What happens |
|---|---|
| 0-14 | Spin-up |
| 11.5-17.2 | Impulse buzz |
| 17.20-17.45 | Recalibration rattle |
| 19.9-25.1 | Burst of single steps |
| 25.1-50 | Idle; reference used everywhere |
| 50-350 | Use |
| 350.4-352.85 | Stepping during spin-down (park) |
| 352.8-about 360 | Spin-down |
| 369.5-390 | A second power-up, which repeats the first. Spindle 26→60 Hz over 371-376 s; buzz 380.36-386.1 s; recalibration rattle 386.11-386.29 s; then single steps |

**Seek = impulse train**
- **Synchronous average of 59 eight-to-nine-impulse seeks.** The 800-1250 Hz and 1250-1700 Hz envelopes show discrete peaks about 5.5-6 ms apart (0, about 5.5, 11.5, 17, 23 ms), all within about 2 dB of each other, then weaker and wider-spaced ones.
- **Periodicity check.** Envelope autocorrelation inside single seeks peaks at 5.5-5.8 ms (r≈0.3-0.5).
- **Waveform.** The 300-1200 Hz waveform is a continuous about 1 kHz ring, re-struck rather than a sweeping tone.
- **Spectra repeat exactly from seek to seek.** Peaks (dB over idle) at 129.07, 129.57 and 129.99 s:
  - 129.07 s: 1416 (+33), 921 (+28), 984 (+23), 1024 (+22), 699 (+21), 346 (+20), 1599 (+17), 503 (+15) Hz.
  - 129.57 s: the same peaks within ±1 dB.
  - 129.99 s: the same peaks within ±1 dB.
  - So the frequencies are resonances. A changing step rate would have moved them.
- **Impulse-count histogram (17.6-352 s, 1902 gestures):**

  | Impulses | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 13 | 26 | 88 |
  |---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
  | Gestures | 1208 | 332 | 124 | 41 | 23 | 69 | 23 | 43 | 27 | 6 | 3 | 1 | 1 | 1 |

  The 26- and 88-impulse gestures are the park.
- **Positional median intervals by class (17.6-349 s):**

  | Impulses | n | Median intervals (ms) | Median duration | Median peak over idle (800-1700 Hz) |
  |---|---|---|---|---|
  | 4 | 41 | 6.5, 5.5, 6.0 | 24 ms | +16.0 dB |
  | 5 | 20 | 6.25, 4.75, 6.5, 7.25 | 31.5 ms | +16.8 dB |
  | 6 | 68 | 5.5, 5.5, 5.5, 6.5, 7.0 | 38 ms | +17.7 dB |
  | 7 | 23 | 5.5, 5.5, 5.5, 6.5, 7.0, 8.5 | 45 ms | +17.2 dB |
  | 8 | 43 | 5.5, 5.5, 5.5, 6.5, 7.0, 10.5, 13.5 | 60 ms | +17.3 dB |
  | 9 | 27 | 5.5, 5.5, 5.5, 6.5, 7.0, 10.5, 7.0, 7.0 | 61 ms | +18.6 dB |
  | 10 | 6 | 5.5, 6.0, 5.5, 6.5, 7.0, 10.5, 7.0, 5.25, 7.0 | 66 ms | +18.1 dB |

  All within-gesture intervals, p10/25/50/75/90: 4.5/5.5/6.0/7.5/10.5 ms. Resolution is 0.5 ms.
- **No acceleration ramp and no kHz chirp.**
  - The first interval is already 5.5 ms in every class.
  - Whitened spectrograms (0.2-16 kHz, 0.4 ms hop) show no rising or falling tone during the train.
- **Tone bursts after the train.** In the 128-132 s passage, each seek train is followed by two about 45 ms steady tone bursts: 12.05, 12.9 and 14.9 kHz plus 2.72-2.83 kHz.
  - The first burst starts right after the train; the second starts about 25 ms after the first ends.
  - The bursts have abrupt onsets and only a 1-2 ms upward glide at onset, so they are not a step-rate ramp.
  - In the 75-100 ms window after the first impulse, the averaged spectrum shows 11948 Hz (+24 dB), 2772 Hz (+18), 9203 Hz (+13) and 7176 Hz (+13).

**Seek mode list.** Envelope peak dB relative to the strongest mode, for 59 eight-to-nine-impulse seeks aligned on the first impulse (`aligned_modes.py`). Q is from single-step decays where available, because repeated strikes make the decay fits inside a train unreliable.

| Hz | dB | Peak time after first impulse | Q |
|---|---|---|---|
| 1428 | 0 | 11 ms | ≈27-40 (single step: 1410 Hz, T60 42 ms → Q 27) |
| 1385 | −0.6 | 7 ms | ≈29-32 |
| 915 | −2.7 | 18 ms | ≈21-29 (single step: 922 Hz, T60 53 ms → Q 22) |
| 1012 | −3.2 | 25 ms | single step: 1005 Hz, T60 86 ms → Q 39 |
| 498 | −3.6 | 41 ms (late) | — |
| 557 | −3.6 | 40 ms (late) | T60 88-102 ms → Q 22-26 |
| 845 | −4.4 | — | — |
| 1304 | −4.4 | — | — |
| 1077 | −5.3 | — | — |
| 709 | −8.4 | — | — |
| 1262 | −8.9 | — | — |
| 1606 | −10.1 | — | — |
| 343 | −11.5 | — | — |
| 170 | −13.6 | 43 ms | — |

- **Spectral peaks in the first 30 ms** (dB over idle): 1410 (+32), 945 (+27), 993 (+24), 708 (+20), 331 (+18), 1604 (+18), 821 (+14) and 503 (+13) Hz.
- **Late low-mid component.** In the 36-62 ms window the 1386 Hz (+26) and 571 Hz (+21) peaks dominate. In the 300-800 Hz envelope the peak comes at 42.5 ms (eight-to-nine-impulse seeks) or 79 ms (six-impulse seeks), so it is a late low-mid "landing" component. Its timing relative to the train is not consistent.

**Single-track step**
- **Selection:** 230 isolated single impulses, at least 150 ms from any other gesture.
- **Level:** peak +12/13.9/15.9 dB (p10/50/90) in 800-1700 Hz; only +8.1 dB over idle in 300-16 kHz.
- **Modes** (dB re max | delay | T60 → Q; T60 from the "alt" fit):

  | Hz | dB | Delay | T60 → Q |
  |---|---|---|---|
  | 573 | 0 | 3 ms | 90 ms → 23 |
  | 458 | −0.7 | 5 ms | 217 ms → 45 (standard fit) |
  | 922 | −2.5 | 0 | 53 ms → 22 |
  | 1292 | −3.4 | — | — |
  | 1005 | −3.8 | — | 86 ms → 39 |
  | 1410 | −5.2 | 0 | 42 ms → 27 |
  | 736 | −6.7 | — | 77 ms → 26 |
  | 685 | −7.5 | — | — |
  | 374 | −8.1 | 0 | 125 ms → 21 |
  | 131 | −10.7 | 4 ms, hold 15 ms | — |

- **Envelopes:**
  - 800-1700 Hz is −10 dB about 3-4 ms after its peak, because it reaches the bed at −17.
  - 300-800 Hz peaks at 2 ms, holds about 5 ms, and is −10 dB about 18 ms after the peak.
- **Band shares** (excess bins at least 3 dB over idle):
  - Unweighted <300 Hz 3%, 300 Hz-1 kHz 76%, 1-5 kHz 19%, >5 kHz 1%.
  - A-weighted 0/66/32/1%.
- **Compared with seek trains** (unweighted 1/62/37/0%, A-weighted 0/52/47/0%): single steps are clearly darker.

**Rhythm during use (50-350 s)**
- **All gestures:** 1750 (5.8/s). IOI p10/50/90 = 23/98/317 ms.
- **Multi-impulse seeks (4 or more):**
  - 231 (0.77/s).
  - IOI p10/50/90 = 171/417/4352 ms; duration 24/39/61 ms.
  - Peak +15.6/17.3/19.1 dB (800-1700 Hz band over idle median).
- **One-or-two-impulse events:** 1404. Duration 3/7/12 ms; peak +9.7/13.8/16.5 dB.
- **Sequential rhythm:** IOIs between consecutive single impulses cluster at 300-350 ms (200 of about 1000 pairs fall in the 300-350 ms bins), for example 165.72, 166.04, 166.39, 166.71, 167.02 s and so on.
- **Test-like passage (128-132 s):** 8-impulse (59 ms) and 6-impulse (35 ms) seeks alternate every 0.42-0.56 s, each followed by the two tone bursts and 2-4 single impulses.

**Levels and band shares**
- **Idle (26-50 s):** −22.6 dBFS / −26.1 dBA.
  - Unweighted shares 63/7/30/1%; A-weighted 1/11/88/1%.
- **Seek window (−3 to 45 ms):** +3.2 dB and +5.3 dBA over idle.
  - Octave rises: 63 Hz +0, 125 Hz +2, 250 Hz +4, 500 Hz +6, 1 kHz +13, 2 kHz +3, 4 kHz +0, 8 kHz +1, 12.5 kHz −1 dB.
- **Single-step window:** +0.5 dB / +0.7 dBA, with +4 dB in the 500 Hz octave.
- **Loudest passages:** the park, at 0.5 s RMS −15/−16 dBFS (352.0-353.0 s), against −22/−23 dBFS in idle and use.

**Spindle and tones**
- **Idle fundamental:** 60.0 Hz (rpm/60), prominence 47 dB. Harmonics 2-7 are weak (−38 to −56 dB re fundamental); the 8th (480 Hz) is −32 dB.
- **A separate tone comb, not locked to the spindle:** exact multiples of 213 Hz.
  - Members: 426, 639, 1065, 1491, 1704, 1916, 2130 and 2342 Hz.
  - 2130 Hz is the strongest tone above 1 kHz (−11 dB re 60 Hz, prominence 39 dB).
  - Partner lines spaced by 213 Hz: 2959/3172, 3598/3811 and 4069/4282 Hz. Further lines: 616.5 and 874 Hz.
  - 213 Hz = 3.55× rotation, so this comb is not a spindle harmonic.
- **No HF whine** was found above 4.3 kHz in idle.

**Power-up (first power-up, 0-25 s; the second repeats it)**
- **Spin-up.** Spindle fundamental tracked in 0.5 s blocks:

  | Time (s) | 1.5 | 4.0 | 7.0 | 8.5 | 11.5-12 | 14 |
  |---|---|---|---|---|---|---|
  | Hz | 19.3 | 42.1 | 60.6 | 64.6 (peak, +7.7%) | 58.0-58.7 | 60.1 |

  That is a near-linear ramp of about 7-8 Hz/s, about 7 s to nominal, and 14 s to settled. Second power-up: 26 Hz at 371 s, 60 Hz at 376 s, 64.4 Hz at 377 s, 58.7 Hz at 381 s, 60.1 Hz at 383 s.
  - Rising motor-tone harmonics fan upward during 0-8.7 s.
- **Impulse buzz (11.5-17.2 s and 380.36-386.1 s).** About 6 s of continuous impulses after the spindle reaches speed.
  - 383.0-386.1 s holds 544 impulses alternating 5.5 and 6.0 ms (5.75 ms mean, about 174/s).
  - The averaged spectrum shows 1407 Hz +18 dB over idle, plus 352, 1017, 1648, 1758 and 2276 Hz.
  - Level is +13-20 dB in 800-1700 Hz.
- **Recalibration rattle.**
  - First power-up (17.20-17.45 s, about 250 ms): 42 impulses, intervals p10/50/90 = 3.0/5.0/9.5 ms. Spectrum 1406 Hz (+33), 686 (+30), 1019 (+30), 579 (+29), 361 (+27).
  - Second power-up (386.11-386.29 s): 30 impulses, mostly 5.5-6.0 ms, +22.1 dB.
- **Quiet spell (17.45-19.9 s):** no impulses, apart from a 6.5 kHz tone between about 18.3 and 19.3 s.
- **Busy burst (19.9-25.1 s):** 23 gestures/s, IOI p10/50/90 = 19/40/72 ms, mostly single impulses at +8 to +17 dB. Possibly host boot reads; not identifiable.

**Power-down**
- **Spindle slowdown:**

  | Time (s) | 350.3 | 351.5 | 352.8 | 353.2 | 354 | 357 |
  |---|---|---|---|---|---|---|
  | Hz | 60.1 | 56.0 | 51.3 | 46.6 | 36.5 | 20 |

  It is near stop by about 358-360 s.
- **Stepping during the slowdown:**
  - Phase 1 (350.4-351.4 s): 156 impulses, median 5.0 ms (p10 3.5, p90 10.5 ms).
  - Phase 2 (351.45-352.85 s): louder. Impulses come in pairs about 4-6 ms apart, and the pairs repeat about every 22.5 ms (envelope modulation peak 42-45 Hz, falling slightly).
  - Phase 2 spectrum: 1372 Hz (+39), 1432 (+36), 571 (+36), 1402 (+35), 2708 (+33), 684 and 1552 (+31), 925-992 (+30).

### Inferences
- **What one impulse is.** 820 tracks in 95 ms (full stroke) needs roughly 9-10 kHz of track stepping. An impulse every 5.75 ms over 30-60 ms is only 6-10 impulses per seek. So each audible impulse cannot be one track.
  - The impulses are more likely a coarse mechanical cycle: motor full-step or phase cycle, or carriage/band rocking at about 174 Hz.
  - The same 5.5-6.0 ms period appears in seeks, the power-up buzz, the recalibration rattle and the park.
  - Whatever the mechanism, the audible structure is a fixed-rate impulse train, and its length grows in steps with seek distance.
- **Recipe for a stepper seek** (new preset fields are needed; DrivePreset has no step-train concept yet):
  - **Impulse count from seek time.** n = clamp(round(seekTime(d) / 6 ms), 1, 12). Datasheet timing (8/40/95 ms) gives 1-2 impulses for track-to-track, about 7 for average and 12 for full stroke. Measured classes cluster at 4, 6, 8 and 9.
  - **Interval schedule.** For n ≥ 5, take (n−3) × 5.5 ms, then 6.5, then 7.0 ms. For n ≥ 8, end with a slowing tail of 10.5 and 13.5 ms.
  - **Timing jitter:** ±0.5 ms.
  - **No ramp-up:** start at full rate.
  - **Impulse character:** a broadband strike, 1 ms or shorter, of equal force for the first 5 impulses, about −3 dB for the tail impulses. It excites the seek mode bank (0.9-1.43 kHz centred).
  - **Landing component:** at the end of the train, an optional late 0.5-0.57 kHz knock (−4 dB), 0-45 ms after the last impulse.
  - **Pitch:** the perceived buzz pitch is the impulse rate (about 174-182 Hz), dropping to about 70-95 Hz in the tail. It is a "brrrt" or "drrrt-t", not a kHz "fweep".
- **Single-track step:** one impulse that weights the 0.45-0.6 kHz modes (573/458 Hz at 0 dB, 922 Hz at −2.5) over the 1.4 kHz group (−5 dB). During sequential I/O, one step every about 300-350 ms. At 3600 rpm, 317 ms is 19 revolutions, consistent with a 6-head cylinder read at interleave about 3 (inference).
- **Power-up sequence for Whirr:**
  - spin-up ramp of about 7 s (motor tones rising),
  - an overshoot hump,
  - about 6 s of 174 Hz impulse buzz,
  - a recalibration rattle of 180-250 ms (30-42 impulses at about 5 ms),
  - a short silence,
  - then normal activity.
- **Power-down "head park":** about 2.4 s of stepping during spin-down, the loudest event in the recording, at about +6-7 dB in 0.5 s RMS. First about 1 s of impulses at about 5 ms, then paired impulses every about 22.5 ms.
- **Suggested preset** (dB re strongest mode; Q from single-step decays, capped 20-40):

```swift
// ST-277N-like 1987 stepper (3600 rpm, 5.25" HH): seek = 4-12 impulses at ~5.5 ms (decel tail 6.5, 7, 10.5, 13.5 ms),
// each ringing a 0.9-1.43 kHz cluster; single steps are darker (0.45-0.6 kHz).
rpm: 3600, trackToTrack: 0.008, average: 0.040, fullStroke: 0.095,   // datasheet (max values)
settle: 0.015,                // inference: tail + landing within ~10-45 ms of the last impulse
maxSeekRate: 20,              // 1 / (40 ms + 8.3 ms latency)
modes: [
    Mode(hz: 1_428, q: 30, db: 0),    Mode(hz: 1_385, q: 30, db: -1),
    Mode(hz: 918, q: 22, db: -3),     Mode(hz: 1_010, q: 38, db: -3),
    Mode(hz: 845, q: 30, db: -4),     Mode(hz: 1_304, q: 30, db: -4),
    Mode(hz: 1_077, q: 30, db: -5),   Mode(hz: 709, q: 25, db: -8),
    Mode(hz: 1_606, q: 30, db: -10),  Mode(hz: 343, q: 20, db: -11),
    Mode(hz: 573, q: 23, db: -6),     Mode(hz: 458, q: 30, db: -8),   // single-step "tok" pair: raise to 0/-1 dB for 1-impulse steps
],
lowPassHz: 6_000, highPassHz: 250,
thump: Thump(hz: 565, q: 23, db: -4, delay: 0.000...0.045)  // "landing" knock, timed from the LAST impulse (needs code change)
// new: stepIntervals core [0.0055, 0.0055, 0.0055, 0.0065, 0.0070], tail [0.0105, 0.0135]; impulse jitter ±0.0005
```

- Leave out the 213 Hz comb, which is likely the host or test bench. Also leave out the 12-15 kHz post-seek tone bursts, which are probably electronic and in any case above Whirr's 8 kHz default low-pass. If modelled at all, a 60 Hz idle tone is the only spindle cue.

### Gaps
- **Mechanism of the 5.5-6 ms impulse is not established.** Steps per track, step angle and the buffered-seek pulse table are not in the sources (see the earlier note's Gaps). The recording gives no access to the drive's commands, so seek distances are unknown. The mapping from distance to impulse count above is an inference from the datasheet seek times.
- **Tone bursts:** the source of the 12.05/12.9/14.9 kHz plus 2.7-2.8 kHz bursts (electronic or mechanical) and of the 213 Hz comb is unknown.
- **Q inside trains:** decay inside multi-impulse trains cannot be separated from re-excitation. The Q values come from single steps, whose fits stop early on a busy floor ("alt" fits from −3 to −12 dB).
- **Signal-to-bed:** single steps stand only +4-8 dB over the pre-onset level. Seeks and steps are weak against this recording's bed (seek window +3.2 dB broadband), so mic placement probably favoured the spindle.
- **Lossy preview:** the original was not used.

## 2. 2.5" laptop drives (Fujitsu MHV2200BT 4200 rpm, 143917; Toshiba MK5055GSX 5400 rpm, 143269): modes, tones, rhythm, and a test of laptop2005's "desktop × 1.3"

### Takeaway
- **Both drives write continuously.** There is no idle, and the 0.7-3 kHz spindle/air hiss fills that band throughout. Its 1 ms crest is 6-8 dB, which is noise-like.
- **Fujitsu seeks** are faint, very short high-frequency ticks:
  - Dominant mode 6.38 kHz, with 6.19 and 6.75 kHz partials and a 2.77-2.88 kHz pair.
  - Q≈40-80, −10 dB within about 5 ms.
  - +15.5 dB median in 3-16 kHz, but only +3.5 dB broadband.
  - About 5.5 gestures/s.
- **Toshiba:** no detectable seek events at all.
- **Spindle cues are strong:**
  - Fujitsu: 70.0 Hz fundamental, plus tones at 10×/12×/16×/48×/162× rotation.
  - Toshiba: 90.0 Hz, with 12× (1080 Hz) and 24× (2160 Hz) tones.
- **The laptop2005 assumption fails.** Desktop modes × 1.3 put the bank's strongest modes at 2.2-3.4 kHz, plus 1.3-1.45 kHz "weight". The measured laptop seek energy sits at 5-7 kHz, and nothing is event-locked below 2.7 kHz. Measured ratios:
  - about 1.4-1.7× the 3.5" desktop centres of 3.75-4.06 kHz,
  - about 2.3-2.8× laptop2005's strongest mode.

### Cited Findings
**Fujitsu MHV2200BT (143917, 50.8 s)** — own analysis of [143917](https://freesound.org/people/Klerrp/sounds/143917/)
- **Timeline.**
  - Spin-up: fundamental 53.2 Hz at 1.0 s, 69.3 at 1.5 s, 70.0 Hz from 1.75 s.
  - Head-load cluster 1.55-1.93 s.
  - Writing 2-43.4 s.
  - Unload clicks at 43.44 and 43.51 s, then spin-down 44-49.5 s.
- **Writing bed (4-43 s):**
  - Level −23.6 dBFS / −31.7 dBA.
  - Unweighted shares <300 Hz 85%, 300 Hz-1 kHz 7%, 1-5 kHz 8%, >5 kHz 0%. A-weighted 2/40/57/1%.
  - The 700-3000 Hz band holds a steady −32 dBFS (crest 6-8 dB) and fades with the spindle during spin-down (−32 at 44 s, −67 at 50 s). So it is spindle/air noise, not seek activity.
- **Tones** (dB re the 70 Hz line, prominence):

  | Hz | Rotation multiple | dB | Prominence |
  |---|---|---|---|
  | 70.0 | 1× | 0 | 48 dB |
  | 107.8 | — | −21 | — |
  | 90.0 | — | −26 | 24 dB |
  | 700 | 10× | −24 | 20 dB |
  | 840 | 12× | −20 | 13 dB |
  | 1122 | 16× | −29 | 12 dB |
  | 3360 | 48× | −46 | 10 dB |
  | 11339 | 162× | −42 | 21 dB |

  Spindle harmonics 2-8 are −51 to −66 dB.
- **Head-load event (1.770 s).**
  - 60 ms long; peaks 12 ms after onset.
  - +44.8 dB over the bed in 3-16 kHz; +24.9 dB in 300 Hz-16 kHz.
  - Octave rises: 2 kHz +19, 4 kHz +30, 8 kHz +43 dB.
  - Peaks: 9146 Hz (+51), 6312 (+50), 5666 (+49), 8166 (+49), 5378 (+48), 6829 (+45), 4474 (+43), 4245 (+39), 11009 (+40).
  - Second part (20-60 ms): 4791 Hz (+35), 8199 (+30), 5464 (+29), 7281 (+28), 2856 (+22).
- **Regular click train after load (3.025-3.737 s).**
  - 26 clicks, IOI p10/50/90 = 26/28/29.6 ms. At 4200 rpm one revolution is 14.29 ms, so 28 ms is 2 revolutions.
  - Each click is 9-12 ms long at +22-28 dB in 3-16 kHz; −10 dB about 9 ms after its peak.
  - Peaks: 6441 Hz (+32), 2867 (+27), 6164 (+26), 4915 (+24), 7195 (+24), 5416 (+23), 5809 (+22).
- **Seek ticks during writing.** 3-16 kHz detector, +10 dB over the 4-6.9 s bed (−54.1 dBFS in band), window 4.0-43.3 s, 3 ms merge.
  - 6.18 events/s; duration p10/50/90 = 1/4/7 ms; IOI 14/110/365 ms; peak +10.4/15.5/21.1 dB.
  - Gestures at 15 ms merge: 5.45/s, IOI 22/121/382 ms. At 50 ms merge: 3.87/s, IOI 99/180/494 ms.
  - Clusters of 2-5 ticks over 20-200 ms, for example 7.08-7.29, 8.13-8.21 and 8.90-9.01 s.
- **Seek tick mode list.** 81 isolated ticks (≥30 ms clear before, ≥80 ms after, ≥+14 dB). Columns: Hz | dB re max | over bed / over pre | peak delay | hold | −10 dB time | T60 → Q.

  | Hz | dB | Over bed / pre | Delay | Hold | −10 dB | T60 → Q |
  |---|---|---|---|---|---|---|
  | 6382 | 0 | +37 / +20 | 1 ms | 3 ms | 6 ms | 18-19 ms → 54 |
  | 2766 | −6.3 | +22 / +14 | 3 | 4 | 9 | 50-57 → 62-71 |
  | 6189 | −7.4 | +31 / +18 | — | 2 | 5 | 28 → 80 (standard fit 85 → 239) |
  | 6753 | −9.5 | +28 / +18 | — | 2 | 4 | 17-18 → 53-55 |
  | 2879 | −11.4 | — | — | 4 | 7 | 28-31 → 37-41 |
  | 5377 | −15.0 | — | — | 3 | 5 | 26 → 63 |
  | 5973 | −15.2 | — | — | 3 | 6 | 24 → 65 |
  | 11341 | −15.7 | weak over pre | — | — | — | unresolved |
  | 4807 | −16.2 | — | — | 3 | 7 | 27 → 58 |
  | 7105 | −16.5 | — | — | 2 | 5 | 25-26 → 82-85 |
  | 5710 | −17.6 | — | — | 3 | 6 | 29 → 76 |
  | 9284 | −17.8 | — | — | 2 | 7 | 42 → 178 |

  Nothing event-locked was found between 478 Hz and 2.08 kHz above −13.6 dB.
- **Band envelopes** (energy average of the 81 ticks):
  - 3-16 kHz: peak +19.1 dB over the bed at 0.5 ms, −10 dB 5 ms after the peak.
  - 5-8 kHz: peak +29.3 dB, −10 dB at 5 ms.
  - 2-3.5 kHz: peak +13.6 dB at 2 ms, about −9 dB at 5-6 ms before reaching the bed.
  - 300 Hz-16 kHz: only +3.5 dB over the bed.
  - Implied 3-16 kHz T60 is about 35 ms (slope about 1.7 dB/ms between −3 and −13 dB).
- **Band shares** (excess bins at least 3 dB over the bed):
  - Unweighted 0/5/43/52% (<300 Hz, 300 Hz-1 kHz, 1-5 kHz, >5 kHz); A-weighted 0/2/54/44%.
  - Octave rises (40 ms window): 4 kHz +1, 8 kHz +8, 12.5 kHz +4 dB.
- **Unload clicks.**
  - 43.443 s: 17 ms, +31.8 dB in 3-16 kHz. Peaks 6298 Hz (+39), 8161 (+38), 7222 (+37), 9195 (+37), 4775 (+34), 5410 and 5652 (+33).
  - 43.506 s: 46 ms, +33.9 dB. Peaks 8331 (+32), 7276 (+29), 5469 (+28), and in its 20-60 ms tail 8323 Hz (+49), 2770 (+35), 5561 (+35), 269 (+22).

**Toshiba MK5055GSX (143269, 36.6 s)** — own analysis of [143269](https://freesound.org/people/Klerrp/sounds/143269/)
- **Spin-up:** 62.1 Hz at 1.2 s, 78.9 at 1.75 s, 90.3 Hz from 2.25 s. Spin-down starts at about 34.6 s.
- **Writing bed (3-33.5 s):**
  - Level −24.1 dBFS / −24.1 dBA.
  - Unweighted shares 1/61/38/0%; A-weighted 0/57/43/0%.
  - A broad hump at 0.86-1.0 kHz; the 700-3000 Hz band is steady at −23 to −26 dBFS (crest 6-9 dB).
  - The 40-300 Hz band switches between about −36 to −40 dBFS (1.5-7, 18.5-25 and 29-34.5 s) and −55 to −69 dBFS. The cause is unknown, possibly handling or the rig.
- **Tones** (dB re strongest, prominence):

  | Hz | Rotation multiple | dB | Prominence |
  |---|---|---|---|
  | 1080 | 12× | 0 | 11 dB |
  | 90.0 | 1× | −2 | 34 dB |
  | 2160 | 24× | −13 | 15 dB |
  | 360 | 4× | −30 | 7 dB |

  Other harmonics are buried in the hump.
- **No seek events.**
  - 3-16 kHz at +10 dB over the median of the bed: 7 events in 36 s (0.19/s), peaks +10.2/11.3/16.0 dB.
  - 700-3000 Hz: 31 events at +10-11 dB, which is noise-level.
  - Whitened spectrograms (4-8 s against the 3-30 s median) show only low-frequency fluctuation. The drive appears to write sequentially, with no audible repositioning.
- **Unload (34.372 s):**
  - 14 ms long; +21.4 dB in 3-16 kHz; +9.7 dB in 300 Hz-16 kHz.
  - Peaks 8506 Hz (+39), 5666 (+26), 11310 (+22), 6420 (+21), 2840 (+20), 186 (+17).
  - Preceded by ticks at 34.18-34.34 s (+11 to +13 dB).

**3.5" reference frequencies used for the comparison**
- Whirr presets:
  - `quiet2010s` strongest mode 3752 Hz.
  - `desktop2005` cluster 1.73-3.0 kHz plus 5.47-6.25 kHz, strongest 1730 Hz.
  - `laptop2005` = `desktop2005` × 1.3 (capped at 8.4 kHz), so its strongest modes are 2249 (0 dB), 3419 (−1), 2847 (−3), 2554 (−5) and 3627 Hz (−6), with 1448/1288 Hz "weight" modes at −7/−10 dB.
  - Source: [SoundBank.swift](/Users/zihangqi/Workspace/Canister.Whirr/Sources/Whirr/SoundBank.swift)
- Measured 3.5" drives, from [measured_server_and_samsung_recordings.md](/Users/zihangqi/Workspace/Canister.Whirr/research_notes/HDD%20sound%20presets%20by%20drive%20type/measured_server_and_samsung_recordings.md):
  - SV1022D click 3.4-4.9 kHz, strongest 4064 Hz, Q 40-75.
  - T166 kHz modes 4.5-5.4 kHz (weak).
  - Atlas 10K 4.6-6.5 kHz, Allegro 15k 3.6 and 6.1 kHz.

### Inferences
- **Mode frequencies, the key test.**
  - The Fujitsu's strongest seek mode (6382 Hz) is 1.70× `quiet2010s` (3752), 1.57× SV1022D (4064), 2.8× `laptop2005`'s strongest (2249) and 3.7× `desktop2005`'s (1730).
  - The USB Toshiba's strongest kHz modes (5.1-5.7 kHz, section 3) are 1.36-1.51× `quiet2010s`.
  - Only the Fujitsu's secondary 2.77/2.88 kHz pair (−6/−11 dB) falls inside `laptop2005`'s scaled cluster.
  - There is no evidence for event-locked 1.29-1.45 kHz "weight" in the 2.5" drives.
  - A better rule than "× 1.3 of desktop2005" is: centre the bank at about 5-6.5 kHz (1.4-1.7× of a 3.5" desktop centre), keep a weak 2.8 kHz pair, and drop the sub-2 kHz modes. Any low-mid body belongs to the enclosure (chassis/desk path), not to the drive's own modes. This agrees with the existing note that small-drive airborne seeks are weak and mostly high ([small_form_factor.md](/Users/zihangqi/Workspace/Canister.Whirr/research_notes/HDD%20sound%20presets%20by%20drive%20type/small_form_factor.md)).
- **Damping.** Q≈40-85 (T60 17-57 ms) for the 2.5" seek tick sits between `desktop2005`'s Q 24-36 and the servers' 150-300. The ring is short: about −10 dB in 5 ms in 3-16 kHz.
- **Level.** In these close-up recordings, laptop seeks barely rise over the spindle hiss broadband: +3.5 dB for the Fujitsu, and nothing at all for the Toshiba while writing sequentially. A laptop preset should keep the idle bed (hiss plus spindle tones) relatively loud and the seek tick quiet. Whirr's `laptopOnDesk` enclosure would supply any thump.
- **Rhythm:** about 5.5 tick gestures/s, IOI p10/50/90 = 22/121/382 ms. With 50 ms merge, about 3.9/s with IOI p10/50/90 = 99/180/494 ms.
- **Spindle bed.** A 70/90 Hz fundamental and rotation-locked tones (10×/12×/16×/24×/48×) over a 0.7-3 kHz hiss hump. The hump centre is about 1-2 kHz for the Fujitsu and about 0.9-1.1 kHz for the Toshiba.
- **Suggested laptop preset:**

```swift
// 2.5" 4200-5400 rpm laptop (Fujitsu MHV2200BT seek tick): high, short 6.2-6.8 kHz tick with a weak 2.8 kHz pair.
modes: [
    Mode(hz: 6_380, q: 55, db: 0),     Mode(hz: 6_190, q: 80, db: -7),
    Mode(hz: 2_766, q: 65, db: -6),    Mode(hz: 6_750, q: 55, db: -10),
    Mode(hz: 2_879, q: 40, db: -11),   Mode(hz: 5_380, q: 65, db: -15),
    Mode(hz: 5_970, q: 65, db: -15),   Mode(hz: 4_810, q: 60, db: -16),
    Mode(hz: 7_105, q: 80, db: -16),   Mode(hz: 9_280, q: 150, db: -18),
],
lowPassHz: 12_000,   // the tick lives at 5-9 kHz; 9.5 kHz would shave the 9.3 kHz partial
thump: nil           // chassis path (Enclosure.laptopOnDesk) supplies any low end
// idle bed: 70 Hz (4200 rpm) or 90 Hz (5400 rpm) fundamental + 12x/24x rotation tones + 0.7-3 kHz hiss hump
```

### Gaps
- **Only one of the two laptop recordings contains seeks.** Two drives is a thin basis for a class rule. The USB Toshiba (section 3, contact mic) supports the 5-5.7 kHz placement but cannot test airborne levels.
- **No true idle exists for either laptop**, so "over idle" means over the writing bed. The measured seek level is a lower bound on prominence in a quiet room.
- **The Fujitsu click modes might partly reflect the close-up mic's response** or the drive's top cover, not the actuator alone.
- **Datasheet timing for these models was not checked in this pass.** Seek timing fields should come from [small_form_factor.md](/Users/zihangqi/Workspace/Canister.Whirr/research_notes/HDD%20sound%20presets%20by%20drive%20type/small_form_factor.md) (12-15 ms average for 4200/5400 rpm).
- **Unexplained sources:** the 90 Hz and 107.8 Hz lines in the Fujitsu (a 4200 rpm drive) and the Toshiba's switching 40-300 Hz band.

## 3. USB portable (Toshiba MQ01UBD100, 401271, contact mic): seek character and the emergency-park click

### Takeaway
- **Seeks through the contact mic** are weak, about +12 dB in 150-700 Hz, and two-part:
  - a structure-borne 314-390 Hz knock (Q≈22-40, T60 120-280 ms),
  - a 5.1-5.7 kHz tick (hold about 3 ms).
  - About 3.3 gestures/s.
- **The unplug emergency park** is a single violent event: about 50 ms, +42 dB broadband over the bed, which is about 27-30 dB above typical seeks.
  - It clipped the recording, so the true level is higher.
  - Its spectrum is dominated by 9-11.3 kHz and 6.5-9 kHz, with a 1.87 kHz component.
  - It holds within 2 dB of its peak for about 12 ms and falls to −20 dB by about 40 ms.
  - About 75 ms after its onset come a 3.16 kHz braking tone with harmonics and the spindle run-down.

### Cited Findings
All findings in this section are my own analysis of [401271](https://freesound.org/people/eardeer/sounds/401271/).
- **Timeline.**
  - Spin-up: 28.6 Hz at 1.0 s, 47.4 at 1.5 s, 62.7 at 2.0 s, 84.8 at 3.0 s, overshoot 91.2 Hz at 3.5 s, 90.0 Hz from 3.75 s.
  - Steady spinning and sparse activity 3.5-53.2 s.
  - Emergency park at 53.245 s, then spin-down to about 61 s.
- **Bed (5-52 s):**
  - Level −32.5 dBFS / −42.0 dBA.
  - Unweighted shares 90/2/7/0%; A-weighted 7/14/76/3%.
- **Bed tones** (dB re 90 Hz, prominence):

  | Hz | Rotation multiple | dB | Prominence |
  |---|---|---|---|
  | 90.0 | 1× | 0 | 48 dB |
  | 1080 | 12× | −21 | 26 dB |
  | 900 | 10× | −25 | 19 dB |
  | 44.8 | 0.5× | −33 | 12 dB |
  | 720 | 8× | −34 | 11 dB |
  | 2160 | 24× | −34 | 17 dB |
  | 3240 | 36× | −34 | 22 dB |
  | 2520 | 28× | −37 | 15 dB |

- **Seek activity (3.5-52.8 s).**
  - 150-700 Hz detector (+10 dB over the 30-50 s bed): 221 events (4.48/s at 3 ms merge); 161 gestures at 15 ms merge (3.27/s), IOI p10/50/90 = 22/104/652 ms; duration 1/4/17 ms; peak +10.3/11.9/14.2 dB.
  - 3-16 kHz detector: 2.03 events/s, peak +10.5/12.0/16.3 dB.
  - 300 Hz-16 kHz detector: seeks peak +10.5/11.5/15.0 dB.
  - Whitened spectrograms also show steady 7.8-11 kHz tones during activity bursts. Their origin is unknown, possibly electronic.
- **Seek mode list.** 29 isolated events (Hz | dB re max | delay | hold | T60 → Q):

  | Hz | dB | Delay | Hold | T60 → Q |
  |---|---|---|---|---|
  | 390 | 0 | 2 ms | 7 ms | 123-159 ms → 22-28 |
  | 314 | −0.9 | 2 | 7 | 195-277 → 28-40 |
  | 5117 | −1.6 | 2 | 3 | unresolved |
  | 5416 | −2.8 | 2 | 3 | unresolved |
  | 509 | −3.9 | 12 | 14 | — |
  | 5657 | −5.0 | 3 | 3 | 78 → 200 (low confidence) |
  | 221 | −5.7 | 4 | 10 | 309 → 31 (alt) |
  | 3961 | −7.9 | — | — | — |
  | 4311 | −9.1 | — | — | — |
  | 5835 | −9.5 | — | — | — |
  | 6212 | −9.7 | — | — | — |
  | 7717 | −9.7 | — | — | fits fail (steady tones) |
  | 164 | −9.8 | — | — | 119 → 9 (alt) |
  | 7399 | −12.2 | — | — | fits fail (steady tones) |

  - Band shares (excess bins at least 3 dB over the bed): unweighted 16/68/4/12%; A-weighted 3/68/8/21%.
  - Octave rises (40 ms window): 250 Hz +8, 8 kHz +4, 12.5 kHz +4 dB.
- **Emergency park click (onset 53.245 s).**
  - **Clipping:** the sample peak reaches 0 dBFS, with 4 samples at or above 0.99 full scale.
  - **Duration:** 52 ms in the 300 Hz-16 kHz detector.
  - **Band peaks over the bed median:** 300 Hz-16 kHz +42.1 dB; 300 Hz-1 kHz +40.7; 1-3 kHz +44.4; 3-8 kHz +47.2; 8-16 kHz +66.1.
  - **Envelope (300 Hz-16 kHz):**

    | Time after onset | Level re peak |
    |---|---|
    | about 3 ms | rising |
    | about 9-21 ms | within 2 dB of peak |
    | 25 ms | −13 dB |
    | 30-45 ms | −16 to −21 dB |
    | after about 50 ms | −28 to −39 dB |

  - **Spectrum, 0-25 ms** (dB over bed): 10750 and 11308 Hz (+66), 9480 (+63), 11951 (+63), 10314 (+61), 9001 (+58), 7154 (+57), 7607 (+56), 8148 (+55), 1865 (+54), 6533 (+54), 5674 and 6826 (+51).
  - **Spectrum, 25-50 ms:** 10126 (+51), 10750 and 11480 (+48), 8931 (+46), 5825/6796/7585 (+42), 3149 (+36).
  - **Octave rises, 0-25 ms:** 250 Hz +34, 500 Hz +25, 1 kHz +27, 2 kHz +42, 4 kHz +39, 8 kHz +50 dB.
  - **Band shares** (masked excess, 0-50 ms): unweighted 1/9/83/7%; A-weighted 0/6/89/5%. In absolute power the 1-5 kHz region carries the energy; the 8-16 kHz rise is huge only because the contact-mic bed is nearly empty there.
- **After the park.**
  - From 53.32 s a steady tone sits at 3163 Hz (+44 dB), with harmonics 6323 (+30) and 9477 Hz (+18) plus 180 Hz (+28), lasting at least 256 ms (80-200 ms window).
  - The spindle lines sweep down over about 5-8 s.

### Inferences
- **For a "head park" sound** (unplug, sleep, or emergency retract):
  - a 50 ms burst roughly 25-30 dB above a typical seek tick,
  - a fast attack (3 ms or less), a 10-15 ms plateau, then about 1 dB/ms decay to −20 dB at about 40 ms,
  - energy spread over 1.8-12 kHz, peaking at 9-11 kHz and 6.5-9 kHz, with a 1.87 kHz body,
  - optionally followed about 75 ms later by a 3.16 kHz braking tone (with 2× and 3× harmonics) and a spindle run-down.
- **Contact mic versus air.** Because this is a contact mic, the 9-11 kHz dominance and the +66 dB figure overstate what air carries. The ramp-unload clicks of the airborne Fujitsu (4.5-9.2 kHz, +32 to +45 dB in 3-16 kHz) and Toshiba (8.5 kHz, +21 dB) are a safer level and spectrum template for a normal, non-emergency park.
- **USB seek template:** a 0.31-0.39 kHz knock (Q≈25-35) plus a 5.1-5.7 kHz tick. The knock is the enclosure/desk path, which supports modelling 2.5" low end through the enclosure, not the drive's mode bank.
- **Suggested park voice** (a separate one-shot, not a seek):

```swift
// Emergency head park (USB 2.5", contact mic; clipped, so level is a lower bound): ~+27-30 dB over a seek tick.
parkModes: [ Mode(hz: 10_750, q: 200, db: 0),  Mode(hz: 11_300, q: 200, db: 0),
             Mode(hz: 9_480, q: 180, db: -3),  Mode(hz: 9_000, q: 160, db: -8),
             Mode(hz: 7_150, q: 130, db: -9),  Mode(hz: 8_150, q: 150, db: -11),
             Mode(hz: 1_865, q: 50, db: -12),  Mode(hz: 6_530, q: 120, db: -12) ],
// excitation: 12-15 ms noise burst (plateau), then free ring; optional braking tone 3_163 Hz (+2x, 3x) from +75 ms for ~250 ms
// Q values are not fitted (single, clipped event). They are inferred from the average post-plateau decay of ~1 dB/ms
// in the 8-16 kHz and 1-3 kHz bands (T60 ≈ 55-60 ms -> Q ≈ 250 at 10.7 kHz, ≈ 50 at 1.87 kHz), reduced because part
// of that tail is rattle (re-strikes), not free ring.
```

### Gaps
- **Single park event:** only one park was recorded, and it is clipped. No decay-derived Q could be fitted, and the true peak level is unknown.
- **Contact-mic coloration:** the coupling point is unknown, so the relative weighting of LF knock and HF tick is unreliable for airborne synthesis.
- **Seek decays:** HF Q fits failed because of steady 7-11 kHz tones in the activity passages. The kHz Q of USB seeks is unresolved.
- **Origin of the 3.16 kHz post-park tone** (spindle braking drive or other electronics) is not established.

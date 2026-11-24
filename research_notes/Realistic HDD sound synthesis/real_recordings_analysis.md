# Real HDD recordings: measured acoustic targets for seek/idle synthesis

Method note (applies to every "own analysis" item below): 18 openly licensed recordings (5 Wikimedia Commons, 13 Freesound) were downloaded (no login) into `research_notes/Realistic HDD sound synthesis/recordings/`, converted to mono 16-bit WAV with ffmpeg/afconvert, and analysed with numpy (Welch spectra, 1 ms and 0.25 ms RMS envelopes, onset detection at +10 to +15 dB over the background envelope, "event minus idle" excess spectra, band-limited envelopes for 150-400 Hz / 400-1000 Hz / 1-5 kHz / 5-16 kHz, A-weighted band shares). Analysis scripts are in the session scratchpad (`.../scratchpad/scripts/hdd_analyze.py`, `hdd_excess.py`, `hdd_detail.py`, `hdd_batch.py`, `hdd_bandenv.py`). Caveats that apply to all measured numbers: all sources are lossy (Vorbis or ~128 kbps MP3 previews), microphones/distances/mounting are undocumented, one file is band-limited to 5.5 kHz, and "events" are detected algorithmically, so durations/rates depend on threshold. Treat numbers as ranges across drives, not as a single drive's specification.

## 1. Openly licensed reference recordings (provenance + license)

### Takeaway
A CC0 Freesound pack by user Klerrp ("Old HDDs", 13 close-up recordings of drives from 1993-2012 with model numbers, manufacture years and rpm) is the best usable reference set; Wikimedia Commons adds a CC BY-SA healthy-seek recording of a Seagate 7200.8-era drive, a CC BY 4.0 modern spin-up/spin-down, and CC0/PD failure sounds. All were downloadable without login.

### Cited Findings
Downloaded and analysed (local folder `recordings/`):
- **Seagate ST3250823A "Kopfgeräusche" (head noises)**, 250 GB IDE, recorded 2007-03-28 by MOS6502; CC BY-SA 3.0; 19.2 s, mono, 11.025 kHz Vorbis ~35 kbps (so nothing above 5.5 kHz is usable). Local: `commons_Seagate_ST3250823A_Kopfgeraeusche.{ogg,wav}` — [Commons](https://commons.wikimedia.org/wiki/File:Seagate_ST3250823A_Kopfger%C3%A4usche.ogg)
- **WD102AA "Scratched area read retries"** (old WD Caviar 10 GB-class drive reading bad sectors), uploaded 2013-04-05 by AlepouTheFox; CC0; 16.6 s, 24 kHz Vorbis. Local: `commons_WD102AA_scratched_area_read_retries.*` — [Commons](https://commons.wikimedia.org/wiki/File:WD102AA_Scratched_area_read_retries.ogg)
- **"WD bad heads click of death"**, 2008-10-26 by Zzptichka; Public domain; 43.8 s, 22.05 kHz. Local: `commons_WD_bad_heads_click_of_death.*` — [Commons](https://commons.wikimedia.org/wiki/File:WD_bad_heads_click_of_death.ogg)
- **"Sound of defective IBM Deskstar"**, recorded 2007-11-24 by Malenki; CC BY-SA 3.0; 68 s, 44.1 kHz stereo Vorbis 256 kbps (exact Deskstar model not stated). Local: `commons_IBM_Deskstar_defective.*` — [Commons](https://commons.wikimedia.org/wiki/File:Sound_of_defective_IBM_Deskstar.ogg)
- **"TOSHIBA HDWR480 spinup and spindown sounds"**, recorded 2021-12-25 by TheDragonFire300; CC BY 4.0; original WAV is 11.4 MB, so only the first 8 MB (41.7 s of 48 kHz stereo) was fetched via HTTP range request and converted to mono. Local: `commons_TOSHIBA_HDWR480_first8MB_mono.wav` — [Commons](https://commons.wikimedia.org/wiki/File:TOSHIBA_HDWR480_spinup_and_spindown_sounds.wav)
- **Freesound pack "Old HDDs" by Klerrp, all CC0**, each described as a close-up recording of spin-up, writing or seek test, then spin-down. Freesound needs login for originals, so the public "hq" MP3 previews were downloaded (local folder `recordings/freesound_Klerrp_OldHDDs_CC0/<id>.{mp3,wav}`) — [pack](https://freesound.org/people/Klerrp/packs/8850/):
  - 155882 Conner CFS420A, 1993, 3600 rpm, ball bearing, "seek test" — [link](https://freesound.org/people/Klerrp/sounds/155882/)
  - 166638 Fujitsu Picobird 15 MPF3102AT, 2000, 5400 rpm FDB, writing — [link](https://freesound.org/people/Klerrp/sounds/166638/)
  - 167420 Samsung Voyager SV1022D, 2000, 5400 rpm ball bearing, writing — [link](https://freesound.org/people/Klerrp/sounds/167420/)
  - 182365 Samsung V40 SV4002H, 2001, 5400 rpm BB, spin-up/down only — [link](https://freesound.org/people/Klerrp/sounds/182365/)
  - 166898 WD1600JD, 2005, 7200 rpm, writing — [link](https://freesound.org/people/Klerrp/sounds/166898/)
  - 167422 Maxtor DiamondMax 10 6B160M0, 2005, 7200 rpm, writing — [link](https://freesound.org/people/Klerrp/sounds/167422/)
  - 182363 Hitachi Deskstar T7K500, 2006, 7200 rpm, spin-up/down — [link](https://freesound.org/people/Klerrp/sounds/182363/)
  - 182366 Maxtor Atlas 10K V, 2006, 10000 rpm server — [link](https://freesound.org/people/Klerrp/sounds/182366/)
  - 167421 Samsung T166 HD501LJ, 2007, 7200 rpm, 3 platters, writing — [link](https://freesound.org/people/Klerrp/sounds/167421/)
  - 182364 Fujitsu Allegro 10LX MBA3300RC, 2008, 15000 rpm server, writing — [link](https://freesound.org/people/Klerrp/sounds/182364/)
  - 166639 WD Green WD30EZRX, 2012, 5400-class, 4 platters, writing — [link](https://freesound.org/people/Klerrp/sounds/166639/)
  - 166641 Seagate Barracuda 7200.14 ST3000DM001, 2012, writing — [link](https://freesound.org/people/Klerrp/sounds/166641/)
  - 173856 Hitachi Deskstar 5K3000, 2012, spin-up/down — [link](https://freesound.org/people/Klerrp/sounds/173856/)
- Other CC0 Freesound item found but not downloaded: EzoGaming 613791, a DVD drive recording with occasional rumble from a 2 TB 7200 rpm drive (mixed source) — [Freesound search, CC0 filter](https://freesound.org/search/?q=hard+drive+seek&f=license:%22Creative+Commons+0%22)
- Also on Commons but not analysed: an IBM computer room disk drive switching on and off, CC BY-SA 3.0, from Beeld en Geluid — [Commons](https://commons.wikimedia.org/wiki/File:Het_in-_en_uitschakelen_van_een_disk_drive_-_SoundCloud_-_Beeld_en_Geluid.ogg)
- Not openly licensed or license not shown: the Mixcloud "Seagate hard disk boot-up" (Cities and Memory) — [Mixcloud](https://www.mixcloud.com/citiesandmemory/seagate-hard-disk-boot-up/); Duke "Sonic Dictionary" computer hard drive item — [Duke](https://sonicdictionary.duke.edu/items/computer-hard-drive.html); commercial libraries (Epidemic, AudioJungle, Soundstripe) appeared in results but are not open — [Epidemic](https://www.epidemicsound.com/sound-effects/categories/computers/hard-drive).

### Inferences
- For a "classic" target, the best clean healthy-seek references are Conner CFS420A (1993), Fujitsu MPF3102AT and Samsung SV1022D (2000), Maxtor 6B160M0 and WD1600JD (2005), Samsung HD501LJ (2007), and the Seagate ST3250823A Commons clip (about 2005-2007). The IBM Deskstar, WD click-of-death and WD102AA clips are failure modes (retries, head slaps). They help with timbre but not with normal rhythm.
- Licensing for shipping derived assets: CC0 and PD files can be used freely. CC BY 4.0 needs attribution. CC BY-SA 3.0 files (Seagate ST3250823A, IBM Deskstar) are fine as analysis references, but bundling them or derivatives would need share-alike handling.

### Gaps
- BBC Sound Effects (RemArc), archive.org and Sonniss GDC bundles were not checked within the tool budget. BBC RemArc is non-commercial anyway.
- No recording in the set is documented as "inside a desktop case". All Klerrp recordings say only "close up". Mounting and mic are unknown.
- I did not download the Freesound originals (login required). Previews are lossy MP3.

## 2. Measured acoustic targets from real recordings (own analysis)

### Takeaway
Real seek events are drive-specific clusters of narrow resonances (Q roughly 15-35 for kHz peaks) mostly in 0.9-6 kHz. They have an instantaneous attack, a fast ~10 dB drop within 3-7 ms, then a lower tail lasting 20-40 ms. Many older desktop drives (1993-2007) also add a delayed, low-Q 190-300 Hz "thunk" that peaks 6-14 ms after the click. A-weighted, the 1-5 kHz click still dominates in most drives. Activity plays as 9-19 events/s with heavy-tailed gaps (median 20-40 ms). The average level rises only 2-7 dB over idle, while individual peaks stand 12-18 dB above the idle envelope.

### Cited Findings
**Spindle/idle (sanity check of the method)**
- Idle spectral peaks sit at rpm/60 in every drive with a clean idle passage: 60 Hz for the Conner at 3600 rpm ([155882](https://freesound.org/people/Klerrp/sounds/155882/)); 90 Hz for the 5400 rpm Fujitsu, WD Green and Samsung drives ([166638](https://freesound.org/people/Klerrp/sounds/166638/), [166639](https://freesound.org/people/Klerrp/sounds/166639/), [167420](https://freesound.org/people/Klerrp/sounds/167420/)); 120 Hz for the 7200 rpm Seagate 7200.14, WD JD, Samsung T166, Maxtor DM10 and Hitachi T7K500 ([166641](https://freesound.org/people/Klerrp/sounds/166641/), [166898](https://freesound.org/people/Klerrp/sounds/166898/), [167421](https://freesound.org/people/Klerrp/sounds/167421/), [167422](https://freesound.org/people/Klerrp/sounds/167422/), [182363](https://freesound.org/people/Klerrp/sounds/182363/)); 166 Hz for the 10k rpm Maxtor Atlas ([182366](https://freesound.org/people/Klerrp/sounds/182366/)). This matches the published rule that idle tone = RPM/60 ([DiskFiltration, arXiv 1608.03431](https://arxiv.org/pdf/1608.03431), via search summary).
- Idle also carries drive-specific whine tones, for example the Conner at 3466, 1080 and 2004 Hz, within 4 dB of each other ([155882](https://freesound.org/people/Klerrp/sounds/155882/)), and the Samsung T166 at 120 Hz with harmonics at 241 Hz (-11 dB) and 482 Hz (-21 dB) ([167421](https://freesound.org/people/Klerrp/sounds/167421/)).
- Toshiba HDWR480 (modern 7200 rpm): steady spin is about 12 dB above the room floor (-46 vs -58 dBFS in this recording). Idle energy is 75-90% below 300 Hz, with 120 Hz dominant and 360 Hz at -13 to -16 dB. Spin-up goes from floor to steady level in about 1.5 s, and the fundamental is still at 107 Hz about 1.5 s into spin-up. Spin-down returns to within about 2 dB of the floor in about 2.5 s. One isolated transient at about 31 s stands +10 dB over spin and may be a head unload (inference) ([Commons Toshiba](https://commons.wikimedia.org/wiki/File:TOSHIBA_HDWR480_spinup_and_spindown_sounds.wav)).

**Seek-event spectra (event-minus-idle "excess")**
- Seagate ST3250823A (healthy random access): 98.7% of the excess energy falls in 1-5 kHz, with 0.2% below 300 Hz. The centroid is 2.77 kHz. The main peak is 2.63 kHz, with -3 dB bandwidth 136 Hz (Q≈19) and -10 dB edges at 2.42-3.04 kHz. Further peaks sit at 2.79, 2.22, 3.01, 3.64 and 2.02 kHz, within -4.6 to -11 dB. In 1/3-octaves, loud frames exceed quiet frames by +19 dB at 2.5 kHz and +14 dB at 4 kHz, but only +2 to +5 dB in every band at or below 1.6 kHz ([Commons Seagate](https://commons.wikimedia.org/wiki/File:Seagate_ST3250823A_Kopfger%C3%A4usche.ogg)).
- WD1600JD (2005): excess peaks at 1114, 2191, 5712, 2740, 5469, 1297 and 6250 Hz all fall within 6 dB of each other, a broad multi-modal band from 1 to 6.5 kHz. Octave rise over idle is +12 dB at 1k, +9 at 2k, +14 at 4k, +10 at 8k, and only +3 at 250 Hz. A-weighted shares: 70% in 1-5 kHz, 28% above 5 kHz ([166898](https://freesound.org/people/Klerrp/sounds/166898/)).
- Maxtor DiamondMax 10 6B160M0 (2005): excess peaks at 1728 Hz (0 dB), 291 Hz (-5), 991 and 1965 Hz (-8), and 3607 Hz (-9). The 2k and 4k octaves rise +25 dB over idle, the 250 Hz octave +15 dB. 86% of A-weighted excess is in 1-5 kHz ([167422](https://freesound.org/people/Klerrp/sounds/167422/)).
- Fujitsu MPF3102AT (2000): excess peaks at 888, 1378 and 2659 Hz. The 1 kHz octave rises +22 dB over idle and the 2 kHz octave +14 dB. A-weighted: 41% in 300-1k, 57% in 1-5k ([166638](https://freesound.org/people/Klerrp/sounds/166638/)).
- Conner CFS420A (1993, the oldest drive): the largest excess peak is at 264 Hz, followed by 1.89 kHz (-9 dB), 764 Hz (-10) and 2.72 kHz (-12). Octave rise over idle is +24 dB at 250 Hz and +17 at 125 Hz, against only +6 to +8 dB at 1-2 kHz. Unweighted, 52-60% of excess energy is below 300 Hz. A-weighted, the split is 19% below 300, 18% in 300-1k and 58% in 1-5k ([155882](https://freesound.org/people/Klerrp/sounds/155882/)).
- Samsung SV1022D (2000, ball bearing): excess peaks at 194, 458 and 678 Hz. Octave rise is +22 dB at 250 Hz and +12 at 500 Hz. Centroid is 735 Hz, and 78% of A-weighted excess is in 300-1k ([167420](https://freesound.org/people/Klerrp/sounds/167420/)).
- Samsung HD501LJ T166 (2007): excess peaks at 215 Hz, 382 Hz (-9 dB) and 1653 Hz (-18). Octave rise is +24 dB at 250, +16 at 500, +14 at 2k and +12 at 4k. Unweighted 80-84% below 300 Hz. A-weighted: 41% below 300, 22% in 300-1k, 33% in 1-5k ([167421](https://freesound.org/people/Klerrp/sounds/167421/)).
- WD102AA (old Caviar, read retries): excess peaks at 278 Hz (0 dB), 1096 Hz (-8), 706 Hz (-10.5) and 2098 Hz (-11). The 281 Hz peak has Q≈5, 1094 Hz Q≈16 and 2098 Hz Q≈36. In 1/3-octaves, loud frames exceed quiet ones by +19 dB at 250 Hz and +14-15 dB at 1-1.6 kHz, but only +3 dB at 2.5-4 kHz. A-weighted: 12% below 300, 18% in 300-1k, 70% in 1-5k ([Commons WD102AA](https://commons.wikimedia.org/wiki/File:WD102AA_Scratched_area_read_retries.ogg)).
- 2012 drives have almost no low end. WD30EZRX: excess 79% in 1-5k and 20% above 5k, main peak 3752 Hz (second 6067 Hz at -11). The 4k octave rises +18 dB and 8k +15, while ≤2k rises only 0-3 dB. ST3000DM001: few seeks, main peak 3.93 kHz, 4k octave +19 dB ([166639](https://freesound.org/people/Klerrp/sounds/166639/), [166641](https://freesound.org/people/Klerrp/sounds/166641/)).
- Maxtor Atlas 10K V (10k rpm server): excess peaks at 140, 2035, 393, 6551, 1270 and 996 Hz, all within 5 dB. Octave rises of +10 to +20 dB from 63 Hz to 8 kHz. A-weighted: 54% in 1-5k, 41% above 5k ([182366](https://freesound.org/people/Klerrp/sounds/182366/)).
- IBM Deskstar (defective): very narrow excess peaks at 5615 Hz (Q≈99) and 4527 Hz (Q≈72), plus 5.3, 5.8 and 2.4 kHz and a 291 Hz component (-12 dB, Q≈3.7). The 6.3 kHz 1/3-octave rises +20 dB over quiet frames ([Commons Deskstar](https://commons.wikimedia.org/wiki/File:Sound_of_defective_IBM_Deskstar.ogg)).
- WD "click of death" (head slap, not a seek): a single ringing mode at 1.125 kHz, -3 dB bandwidth 51 Hz (Q≈22), -10 dB edges 1052-1279 Hz, holding 92% of excess energy in 1-5 kHz. The ring is long: the 1-5 kHz band is only about 9 dB down 40 ms after the hit, and ring-down T60 is about 130-220 ms. The clicks repeat every 510 ms ([Commons WD click](https://commons.wikimedia.org/wiki/File:WD_bad_heads_click_of_death.ogg)).

**Envelope/attack/decay**
- Attack: the 1-5 kHz and 5-16 kHz bands peak 0-4 ms after the detected onset in every drive with clean isolated events (1 ms frames). In practice the attack is instantaneous ([155882](https://freesound.org/people/Klerrp/sounds/155882/), [166638](https://freesound.org/people/Klerrp/sounds/166638/), [167421](https://freesound.org/people/Klerrp/sounds/167421/), [167422](https://freesound.org/people/Klerrp/sounds/167422/), [Commons Seagate](https://commons.wikimedia.org/wiki/File:Seagate_ST3250823A_Kopfger%C3%A4usche.ogg)).
- Two-stage HF decay. The first 10 dB drop takes 3-7 ms (Conner 7 ms, Fujitsu 3 ms, Samsung T166 4 ms, WD Green 5-16k band 3 ms, WD JD 5-16k band 3 ms). The 1-5 kHz band then sits on a tail at -9 to -16 dB from the peak for the rest of the 30 ms window (Conner -13 to -15, Fujitsu -9 to -12, Samsung T166 -11 to -16) ([155882](https://freesound.org/people/Klerrp/sounds/155882/), [166638](https://freesound.org/people/Klerrp/sounds/166638/), [167421](https://freesound.org/people/Klerrp/sounds/167421/)).
- Louder or "grindier" drives decay more slowly. The 1-5 kHz band reaches -10 dB after 18 ms (Maxtor DM10, WD JD), 21 ms (WD Green) and 43 ms (Maxtor Atlas). Maxtor DM10 reaches -20 dB after 40 ms ([167422](https://freesound.org/people/Klerrp/sounds/167422/), [166898](https://freesound.org/people/Klerrp/sounds/166898/), [166639](https://freesound.org/people/Klerrp/sounds/166639/), [182366](https://freesound.org/people/Klerrp/sounds/182366/)).
- The low-frequency thump is delayed and slower. The 150-400 Hz band peaks 7 ms after onset in the Conner (-10 dB at 11 ms, -20 dB at 15 ms), 6 ms in the Maxtor DM10 (-10 dB at 28 ms), and 14 ms in the Samsung T166 (still within 4 dB at 30 ms) ([155882](https://freesound.org/people/Klerrp/sounds/155882/), [167422](https://freesound.org/people/Klerrp/sounds/167422/), [167421](https://freesound.org/people/Klerrp/sounds/167421/)).
- Extrapolated T60 of broadband (300 Hz+) events, as medians: 25 ms (Fujitsu 2000), 23-28 ms (WD JD), 29 ms (Samsung SV1022D), 24 ms (Maxtor DM10), 38-40 ms (Conner), 49 ms (Seagate ST3250823A), 112-116 ms (Samsung T166 and Maxtor Atlas). The 10th-90th percentile range across drives runs from about 11 to 240 ms ([Klerrp pack](https://freesound.org/people/Klerrp/packs/8850/), [Commons Seagate](https://commons.wikimedia.org/wiki/File:Seagate_ST3250823A_Kopfger%C3%A4usche.ogg)).
- Multi-burst seeks. In the Seagate ST3250823A, the strongest events at 0.25 ms resolution show a first burst, then a second burst of similar level (-2 to -5 dB) 14-17 ms later, with a -10 to -17 dB "hiss" bed between them. Merging gaps up to 15 ms gives "seek units" of median 12 ms (p90 41 ms) ([Commons Seagate](https://commons.wikimedia.org/wiki/File:Seagate_ST3250823A_Kopfger%C3%A4usche.ogg)).
- Duration of individual above-threshold bursts (>12 dB over the idle envelope, 300 Hz+, 1 ms frames): median 1-6 ms in all drives (p90 3-17 ms). Exception: Samsung T166, median 15 ms and p90 45 ms ([Klerrp pack](https://freesound.org/people/Klerrp/packs/8850/)).

**Rhythm**
- Conner "seek test": perfectly periodic events, inter-onset interval 58 ms in 10th-90th percentile terms (58-60 ms, about 17/s) ([155882](https://freesound.org/people/Klerrp/sounds/155882/)).
- "Writing" passages: 11-19 events/s inside active blocks, with heavy-tailed inter-onset intervals. Fujitsu: median 32 ms (p10 16, p90 82). WD JD: 33 ms (6/144). Samsung SV1022D: 39 ms (10/119). Samsung T166: 34 ms (8/199). Maxtor Atlas: 20 ms (8/86) ([166638](https://freesound.org/people/Klerrp/sounds/166638/), [166898](https://freesound.org/people/Klerrp/sounds/166898/), [167420](https://freesound.org/people/Klerrp/sounds/167420/), [167421](https://freesound.org/people/Klerrp/sounds/167421/), [182366](https://freesound.org/people/Klerrp/sounds/182366/)).
- Seagate ST3250823A random-access "crunch": with fine detection (+10 dB, 2 ms merge), 43 bursts/s and median inter-onset 15 ms (p10 5, p90 45). With coarse detection (+15 dB, 15 ms merge), 12.9 seek units/s and median 54 ms (p10 26, p90 145) ([Commons Seagate](https://commons.wikimedia.org/wiki/File:Seagate_ST3250823A_Kopfger%C3%A4usche.ogg)).
- WD102AA read retries: about 16 events/s, median interval 16 ms (p10 12, p90 25), more regular than normal seeking ([Commons WD102AA](https://commons.wikimedia.org/wiki/File:WD102AA_Scratched_area_read_retries.ogg)).

**Levels (seek vs idle)**
- Peak of each event over the idle-envelope median (1 ms frames): median 13-16 dB in every analysed drive, p90 15-26 dB ([Klerrp pack](https://freesound.org/people/Klerrp/packs/8850/)).
- A 20 ms event window against the 20 ms before it: Conner +5.7 dBA, Fujitsu +3.2, WD Green +7.2, Samsung T166 +8.2, Maxtor Atlas +9.9, WD JD +10.7, Maxtor DM10 +12.5, Seagate ST3250823A +4.5 ([Klerrp pack](https://freesound.org/people/Klerrp/packs/8850/); [Commons Seagate](https://commons.wikimedia.org/wiki/File:Seagate_ST3250823A_Kopfger%C3%A4usche.ogg)).
- 0.5 s block RMS during seek activity rises only +2 to +7 dB over idle: Fujitsu +2.6, Maxtor DM10 +2.2, Samsung SV1022D +3.0, Conner +4.4, Samsung T166 +6.5, Maxtor Atlas +6.8 ([Klerrp pack](https://freesound.org/people/Klerrp/packs/8850/)). In the Seagate clip, the loudest 10% of 20 ms frames are 17.6 dB above the quietest 15% ([Commons Seagate](https://commons.wikimedia.org/wiki/File:Seagate_ST3250823A_Kopfger%C3%A4usche.ogg)).

### Inferences
- Why the current Whirr synthesis may sound "flat": its 2.5-5 kHz centre is right for some drives (Seagate 7200.8-era 2.63 kHz; 2012 drives 3.75-3.93 kHz). But low-Q bandpasses on sub-millisecond noise impacts lack three features the recordings show:
  - 3-8 narrow, irregularly spaced resonances per drive (Q about 15-35);
  - a 20-40 ms tail at -10 to -16 dB after a 3-7 ms initial drop;
  - multi-burst seeks, with a second burst 10-17 ms after the first.
- Why the earlier "body" version sounded bassy: the measured low component is real in about half the drives, centred at 190-300 Hz, but it is low-Q (Q about 4-5), delayed 6-14 ms after the click, and mostly gone within 11-28 ms. A-weighted it is usually 5-16 dB below the 1-5 kHz click (Conner about -5 dB, WD102AA about -8 dB, Maxtor DM10 about -16 dB). Samsung T166 is the exception, at about +1 dB. A long-ringing 150-500 Hz mode at equal or greater level would overshoot every recording. Suggested target: a 200-300 Hz thump at -6 to -12 dB (A-weighted) relative to the click, decaying -10 dB in about 10-25 ms, started 5-10 ms after the click and made optional per drive "personality".
- Playback through small laptop speakers will mostly drop content below about 200-300 Hz anyway. That argues for carrying "weight" in the 300-1000 Hz region, as the Fujitsu 2000 (888 Hz) and Samsung 2000 (458/678 Hz) peaks do. This is an inference, not measured.
- Perceived loudness should come from crest factor (peaks 13-16 dB over the idle envelope), not from a big RMS rise. Seek activity adds only about 2-7 dB RMS over spin noise.
- A continuous idle bed at rpm/60 (plus a few drive-specific whine tones) sits under the seeks. It is part of what makes seeks read as "inside a drive" rather than as isolated clicks.

### Gaps
- Unknown microphones, distances and surfaces. The 190-300 Hz component could be partly desk or table radiation (see section 5). The low-end numbers are confounded by this.
- Lossy MP3/Vorbis previews and the 11 kHz Seagate file limit precision above about 5 kHz and of very short transients (below 1 ms).
- I could not tag individual events as short-stroke or full-stroke seeks, so the level difference between seek types is not measured. The only proxy is the spread: p10 to p90 peak-over-idle varies by 2-13 dB within a drive.
- The Fujitsu Allegro 15k recording failed the automatic idle/seek split. Hitachi 5K3000, Hitachi T7K500 and Samsung SV4002H had fewer than 10 events, so their spectra (broadly flat 0.25-12 kHz rises of +13-21 dB) are low-confidence.

## 3. Published analyses and measurements of seek noise

### Takeaway
The engineering literature (patents, trade articles) agrees that seek noise is tonal and set by actuator structural resonances excited by the voice-coil current profile, with energy into several kHz. Consumer acoustic reviews (SPCR) report broadband dBA at 1 m (seek typically +1 to +4 dB over idle) and give only qualitative descriptions. I found no openly accessible published seek spectrograms with numeric peaks.

### Cited Findings
- Seek noise is "normally dominated by fewer tones" tied to head-actuator structural resonances. Its level depends on seek speed, the voice-coil current profile and actuator dynamics — [Data Storage industry article (Scribd)](https://www.scribd.com/doc/133241149/Data-Storage-4-1) (via search summary)
- Patents attribute seek noise to the harmonic content of square-wave or bang-bang seek currents exciting actuator and head-gimbal resonances. One cites about 2.5 kHz as the seek-excited high-frequency region a prior system tried to damp. Another notes that smaller actuators push modes into the audible range — [US 6930853](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/6930853), [US 5291110](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/5291110), [US 5668680](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/5668680), [US 6441988](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/6441988) (via search summary; patent PDFs not read in full)
- DiskFiltration (Guri et al.) separates seek noise from idle noise. Idle noise comes from the spindle and bearings with a tone at RPM/60, and the paper states the seek tone frequency cannot be computed by formula — [arXiv 1608.03431](https://arxiv.org/pdf/1608.03431) (via search summary; the PDF text could not be extracted here)
- Gao, Yan and Yap (Microsystem Technologies, 2003) study vibro-acoustic interaction during the seek process. Only the abstract was visible — [Springer](https://link.springer.com/article/10.1007/s00542-002-0279-2)
- SPCR measured airborne and vibration-induced noise separately. They forced seeks with the AAM test in Hitachi's Feature Tool, or with large file copies on drives without AAM. Reported pairs include Samsung MP0402H 17 dBA idle / 18 dBA seek at 1 m, and Barracuda 7200.9 500 GB 2.8 / 3.2 Bels idle/seek. One Samsung review describes seek noise as mid-high frequency, rapid clicks and clattering — [SPCR 7200.9](https://silentpcreview.com/article283-page1.html), [SPCR article244](https://silentpcreview.com/article244-page1.html), [SPCR Momentus](https://www.silentpcreview.com/article264-page1.html) (via search summary; SPCR pages return HTTP 403 to direct fetch)

### Inferences
- The engineering view ("few tones from actuator resonances") supports a modal-bank synthesis: several narrow resonators per drive, excited by an accel pulse and a decel pulse. That matches the measured Q≈15-35 peaks and the two-burst structure. Seek current shape (bang-bang vs smoothed/AAM) sets how hard the modes are hit, so a "quiet/AAM" mode means a softer excitation and lower HF, not just lower gain.
- SPCR's +1 to +4 dBA idle-to-seek deltas agree with the measured small RMS rise (+2 to +7 dB in close-up recordings).

### Gaps
- No open spectrogram with labelled seek peaks was found. SPCR archives were blocked (403), and StorageReview and Tom's Hardware were not reached within the budget.

## 4. Listener descriptions of the "classic" HDD sound

### Takeaway
Listeners describe chatter and clicking ("Geiger counter", "crunching/chunking", "grinding", "metallic ting", "woosh+klonk"). They value it as proof of activity. A repeated critique of synthetic recreations is "pitch too high, pulses too short". Maxtor and other cheaper 1990s-2000s IDE drives are cited as the loudest.

### Cited Findings
- Hackaday describes heads "constantly thrashing" with a stream of Geiger-counter-like clicks. Commenters describe a "metallic ting" in 3.5-inch drives that the piezo HDD Clicker lacks, and loud drives as a "faint woosh+klonk" rather than a loud click. One says the clicker's simulated pitch is too high and its pulses too short compared to real drives. Another names low-quality Maxtor units as the loudest. Another says real drives seek audibly only when the head moves, and that the whine is closer to broadband noise than a single tone — [Hackaday](https://hackaday.com/2022/09/26/tiny-dongle-brings-the-hard-drives-song-back-to-updated-retrocomputers) (summarised by fetch tool)
- The HDD Clicker is an ATtiny plus piezo driven from the HDD LED header, and it emits a series of clicks per LED event — [Hackaday](https://hackaday.com/2022/09/26/tiny-dongle-brings-the-hard-drives-song-back-to-updated-retrocomputers); see also [Tom's Hardware](https://www.tomshardware.com/news/hdd-clicker-v02-restores-aural-ambience-of-pre-ssd-life) and [PC Gamer](https://www.pcgamer.com/hdd-clicker-retro-sound-device)
- Nostalgia themes: proof that the computer is busy, overnight-defrag ritual, a "clicking grinding sound" missed in the SSD era. Some found it annoying — [AnandTech forum](https://forums.anandtech.com/threads/does-anyone-miss-hdd-sounds.2380812) (via search summary)
- The defrag98.com recreation uses recorded drive "chunking" sounds — [PC Gamer](https://pcgamer.com/hardware/if-you-miss-defragmenting-your-c-drive-theres-a-website-that-lets-you-recreate-the-experience-complete-with-hard-drive-chunking-sounds)

### Inferences
- "Too high and too short" in the HDD Clicker critique is the same failure mode as Whirr's "too flat". Real seek units last about 10-40 ms (median 12 ms) with tails, and many older drives carry energy at 0.9-2 kHz plus a 200-300 Hz thump. A sub-millisecond 2.5-5 kHz impact reads as a "tick", not a "chunk".
- "Metallic ting" points to the narrow kHz resonances (Q 15-35, ring T60 about 60-180 ms in band) measured above. "Woosh+klonk" points to the hiss bed between bursts plus the delayed low thump.

### Gaps
- I found no systematic listener study ranking drives or eras. Mentions of Quantum Fireball, IBM Deskstar and Seagate Barracuda as iconic did not appear in fetched sources (only Maxtor as "loudest"), so the iconic-drive question remains anecdotal.

## 5. Bare drive vs drive inside a desktop case

### Takeaway
No paired recordings were found. Secondary sources say case coupling mainly amplifies vibration-borne (lower-frequency) noise and that elastic suspension reduces seek noise most. This suggests that the 150-400 Hz "thump" is largely structure-borne and case- or desk-dependent, while the kHz clicks are airborne from the drive itself.

### Cited Findings
- SPCR splits drive noise into airborne and vibration-induced components, and says their relative importance depends on mounting — [SPCR article611](https://www.silentpcreview.com/article611-page1.html) (via search summary)
- SPCR's elastic suspension reduced HDD noise in idle and seek, "particularly in seek" — [SPCR Sandwiches & Suspensions](https://www.silentpcreview.com/article8-page2.html) (via search summary)
- A user reports drives almost silent in a USB enclosure but noisy in the case, implicating case or cage resonance — [Tom's Hardware forum](https://forums.tomshardware.com/threads/how-to-avoid-resonant-vibrations-of-harddisks-in-a-case.3884195/post-23522477) (via search summary)
- A commenter says the head stepper of 5.25-inch MFM drives could be felt through a table — [Hackaday](https://hackaday.com/2022/09/26/tiny-dongle-brings-the-hard-drives-song-back-to-updated-retrocomputers)

### Inferences
- The analysed recordings are "close-up" and probably bare drives on a surface. Their 190-300 Hz components (Conner 264, Samsung 194/215, WD102AA 278, Maxtor 291) may be partly surface radiation of actuator reaction forces. A "drive in case" preset should strengthen and slightly lengthen this low component and add case-panel coloration. A "bare/external" preset should be HF-dominant (like the Seagate 7200.8 clip, under 1% below 300 Hz).

### Gaps
- No measured spectra comparing the same drive bare vs cased were found. This would need a controlled recording.

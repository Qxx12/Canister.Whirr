# Server (10k/15k rpm) and modern helium enterprise/NAS HDDs: mechanics, datasheet timing, acoustics, and synthesizable sound descriptions

Scope note: hard disk drives only. Throughout, "datasheet" = manufacturer document, "measured" = third-party instrument measurement, "user report" = forum description (anecdotal), "inference" = my reasoning, not sourced. Sound power figures in bels (B) are A-weighted sound power per ISO 7779 (1 B = 10 dB sound power; this is NOT the same as dBA sound pressure at 1 m, and the two cannot be compared directly). Several vendors (WD Red, Toshiba) now print sound power with a "dB"/"dBA" label (e.g., "20 dB" = 2.0 B). Audio analysis of the repo's CC0 Maxtor Atlas 10K V and Fujitsu Allegro 10LX recordings is being done by another researcher and is not attempted here.

## Datasheet timing and acoustics for representative models

### Takeaway
15k drives have ~2.0 ms latency, ~3.4/3.9 ms average read/write seek, 0.2/0.4 ms track-to-track, ~6.6–7.4 ms full stroke, and idle sound power ~3.4–3.7 B; 10k drives are ~3 ms latency, ~4–4.9 ms seek, 11 ms full stroke, 3.2–3.7 B idle and 3.6–4.0 B seek. Modern helium 7200 rpm drives are much quieter at idle (2.0–2.8 B) but seek at 3.2–3.6 B, i.e., the idle-to-seek jump (~1.2–1.6 B) is much larger than for 10k/15k drives (~0.4 B). Modern helium datasheets have stopped publishing seek times at all.

### Cited Findings

**15k rpm**
- Seagate Cheetah 15K.7 SAS (600/450/300 GB; 8/6/4 heads; 165k TPI): 15k rpm, average rotational latency 2.0 ms; access time (no controller overhead) average 3.4 ms read / 3.9 ms write; single track 0.2 ms read / 0.44 ms write; full stroke 6.6 ms read / 7.4 ms write — [Seagate Cheetah 15K.7 SAS Product Manual, Rev. F, Dec 2012 (archive.org copy)](https://archive.org/download/manualsonline-id-3ef39731-d1a1-4222-8c31-490b7fa44f7e/3ef39731-d1a1-4222-8c31-490b7fa44f7e.pdf)
- Cheetah 15K.7 acoustics: "Sound power during idle mode shall be 3.4 bels typical ... Sound power while operating shall be 3.8 bels typical" (ISO 7779); "There will not be any discrete tones more than 10 dB above the masking noise on typical drives" and none more than 24 dB above masking on any drive — [same manual, §6.4.5](https://archive.org/download/manualsonline-id-3ef39731-d1a1-4222-8c31-490b7fa44f7e/3ef39731-d1a1-4222-8c31-490b7fa44f7e.pdf)
- Cheetah 15K.7 uses a dedicated landing zone at the innermost radius (contact start/stop style), automatic shipping lock, and a "low-inertia, balanced, patented, straight arm" actuator — [same manual](https://archive.org/download/manualsonline-id-3ef39731-d1a1-4222-8c31-490b7fa44f7e/3ef39731-d1a1-4222-8c31-490b7fa44f7e.pdf)
- Seagate's Cheetah 15K.7 data sheet repeats 3.4/3.9 ms average and 0.2/0.4 ms track-to-track for all three capacities — [search summary of Seagate Cheetah 15K.7 data sheet (Bechtle mirror)](https://media.bechtle.com/asrc/180712/1c4b3d4ee288fc9434f5175bf56070570/c3/-/f13d4f728c144e119dcaf70ab3dea48f/seagate-cheetah-15k-7-600-gb-hard-drive-data-sheet-1)
- Hitachi Ultrastar 15K600 (3.5"): 15,000 rpm, 2.0 ms average latency, idle acoustics 3.7 B; read seek listed as 3.4 ms (extracted text garbled, treat as approximate). The 2.5" Ultrastar C15K600 lists 3.2 B idle and 2.9/3.1 ms read/write seek. The older 15K147 lists 0.6 ms track-to-track — [manualmachine mirror of Ultrastar 15K600 datasheet](https://manualmachine.com/hitachi/hus156030vls601/10779083-datasheet); [Thomas-Krenn datasheet PDF](https://www.thomas-krenn.com/redx/tools/mb_download.php/mid.120101051122122110070108112104119061/Datenblatt_Hitachi_US15K600.pdf); [15K147 datasheet mirror](https://manualmachine.com/hitachi/hus151473vlf200/10779061-datasheet) (values via search-result extraction, not read in full)
- Fujitsu MBA3xxxRC 15k (MBA3073/3147/3300RC family, the SAS successor to MAX; "Allegro 10LX" is Fujitsu's 15k product family name per the Freesound title of the repo recording): idle sound power ≤ 3.6 B; track-to-track 0.2 ms read / 0.4 ms write typical — [Fujitsu MBA3147RC Product Manual (manualowl)](https://www.manualowl.com/m/Fujitsu/MBA3147RC/Manual/335903?page=16) (via search-result extraction; full page not read)

**10k rpm**
- Maxtor Atlas 10K V (73.5/147.1/300 GB): 10,000 rpm; average rotational latency 3 ms; average seek read <4.0/4.2/4.4 ms (max 4.8), write 4.5/4.7/4.9 ms (max 5.3); full stroke 11.0 ms typ (12.0 max); sequential head/cylinder switch 0.3 ms read / 0.5 ms write (no explicit track-to-track row) — [Maxtor 10K V manual, Table 4-3 (manualsdir p.52)](https://www.manualsdir.com/manuals/123661/maxtor-10k-v.html?page=52)
- Maxtor Atlas 10K V sound power (ISO 7779, mean / mean+3σ, bels): idle on-track 3.16/3.38 (73.5 GB), 3.52/3.68 (147 GB), 3.67/3.91 (300 GB); random seeking 3.60/3.72, 3.87/4.04, 3.96/4.19. Tone spec: typical drive has no discrete tones exceeding a tone ratio of 8 dB (ECMA-74) — [Maxtor 10K V manual, Table 4-6 (manualsdir p.55)](https://www.manualsdir.com/manuals/123661/maxtor-10k-v.html?page=55)
- WD VelociRaptor WD1000DHTZ (1 TB, 3.5" IcePack carrier around a 2.5" drive): WD spec 30 dBA idle, 37 dBA "performance seek" (average) — [StorageReview VelociRaptor 1TB review](https://www.storagereview.com/review/western-digital-velociraptor-1tb-review); [B&H spec listing](https://www.bhphotovideo.com/c/product/871968-REG/Western_Digital_WD1000DHTZ_1_TB_Velociraptor_3_5.html)
- Tom's Hardware measured random read seek 6.8 ms and random write 8.8 ms on the WD1000DHTZ (benchmark access time including latency, not the datasheet seek metric) — [Tom's Hardware WD1000DHTZ review](https://www.tomshardware.com/reviews/velociraptor-1tb-hdd-ssd,3250-2.html)

**Modern helium 7200 rpm**
- WD Ultrastar DC HC550 (16/18 TB, helium "H" in model number, 7200 rpm): latency average 4.16 ms; Acoustics Idle/Operating 2.0/3.6 B typical for both SATA and SAS; datasheet gives no seek times; idle spec based on Idle_A — [WD Ultrastar DC HC550 data sheet (June 2020)](https://documents.westerndigital.com/content/dam/doc-library/en_us/assets/public/western-digital/product/data-center-drives/ultrastar-dc-hc500-series/data-sheet-ultrastar-dc-hc550.pdf)
- Seagate Exos X18 SATA (16/18 TB; 9 disks, 18/17 heads; 2470 KBPI): average latency 4.16 ms; sound power idle 2.8 B typ (3.0 max), performance seek 3.2 B typ (3.4 max); "During periods of drive idle, some offline activity may occur according to the SMART specification, which may increase acoustic and power to operational levels" — [Seagate Exos X18 SATA Product Manual Rev. A](https://www.seagate.com/www-content/product-content/enterprise-hdd-fam/exos-x18/_shared/en-us/docs/100865854a.pdf)
- Exos X18 acoustic test method: seek-mode test rate "Number of seeks per second = 0.4 / (average latency + average access time)"; prominent discrete tones assessed per ECMA-74 — [same manual §2.7–2.8](https://www.seagate.com/www-content/product-content/enterprise-hdd-fam/exos-x18/_shared/en-us/docs/100865854a.pdf)
- Exos X18 PowerChoice idle states and default timers: Idle_a (reduced electronics) 100 ms; Idle_b (heads unloaded, full rpm) 2 min; Idle_c (heads unloaded, reduced rpm) 4 min; Standby_z (motor stopped) 15 min — [same manual §2.5.4](https://www.seagate.com/www-content/product-content/enterprise-hdd-fam/exos-x18/_shared/en-us/docs/100865854a.pdf)
- Seagate Exos X20 data sheet: helium sealed with "helium side-sealing weld technology", 7200 rpm, 4.16 ms latency; no seek times or acoustics in the channel data sheet — [Seagate Exos X20 data sheet DS2080](https://www.seagate.com/files/www-content/datasheets/pdfs/exos-x20-channel-DS2080-2111GB-en_EM.pdf)
- Exos X20 acoustics as reproduced by reviewers: 28 dBA idle (Idle 1); seek 30 dBA in one StorageReview table vs 32 dBA in another (conflict) — [StorageReview Exos X20 review](https://www.storagereview.com/review/seagate-exos-x20-20tb-enterprise-hdd-review); [AnandTech](https://www.anandtech.com/show/17099)
- Seagate Exos M (Mozaic 3+/HAMR, 24–32 TB, ST30000NM004K etc.): helium, CMR, 7200 rpm, 4.16 ms latency, Idle A 6.9 W, 4K QD16 random read/write 170/350 IOPS; this data sheet lists no acoustics — [Seagate Exos M v1.2 data sheet DS2045](https://www.seagate.com/content/dam/seagate/en/content-fragments/products/datasheets/exos-m-v1-2/exos-v1-2-DS2045-4-2511-en_US.pdf)
- Toshiba MG10 (18/20 TB, 10-disk helium, 7200 rpm): sound power idle 20 dB typ, seek 32 dB typ (= 2.0 B / 3.2 B) — [Toshiba MG10 Product Overview rev.4](https://toshiba-semicon-storage.com/content/dam/toshiba-ss-v3/master/en/storage/product/data-center-enterprise/MG10-Product-Overview_rev.4.pdf)
- WD Red Pro 24 TB (WD240KFGX): 20 dBA idle / 32 dBA average seek per WD datasheet table (one retailer lists 25 dBA idle — conflict); TechRadar notes IronWolf Pro 24 TB is quoted at 24 dBA and calls the Red Pro "noisy in use" — [search summary of WD datasheet mirror (Farnell)](https://www.farnell.com/datasheets/4019029.pdf); [TechRadar WD Red Pro 24TB review](https://www.techradar.com/pro/western-digital-wd-red-pro-24tb-review); [Memory Express listing](https://www.memoryexpress.com/Products/MX00135488)
- Seagate Exos 2X18 (Mach.2 dual actuator): 7200 rpm, 256 MB cache, idle 7.8 W SATA / 8 W SAS, up to 13.5/12.8 W under load; sequential up to ~554 MB/s. No acoustic figure found — [Tom's Hardware](https://www.tomshardware.com/news/seagate-launches-2nd-gen-dual-actuator-hdds-18-tb); [PCGH](https://www.pcgameshardware.de/Festplatte-Hardware-255553/News/Seagate-Exos-2X18-HDD-mit-bis-zu-554-MB-s-via-Dual-Aktor-1407570/)

### Inferences
- Rotational latency (half a revolution) is exact from rpm: 10k = 3.0 ms, 15k = 2.0 ms, 7200 = 4.17 ms. For a virtual head model, full-stroke ≈ 2× average seek holds for both generations (Cheetah 6.6 vs 3.4; Atlas 11 vs ~4.2).
- For helium drives with no published seek time, a reasonable assumption is the last generation that did publish (e.g., Seagate enterprise 7200 class ~8.5 ms read avg) — not sourced here; flag as an assumption in the preset.
- Idle-to-seek level step: 15k/10k ≈ +0.3–0.4 B (whine dominates even when seeking); helium ≈ +1.2–1.6 B (quiet idle, seeks stand out strongly). For Whirr's mix: 10k/15k presets should keep a loud continuous bed with seeks layered on top; helium presets should have a near-silent bed so seeks read as isolated loud events.

### Gaps
- Seek times for modern helium drives (WD HC5xx/HC6xx, Exos X16–X24, Toshiba MG07–MG10, Mozaic) are not published in the data sheets I read.
- No acoustic figures found for Exos 2X18 (Mach.2), Exos M Mozaic 3+, WD HC570/HC580/HC680, or Seagate Savvio 10K / WD 2.5" VelociRaptor spec sheets (not fetched).
- Fujitsu MAX-series (FC/SCSI) and MBA average seek and full-stroke values were not retrieved (only track-to-track and idle bels via search snippets).

## Why helium drives sound different, and what users say

### Takeaway
Manufacturers say helium reduces spinning noise (1/7 the density of air, less turbulence), which matches the very low idle sound power; but helium enables up to 9–11 platters and 18–20+ heads on one actuator, and users consistently describe helium/high-capacity drives as having loud, low "thud/clack" seeks and periodic idle head movements. Nobody published a controlled explanation of the seek-loudness; the mechanism below is partly inference.

### Cited Findings
- Helium has "about 1/7 the density of air"; "Disks spinning in helium create significantly less noise"; reduced friction "requires less rigidity in platter thickness" (thinner platters); max 10 platters in a helium drive vs 6 in air — [WD blog, Helium Hard Drives Explained](https://blog.westerndigital.com/helium-hard-drives-explained/)
- Toshiba MG10 is a "10-disk helium-sealed design"; helium is permanently sealed inside to reduce aerodynamic drag and power — [Toshiba MG10 Product Overview](https://toshiba-semicon-storage.com/content/dam/toshiba-ss-v3/master/en/storage/product/data-center-enterprise/MG10-Product-Overview_rev.4.pdf)
- Seagate uses "helium side-sealing weld technology" (welded enclosure) — [Exos X20 data sheet](https://www.seagate.com/files/www-content/datasheets/pdfs/exos-x20-channel-DS2080-2111GB-en_EM.pdf)
- Exos X18: 9 disks, 18 heads on one actuator — [Exos X18 manual](https://www.seagate.com/www-content/product-content/enterprise-hdd-fam/exos-x18/_shared/en-us/docs/100865854a.pdf)
- A source summarized in search results says helium's lower vibration reduced drive noise "by about 30%"; another notes bigger platter stacks imply bigger/heavier actuators — [BGR explainer](https://bgr.com/2125364/what-helium-hard-drives-are-explained) (secondary source)
- User reports (anecdotal):
  - SPCR forum: a WD helium drive's seeks described as a loud, dull "thud", and it does background activity so seek noises are heard even at idle — [SPCR thread "With helium drives, anything above 6TB = noisy?"](https://silentpcreview.com/forums/viewtopic.php?p=609526) (403 on fetch; content from search snippet)
  - Exos X20: "the clacking from the heads is really loud", much louder than a Barracuda Compute 10TB and WD Reds; sounds closer to "old 20MB hard drives"; drives "quietened down" over the first week; one drive had a "loud click every 1 minute" (stopped after changing power cable) — [Overclockers UK "Noisy Seagate Exos X20s"](https://forums.overclockers.co.uk/threads/noisy-seagate-exos-x20s.18976282)
  - Exos X18 replacing X10s: constant head seek noise "about once every 1.4s" when idle, "not clicks of death" — [HardForum "Seagate Exos X10 constant seek noises at idle"](https://hardforum.com/threads/seagate-exos-x10-constant-seek-noises-at-idle.2019264) (403 on fetch; content from search snippet)
  - Toshiba (MG09 thread): a drive "will sound like a chainsaw whilst it's seeking" — [TechPowerUp forum post](https://techpowerup.com/forums/posts/4663273) (via search snippet; model ambiguous)
  - Older HGST drives: "loud chattering noises upon I/O" but no idle clicking; newer Seagates reportedly have a PWL-like behavior that is "much, much quieter, as in more muted" — [TrueNAS forum thread](https://www.truenas.com/community/threads/new-wd-red-pros-clicking-every-5-seconds-preventive-wear-leveling-firmware-feature.105866)
  - Counterpoints: TechPowerUp users disagree whether helium drives get louder with capacity; a Storj user found no air-vs-helium difference and blamed vibration transmitted to the enclosure — [Storj forum "Are helium filled HDDs louder?"](https://forum.storj.io/t/are-helium-filed-hdds-louder/19653); [TechPowerUp](https://techpowerup.com/forums/goto/post?id=4625096)
  - Damping the drive-to-case connection makes the periodic noise largely vanish (user) — [search summary of WD/Reddit PWL threads](https://lr.us.psf.lt/r/LinusTechTips/comments/113cpje/pwl_clicking_annoying_sounds_in_wd_drives/j8rqasc/?context=3)
- Mach.2: NASCompares (single informal test) found the Exos 2X18 quieter than an IronWolf Pro 20TB and speculates each actuator moves a smaller, less heavily sprung arm stack; a 2X16 sounded similar to a single 8TB — [NASCompares Mach.2 review](https://nascompares.com/review/seagate-exos-mach-2-2x18-hard-drive-review-should-you-buy/); [NASCompares 2023](https://nascompares.com/2023/03/27/seagate-exos-mach-2-2x18-hard-drive-should-you-buy/)

### Inferences
- Likely mechanism for loud helium seeks (inference, unsourced): (1) a much heavier actuator (18–20 arms/heads) driven hard by the VCM produces larger reaction impulses into the base casting at accel/decel reversal; (2) more mass means lower structural resonances excited, giving a lower, "thuddier" body than 2-platter desktop drives; (3) low-density helium provides little aerodynamic damping of the arm/base ringing, and the very low idle floor (2.0–2.8 B) makes each seek stand out. Mounting matters: much of the audible sound is chassis-radiated vibration, which is why rubber isolation "makes it vanish."
- Words users use map to synthesis targets: "thud/thump" = low-mid (≈150–600 Hz) body with fast decay; "clack/click/tick" = short broadband transient with 1–5 kHz content; "chainsaw/chatter/crunch/gravel" = dense trains of short seeks at high queue depth (many events per 10 ms). I found no source using "popcorn", "bloop" or "chirp" specifically for these drives — those terms appear to be community folklore not captured by my searches.
- Mach.2: two independent actuators each carrying half the heads suggests two interleaved seek streams with lighter (higher-pitched, quieter) impulses; preset could run two virtual heads with independent timing.

### Gaps
- No measured spectra or impulse responses for any helium drive's seek were found. No controlled study comparing air vs helium seek acoustics.
- SPCR, HardForum and SilentPCReview pages returned 403; their content is only from search snippets.
- No source documents thinner/stiffer platter dimensions or lid thickness for helium drives.

## PWL, background media scan, and periodic idle head movements

### Takeaway
WD's "Preventive Wear Leveling" is a periodic idle head sweep reported by users at roughly every 5 s on recent WD Red Pro/Gold/Black/Ultrastar (some older builds about once a minute); there is no public WD document giving the interval. Seagate's own 15k manual documents idle head relocation every 60 s to a random location in the outer quarter of the stroke, and Background Media Scan starting after 500 ms idle in 800 ms bursts with 100 ms pauses.

### Cited Findings
- PWL described as "a periodic head sweep to distribute lubricant and prevent wear in a particular place"; WD Red Pro 20TB (twin of Ultrastar HC550/HC560 with OptiNAND) clicks about every 5 s at idle, head movement can be felt, stops only on spin-down; WD support reportedly said "all new generation HDDs have this feature enabled" (second-hand); "On many older models, this would happen maybe once a minute. But on some builds it's maybe every 5 seconds" — [TrueNAS forum](https://www.truenas.com/community/threads/new-wd-red-pros-clicking-every-5-seconds-preventive-wear-leveling-firmware-feature.105866)
- Ultrastar HC510 10TB user logged "tick" noises at ~1, 6, 11, 16, 21, 26, 30 s (≈5 s period); recording at voca.ro (not openly licensed) — [Tom's Hardware forum](https://forums.tomshardware.com/threads/new-ultrastar-10tb-hdd-annoying-pwl-noise-what-now-buy-wd-purple-pro-instead-noise-example-included.3798784)
- WD Black: "all 8 of them do a periodic head movement every 5 seconds (approx) even when idle"; WD Level 3 support reportedly identified the sound as PWL; one user calls it "a short little (normal) head-movement sound" — [WD Community, periodic noise from head movement](https://community.wd.com/t/periodic-noise-from-head-movement-wd-black-4tb/183096)
- Other reported intervals: "every 3-10 seconds", a 2013 WD Black "every 10m" vs 2016 "every 5 seconds"; a tick every 1–2 s was judged not to be PWL; PWL described as feelable up to a meter away — [search summary across WD Community/ipcamtalk/guru3d threads](https://community.wd.com/t/wd-black-4tb-hdd-makes-clunking-noise-every-5-second/295472); [WD Gold thread](https://community.wd.com/t/recurring-clucking-sound-every-5-seconds-western-digital-gold/228605)
- Cheetah 15K.7: "During idle, the drive heads are relocated every 60 seconds to a random location within the band from three-quarters to maximum track" — [Cheetah 15K.7 SAS manual, DC power note 7](https://archive.org/download/manualsonline-id-3ef39731-d1a1-4222-8c31-490b7fa44f7e/3ef39731-d1a1-4222-8c31-490b7fa44f7e.pdf)
- Cheetah 15K.7 Background Media Scan: sequential reads across the pack while idle; first scan starts after 5 ms idle, subsequent scans after 500 ms idle; "BMS functions for bursts of 800ms and then suspends activity for 100ms"; interrupts immediately for host commands (~1 ms delay). SMART off-line data saved "once every two hours subject to an idle period" — [same manual §9.4, SMART section](https://archive.org/download/manualsonline-id-3ef39731-d1a1-4222-8c31-490b7fa44f7e/3ef39731-d1a1-4222-8c31-490b7fa44f7e.pdf)
- Exos X18: idle SMART off-line activity "may increase acoustic and power to operational levels"; heads unload after 2 min idle by default (Idle_b) — [Exos X18 manual](https://www.seagate.com/www-content/product-content/enterprise-hdd-fam/exos-x18/_shared/en-us/docs/100865854a.pdf)
- Exos X18 user report: idle seek ~every 1.4 s — [HardForum (snippet)](https://hardforum.com/threads/seagate-exos-x10-constant-seek-noises-at-idle.2019264)

### Inferences
- Suggested idle-event schedulers per preset (derived from the above):
  - WD helium (Red Pro / Gold / Ultrastar HC5xx): single medium seek "tick/thunk" every 5.0 s ± ~0.3 s jitter while host-idle; suppress while I/O is active; stop only if the virtual drive spins down.
  - Seagate Exos: optional quieter, irregular idle seeks (~1–2 s spacing reported for X18, but only one report) plus an occasional head unload/load click after 2 min idle; use lower amplitude than WD PWL per the "more muted" report.
  - 15k Cheetah-class: one random-position seek every 60 s into the outer quarter of the stroke; BMS is sequential reads so it should be acoustically near-silent (maybe occasional track-to-track ticks).
- PWL sound itself: a single seek of moderate length (users call it "normal head-movement sound"), so synthesize with the same seek-impulse model as a mid-length seek, not a special click.

### Gaps
- No official WD document describing PWL, its interval, which models have it, or whether it can be disabled.
- Seagate does not document an Exos equivalent; the 60 s relocation is documented only for Cheetah 15K.7.
- Toshiba MG idle-sweep behavior: nothing found.

## Spindle whine and motor tones for 10k/15k

### Takeaway
The idle spindle fundamental is rpm/60: 166.7 Hz for 10k, 250 Hz for 15k (120 Hz for 7200). Enterprise specs cap discrete tones (Cheetah ≤10 dB above masking typical; Atlas tone ratio ≤8 dB), so the audible "whine" is mostly higher-order electromagnetic/structural tones riding on broadband aerodynamic noise; no source gave measured whine frequencies for 10k/15k drives.

### Cited Findings
- "Idle noise is generated mainly by the spindle motor and the ball bearings inside the motor" with main frequency = RPM/60 (120 Hz at 7200 rpm on a WD drive); seek noise "is usually louder than the static Idle acoustic noise" and its tone frequency cannot be calculated by formula — [DiskFiltration, Guri et al., arXiv:1608.03431](https://arxiv.org/pdf/1608.03431)
- DiskFiltration (desktop 7200 rpm Seagate Barracuda / WD Blue drives, not server drives): repeated seeks between consecutive tracks gave "a strong signal ... between 1500 – 8000 Hz"; seek+read operations spread energy over 0–6000 Hz with no significant difference between full-stroke, adjacent-track and adjacent-sector seeks; most informative band ~2080 Hz, which the authors relate to a 0.48 ms track-to-track seek — [same paper](https://arxiv.org/pdf/1608.03431)
- Electromagnetically induced vibration in spindle motors occurs mainly at harmonics of the commutation frequency and can produce audible prominent tones — [US patent 6493169, spindle motor commutation time variation for reducing acoustic noise](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/6493169)
- Pure tones appear when an electromagnetic frequency (dependent on magnet pole count and stator harmonic) approaches a structural resonance of the drive — [US patent 8917479, Harmonic shaping of a motor](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/8917479)
- Tone limits: Cheetah 15K.7 no discrete tones >10 dB above masking (typical), >24 dB (any drive) — [Cheetah manual](https://archive.org/download/manualsonline-id-3ef39731-d1a1-4222-8c31-490b7fa44f7e/3ef39731-d1a1-4222-8c31-490b7fa44f7e.pdf); Atlas 10K V tone ratio ≤8 dB typical (ECMA-74) — [Maxtor manual p.55](https://www.manualsdir.com/manuals/123661/maxtor-10k-v.html?page=55)
- Qualitative whine reports: WD Raptor WD740 "slight high-pitched whine" inaudible from a closed case or >1 m — [search summary of Raptor reviews (HotHardware/AnandTech)](https://hothardware.com/reviews/western-digital-raptor-wd1500adfd--bigger-faster-stronger?page=2); WD1500ADFD whine on spin-up/down "perhaps more pronounced than many 7200 RPM drives" — [HotHardware](https://hothardware.com/reviews/western-digital-raptor-wd1500adfd--bigger-faster-stronger); VelociRaptor 1TB's "comparatively loud seek operations" its main weakness — [Tom's Hardware](https://www.tomshardware.com/reviews/velociraptor-1tb-hdd-ssd,3250-8.html); StorageReview notes a low dBA score doesn't predict whether a drive whines — [StorageReview Raptor WD740GD review](https://www.storagereview.com/review/western-digital-raptor-wd740gd-00flc0)
- Users found two 15k Atlas II disks loud in a desktop — [Vogons thread](https://www.vogons.org/viewtopic.php?p=897723)

### Inferences
- Spindle partials to synthesize (inference): fundamental f0 = rpm/60 (166.7 Hz / 250 Hz), low-level harmonics 2f0–4f0; plus one or two narrow tonal partials in the 1–6 kHz region at integer multiples of f0 representing commutation/slot harmonics. If the motor were a common 8-pole/12-slot design (assumption, not sourced for these drives), electrical frequency = 4·f0 (667 Hz at 10k, 1 kHz at 15k) and slot-pass = 12·f0 (2 kHz / 3 kHz), with a cogging/LCM term at 24·f0 (4 kHz / 6 kHz). Keep these tones ≤8–10 dB above the broadband bed to respect the tone specs. A search-result summary mentioned a patent example of a 5760 Hz tone at 7200 rpm (= 48·f0), consistent with high-order motor harmonics, but I could not confirm which patent it came from.
- Broadband "air rush" bed: much stronger at 10k/15k than at 7200 rpm (aerodynamic power scales steeply with tip speed); 3.5" 15k drives use small (~65–70 mm) platters, which is why their idle level (3.4–3.7 B) is similar to 10k drives rather than much higher (platter size is general knowledge, unsourced here).
- Spin-up: a rising-pitch sweep of all spindle partials from 0 to f0 over several seconds is the most characteristic sound of these drives (the repo's CC0 recordings capture this).

### Gaps
- No published spectrum or measured whine frequency for any 10k/15k drive (SPCR VelociRaptor page with spectra returned 403).
- Pole/slot counts of 10k/15k spindle motors not found.

## Synthesizable preset descriptions

### Takeaway
Three to four presets cover the space: "10k Raptor/Atlas", "15k Cheetah/Allegro", "Helium NAS/enterprise (WD-style with PWL)", and "Helium Exos (Seagate)", with optional "Mach.2 dual-actuator". The defining contrast is: server = loud tonal whine + fast, short, bright seek ticks; helium = near-silent bed + slower, heavier, low "thunk/clack" seeks + periodic idle ticks.

### Cited Findings
- Timing anchors: 15k avg 3.4/3.9 ms, t2t 0.2/0.44 ms, full 6.6/7.4 ms, latency 2.0 ms — [Cheetah 15K.7 manual](https://archive.org/download/manualsonline-id-3ef39731-d1a1-4222-8c31-490b7fa44f7e/3ef39731-d1a1-4222-8c31-490b7fa44f7e.pdf); 10k avg 4.0–4.9 ms, head switch 0.3/0.5 ms, full 11 ms, latency 3 ms — [Maxtor 10K V manual](https://www.manualsdir.com/manuals/123661/maxtor-10k-v.html?page=52); helium 7200 latency 4.16 ms — [Exos X18 manual](https://www.seagate.com/www-content/product-content/enterprise-hdd-fam/exos-x18/_shared/en-us/docs/100865854a.pdf)
- Level anchors (sound power, bels): 15k 3.4 idle / 3.8 operating; 10k 3.2–3.7 idle / 3.6–4.0 seek; helium 2.0–2.8 idle / 3.2–3.6 seek — sources as in section 1
- Seek spectrum anchor (desktop drives): 1.5–8 kHz discrete bands for short seeks, 0–6 kHz for seek+read — [DiskFiltration](https://arxiv.org/pdf/1608.03431)

### Inferences
Parameter suggestions (all inference, intended as starting points to be tuned against the repo's CC0 recordings):

| Preset | Bed | Seek impulse character | Seek timing (virtual head) | Idle events | Relative level |
|---|---|---|---|---|---|
| 10k (Raptor / Atlas 10K / Savvio 10K) | f0 166.7 Hz + harmonics, tonal partial(s) ~0.7–4 kHz, strong broadband air hiss | short (decay ~5–15 ms), bright tick, modes weighted 1.5–6 kHz, little low body (light 1–4 head actuator) | avg ~4.2 ms read / 4.7 write, full stroke ~11 ms, t2t ~0.3–0.5 ms, latency 3 ms | none documented | bed loud; seeks only +0.4 B over idle |
| 15k (Cheetah 15K / Allegro / Ultrastar 15K) | f0 250 Hz + harmonics, higher tonal partials ~1–6 kHz, strongest hiss | very short (≤10 ms), sharp, highest-pitched ticks; fast "buzzing chatter" under random load because seeks are ~3.4 ms | avg 3.4/3.9 ms, full 6.6/7.4, t2t 0.2/0.44, latency 2.0 ms | one outer-band random seek every 60 s (Cheetah) | bed loudest; seeks +0.4 B |
| Helium WD (Red Pro / Gold / Ultrastar HC5xx-HC6xx) | very quiet: faint 120 Hz + soft hiss | heavy "thunk/clack": low-mid body (~150–600 Hz) plus 1–4 kHz click, longer ring (~20–40 ms) | 7200 rpm, latency 4.17 ms; avg seek unknown (assume ~8 ms) | PWL tick every ~5 s while idle | bed ~2.0 B; seeks ~3.6 B (large contrast) |
| Helium Seagate (Exos X16–X24 / IronWolf Pro / Mozaic) | quiet 120 Hz + hiss, a bit louder than WD (2.8 B) | loud "clacking", similar to WD helium but users call it louder/"old 20MB drive" like | as WD helium | optional muted irregular idle seeks; head unload click after ~2 min idle | idle 2.8 B, seek 3.2 B |
| Toshiba MG07–MG10 | as helium | heavy seeks, user: "chainsaw" when seeking | as helium | unknown | idle 2.0 B, seek 3.2 B |
| Mach.2 (Exos 2X14/2X18) | as Exos | lighter, quieter impulses, two independent heads | two interleaved virtual heads | as Exos | reportedly quieter than single-actuator 20 TB |

- Under queue-depth-heavy load, helium drives' long seek + 4.17 ms latency gives ~80–170 seeks/s (Exos M datasheet 170 random-read IOPS at QD16), i.e., distinct individual "clacks" rather than the near-continuous buzz of a 15k drive (~250+ seeks/s possible at ~3.4 + 2.0 ms).

### Gaps
- None of these frequency ranges were measured on helium or 10k/15k drives specifically; they should be validated against recordings.

## Openly licensed recordings

### Takeaway
Openly licensed, model-labelled recordings of server/enterprise drives are very scarce: the Klerrp Maxtor Atlas 10K V (CC0) and Fujitsu Allegro 10LX 15k recordings (already in repo) are the only model-labelled ones I found. I found no openly licensed, model-labelled recording of any helium drive or of PWL ticks.

### Cited Findings
- Maxtor Atlas 10K V – 10000rpm – FDB (2006 server drive; close-up spin-up and spin-down), CC0 — [Freesound, Klerrp, #182366](https://freesound.org/people/Klerrp/sounds/182366/) (already in repo)
- Fujitsu Allegro 10LX – 15000rpm – FDB (2008 server drive; spin-up, writing, spin-down) — [Freesound, Klerrp, #182364](https://freesound.org/people/Klerrp/sounds/182364/) (already in repo; license shown as CC0 per repo, listing page did not display it)
- NAS drive running (67 s; "uneven rhythm of my NAS hard drive busy doing a backup", PC fan in background; model not stated), CC0 — [Freesound, phonoflora, #857845](https://freesound.org/people/phonoflora/sounds/857845/)
- Old server turning on and off (older HP ProLiant; long spin, deeper-than-usual drive sound; model unknown), CC0 — [Freesound, pimstoltz, #520722](https://freesound.org/people/pimstoltz/sounds/520722/)
- hum hard drive working server computer process data.wav (coil pickup = electromagnetic, not acoustic), CC0 — [Freesound, JavierZumer, #426059](https://freesound.org/people/JavierZumer/sounds/426059/)
- noisy server computer.wav (file server with several drives and fans, mics inside case; license not verified) — [Freesound, the_toilet_guy, #98930](https://freesound.org/people/the_toilet_guy/sounds/98930/)
- Antec Xeon server with hard drive clicking (old 80 GB ATA drive, not a server-class drive; license not verified) — [Freesound, Vlaxim, #676587](https://freesound.org/people/Vlaxim/sounds/676587/)
- Wikimedia Commons audio search for HDD sounds returned only consumer/failure clips (TOSHIBA HDWR480 spin-up/down, defective IBM Deskstar, WD click of death, WD102AA read retries), none server/helium — [Commons media search](https://commons.wikimedia.org/w/index.php?search=hard+disk+drive+sound&title=Special:MediaSearch&type=audio)
- Freesound searches for "scsi", "exos", "10000rpm" (beyond Klerrp) returned no relevant drive recordings — [Freesound search "exos"](https://freesound.org/search/?q=exos); [Freesound search "10000rpm"](https://freesound.org/search/?q=10000rpm)
- The only PWL recording found (Ultrastar HC510) is on voca.ro with no open license — [Tom's Hardware forum](https://forums.tomshardware.com/threads/new-ultrastar-10tb-hdd-annoying-pwl-noise-what-now-buy-wd-purple-pro-instead-noise-example-included.3798784)

### Inferences
- Helium presets will have to be designed from datasheet levels and user descriptions, or from new recordings made by the project (e.g., a contact-mic or near-field mic on an owned WD Red Pro / Exos, released CC0).

### Gaps
- archive.org advanced search returned mostly unrelated podcasts/transcripts; I could not review all 458 hits.
- No openly licensed recordings of WD Raptor/VelociRaptor, Seagate Cheetah/Savvio, Hitachi Ultrastar 15K, any helium drive, or Mach.2 found.
- Freesound license filters combined with OR broke the search; per-sound license must be checked on each sound page.

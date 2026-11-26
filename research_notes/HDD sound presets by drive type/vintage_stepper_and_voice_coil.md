# Vintage HDD sound presets (1980s to early 1990s): stepper-motor MFM/RLL drives and early voice-coil drives

Scope note: hard disk drives only. "Datasheet" means a manufacturer manual or spec sheet. "Inference" means my own derivation from those numbers. PDF manuals were text-extracted locally (macOS PDFKit) from the OCR layer, so some digits are OCR-garbled; where a digit looked doubtful I say so. No audio files were downloaded or analysed in this pass (see the Gaps under Q5), so there are **no new measured spectra for stepper drives** here. All pitch numbers for stepper buzz are derived from datasheet timing.

## Q1. Stepper-motor drives: mechanism and datasheet timing

### Takeaway
Stepper drives (ST-506/ST-412 family, ST-225/251/277, Miniscribe 8425) position the heads open-loop: a stepper motor drives a band (or rack-and-pinion) actuator, and each interface STEP pulse means one track. Datasheet seek times are slow (track-to-track 3-20 ms, average 28-85 ms, full stroke 95-205 ms), and a large fixed settle time (8-20 ms) sits on top of every seek.

### Cited Findings
**Mechanism**
- ST-506/ST-412: "band actuator and open loop stepper head positioning mechanism". Heads sit on a ball-bearing carriage "positioned by a band actuator connected to the stepper motor shaft", and the stepper motor is thermally isolated from the head/disc assembly. "Each step pulse will cause the heads to move either 1 track in or 1 track out" — [Seagate ST506/ST412 OEM Manual](https://www.minuszerodegrees.net/manuals/Seagate/Seagate%20ST506%20ST412%20-%20OEM%20Manual.pdf)
- A patent describes this drive class as open-loop positioners where "concentric data track locations are defined by stable positional states or detents of the step motor". It names the Shugart SA1000 and Seagate ST-506/ST-412 as examples, and says the SA1000 used a viscous damper because single-track settling was hard — [US4598328A, mechanical damper for band-drive actuators](https://patents.google.com/patent/US4598328) (via search summary)
- ST-225: "Seagate's proprietary helical-band rotary-actuator". The drive has a "custom stepper IC" that does the phase commutation. "Acceleration/deceleration are determined by the varied frequency of the pulses". The manual also describes a "microstep" repositioning option used for error recovery (8 ms settle per microstep attempt) — [Seagate ST225 OEM Manual, Oct 1985](https://www.minuszerodegrees.net/manuals/Seagate/Seagate%20ST225%20-%20OEM%20Manual%20-%20Oct85.pdf)
- Miniscribe 8425 (3.5", about 20 MB, ST-412 interface): a 1987-era vendor description cites a "rack and pinion, linear stepper motor actuator" — [search summary of Miniscribe sources incl. redhill.net.au](https://redhill.net.au/d/11.php); [Miniscribe Product Line 1989](https://ftp.mirrorservice.org/sites/www.bitsavers.org/pdf/miniscribe/brochures/Miniscribe_Product_Line_1989.pdf)

**ST-506 interface step modes (datasheet)**
- ST-506/412 slow seek: "The minimum time between successive steps is 3.0ms. The minimum pulse width is 2.0 usec." — [ST506/412 OEM Manual](https://www.minuszerodegrees.net/manuals/Seagate/Seagate%20ST506%20ST412%20-%20OEM%20Manual.pdf)
- ST-506 "Algorithm Driven Seek" (not on 412): the controller sends pulses faster than 3 ms. The algorithm "accelerates the motor to its maximum speed, steps it slightly less than the desired distance, and then decelerates it prior to arriving on the specified track", keeping a 15 ms settling time — [ST506/412 OEM Manual](https://www.minuszerodegrees.net/manuals/Seagate/Seagate%20ST506%20ST412%20-%20OEM%20Manual.pdf)
- ST-412 buffered seek: the microprocessor captures up to 305 step pulses, accepted until more than 200 µs passes after the last pulse. It then "will begin issuing them to the stepper motor", choosing "the optimum algorithm" for the seek length. "Any pulses issued at a rate between 200 usec and 3 msec may be lost" — [ST506/412 OEM Manual](https://www.minuszerodegrees.net/manuals/Seagate/Seagate%20ST506%20ST412%20-%20OEM%20Manual.pdf)
- ST-225: a pulse period of 5 µs to 200 µs selects Buffered-Seek, and 3 ms or more selects Slow-Step. In buffered mode "Head motion occurs during pulse accumulation". After each pulse the MPU waits 250 µs for more pulses before running the seek, and every new pulse resets that timer. In slow-step mode the heads "move at the rate of the incoming Step pulses", the minimum period is 3 ms, and SEEK COMPLETE comes "20msec max. after the leading edge of the last pulse" — [ST225 OEM Manual](https://www.minuszerodegrees.net/manuals/Seagate/Seagate%20ST225%20-%20OEM%20Manual%20-%20Oct85.pdf)
- Buffered step-rate limits by drive: ST-412 5-500 µs (minuszerodegrees flags a conflict with the manual's 25-200 µs), ST-225 5-200 µs, ST-4038 10-70 µs. All accept slow step at 3 ms or more — [minuszerodegrees: Head stepping in MFM drives](https://www.minuszerodegrees.net/hdd/head_stepping.htm)
- ST-251: buffered step pulse rate 3-200 µs — [Lo-tech wiki ST-251](https://www.lo-tech.co.uk/wiki/Seagate_ST-251). The ST251N/ST277N manual computes its seek specs "with a step pulse period of 10 µsec" — [ST251N/ST277N Product Manual, Mar 1987](https://ftp.mirrorservice.org/sites/www.bitsavers.org/pdf/seagate/scsi/36034-001B_ST251N_ST277N_Product_Manual_Mar87.pdf) (via search summary)

**Datasheet timing table (stepper drives)**

| Drive | Cyl | rpm | Track-to-track | Average | Full stroke | Settle | Source |
|---|---|---|---|---|---|---|---|
| ST-412 (10 MB, FH 5.25") | 306 | 3600 | 3 ms | 85 ms | 205 ms | 15 ms | [OEM manual](https://www.minuszerodegrees.net/manuals/Seagate/Seagate%20ST506%20ST412%20-%20OEM%20Manual.pdf) |
| ST-506 (5 MB) | 153 | 3600 | 3 ms | 85 ms | 205 ms | 15 ms | same |
| ST-225 (20 MB, HH) | 615 (+ship zone 615-670) | 3600 | 20 ms (OCR of Seagate manual reads "10.0", other copies say 20) | 65 ms (over 1/3 stroke, 205 tracks) | 150 ms | 20 ms max (slow step) | [OEM manual](https://www.minuszerodegrees.net/manuals/Seagate/Seagate%20ST225%20-%20OEM%20Manual%20-%20Oct85.pdf); 20 ms t-t in [Olivetti M24 manual](https://hadesnet.org/olivettim24/docs/st225.pdf) and [Tech Page](https://thetechpage.mirror.kb1max.com/cgi-bin/db/db.cgi_displayItem=117) (via search summary) |
| ST-251 (40 MB) | 820 | 3600 | 8 ms | 40 ms (ST251-0/-1: 28 ms) | unclear ("70" in table) | n/a | [Lo-tech](https://www.lo-tech.co.uk/wiki/Seagate_ST-251) |
| ST-277N (63 MB SCSI) | 820 | 3600 | 8 ms max | 40 ms max | 95 ms max | n/a | [ST251N/277N manual](https://ftp.mirrorservice.org/sites/www.bitsavers.org/pdf/seagate/scsi/36034-001B_ST251N_ST277N_Product_Manual_Mar87.pdf) (via search summary) |
| Miniscribe 8425 (3.5", 20 MB) | n/a | 3600 | 15 ms (8425S) | 68 ms (8425F: 40 ms) | n/a | n/a | [Miniscribe 1989 line](https://ftp.mirrorservice.org/sites/www.bitsavers.org/pdf/miniscribe/brochures/Miniscribe_Product_Line_1989.pdf), [8425S brochure](https://ftp.mirrorservice.org/sites/www.bitsavers.org/pdf/miniscribe/brochures/Miniscribe_8425S_Brochure.pdf) (via search summary); rpm from [86Box assets profile](https://github.com/86Box/assets/blob/master/sounds/hdd/hdd_audio_profiles.cfg) |

- 86Box's ST-225 timing preset is 65 ms full stroke, 8 ms track-to-track, 3600 rpm. That conflicts with Seagate's 150 ms full stroke and 20 ms track-to-track — [86Box hdd.c presets, as recorded in existing repo notes](https://github.com/86Box/86Box/blob/master/src/disk/hdd.c)
- Stepper drives in general had seek times of 80-120 ms before voice coils brought them to about 20 ms — [Wikipedia: HDD performance characteristics](https://en.wikipedia.org/wiki/Hard_disk_drive_performance_characteristics) (via search summary)
- Acoustic level: ST-506/412 "Max Accoustic Output: 50 DBA". The extracted text gives no distance — [ST506/412 OEM Manual](https://www.minuszerodegrees.net/manuals/Seagate/Seagate%20ST506%20ST412%20-%20OEM%20Manual.pdf)

**Power-up recalibration, parking, spindle**
- ST-506/412: "A speed sense circuit counts 512 disc revolutions before recalibrating the heads to track 0." At 3600 rpm that is 8.5 s. TRACK 0, SEEK COMPLETE and READY then go true in sequence — [ST506/412 OEM Manual](https://www.minuszerodegrees.net/manuals/Seagate/Seagate%20ST506%20ST412%20-%20OEM%20Manual.pdf)
- ST-412 test jumper: with shunt "H" cut, "ST412 will continually seek from TK0-305". The ST-225 has a similar jumper (pins 7-8) where "the stepper motor will continuously seek between Track 0" and the far end — [ST506/412 OEM Manual](https://www.minuszerodegrees.net/manuals/Seagate/Seagate%20ST506%20ST412%20-%20OEM%20Manual.pdf); [ST225 OEM Manual](https://www.minuszerodegrees.net/manuals/Seagate/Seagate%20ST225%20-%20OEM%20Manual%20-%20Oct85.pdf)
- ST-225 power-up: the spindle runs bipolar for about 40 revolutions, then switches to unipolar. The MPU checks the index period before recalibrating. The drive has no Track-0 sensor: "The MPU then seeks in multiples of eight tracks until it finds Track 617 and Track minus 1" (reference tracks), then "steps in one track from track minus 1" to set Track 0. Ready in "24 seconds max. after power-up" — [ST225 OEM Manual](https://www.minuszerodegrees.net/manuals/Seagate/Seagate%20ST225%20-%20OEM%20Manual%20-%20Oct85.pdf)
- ST-225 parking is manual. The shipping zone is cylinders 615-670, and heads are parked "by issuing a seek to any cylinder between 615-670". If the heads are parked while power is on, the next step pulse triggers a recalibration to Track 0 — [ST225 OEM Manual](https://www.minuszerodegrees.net/manuals/Seagate/Seagate%20ST225%20-%20OEM%20Manual%20-%20Oct85.pdf)
- ST-251 "automatically parked disk heads on power down" — [Lo-tech wiki](https://www.lo-tech.co.uk/wiki/Seagate_ST-251)
- ST-225 index pulse once per revolution (16.67 ms) at 3600 rpm ±1%. ST-506/412 spindle: "A brushless DC drive motor rotates the spindle at 3600 rpm" — [ST225 OEM Manual](https://www.minuszerodegrees.net/manuals/Seagate/Seagate%20ST225%20-%20OEM%20Manual%20-%20Oct85.pdf); [ST506/412 OEM Manual](https://www.minuszerodegrees.net/manuals/Seagate/Seagate%20ST506%20ST412%20-%20OEM%20Manual.pdf)

### Inferences
- **Seek time is close to linear in distance for steppers, with a big intercept.** ST-225: going from the 205-track average (65 ms) to the 614-track full stroke (150 ms) gives a slope of about 0.21 ms per track and an intercept of about 22 ms. That intercept matches the 20 ms settle, so roughly t ≈ 22 ms + 0.21 ms × N. ST-412: (205-85)/(305-102) ≈ 0.59 ms/track, intercept about 25 ms (15 ms settle plus ramp). ST-277N: if the average is taken over 1/3 stroke (273 tracks; not stated in the snippet), the slope is about 0.10 ms/track and the intercept about 13 ms. A linear model fits steppers better than the sqrt-like model used for voice coils, because the motor spends most of a long seek at a fixed maximum slew rate.
- **Mean track rate during a buffered seek** (inference, upper bound because settle and ramps are folded in): ST-412 about 1.6-1.7 kHz (0.6 ms/track), ST-225 about 4.7 kHz (0.21 ms/track), ST-277N about 9-10 kHz (0.1 ms/track). The ST-225/251 class has 600-820 tracks on a band actuator, and the ST-225 manual mentions microstepping, so one track may be less than one full motor step. The audible commutation rate may therefore be lower than the track rate. This is unverified (see Gaps).

### Gaps
- No datasheet found for ST-238R, ST-4096, Tandon TM262 or ST-412's successor drives in this pass. Search results gave nothing citable for ST-4096 sound or timing. ST-238R is commonly described as the RLL version of the ST-225, but that is unsourced here.
- Motor step angle, steps per track, and the internal acceleration profile (pulse-period table) of buffered seeks are not in the manuals I read. Seagate Application Note ST-001 (referenced in the ST-506 manual) probably has it, but I did not find it.
- The ST-225 track-to-track value is uncertain: OCR says 10.0 ms, other copies say 20 ms.

## Q2. Stepper seek sound: step rate, pitch, distance scaling, recal, spindle

### Takeaway
A stepper seek is a train of discrete step impulses. In slow-step mode (3 ms period) that is a 333 Hz buzz lasting N × 3 ms, which is long (about 0.9 s for a 300-track seek). In buffered mode the drive's own MPU ramps the step rate up and back down, so the sound is a short pitch-swept "fweep/zzzt" whose length grows linearly with distance and whose top pitch is in the low-kHz range. Enthusiasts describe stepper drives as loud and "fweep"-like, with a knocking power-up recalibration.

### Cited Findings
- "A lot of older hard drives made a soft 'fweep fweep fweep' as the heads were actuated by a stepper motor". Drives with servomotors made "tik-tik-tik" — HN user bitwize, [Hacker News thread on an HDD clicker gadget](https://news.ycombinator.com/item?id=44538819)
- In the same thread: "The HDD sound is much deeper" than the gadget's click, and drives' noises "come in many registers" — [Hacker News](https://news.ycombinator.com/item?id=44538819)
- ST-251 is "noisy in operation" — [Lo-tech wiki](https://www.lo-tech.co.uk/wiki/Seagate_ST-251). Its startup has "a characteristic head-bang noise when starting up", which the blogger attributes to "the head calibration process in order to find track0" — [Hack Something Tonight](http://hacksomethingtonight.blogspot.com/2011/02/vintage-hard-drives-seagate-st-251.html). Others call it a "hollow knocking sound" and the ST-251 family "my favorite stepper-motor sound of all time" — forum posts via search summary ([VOGONS ST-251 thread](https://www.vogons.org/viewtopic.php?t=92047), [exxos forum](https://www.exxosforum.co.uk/forum/viewtopic.php?t=6087)). I did not verify these quotes on the pages themselves.
- A VOGONS ST-251 thread notes that during a seek test "you can hear the heads moving", even unformatted — [VOGONS](https://www.vogons.org/viewtopic.php?t=92047) (via search summary)
- A commenter says the head stepper of 5.25" MFM drives could be felt through a table — [Hackaday](https://hackaday.com/2022/09/26/tiny-dongle-brings-the-hard-drives-song-back-to-updated-retrocomputers) (from existing repo notes)
- Slow-step minimum period of 3 ms (ST-506/412/225) and buffered-mode internal acceleration and deceleration: see Q1 citations — [ST506/412 manual](https://www.minuszerodegrees.net/manuals/Seagate/Seagate%20ST506%20ST412%20-%20OEM%20Manual.pdf), [ST225 manual](https://www.minuszerodegrees.net/manuals/Seagate/Seagate%20ST225%20-%20OEM%20Manual%20-%20Oct85.pdf)
- ST-225 recalibration seeks "in multiples of eight tracks" to find reference tracks — [ST225 manual](https://www.minuszerodegrees.net/manuals/Seagate/Seagate%20ST225%20-%20OEM%20Manual%20-%20Oct85.pdf)

### Inferences
- **Slow-step (controller-paced) gesture**: impulse train at exactly 1/3 ms = 333 Hz (or 1/T for any T ≥ 3 ms), N impulses for N tracks, then a 15-20 ms settle ring. Duration ≈ 3 ms × N + 15-20 ms, for example 0.33 s for 100 tracks and 0.94 s for a 306-track ST-412 full stroke. Each impulse is a strong low-mid "tok" because the motor snaps into a detent, and spacing it every 3 ms gives a buzzy 333 Hz tone with harmonics at 667 Hz, 1 kHz and up. This matches the brief's "3 ms/step = 333 Hz" example, and it is the right model for ST-506 drives and for controllers configured for slow step.
- **Buffered gesture (ST-412 and later)**: a chirp. The step rate rises from a low starting rate, plateaus at the motor's maximum, then falls before the target, followed by settle. Short seeks never reach the plateau (short "fwip", lower top pitch). Long seeks hold the plateau ("fweeeeep", or "zzzt" if the plateau is long). The HN "fweep" description fits a rising-then-falling pitch. Suggested parameters, derived from Q1 mean rates:
  - ST-412-like: start rate about 300-500 Hz, plateau about 2 kHz, mean about 1.6 kHz; duration ≈ 25 ms + 0.6 ms × N (full stroke 205 ms).
  - ST-225/238-like: plateau about 4-5 kHz if each track is one impulse (or proportionally lower if several tracks share one full step); duration ≈ 22 ms + 0.21 ms × N (full 150 ms).
  - ST-251/277-like: duration ≈ 10-13 ms + 0.1 ms × N (full about 95 ms). The track rate is about 10 kHz, so the audible content is probably the commutation rate, a lower but unknown fraction of that.
  - At plateau rates above about 1-2 kHz, individual impacts fuse into a tone. Synthesize it as a dense impulse train driving the modal bank, or as a tone plus noise, rather than as separate strikes. The chirp sweeping through the bank's modes (for example the Conner-like 0.76/1.89/2.72 kHz modes) will "whoop" as it passes each resonance.
- **Single-track step**: one impulse plus a long settle ring. Settle is 15 ms (ST-412) or 20 ms (ST-225) versus about 1-3 ms on later drives, so use a lower-damped, longer actuator ring (perhaps 15-20 ms to -20 dB) and a heavier low-frequency thump. Track-to-track 3-20 ms means sequential reads produce a slow tick.
- **Power-up sequence** (stepper preset): spindle spin-up (ST-412 counts 512 revolutions, about 8.5 s, before recalibrating; ST-225 up to 24 s until ready). Then the recalibration: ST-225 does a series of 8-track hops (eight short bursts, each like an 8-track buffered seek) out to the reference track, then 1 step. ST-412 steps back to Track 0. Enthusiasts hear this as a "head-bang"/"hollow knock", possibly the carriage hitting its outer stop. Parking on shutdown is either a single long seek inward to the ship zone (ST-225 park utility) or an automatic park (ST-251).
- **Spindle**: 3600 rpm means a 60 Hz rotation fundamental and harmonics (16.67 ms period). For a 1980s FH/HH drive, add a stronger 60/120/180 Hz component than modern drives, plus a bearing hiss. ST-225 spin-up switches from bipolar to unipolar drive after about 40 revolutions, which may give an audible change in motor tone early in spin-up (unverified).
- **Loudness**: ST-412 at a max of 50 dBA, against the Conner CP3104 at a max of 40 dBA at 1 m (Q3), suggests a stepper preset should be noticeably louder (perhaps +6 to +10 dB) than the 1990 voice-coil preset. This is a cross-spec comparison, and the ST-412 measurement distance is unknown.

### Gaps
- **No measured buzz frequency for any real stepper drive.** The CC0 ST-277N recording (Q5) is the obvious source to measure the chirp's start, plateau and decay pitches; it was not downloaded in this pass.
- No source states steps per track, step angle or the commutation rate at slew, so it is unknown whether the audible pitch equals the track rate.
- No source quantifies the spindle tone spectrum (motor pole count and whine frequencies) of stepper-era drives.

## Q3. Late-1980s / early-1990s voice-coil drives: timing, mechanics, TCAL, stiction, spin-up

### Takeaway
Rotary voice-coil drives of 1987-1993 run at 3400-3600 rpm (IBM 0663 at 4316 rpm). They have 4-8 ms track-to-track, 19-26 ms average and 35-50 ms full-stroke seeks, are rated at ≤40 dBA at 1 m (Conner), and park and latch automatically. Characteristic sounds are a start/stop "clack" per seek, a startup seek test ("click pattern"), and periodic thermal recalibration sweeps of about 1 s on dedicated-servo drives (often after power-on, then every 20-30 min).

### Cited Findings
**Timing table (datasheet or spec listing)**

| Drive | Year | Actuator | Cyl | rpm | Track-to-track | Average | Full | Source |
|---|---|---|---|---|---|---|---|---|
| Maxtor XT-1140 (FH 5.25", MFM, 120 MB) | late 1980s | rotary voice coil | 918 (15 heads) | 3600 | <4 ms | 26 ms | n/a | [stason.org](https://stason.org/TULARC/pc/hard-drives-hdd/maxtor/XT-1140-120MB-5-25-FH-MFM-ST506.html) (via search summary) |
| Micropolis 1355 (FH 5.25", ESDI, 151 MB) | about 1987 | not stated on page | 1024 (8 heads) | 3600 ±0.5% | 5 ms | 23 ms | n/a | [Micropolis support](https://www.micropolis.com/support/hard-drives/1355) |
| Conner CP3044 (3.5") | about 1989 | voice coil | n/a | 3557 | n/a | 25 ms | 50 ms | [computerhope / Conner manual](https://www.computerhope.com/hdd/hdd0036.htm) (via search summary) |
| Conner CP3104 (3.5", 104 MB) | 1988-90 | rotary voice coil, embedded servo | 776 | 3575 | 8 ms | 25 ms | 45 ms | [Conner CP3104 Product Manual 1990](https://ftp.mirrorservice.org/sites/www.bitsavers.org/pdf/conner/disk/00501-023_Conner_CP3104_Product_Manual_199008.pdf) |
| Conner CP30104 (3.5") | 1991 | voice coil | n/a | 3400 | 8 ms | <19 ms | 35 ms | [Conner CP30064/84/104 manual](https://ftp.mirrorservice.org/sites/www.bitsavers.org/pdf/conner/disk/00501-045_Conner_CP30064_CP30084_CP30104_Product_Manual_199107.pdf) (via search summary; one text summary says 45 ms max) |
| IBM 0663 (3.5" SCSI, 1 GB) | about 1991 | n/a | n/a | 4316 (6.95 ms latency) | n/a | n/a | n/a | [IBM 0663 spec sheet](https://ftp.hanmesoft.com/OS2/PS2Mafia2000/pdf/Common/ibm_0663-x.pdf) (via search summary) |
| Seagate ST3120A (3.5" IDE) | 1992 | n/a | n/a | 3211 | n/a | n/a | n/a | [86Box assets profile](https://github.com/86Box/assets/blob/master/sounds/hdd/hdd_audio_profiles.cfg) |
| Conner CFS420A (existing repo baseline) | 1993 | voice coil | n/a | 3600 | n/a | n/a | n/a | [Freesound 155882](https://freesound.org/people/Klerrp/sounds/155882/) |

**Conner CP3104 mechanics (datasheet)**
- "High performance rotary voice coil actuator with embedded servo system", and "Automatic actuator latch against inner stop upon power down". "At power down the heads are automatically retracted to the inner diameter of the disk and are latched and parked on a landing zone". "A dynamic brake is used to provide a fast stop to the spindle motor and return the heads to the landing zone" — [CP3104 Product Manual](https://ftp.mirrorservice.org/sites/www.bitsavers.org/pdf/conner/disk/00501-023_Conner_CP3104_Product_Manual_199008.pdf)
- Start time (0 rpm to ready) is 15 s typical and 20 s max. Stop time is 15 s typical and 20 s max. The drive runs "Microprocessor controlled diagnostic routines that are automatically executed at start up" — [CP3104 manual](https://ftp.mirrorservice.org/sites/www.bitsavers.org/pdf/conner/disk/00501-023_Conner_CP3104_Product_Manual_199008.pdf)
- Acoustic: "The sound pressure level will not exceed 40 dBA at a distance of 1 meter" — [CP3104 manual](https://ftp.mirrorservice.org/sites/www.bitsavers.org/pdf/conner/disk/00501-023_Conner_CP3104_Product_Manual_199008.pdf)
- The average seek is the mean of at least 1000 random-length seeks. The drive has 4 disks of 95 mm and 8 heads — [CP3104 manual](https://ftp.mirrorservice.org/sites/www.bitsavers.org/pdf/conner/disk/00501-023_Conner_CP3104_Product_Manual_199008.pdf)

**Thermal recalibration, startup seek test, stiction**
- 1993 Usenet: a momentary sound like "the drive has been given a seek command" is a "periodic thermal calibration sweep" on drives with a dedicated servo platter. It happens often right after power-on and less often later, "every 20 or 30 minutes", with "a second or so duration". Drives with embedded servo "will do a calibration sweep at power-on" — [comp.periphs.scsi archive post 6705](https://discmaster.textfiles.com/view/28249/NN_1993_3.iso/spool/comp/periphs/scsi/6705). Another post says the sweeps happen whether or not the drive is in use — [post 6779](https://discmaster.textfiles.com/view/28249/NN_1993_3.iso/spool/comp/periphs/scsi/6779) (via search summary)
- Modern note: drives now tend to wait for idle before recalibrating, and a recalibration pauses I/O — [Sweetwater](https://www.sweetwater.com/insync/thermal-recalibration/) (via search summary)
- Quantum ProDrive LPS/ELS (40-500 MB, firmware dated 1992-93): AIRLOCK "keeps the head stack latched in place near the spindle until the drive spins up". A healthy drive produces "the familiar click pattern that Quantum hard drives make as they're running their seek test" at startup. Failing drives have degraded rubber crash-stop bumpers, so "The voice coil motor ... isn't strong enough to overcome this sticky rubber", and the drive spins down "after a few seconds" with no click pattern. There are two bumpers, one at the park position and one at the outer edge — [downtowndougbrown.com](https://downtowndougbrown.com/2025/03/the-gooey-rubber-thats-slowly-ruining-old-hard-drives). The same post mentions that failing Conner drives make "a repeated tone between retries" — same source
- Micropolis 2105 (560 MB, 5400 rpm, 1990s): spin-up is followed by "its head alignment procedure" — [Freesound 637061](https://freesound.org/people/micropolis/sounds/637061/)

### Inferences
- **Voice-coil seek duration vs distance** (CP3104: 8 / 25 / 45 ms) lies between linear and sqrt. A linear fit through 8 ms at 1 track and 45 ms at 775 tracks predicts 20 ms at 1/3 stroke; a sqrt fit predicts 29 ms; the datasheet says 25 ms. A power law t ≈ t_tt + k × N^0.7 fits reasonably (inference). Use a sqrt-to-0.7 law with t_tt = 4-8 ms and full stroke 35-50 ms for the 1988-1991 preset. That is about 1.5-2× the 1992 86Box preset (30 ms full / 6 ms t-t) and about 2-3× modern drives.
- **Spindle**: 3400-3600 rpm gives a 56.7-60 Hz fundamental (CP30104 at 56.7 Hz, CP3104 at 59.6 Hz, CP3044 at 59.3 Hz). IBM 0663 at 4316 rpm gives 71.9 Hz, and ST3120A at 3211 rpm gives 53.5 Hz. The existing CFS420A analysis found a 60 Hz idle peak plus whine tones at 1080/2004/3466 Hz, so a "1990 3.5-inch" preset can reuse that structure with the fundamental moved per model.
- **Startup**: spin-up of 15-20 s (CP3104 ready time; the 86Box ST3120A asset is about 1.2-1.9 MB of audio for spin-up, so several seconds), then an unlatch click (AIRLOCK or magnetic latch release), then a short startup seek test of a few distinct clacks (Quantum "click pattern"; the CFS420A "seek test" is periodic at about 17/s). Shutdown is a park "clack" against the inner stop (CP3104 latches at the inner stop) plus dynamic-brake spin-down.
- **TCAL preset event**: on an idle timer (first few minutes after start frequent, then every 20-30 min), play a burst of about 1 s of seeks. The sweep content is not described in the sources; model it as a handful of seeks to several radii with short dwell. Only for "dedicated servo" models (larger 5.25" voice-coil drives such as Maxtor and Micropolis). Embedded-servo 3.5" drives (Conner CP3104) only do this at power-on.
- **Timbre**: larger and heavier 5.25" full-height voice-coil actuators (Maxtor XT, Micropolis 13xx) probably produce lower, chunkier "clack/chunk" strikes than the 3.5" Conner. Without measurements, scale the CFS420A modes down by about 0.7-0.8× and lengthen decay for a 5.25" FH preset (pure inference based on size).

### Gaps
- No datasheet values found in this pass for Quantum ProDrive LPS 105/52, Maxtor XT-2190, Seagate voice-coil ST-1xx/ST-4xxx models, early WD Caviar or IBM 0663 seek times (only its rpm).
- Micropolis 1355 actuator type is not stated on the page found.
- No quantitative acoustic description (spectra) of TCAL, of 5.25" voice-coil seeks, or of stiction "release" sounds.

## Q4. Stepper vs voice-coil seek gesture structure, and comparison with the Conner CFS420A baseline

### Takeaway
A stepper seek is a pulse train (N impulses, rate 333 Hz in slow step up to kHz in buffered mode, with an accelerate-plateau-decelerate pitch contour) whose duration is linear in distance and carries a 15-20 ms settle tail. A voice-coil seek is two strikes (an acceleration jerk at start and a deceleration and settle at end) separated by a sub-linear travel time of 4-50 ms, with silence or a faint whoosh between.

### Cited Findings
- Each STEP pulse equals one track. Slow step paces the head at the pulse rate (min 3 ms). Buffered and algorithm seeks accelerate, run at max speed and decelerate — [ST506/412 OEM Manual](https://www.minuszerodegrees.net/manuals/Seagate/Seagate%20ST506%20ST412%20-%20OEM%20Manual.pdf); [ST225 OEM Manual](https://www.minuszerodegrees.net/manuals/Seagate/Seagate%20ST225%20-%20OEM%20Manual%20-%20Oct85.pdf)
- Stepper "fweep" vs servo "tik-tik-tik" — [Hacker News](https://news.ycombinator.com/item?id=44538819)
- Existing repo baseline (Conner CFS420A, 1993, 3600 rpm): largest seek excess peak at 264 Hz, then 1.89 kHz (-9 dB), 764 Hz (-10) and 2.72 kHz (-12). The 150-400 Hz thump peaks 7 ms after onset. Broadband T60 is about 38-40 ms. The seek test is periodic at a 58 ms inter-onset interval. A 20 ms event window measures +5.7 dBA — [Freesound 155882](https://freesound.org/people/Klerrp/sounds/155882/) (from `research_notes/Realistic HDD sound synthesis/real_recordings_analysis.md`)
- Voice-coil seek noise comes from abrupt VCM current changes at seek start and end — patents summarized in existing repo notes (`impact_synthesis_techniques.md`)

### Inferences
Quantified comparison for preset design:

| Property | Stepper, slow step (ST-506) | Stepper, buffered (ST-412/225/251) | Voice coil 1988-91 (CP3104, XT-1140) | Conner CFS420A 1993 (baseline) |
|---|---|---|---|---|
| Force events per seek | N impulses (one per track) | N impulses, rate-ramped (or a fused tone) | 2 (start jerk, stop/settle) | 2 |
| Event rate within seek | 333 Hz (3 ms) | ramp to a plateau of about 1.6 kHz (ST-412) to several kHz (ST-225/251), see Gaps | n/a | n/a |
| Duration law | 3 ms × N + 15-20 ms | about 22-25 ms + (0.1-0.6 ms) × N | about t_tt + k·N^0.5-0.7; 4-8 ms → 35-50 ms | about 6 ms → 30 ms (86Box 1992 preset) |
| 1-track | 3 ms + 15 ms settle | 3-20 ms (ST-412 3 ms, ST-251 8, ST-225 20) | 4-8 ms | about 6 ms |
| Full stroke | 0.9 s (306 tracks) | 95-205 ms | 35-50 ms | about 30 ms |
| Max seeks/s (back-to-back average) | about 3-5 | about 12-25 (1/avg: 85 ms → 12/s, 40 ms → 25/s) | about 40 (1/25 ms) | about 17/s observed in the seek test |
| Spindle | 3600 rpm, 60 Hz | 3600 rpm, 60 Hz | 3400-3600 rpm (4316 for IBM 0663) | 3600 rpm, 60 Hz |
| Relative level | loud (ST-412 ≤50 dBA) | loud ("noisy") | ≤40 dBA at 1 m (CP3104) | +4-6 dBA seek over idle (measured) |

- **Synthesis recipe, stepper**: for each virtual-head move of N tracks, schedule N force pulses on the resonator bank with an inter-pulse period that follows a trapezoidal rate profile: start at T0 (about 1-3 ms), shrink linearly in rate to T_min (0.2-0.6 ms) over the first about 10-20% of tracks, hold, then mirror the ramp. Then add a settle "tok" plus ring (15-20 ms). Keep each pulse's force low enough that a dense train stays below the click level of a single step. Above about 1 kHz pulse rate, consider swapping to a band-limited tone source to save CPU. Distance changes duration and whether the plateau is reached; it does not change the onset count of a voice-coil gesture.
- **Synthesis recipe, early voice coil**: reuse the existing two-strike model with longer travel times (above), a heavier low "chunk" (raise the 264 Hz-style thump relative to clicks, longer decay), and settle rings of about 5-10 ms. Add TCAL and startup seek-test events.
- **Versus Conner CFS420A**: the CFS420A (1993, 3.5") is the late end of this era. A 1988-91 voice-coil preset should be similar in mode structure but slower (25 ms average vs about 15-19 ms) and, for 5.25" full height, lower-pitched and louder. A stepper preset is structurally different, because the seek energy is a tonal chirp rather than two transients.

### Gaps
- No measured spectrum confirming the stepper chirp contour or plateau pitch, and no measurement of how loud a stepper seek is relative to its spindle.

## Q5. Openly licensed recordings and 86Box samples

### Takeaway
One strong openly licensed stepper-era recording exists: Freesound 475216, a CC0 1980s Seagate ST-277N (6.5 min, 96 kHz, power-up, use, power-down). Several CC0/CC BY early-to-mid-1990s voice-coil clips also exist. Wikimedia Commons has no vintage (pre-2000) HDD audio. 86Box's HDD samples (Miniscribe 8425, Seagate ST3120A, IBM H3171, Quantum Bigfoot) are **not** openly licensed.

### Cited Findings
**Freesound (license read from each page's Creative Commons link)**

| ID | Drive / content | License | Length, rate | Notes |
|---|---|---|---|---|
| [475216](https://freesound.org/people/jodybruchon/sounds/475216/) | "1980s Seagate ST277N 63MB SCSI hard drive being powered up, used for a while, and powered down" | CC0 | 6:30, 96 kHz | Stepper drive (ST251N/ST277N manual cites Seagate's own "stepper motor manufacturing" — [manual](https://ftp.mirrorservice.org/sites/www.bitsavers.org/pdf/seagate/scsi/36034-001B_ST251N_ST277N_Product_Manual_Mar87.pdf), via search summary). Best source for stepper chirp, recal and spindle. |
| [493891](https://freesound.org/people/Crinkem/sounds/493891/) | "An old hard drive starting up", idle; model not given; fan rumble partly removed | CC0 | 0:26, 96 kHz | Unknown era |
| [262872](https://freesound.org/people/jaegrover/sounds/262872/) | 1995 Compaq desktop HDD: power up/down, whirring, clicking, "memory access" | CC0 | 0:20, 96 kHz | Mid-90s voice coil |
| [554672](https://freesound.org/people/Exacom/sounds/554672/) | "Old Hard Drive Spin Up and Spin Down", model not given | CC0 | 1:10, 44.1 kHz | Spindle only (by title) |
| [637061](https://freesound.org/people/micropolis/sounds/637061/) | Micropolis 2105 560 MB in 1990s SCSI enclosure: switch-on, spin-up to 5400 rpm, "head alignment procedure"; noisy (fan, case) | CC BY 4.0 | 0:09, 48 kHz | Startup calibration reference |
| [637063](https://freesound.org/people/micropolis/sounds/637063/) | Micropolis 3243S 4 GB 3.5" SCSI-2 7200 rpm (1990s): power on, spin up, head alignment | CC0 | 0:20, 44.1 kHz | Mid/late 90s |
| [637062](https://freesound.org/people/micropolis/sounds/637062/) | Loopable drone of 1990s SCSI enclosure with Micropolis 2105 | CC BY 4.0 | 0:18, 44.1 kHz | Includes fan |
| [513972](https://freesound.org/people/Masman8675/sounds/513972/) | "PC from the 90s starting up": fan, hard drive clicking, POST beep | CC BY 3.0 | 0:24, 44.1 kHz | Mixed sources |
| [155882](https://freesound.org/people/Klerrp/sounds/155882/) | Conner CFS420A 1993 3600 rpm seek test (already analysed in repo) | CC0 | n/a | Baseline |

- Freesound text searches for "MFM", "ST-225", "miniscribe", "stepper hard drive", "RLL hard drive", "quantum prodrive" and "full height hard drive" returned no relevant drive recordings (own search via freesound.org search pages).
- Wikimedia Commons file search (audio, several English and German queries) returned only the five post-2000 HDD clips already in the repo — own query of the [Commons API](https://commons.wikimedia.org/w/api.php)

**86Box HDD audio assets**
- Repository `86Box/assets`, `sounds/hdd/` holds four profiles: "Miniscribe 8425, 3600 RPM, 1987", "IBM H3171, 3600 RPM, 1993", "Seagate ST3120A, 3211 RPM, 1992" and "Quantum Bigfoot 2110AT, 3600 RPM, 1997". Each has spin-up, running loop, spin-down and a single `SEEK_1TRACK` sample (the ST3120A also has "SpinUp with initializing"). Seek sample sizes are about 10-17 KB, which is a fraction of a second — [hdd_audio_profiles.cfg](https://github.com/86Box/assets/blob/master/sounds/hdd/hdd_audio_profiles.cfg) (listed via GitHub API)
- License: "All files in this repository are property of their respective copyright owners, and are made available here in the interest of preservation. There is no warranty of any sort". GitHub reports license "Other / NOASSERTION" — [86Box/assets LICENSE](https://github.com/86Box/assets/blob/master/LICENSE). So **not CC0/CC BY; reference listening only, not bundling.**
- The ST3120A sounds were contributed in a Sept 2026 PR, and the rpm was later corrected from 3600 to 3211 — [86Box/assets commit history](https://github.com/86Box/assets/commits/master/sounds/hdd)
- 86Box loads these via `assets/sounds/hdd/hdd_audio_profiles.cfg` and plays one seek sample per cylinder change, not distance-dependent. The source header reads "Copyright 2026 Toni Riikonen" — [86Box hdd_audio.c](https://github.com/86Box/86Box/blob/master/src/disk/hdd_audio.c)

### Inferences
- 86Box uses one 1-track seek sample even for the stepper Miniscribe profile, so it cannot reproduce a stepper "fweep" on long seeks. Whirr's per-step impulse train would be a real improvement in authenticity.
- The ST-277N CC0 clip is the single most valuable next analysis target. Measure (a) the plateau pitch and ramp duration of long seeks, (b) the 1-track click spectrum and settle ring, (c) the power-up recal pattern, and (d) the 60 Hz harmonics and motor whine.

### Gaps
- **Held step:** downloading the Freesound clips (or the 86Box WAVs) for local spectral analysis needs the user's go-ahead under this session's file-download rule. It was not done, so no measured numbers for stepper or early voice-coil drives are given. Recommended files: Freesound 475216 (ST-277N, CC0, 96 kHz WAV), 637061/637063 (Micropolis), 262872 (Compaq 1995).
- archive.org was not searched (budget). YouTube description text was not mined.
- No openly licensed recording found for any specific ST-225/ST-251/ST-412, Miniscribe, Tandon, Maxtor XT, Micropolis 13xx, Quantum ProDrive or early Conner CP30xx drive.

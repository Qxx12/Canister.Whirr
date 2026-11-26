# Small form factor HDDs (2.5" laptop, 1.8" / 1" microdrive, USB portable): mechanics, timing, acoustics, recordings

Scope: 2.5" laptop drives 1995–2015, 1.8" iPod-class drives and 1" Microdrives, and 2.5" USB portable drives, plus ramp load/unload parking and Apple's Sudden Motion Sensor. Hard drives only.

Labels used below:
- **[DS]** is a manufacturer datasheet or manual.
- **[MEAS]** is an independent measurement (SPCR).
- **[USER]** is a forum or user description.
- **[SUMMARY]** means the figure came from a search-engine summary of a third-party mirror and the PDF itself was not opened.
- Anything under "Inferences" is my reasoning, not a sourced fact.

Method note: SPCR pages return a Cloudflare challenge to direct fetches, but Wayback Machine copies work. Many Hitachi and Fujitsu datasheet mirrors (manualmachine) return HTTP 403. I opened the Seagate Momentus 5400.6 manual and IBM's Microdrive Hot Chips slides in full. Wikimedia Commons (audio and video) and archive.org were searched through their APIs and gave no usable small-drive recordings. Freesound gave several, listed in the recordings section.

## 1. Datasheet timing, sound power and head load/unload behaviour

### Takeaway
2.5" drives typically quote these figures:
- Track-to-track seek of about 1–1.5 ms.
- Average seek of 10–15 ms. The 7200 rpm drives sit near 10 ms; the 4200/5400 rpm drives sit at 12–15 ms.
- Full-stroke seek of 18–30 ms.
- Sound power of about 1.7–2.6 B at idle and 2.1–3.0 B in seek. That is roughly 0.3–0.6 B (3–6 dB) quieter than contemporary 3.5" drives.

1.8" and 1" drives run at 3600–4500 rpm with an average seek of 11–15 ms. All of these classes use ramp load/unload, rated at about 600,000 cycles, and their power-management idle states park the heads on the ramp while the spindle keeps turning.

### Cited Findings
**2.5" laptop drives, timing**
- Seagate Momentus 5400.6 (2008–09, 2 discs and 3–4 heads, 98.8 g) [DS]:
  - 5,400 rpm with 5.56 ms average latency.
  - Track-to-track read 1 ms typical, average read 14 ms typical, full-stroke read 30 ms max.
  - Power-on to ready 3.6 s typical, standby to ready 1.8 s typical.
  - Operating shock 350 G at 2 ms.
  - [Seagate Momentus 5400.6 SATA Product Manual Rev. E](https://www.seagate.com/staticfiles/support/disc/manuals/notebook/momentus/5400.6%20(Wyatt)/100528359e.pdf)
- Hitachi Travelstar 7K100 (7200 rpm, 2005) [SUMMARY of the Hitachi spec manual mirror]:
  - Average seek: read 10 ms typical (16 max), write 11 ms typical.
  - Full stroke: read 18 ms typical (30 max), write 19 ms.
  - Single track: read 1.0 ms typical (4.0 max), write 1.2 ms.
  - Average latency 4.2 ms.
  - [ManualOwl Hitachi 7K100 spec p.28–29](https://www.manualowl.com/m/Hitachi/7K100/Manual/335320?page=29); [Newegg 7K100 listing](https://www.newegg.com/hitachi-gst-travelstar-7k100-100gb-hts721010g9at00/p/N82E16822146052)
- Fujitsu MHV2200BT (4,200 rpm SATA, 12.5 mm high, 2006–07) [SUMMARY, Icecat auto-generated listing, unverified]:
  - Read seek 14 ms, write seek 12 ms, track-to-track 1.5 ms, full stroke 22 ms.
  - Average latency 7.14 ms.
  - [Icecat MHV2200BT](https://icecat.co.uk/prefere/gb/p/fujitsu/mhv2200bt/MHV2200BT-693264.html); [Tom's Hardware MHV2200BT review](https://www.tomshardware.com/reviews/fujitsus-mhv2200bt,1337-2.html)
- Toshiba MKxx55GSX family (5,400 rpm, 2008–2010, includes MK5055GSX) [SUMMARY]:
  - Family sheet: average seek 12 ms.
  - A refurbisher listing says 14 ms.
  - [Thomasnet release](https://news.thomasnet.com/fullstory/hard-disk-drives-offer-capacities-up-to-500-gb-552583); [Disctech listing](https://www.disctech.com/Toshiba-MK5055GSX-SATA-Hard-Disk-Drives)
- WD Scorpio (older generation): WD specifies a 12 ms average seek [SUMMARY] — [Tom's Hardware Scorpio Blue review](https://www.tomshardware.com/uk/reviews/scorpio-notebook-hdd,2109-2.html)
- Older Seagate Momentus "54" (ST94011A family): track-to-track read/write 1.5/2.0 ms [SUMMARY] — [Seagate Momentus manual mirror (search summary)](https://www.scribd.com/document/313610497/Seagate-Momentus)

**2.5" laptop drives, sound power (A-weighted, Bels)**
- Momentus 5400.6 [DS]: idle 2.4 B typical (2.6 max), performance seek 2.6 B typical (2.7 max); 2.5 B seek on some capacities. A footnote says SMART offline activity during idle may raise acoustics — [Seagate Momentus 5400.6 manual](https://www.seagate.com/staticfiles/support/disc/manuals/notebook/momentus/5400.6%20(Wyatt)/100528359e.pdf)
- Hitachi Travelstar idle / seek figures, all typical [SUMMARY of datasheet mirrors]:
  - 7K100: 2.6 / 3.0 B.
  - 7K500: 2.5 / 2.8 B.
  - 5K500.B: 2.4 / 2.6 B.
  - Z7K500: 2.3 / 2.4 B.
  - Z5K500: 1.9 / 2.1 B.
  - Z5K500.B: 1.7 / 2.2 B.
  - Sources: [7K100 spec mirror](https://manualmachine.com/hitachi/hts721010g9at00/9667891-specifications), [7K500](https://manualmachine.com/hitachi/hts725025a9a365/10779229-specifications), [5K500.B](https://store.ee.co.uk/content/uni2/documentation/5hjb/32398_ts5k500.b_ds_final.pdf), [Z7K500/Z5K500 Farnell](https://www.farnell.com/datasheets/2645421.pdf)
- Older Momentus "54": 2.3 B idle typical (2.5 max) [SUMMARY] — [Seagate Momentus manual mirror](https://www.scribd.com/document/313610497/Seagate-Momentus)
- Fujitsu MHT-AT (4,200 rpm, about 2003) [SUMMARY]: "HDD ready" 24 dBA at 30 cm and 2.3 B; random seek 28 dBA at 30 cm and 2.7 B — [Fujitsu MHT20xxAT datasheet](https://www.fujitsu.com/downloads/COMP/fcpa/hdd/discontinued/mht20xxat_datasheet.pdf)
- Toshiba [SUMMARY]: MK5065GSX random seek 25 dBA; the single-platter MKxx55GSX models are 19 dB idle / 20 dB seek. No MK5055GSX-specific figure was found — [Toshiba spec mirrors via search](https://www.itpro.com/608433/toshiba-touts-lower-power-500gb-25in-drive)

**3.5" desktop reference, for comparison (from sibling notes)**
- Barracuda 7200.11 1 TB: about 2.9 B idle and 3.2 B performance seek — [Seagate 7200.11 manual mirror](https://powertool.manualsonline.com/manuals/mfg/seagate/720011.html?p=21)
- Barracuda 7200.9: 2.8 / 3.2 B — [SPCR 7200.9](https://silentpcreview.com/article283-page1.html)

**1.8" drives (iPod class)**
- Toshiba MK3008GAL (30 GB, 1 disc, 2 heads; iPod-era ZIF) [DS, user manual mirror]: 4,200 rpm, average seek 15 ms, maximum 26 ms, average latency 7.14 ms, spin-up 3 s typical — [ManualsDir MK3008GAL p.6](https://www.manualsdir.com/manuals/213958/toshiba-mk3008gal.html?page=6)
- MK8022GAA / MK6022GAA (iPod 80/60 GB era) are listed as 3,600 rpm, 1 platter, 2 heads, ZIF ATA-66 — [rml527 platter database (collector blog)](https://rml527.blogspot.com/2010/10/hdd-platter-database-toshiba-18.html)
  - An eBay listing also says 3,600 rpm with 15 ms seek — [eBay](https://www.ebay.fr/itm/231403206076)
  - Conflict: the brief Toshiba spec on dtsheet did not render its values, so the manufacturer's rpm is unconfirmed. The coordinator's assumption of 4,200 rpm for MK8022GAA appears wrong; the evidence points to 3,600 rpm.
- MK1634GAL, MK3008GAL, MK8034GAL, MK1214GAH and other GAL/GAH models are 4,200 rpm — [rml527](https://rml527.blogspot.com/2010/10/hdd-platter-database-toshiba-18.html)

**1" Microdrive (IBM, 1999–2001)** [DS-equivalent: IBM Hot Chips 13 slides]
- Gen 1 (340 MB): 4,500 rpm, 15 ms average seek.
- Gen 2 (1 GB, DSCM-11000): 3,600 rpm, 12 ms average seek.
- Both: 27.4 mm disk, 16 g, 1,500 G non-op shock (Gen 2).
- The spindle's "rotating mass [is] dominated by spindle rotor, not disk", and spin-up takes about 0.5 s.
- The actuator transfer function is "clean out to ~7 kHz", with actuator inertia I ≈ 0.1 g·cm².
- Load/unload is mandatory because "spindle torque [is] too low for contact start-stop"; L/UL also gives "unlimited start/stops for aggressive power savings". An inertia latch holds the parked actuator.
- Source: [IBM Microdrive, Hot Chips 13](https://old.hotchips.org/wp-content/uploads/hc_archives/hc13/3_Tue/18ibm-microdrive.pdf)
- Second-generation Microdrives switch off after a few seconds idle; spin-up "takes about 1 second" — [Wikipedia: Microdrive](https://en.wikipedia.org/wiki/Microdrive) (conflicts with the 0.5 s slide figure; the slide may mean motor-only time)
- 1 GB DSCM-11000: 3,600 rpm, 8.33 ms average latency, about 12 ms read seek [SUMMARY] — [Hitachi datasheet mirror](https://manualmachine.com/hitachi/dscm11000/9689306-datasheet)
- WD Passport Pocket 6 GB (1", 2006): 3,600 rpm, 11 ms seek — [Wikipedia: Microdrive](https://en.wikipedia.org/wiki/Microdrive)

**Head load/unload and power modes**
- Momentus 5400.6 power modes [DS]:
  - "Idle, performance": heads tracking.
  - "Idle, active": heads floating.
  - "Idle, low power": heads parked, spindle rotating.
  - Standby and Sleep: heads parked, spindle stopped.
  - The standby timer is reset by every read, write or seek.
  - L/UL rating: 600,000 software-controlled cycles plus 20,000 hard power on/off cycles.
  - Source: [Seagate Momentus 5400.6 manual](https://www.seagate.com/staticfiles/support/disc/manuals/notebook/momentus/5400.6%20(Wyatt)/100528359e.pdf)
- Hitachi ABLE-2 and ABLE-3 [SUMMARY]:
  - ABLE-2 defined Performance Idle, Active Idle and Low Power Idle.
  - In Low Power Idle the "heads are unloaded on the ramp but the spindle is still rotating".
  - ABLE-3 sets entry times adaptively from the observed command interval rather than from fixed timers.
  - Recovery to Active takes about 300 ms (ABLE-2) and about 20 ms on another model.
  - Sources: [Hitachi 5K160 spec p.52](https://audio.manualsonline.com/manuals/mfg/hitachi/hts541616j9sa00.html?p=52), [HTS541680J9SA00 spec p.52](https://www.manualowl.com/m/Hitachi/HTS541680J9SA00/Manual/335316?page=52)
- WD Scorpio family: 600,000 load/unload cycles [SUMMARY] — [WD Scorpio Blue spec (Scribd)](https://www.scribd.com/doc/49400192/Scorpio-Blue-Specifications-English)
- Hitachi drives are rated for about 600,000 load/unload cycles; ThinkWiki notes "200,000 unloads are typical" — [ThinkWiki](https://www.thinkwiki.org/wiki/Problem_with_hard_drive_clicking)
- Ramp loading "is widely adopted for 2.5-inch and smaller disks" — [US 7746599](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/7746599)
- Momentus 5400.6 G-models have Free Fall Protection: a 0 G sensor on the PCBA unloads the actuator "in falls of >8 inches (nominal)" — [Seagate Momentus 5400.6 manual](https://www.seagate.com/staticfiles/support/disc/manuals/notebook/momentus/5400.6%20(Wyatt)/100528359e.pdf)

### Inferences
- Whirr's laptop2005 timing (t2t 1.8 ms, average 12 ms, full stroke 24 ms, 5400 rpm) sits inside the datasheet range.
  - Track-to-track is a little slow: datasheets say 1.0–1.5 ms.
  - Full stroke at 24 ms is plausible: 18 ms typical on 7K100, 22 ms on the Fujitsu, 30 ms max on Momentus. Typical values are usually about 0.6–0.75 of max.
- Suggested timing per class:
  - 4200 rpm 2.5" (1995–2005): t2t 1.5 ms, average 13–14 ms, full stroke 24–26 ms, latency 7.14 ms.
  - 5400 rpm 2.5": t2t 1.0–1.5 ms, average 12–14 ms, full stroke 22–26 ms, latency 5.56 ms.
  - 7200 rpm 2.5": t2t 1.0 ms, average 10–11 ms, full stroke 18–19 ms, latency 4.17 ms.
  - 1.8" iPod: 3600 rpm (MK8022GAA) or 4200 rpm (MK3008GAL / MK1634GAL), average 15 ms, max 26 ms.
  - 1" Microdrive: 3600 rpm (4500 for Gen 1), average 12 ms (15 for Gen 1), latency 8.33 ms.
- 3.5" desktops of 2005–08 sit at about 2.8–2.9 B idle and 3.2 B seek; 2.5" drives at about 2.3–2.6 B idle and 2.4–3.0 B seek. So a laptop preset should be roughly 3–6 dB lower in source level before any enclosure effect, with seek-over-idle around +1 to +4 dB.
- Idle tone: an idle spectrum peak at rpm/60 is established for 3.5" drives in the sibling notes. Extending it, a 5400 rpm laptop drive should idle with a 90 Hz fundamental, a 4200 rpm drive 70 Hz, a 3600 rpm drive 60 Hz and a 4500 rpm drive 75 Hz. This is not verified for small drives.

### Gaps
- No primary-PDF figures were confirmed for Toshiba MK8022GAA rpm or acoustics, Hitachi 5K80/5K100 seek times, WD Scorpio Blue Bels, or IBM Travelstar 1990s models; the mirrors were blocked (403) or unrendered.
- No acoustic (Bels/dBA) figure was found for any 1.8" or 1" drive. One garbled Toshiba 1.8" sheet appeared to read "15dB Seek (ave.)"; that is unconfirmed — [dtsheet Toshiba 1.8" brief spec](https://dtsheet.com/doc/1345997/1-2-brief-specification-mobile-hdd--1.8)
- No fixed-seconds unload timers were found in Hitachi or Seagate 2.5" manuals: ABLE-3 is adaptive, and Seagate leaves the timers to the host.

## 2. How smaller actuators and enclosures change the sound; does "desktop modes scaled up 30%" hold?

### Takeaway
Measured and reviewer evidence agrees that 2.5" airborne seek noise is very weak; it was barely above idle in SPCR measurements. What listeners hear is mostly vibration carried through the mounting. SPCR describes some 2.5" drives as "sharper and higher pitched", and others' seeks as "a low rumble". IBM's 1" Microdrive actuator has no resonances below about 7 kHz.

Together this supports raising the actuator/arm modes for small drives. It argues against moving the whole bank (including the low "thump") up 30%. In a laptop the low and mid content comes from the chassis and desk, not the drive.

No measured 2.5" seek spectrum was found online. The two CC0 2.5" recordings found (Section 5) can settle the question once analysed.

### Cited Findings
**SPCR 2.5" noise table** [MEAS, dBA at 1 m, idle / AAM / seek]
- Samsung MP0402H: 17 / 18 / 19–20.
- Seagate Momentus 5400.2: 20 / – / 20–21.
- WD Scorpio: 20 / 21 / 21.
- Fujitsu MHT2080BH: 22 / 23–24 / 23–24.
- Hitachi 5K80: 19 / – / 20.
- Toshiba MK6022GAX: 22 at idle, seek "perhaps by 3 dBA" higher.
- Seagate Momentus ST94811A: 24 at idle, seek "probably 3~5 dBA" higher.
- Fujitsu MHT2040AT: 16 at idle, seek about 2 dBA higher.
- Toshiba MK4025GAS: 16 at idle.
- 3.5" reference: Barracuda IV 21 / 23 / 25–26 and Samsung SP0802N 21 / 23–24 / 25–26.
- Source: [SPCR Momentus 5400.2 review, comparison table (Wayback)](https://web.archive.org/web/2007/http://www.silentpcreview.com/article264-page3.html)

**SPCR subjective descriptions** [MEAS-context]
- WD Scorpio: "Seeks are almost too quiet to notice, and can be characterized as a low rumble." Its idle is "mainly a low frequency motor hum".
- Hitachi Travelstar 5K80: "a slightly sharper and higher pitched sound" than the Samsung.
- Toshiba MK6022GAX: "broadband shhhh quality ... but higher in pitch".
- Seagate Momentus ST94811A: a constant "pure" tone "somewhere in the 6~10KHz range", which drops 2–3 dBA when facing the drive edge (directional HF whine).
- Fujitsu MHT2080BH: idle "sounds undamped".
- Source: [SPCR (Wayback)](https://web.archive.org/web/2007/http://www.silentpcreview.com/article264-page3.html)

**Mounting and vibration**
- Momentus 5400.2: seeks were "completely inaudible" on soft foam but "clearly audible when the drive was placed on our vibration box"; "Any seek noise from the Momentus 5400.2 is likely to be vibration-induced." — [SPCR p.2 (Wayback)](https://web.archive.org/web/2007/http://www.silentpcreview.com/article264-page2.html)
- SPCR: a 2.5" drive has "much less moving mass" than 3.5" drives, and how a 2.5" drive is mounted "has a substantial impact on propagated noise" — [SPCR 500 GB laptop drives](https://silentpcreview.com/500gb_laptop_drives) (via search summary)
- One SPCR forum user reports that a decoupling mount "Changed the pitch of the seek sounds" of a 2.5" drive [USER] — [SPCR forum](https://silentpcreview.com/forums/viewtopic.php?p=585541) (via search summary)

**Actuator scaling**
- IBM 1" Microdrive actuator transfer function is "clean out to ~7 kHz". It has an overmolded plastic carriage and a 127-turn coil, I ≈ 0.1 g·cm² — [IBM Hot Chips 13](https://old.hotchips.org/wp-content/uploads/hc_archives/hc13/3_Tue/18ibm-microdrive.pdf)
- Patent: the problem "is acute in compact DASDs, as the physical dimensions of the actuator components are small, thus pushing the structural vibration modes into the acoustic range sensitive to the human ear" — [US 5291110 / US 5465034 (search summary)](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/5291110)
- Patent: measurements "in 2.5 inch diameter disk drives suitable for portable applications have shown strong correlation between rate-of-change of current and acoustic peaking". Seek current jerk sets the click level — [US 6441988 (search summary)](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/6441988)
- Desktop context from sibling notes:
  - 3.5" actuator butterfly modes sit around 4.8–6 kHz, top-cover modes at about 1–6 kHz — [seek_acoustics_physics.md](../Realistic%20HDD%20sound%20synthesis/seek_acoustics_physics.md)
  - Measured 3.5" seek peaks: Seagate ST3250823A main peak 2.63 kHz; Fujitsu MPF3102AT 888 / 1378 / 2659 Hz — [real_recordings_analysis.md](../Realistic%20HDD%20sound%20synthesis/real_recordings_analysis.md)

### Inferences
- **On the 30% upward scaling.** Simple scaling (modal frequency ∝ 1/length for geometrically similar beams) predicts 2.5" arms (about 0.6–0.7× the length of 3.5" arms) ringing about 1.4–1.6× higher, and the Microdrive's >7 kHz first mode fits that trend. So +30% or more is defensible for the actuator/HGA modes, the "tick" part.
- But SPCR's descriptions ("low rumble", vibration-induced, inaudible on foam) say the audible seek of a laptop drive is mostly the chassis or mounting response to the reaction force. The modes that matter in a laptop are therefore the shell and desk modes, not drive modes scaled from a 3.5" casting.
- The 3.5" "thump" modes (about 200–900 Hz) come from a heavy aluminium base and cover bolted to a steel case. A 2.5" drive's base and cover are much smaller and lighter. Their own modes should go up, while the low "thump" in a laptop comes from the shell. Scaling desktop low modes up 30% keeps a desktop-like body that a 2.5" drive does not have. A better structure:
  1. A sparse, quiet, high actuator tick (desktop actuator modes × 1.3–1.6, high Q, low level).
  2. A lighter, higher drive-casting layer (fewer, weaker modes).
  3. A laptop chassis layer carrying most of the "weight", as Whirr's Enclosure.laptop already does.
- The level contrast between seek and idle should be small at the drive, about +1 to +3 dBA, compared with up to +5 dBA or more on 3.5" drives.
- A 2.5" drive at 4200–5400 rpm has an idle fundamental of 70–90 Hz. Several drives show HF whine (Seagate Momentus 6–10 kHz pure tone), so an optional narrow HF whine partial is period-accurate for early-2000s Momentus-class drives.
- Microdrive (1") and 1.8" drives: the actuator modes are pushed above about 7 kHz. The very small casting radiates little low-frequency energy, so their sound should be a faint, thin, high "tsk", plus whatever the host device (camera body, iPod shell) adds.

### Gaps
- No measured frequency spectrum of 2.5", 1.8" or 1" seek noise was found in any published source.
- The Klerrp CC0 recordings of a Fujitsu MHV2200BT (2.5", 2007) and a Toshiba MK5055GSX (2.5", 2010) are the best available direct evidence. They were not downloaded or analysed in this pass because downloading needs the user's permission. Running the same peak/T60/onset analysis used in real_recordings_analysis.md on them would directly confirm or refute the 30% scaling.

## 3. Ramp load/unload "click": character, frequency of parking, and Apple's Sudden Motion Sensor

### Takeaway
Laptop and portable drives park their heads on a ramp whenever they enter low-power idle, so an audible single "tick" follows a few seconds to tens of seconds after the last access. The timing is set by drive firmware (adaptive on Hitachi ABLE-3, 10–15 s after a seek on one Fujitsu) and by host APM settings.

Aggressive settings caused tens of thousands of cycles per week, against a 600,000-cycle rating. Users describe a soft, discrete "tick", louder and harder on emergency power-loss parks. Apple's Sudden Motion Sensor (2005–2012 Mac laptops) causes a single audible park click when the machine is jolted or lifted quickly.

### Cited Findings
**Timers and APM**
- Fujitsu MHT2080BH "waits for 10-15 seconds after a seek before unloading the heads" and "May avoid the intermittent clicking problem common with notebook drives" [MEAS] — [SPCR (Wayback)](https://web.archive.org/web/2007/http://www.silentpcreview.com/article264-page3.html)
- Momentus 5400.2 at idle: 1.5 W "heads unloaded" versus 2.3 W "heads loaded" [MEAS] — [SPCR p.2 (Wayback)](https://web.archive.org/web/2007/http://www.silentpcreview.com/article264-page2.html)
- ThinkWiki on the click:
  - It is described as a repeating "tick tick tick", or a "faint beep at random intervals".
  - It is caused by the drive "parking its head". It occurs only while idle and stops if the drive is kept busy.
  - Affected drives include Hitachi 5K80, 5K100 and C4K60, Samsung MP0804H, WD Scorpio, Seagate Momentus 7200.1 and 7200.3, and Toshiba MK2035GSS.
  - hdparm -B 254 "will still unload heads, but far less often". -B 192 was the lowest value that worked on the Toshiba.
  - Samsung MP0804H: "15,539 load cycles (out of 600,000) within only one week". A Seagate Momentus reached 106,680 "after owning the laptop for just a few weeks".
  - Source: [ThinkWiki](https://www.thinkwiki.org/wiki/Problem_with_hard_drive_clicking)
- Ubuntu bug 59695: the pm-utils script set APM to 128 on battery and 254 on AC [USER/bug tracker] — [Launchpad bug 59695](https://bugs.launchpad.net/ubuntu/+source/pm-utils/+bug/59695); [ThinkWiki](https://thinkwiki.org/wiki/Problem_with_hard_drive_clicking)
- Toshiba MQ01ABD100: -B 255 worked "only for a short while, and then it starts unloading again" [USER] — [Launchpad 59695 comment](https://bugs.edge.launchpad.net/ubuntu/+source/acpi-support/+bug/59695/comments/244) (via search summary)
- Apple users also reported very high load/unload counts on MacBook drives [USER] — [Apple Discussions 1248163](https://discussions.apple.com/thread/1248163) (not opened)

**External USB drives**
- WD external drives: clicks every 4–5 s and "hard clicks during a head park operation during shutdown or entering sleep" are said to be normal on large drives [USER] — [SanDisk/WD forum](https://forums.sandisk.com/t/external-drive-makes-clicking-noise-every-few-seconds/391389) (via search summary)
- WD Intellipark parks the heads after short idle [USER] — [TechPowerUp forum](https://www.techpowerup.com/forums/goto/post?id=2844874) (via search summary)
- Toshiba MQ01UBD100 (Canvio-class 2.5" USB, 5400 rpm) contact-mic recording: spin-up, access, and "a great final 'CLICK!!' after the plug was pulled". This is a recorded emergency (power-loss) retract — [Freesound 401271 (CC BY 4.0)](https://freesound.org/people/eardeer/sounds/401271/)

**Sudden Motion Sensor and free-fall protection**
- Apple: the SMS "instantly parks the hard drive heads" on a drop or severe vibration and unlocks them when the computer is stable. It is controlled with `sudo pmset -a sms 0|1`. External vibration can park the heads unexpectedly and interrupt audio or video playback — [Apple HT201666](https://support.apple.com/en-us/HT201666)
- The SMS first appeared on the 2005 PowerBook refresh and was on every later Mac laptop with a hard drive until 2012. A triaxial accelerometer is used (MacBook Pro 15": Kionix KXM52-1050, ±2 g, bandwidth up to 1.5 kHz). "A clicking noise can be heard when the sensor activates" — [Wikipedia: Sudden Motion Sensor](https://en.wikipedia.org/wiki/Sudden_Motion_Sensor)
- User reports of SMS parking [USER]:
  - A single click when a MacBook or MacBook Pro is lifted or put down sharply; gentle lifting gives no click.
  - AppleCare attributed it to the SMS.
  - "If it's faint and you have to strain to hear it, it's probably the drive heads"; a loud click suggests failure.
  - Sources: [MacRumors 954995](https://forums.macrumors.com/threads/loud-click-when-i-pick-up-mbp.954995), [MacRumors 1183588](https://forums.macrumors.com/threads/click-sound-from-hdd-7200rpm-probably-when-picking-up-mbp-2011.1183588), [Apple Discussions 1936163](https://discussions.apple.com/thread/1936163) (via search summary)
- The WD Scorpio series was reported to conflict with SMS in aftermarket installs because of its own anti-shock features — [Wikipedia: Sudden Motion Sensor](https://en.wikipedia.org/wiki/Sudden_Motion_Sensor)

**1" and 1.8" drives**
- The Microdrive uses L/UL for "unlimited start/stops for aggressive power savings", with an inertia latch — [IBM Hot Chips 13](https://old.hotchips.org/wp-content/uploads/hc_archives/hc13/3_Tue/18ibm-microdrive.pdf)
- Second-generation Microdrives switch off after a few seconds idle — [Wikipedia: Microdrive](https://en.wikipedia.org/wiki/Microdrive)
- iPod users [USER]: "a click noise when the HD spins up but nothing more than that". An Apple contact said the iPod should be quiet unless held near the ear. A failing drive gives a "spin up, then click, followed by spindown" loop — [MacRumors 193134](https://forums.macrumors.com/threads/i-think-my-ipod-is-dying.193134/), [iFixit 884895](https://www.ifixit.com/Answers/View/884895/Why+is+my+iPod+Classic+making+a+clicking+noise), [Apple Discussions 7639575](https://discussions.apple.com/thread/7639575) (via search summary)

### Inferences
- Park event model for Whirr:
  - After the last I/O, an unload timer runs. Use 8–20 s on desktop-like defaults, 3–8 s for aggressive battery or APM-128 behaviour, and 10–15 s for the Fujitsu-like case.
  - When the timer expires, play one unload event: a fast full-stroke-like swing to the outer diameter, then the lift-tab sliding up the ramp and latching. Synthesize it as a short sweep or rub (5–15 ms) ending in a single latch tick.
  - The next I/O then plays a load event before the first seek: the tab slides down the ramp, a softer tick, and a short settle. Seagate and Hitachi quote about 20–300 ms to recover from low-power idle, which should delay the first seek sound.
  - From the Samsung count: 15,539 cycles in 7 days averages one park every ~39 s, consistent with near-continuous light I/O.
- SMS park: trigger on accelerometer-like events. On a Mac running Whirr this could map to the Mac's own motion or keyboard thumps if available; otherwise just offer it as a "jolt" easter egg. It is a single unload click, louder and more abrupt than the timed park (emergency retract), with no seek activity for about 0.5–1 s, then a load click. Response timing is not documented (see Gaps).
- An emergency power-off retract (the "great final CLICK" in Freesound 401271) is the loudest park. The drive retracts on back-EMF energy, without a controlled velocity profile. Use it for a "drive ejected / unplugged" event in a USB preset.
- 1" and 1.8" drives spin down quickly (a few seconds of idle), so they should play more frequent spin-up / spin-down cycles, each with a load or unload tick. That pattern is the iPod's "click when the HD spins up". This is an inference from the Wikipedia and forum descriptions, not a measured iPod timer.

### Gaps
- No acoustic measurement (level, spectrum, duration) of a ramp load or unload click was found.
- No documented SMS response latency or re-load delay was found.
- No manufacturer-documented fixed idle-to-unload timer was found for any 2.5" model (Hitachi ABLE-3 is adaptive).
- No iPod firmware spin-down timer was found in reliable sources.
- WD My Passport specifics (timer values, Intellipark on portables) come from forum posts only.

## 4. How the laptop chassis, iPod or camera body, and USB enclosure colour the sound

### Takeaway
Direct measurements are almost absent. The best evidence (SPCR) shows that 2.5" seek noise is mostly structure-borne: inaudible on foam and clearly audible on a hard mount. So the host structure (laptop palm rest and bottom shell, desk, USB enclosure, iPod case) largely sets the audible seek timbre. Changing the mount audibly changes the pitch of seek sounds.

### Cited Findings
- "Seeks were clearly audible when the drive was placed on our vibration box"; on soft foam they were "completely inaudible"; seek noise is "likely to be vibration-induced" [MEAS] — [SPCR p.2/p.3 (Wayback)](https://web.archive.org/web/2007/http://www.silentpcreview.com/article264-page2.html)
- Samsung MP0402H: "placing it on soft foam does reduce low freq. noise audibly". The drive's coupling transfers low-frequency energy into the support [MEAS] — [SPCR p.3 (Wayback)](https://web.archive.org/web/2007/http://www.silentpcreview.com/article264-page3.html)
- A decoupling mount "Changed the pitch of the seek sounds" [USER] — [SPCR forum](https://silentpcreview.com/forums/viewtopic.php?p=585541) (via search summary)
- Seagate: "Minor vibrations in a loose enclosure can cause exaggerated noises"; isolating the drive from the desk with a rubber mat helps — [Seagate KB](https://www.seagate.com/support/kb/identifying-hard-drive-sounds-and-determining-what-they-mean/)
- Seagate also notes that drives "chatter" or "click" when reading and writing, which is normal — [Seagate KB](https://www.seagate.com/support/kb/identifying-hard-drive-sounds-and-determining-what-they-mean/)
- Rubber feet on external enclosures reduce vibration and overall noise — [OWC/MacSales KB](https://eshop.macsales.com/Service/Knowledgebase/Article/52/867/Hard-Drive-Expected-and-Unexpected-Drive-Noise)
- Plastic covers, desks and trays have resonant modes that can turn a small drive vibration into "a much larger buzz or hum" (vendor blog, low authority) — [ZimaSpace](https://shop.zimaspace.com/blogs/tech-ai-hub/drive-vibration-dense-home-nas-enclosures)
- The iPod 4G Freesound recording needed a 350 Hz high-pass to get "clean motor noise". There was substantial low-frequency content or handling noise at 3 cm, but the file has it filtered out — [Freesound 569970 (CC0)](https://freesound.org/people/conath/sounds/569970/)

### Inferences
- **Laptop.** Whirr's Enclosure.laptop and laptopOnDesk choices (short sub-50 ms reverb, shell modes at 540–1,700 Hz, desk modes at 180–340 Hz, drive facing down under the board) agree with SPCR's "structure-borne" finding. That is the right place to put the laptop's "weight".
  - Aluminium unibody (2008+ MacBook / MacBook Pro): stiffer and more lightly damped. Expect higher, ringier shell modes and less low-frequency radiation.
  - Plastic iBook, PowerBook-era polycarbonate and 1990s ThinkPads: more damped and lower. A duller, boxier "tok".
  - These are physics inferences; no measurement was found.
- **USB portable** (WD My Passport, Seagate Expansion/Backup Plus portable, Toshiba Canvio): a bare 2.5" drive in a thin plastic or aluminium shell with no rubber isolation, lying flat on a desk. Expect:
  - Strong desk coupling (low-mid boost 150–400 Hz).
  - A small, high, rattly plastic shell resonance (about 1–3 kHz, moderate Q).
  - Almost no internal reverb.
  - Louder seeks relative to idle than the same drive in a laptop, because there is no rubber bracket.
  - Contact-mic recording Freesound 401271 is the right reference to check these values.
- **iPod.** A 1.8" drive held in a steel or chrome back and plastic front (4G/5G), usually in hand or pocket. Expect a quiet, thin sound with little low end and short, high ticks.
- **Camera with a CF Microdrive.** Expect an even fainter sound, heard mostly as spin-up whine and the ticks.

### Gaps
- No measured transfer functions for laptop chassis, USB enclosures or iPod cases, and no recordings of the same drive bare versus installed, were found.
- No StorageReview, Tom's Hardware or notebookreview acoustic test of a USB portable drive's seek timbre was found in this pass.

## 5. Openly licensed recordings (Freesound, Wikimedia Commons, archive.org)

### Takeaway
Freesound has at least two clean CC0 close-up recordings of identified 2.5" laptop drives with writing and seek activity: a Fujitsu MHV2200BT (2007) and a Toshiba MK5055GSX (2010), both by Klerrp. These are the 2.5" counterparts of the desktop pack the project already analysed and were missing from the earlier work.

Freesound also has a CC0 iPod 4G 1.8" drive (failing, clicking), a CC BY 4.0 contact-mic Toshiba 2.5" USB portable drive with an unplug "CLICK", and a CC BY 4.0 1996 IBM ThinkPad drive. Wikimedia Commons and archive.org gave nothing usable. No Microdrive recording was found anywhere.

### Cited Findings
Licences and descriptions were taken from each Freesound sound page on 2026-11-24.

**Highest value: 2.5" laptop drives, identified models, CC0**
- **[Freesound 143917](https://freesound.org/people/Klerrp/sounds/143917/)**, Klerrp, "Fujitsu MHV2200BT 2007":
  - **CC0 1.0.** Description: "A Fujitsu hard drive (2,5") manufactured in 2007 close up; spin up, writing, spin down."
  - Mono WAV, 50.8 s, 4.3 MB. Tags include "rattle".
  - The drive is 4,200 rpm, so expect a 70 Hz idle fundamental (inference).
- **[Freesound 143269](https://freesound.org/people/Klerrp/sounds/143269/)**, Klerrp, "Toshiba MK GSX - 5400rpm - FDB":
  - **CC0 1.0.** Description: "A Toshiba hard drive (2.5") manufactured in 2010 close up; spin up, writing, spin down. This drive has 2 platters. (toshiba mk5055gsx)"
  - Mono WAV, 36.6 s, 3.1 MB.
- Both are separate uploads from Klerrp pack 8850 (the pack holds 3.5" desktop and server drives). They appear to be recorded the same way as the pack the sibling notes analysed, so they allow a like-for-like 2.5" versus 3.5" comparison (inference).
- Three remixes of 143917 by user Timbre (143997, 144006) exist.

**Laptop drives in their machines (with fan or charger)**
- [Freesound 625266](https://freesound.org/people/ffb.soffa/sounds/625266/), ffb.soffa, "1.5 GB HDD from IBM ThinkPad 365XD (1996)":
  - **CC BY 4.0.** Warm-up, idle, power-off.
  - Mono WAV, 22.5 s, iPhone XR, noise-reduced.
  - It is not stated whether any seeks are present.
- [Freesound 182045](https://freesound.org/people/WaveAdventurer/sounds/182045/), WaveAdventurer, "Laptop hard drive noise, dell N5040":
  - **CC BY 4.0.** Recorded with the laptop's internal mic; hard-drive and fan noise; tag 5400 rpm.
  - Mono WAV, 34.4 s.
  - It captures the in-chassis, structure-borne path (inference).
- [Freesound 236951](https://freesound.org/people/matucha/sounds/236951/), matucha, Dell Latitude (D505) with 60 GB drive:
  - **CC BY-NC 4.0** (non-commercial, so likely unsuitable).
  - Start-up, running, shutdown; charger beeps; MKH405/MKH30 microphones.
- [Freesound 250216](https://freesound.org/people/nickijupiter/sounds/250216/), nickijupiter, "hdd_laptop_spinup":
  - **CC BY 4.0.** Recorded with an induction coil, which picks up electromagnetic fields, not sound. Not acoustic.
  - 1.9 s.
- [Freesound 261398](https://freesound.org/people/VlatkoBlazek/sounds/261398/), VlatkoBlazek, "Laptop noises": **CC BY 4.0**, fan plus HDD, Zoom H6, unidentified drive.
- [Freesound 579767](https://freesound.org/people/Mafon2/sounds/579767/), Mafon2, "Old laptop humming": **CC0**, unidentified.
- [Freesound 272347](https://freesound.org/people/Ghostcodex_Dansedestroy_101010/sounds/272347/), "hitachi_laptop_60gb_nospin_buzzing": **CC0**, a non-spinning buzz, not seeks.

**1.8" iPod drive**
- [Freesound 569970](https://freesound.org/people/conath/sounds/569970/), conath, "Broken iPod 1.8" Hard Drive tries to spin up, clicking noises, whirring":
  - **CC0 1.0.** iPod 4th generation A1059 with a 1.8" 40 GB Toshiba drive, recorded with a Zoom H1n at 3 cm.
  - "You can hear the spin up of the motor and the hard drive head clicking back and forth"; the drive fails and spins down.
  - A 350 Hz high-pass and noise reduction were applied, and it was mixed to mono. Mono WAV, 26.9 s, 2.3 MB.
  - This is a failure mode (repeated load attempts), but it is the only iPod-drive recording found.

**USB portable / external**
- [Freesound 401271](https://freesound.org/people/eardeer/sounds/401271/), eardeer, "Toshiba HDD.wav":
  - **CC BY 4.0.** "Toshiba MQ01UBD100 2.5" 1TB external hdd. 5400rpm", recorded with a contact mic clamped to the drive.
  - Spin-up, "some access noise while clicking random direcories", and a final "CLICK!!" after the plug was pulled (emergency park).
  - Stereo WAV, 61.8 s, 17.0 MB.
- [Freesound 553328](https://freesound.org/people/Julian_Eftei/sounds/553328/), Julian_Eftei, "External Hard Drive 1": **CC BY 4.0**, Zoom H4n Pro, model and size unidentified, 10.8 s.
- [Freesound 51152](https://freesound.org/people/RutgerMuller/sounds/51152/), RutgerMuller, "External Harddisk Starting Up": **CC0**, Edirol R-1 with ME66, unidentified drive, 19.8 s.
- [Freesound 250214](https://freesound.org/people/nickijupiter/sounds/250214/): external 3.5" USB drive recorded with an induction coil, **CC BY 4.0**. It is 3.5" and not acoustic, so not useful.
- [Freesound 835803](https://freesound.org/people/thaighaudio/sounds/835803/), thaighaudio, "Hard drives click and whirr close perspective" (2025): **CC0**, tagged usb/sata, during a backup; the form factor is not stated.

**Searched, nothing usable found**
- Wikimedia Commons file-namespace searches (filemime:audio and filemime:video) for "laptop hard drive", "notebook hard disk", "ipod hard drive", "microdrive", "external hard drive clicking", "Festplatte Notebook" and "head parking" found no 2.5", 1.8" or 1" recordings. The only drive audio is the 3.5" Toshiba HDWR480 spin-up clip already used — [Commons API search](https://commons.wikimedia.org/w/api.php?action=query&list=search&srnamespace=6&srsearch=laptop%20hard%20drive%20filemime:audio)
- archive.org advanced search (audio/movies) for laptop or iPod hard drive, microdrive and hard-drive clicking returned only podcasts — [archive.org advancedsearch](https://archive.org/advancedsearch.php)
- Freesound "microdrive" returned no drive recordings — [Freesound search](https://freesound.org/search/?q=microdrive)

### Inferences
- For preset tuning, priority order:
  1. Klerrp 143917 (4200 rpm 2.5", 2007) and 143269 (5400 rpm 2.5", 2010): free-field close-up, same method as the analysed desktop pack, so the cleanest test of the 30% scaling.
  2. eardeer 401271: contact mic on a USB portable drive, so it shows structure-borne seek content and an emergency park.
  3. WaveAdventurer 182045: in-chassis laptop path, though with fan noise.
  4. conath 569970: iPod drive tick character above 350 Hz only.
- Suggested analysis for items 1–2, mirroring real_recordings_analysis.md:
  - Idle fundamental: should be 70 Hz for MHV2200BT and 90 Hz for MK5055GSX.
  - Excess-over-idle spectral peaks and Q.
  - Two-stage decay and T60.
  - Inter-onset intervals in "writing" passages.
  - Event level over idle.
- Compare the peaks directly with the Fujitsu MPF3102AT (888/1378/2659 Hz) and Samsung peaks already measured. If 2.5" peaks land at about 1.3× the desktop peaks, the existing preset is confirmed; if the low and mid content is missing, use the "high tick plus chassis body" structure from Section 2.

### Gaps
- None of the recordings above were downloaded or spectrally analysed here: downloading needs the user's approval, which this sub-task could not obtain. Files to fetch if approved:
  - 143917.wav (4.3 MB), CC0
  - 143269.wav (3.1 MB), CC0
  - 401271 (17.0 MB stereo), CC BY 4.0, credit "eardeer"
  - 569970 (2.3 MB), CC0
  - 182045 (2.9 MB), CC BY 4.0, credit "WaveAdventurer"
- No openly licensed 1" Microdrive, Seagate ST1, WD My Passport, Seagate Expansion/Backup Plus portable, or Apple SMS-park recording was found.
- No healthy (non-failing) iPod seek recording was found.
- Freesound's per-user listing pages did not render server-side, so other Klerrp 2.5" uploads may exist beyond the two found by keyword search.

## 6. Per-class sound descriptions for synthesis (preset proposals)

### Takeaway
Combining the datasheet and reviewer evidence above, each small-drive class can be specified with timing (sourced) and a timbre recipe. The timbre is largely inferred, because no measured small-drive seek spectra exist in the literature. Every timbre number below is a starting point to check against the Klerrp CC0 2.5" recordings.

### Cited Findings
- 2.5" airborne seek is +0 to +3 dBA over idle at 1 m. Seeks are described as "low rumble" (WD Scorpio), "sharper and higher pitched" (Hitachi 5K80), "broadband shhhh ... higher in pitch" (Toshiba MK6022GAX), with HF whine on early Momentus (6–10 kHz) — [SPCR (Wayback)](https://web.archive.org/web/2007/http://www.silentpcreview.com/article264-page3.html)
- Seek noise is vibration-induced and mount-dependent — [SPCR p.2 (Wayback)](https://web.archive.org/web/2007/http://www.silentpcreview.com/article264-page2.html)
- Microdrive actuator is clean to about 7 kHz; 3,600–4,500 rpm; 12–15 ms seeks; aggressive L/UL power saving — [IBM Hot Chips 13](https://old.hotchips.org/wp-content/uploads/hc_archives/hc13/3_Tue/18ibm-microdrive.pdf)
- Momentus 5400.6 timing and Bels — [Seagate manual](https://www.seagate.com/staticfiles/support/disc/manuals/notebook/momentus/5400.6%20(Wyatt)/100528359e.pdf)
- 7K100 timing — [ManualOwl 7K100](https://www.manualowl.com/m/Hitachi/7K100/Manual/335320?page=29)
- iPod drives: 1.8" Toshiba at 3,600 rpm (MK8022GAA, per collector database) or 4,200 rpm (MK3008GAL), 15 ms average seek — [rml527](https://rml527.blogspot.com/2010/10/hdd-platter-database-toshiba-18.html), [MK3008GAL manual](https://www.manualsdir.com/manuals/213958/toshiba-mk3008gal.html?page=6)

### Inferences
All timbre values in this section are proposals, not measurements.

**A. laptop4200 (1995–2005: IBM Travelstar, Toshiba MK, Fujitsu MHT, PowerBook G3/G4 and iBook)**
- Timing: 4200 rpm (70 Hz idle line plus a weak 140 Hz), t2t 1.5 ms, average 13–14 ms, full stroke 24–26 ms, settle about 1 ms.
- Source level about −6 dB versus desktop2005, with seek-over-idle +1 to +2 dB.
- Voice:
  - Actuator tick modes at about 1.4× the desktop actuator modes (for example 3.5–4 kHz → 5–6 kHz), high Q (30–50), short decay (T60 about 10–20 ms).
  - Little drive-body content below 800 Hz.
  - Then the laptop chassis (plastic: damped, 500–1,200 Hz) and desk.
- Parking: unload tick 5–15 s after the last I/O; the load tick precedes the first seek after an idle, with a 20–300 ms delay.

**B. laptop5400 (2004–2012: Hitachi 5K, Seagate Momentus 5400.x, WD Scorpio Blue, Toshiba MKxx55GSX; most MacBooks and iBooks)**
- Timing: 5400 rpm (90 Hz), t2t 1.0–1.5 ms, average 12–14 ms, full stroke 22–26 ms.
- Same voice structure as A, about 1–2 dB louder idle.
- Optional "Momentus whine": a narrow sine at 6–10 kHz, −30 to −40 dB, directional.
- Variant laptopUnibody (2008–2012 aluminium MacBook / MacBook Pro): stiffer, less damped shell with higher modes, plus the SMS park event.

**C. laptop7200 (2005–2015: Travelstar 7K100/7K500, Momentus 7200.x, WD Scorpio Black)**
- Timing: 7200 rpm (120 Hz), t2t 1.0 ms, average 10–11 ms, full stroke 18–19 ms.
- Bels about 0.2–0.4 above 5400 rpm drives. Stronger, more frequent ticks; seek about +3 to +4 dB over idle (7K100 2.6 → 3.0 B).

**D. ipod1.8 (2004–2014 Toshiba 1.8" in iPod 4G/5G/Classic)**
- Timing: 3600 or 4200 rpm (60/70 Hz), average 15 ms, max 26 ms.
- Behaviour: bursts. The drive spins up for about 1–3 s (3 s typical spin-up per MK3008GAL), reads a large chunk with a cluster of quick ticks, unloads (tick) and spins down. Seconds-to-minutes gaps are silent.
- Voice: very quiet, thin ticks with most energy above about 1–2 kHz, plus a faint rising spin-up whine. The case adds little low end.

**E. microdrive1in (1999–2008 IBM/Hitachi Microdrive, Seagate ST1, WD Passport Pocket)**
- Timing: 3600 rpm (60 Hz; Gen 1 4500 rpm = 75 Hz), average 12 ms (Gen 1 15 ms), latency 8.33 ms.
- Spin-down after a few seconds idle; spin-up about 0.5–1 s.
- Voice: the faintest. Actuator modes ≥7 kHz, so a tiny bright "tsk" per seek plus a high whiny spin-up. It needs a camera or reader body enclosure (tiny, plastic, no reverb).

**F. usbPortable (2008–2015 WD My Passport, Seagate Expansion/Backup Plus portable, Toshiba Canvio)**
- Use a B or C drive voice with a "bare plastic shell on desk" enclosure:
  - No rubber isolation.
  - Strong desk coupling at 150–400 Hz.
  - A rattly shell mode at about 1–3 kHz.
  - Near-zero reverb.
- Parking: aggressive. Unload after about 4–10 s idle, plus a louder "eject/unplug" emergency retract click.

### Gaps
- Every timbre number in this section needs checking against the Klerrp 143917/143269 and eardeer 401271 recordings once their download is approved.
- No source gives modal frequencies of 2.5" or 1.8" actuators directly. The only quantitative small-actuator frequency datum is the Microdrive's "clean to ~7 kHz".

# Physics and Measured Acoustics of HDD Seek Noise (and related mechanical sounds)

Scope note: these notes cover sound-generating mechanisms and measured numbers useful for procedural synthesis. Many primary IEEE/JSME full texts were paywalled (ResearchGate, ScienceDirect and NTU returned 403/405 to fetches), so several spectral numbers come from abstracts or search-index excerpts rather than the full papers. Each such case is flagged. "Inference" items are my reasoning, not measurements.

## 1. Mechanism: how a VCM seek works and what radiates sound

### Takeaway
A seek is a speedup / (coast) / slowdown / settle sequence driven by voice-coil current. Abrupt current changes, worst with bang-bang square-wave current, excite a small number of fixed-frequency structural resonances of the head-stack/actuator assembly. Those resonances reach the air two ways: structure-borne through the cover, base and PCB (each with its own resonances), and airborne through the housing. Spindle noise is a steady periodic tonal series locked to rotation speed. Seek noise is a transient burst of a few fixed resonance tones whose level, not pitch, depends on the drive current.

### Cited Findings
- Seek phases: "a speedup, where the arm is accelerated until it reaches half of the seek distance or a fixed maximum velocity; a coast for long seeks, where the arm moves at its maximum velocity; a slowdown, where the arm is brought to rest close to the desired track; and a settle, where the disk controller adjusts the head." — [Ruemmler & Wilkes, "An Introduction to Disk Drive Modeling", IEEE Computer 1994](https://pages.cs.wisc.edu/~dusseau/Classes/CS537-F05/Readings/ruemmler94introduction.pdf)
- The seek noise source is the head actuator, meaning the VCM, its ball bearing and the arm/suspension assembly. It "generate[s] transient and discrete noises". Seek noise "is normally dominated by fewer tones that are related to the structural resonances of the head actuator assembly". These tonal frequencies "are not affected by the seek speed as they remain fixed in frequency even if the disk is operated at different seek rates." — [Jiang & Macioce (Roush Industries), "Fundamentals of Hard Disk Drive Acoustics", Data Storage magazine](https://cdn.mediavalet.com/usva/roush/Rsrqc_YhbU-GP6sYr323gg/4WWZaqVt6EKK92EQL0k7_A/Original/Data-Storage.pdf)
- "The seek noise source level is determined by seek speed, the current profile applied to the voice coil motor, and the head actuator dynamics." There are two ways to lower it: smooth the seek profile and slow the seek, which costs performance, or add damping to the actuator components. — [Jiang & Macioce, Roush](https://cdn.mediavalet.com/usva/roush/Rsrqc_YhbU-GP6sYr323gg/4WWZaqVt6EKK92EQL0k7_A/Original/Data-Storage.pdf)
- Idle (spindle) noise is "steady-state periodic tones" from the spindle motor, bearings and disk stack. Its harmonics relate to spin speed, the number of bearing balls and bearing imperfections. Fluid dynamic bearings are quieter because they have no metal-to-metal contact. — [Jiang & Macioce, Roush](https://cdn.mediavalet.com/usva/roush/Rsrqc_YhbU-GP6sYr323gg/4WWZaqVt6EKK92EQL0k7_A/Original/Data-Storage.pdf)
- Transmission paths:
  - Structure-borne: actuator and spindle vibration passes through screws into the cover and base plate and "will be amplified by resonances of the drive housing."
  - Airborne: internal noise passes through the housing, possibly amplified by internal acoustic resonances.
  - PCB: base-plate vibration passes to the PCB through its screw mounts and is amplified by PCB resonances. The cavity between the base plate and the PCB acts as "an acoustic amplifier due to reverberation effects". The PCB "tended to act like a speaker".
  - [Jiang & Macioce, Roush](https://cdn.mediavalet.com/usva/roush/Rsrqc_YhbU-GP6sYr323gg/4WWZaqVt6EKK92EQL0k7_A/Original/Data-Storage.pdf)
- Which parts ring:
  - The top cover is "flimsy" and resonant. Constrained-layer damping on it is standard.
  - The base plate "does not possess much resonant behavior", so CLD is rarely applied there.
  - Damping is also applied between the VCM housing and the covers, to "damp resonances of this component".
  - Flexure dampers on the arms "damp arm modes excited whenever the rotary actuated arm comes to a sudden stop".
  - Arms are stamped from damped laminate "to reduce seek noise".
  - [Jiang & Macioce, Roush](https://cdn.mediavalet.com/usva/roush/Rsrqc_YhbU-GP6sYr323gg/4WWZaqVt6EKK92EQL0k7_A/Original/Data-Storage.pdf)
- Cover damping cut idle noise by 8.3 dBA on the cover side. It has "little effect" on forced vibration from internal resonances excited during seek, unless a forcing frequency aligns with a cover resonance. — [Jiang & Macioce, Roush](https://cdn.mediavalet.com/usva/roush/Rsrqc_YhbU-GP6sYr323gg/4WWZaqVt6EKK92EQL0k7_A/Original/Data-Storage.pdf)
- Bang-bang control produces square current waveforms, which "contain high frequency harmonics which stimulate mechanical resonance in the HGA causing acoustic noise". The patent replaces them with a near-sinusoidal acceleration profile, plus a zero-acceleration coast phase on long seeks. — [US6441988, Method and apparatus for reducing acoustic noise in a hard disk drive](https://patents.google.com/patent/US6441988)
- Seagate patent: sudden, large changes in actuator coil current set up vibrations, so the current profile is shaped to reduce both acoustic noise and seek-time variation. — [US6178060 (Seagate)](https://patents.google.com/patent/US6178060). A related Seagate patent limits current in the initial (acceleration) stage of a seek to cut noise ([US6449117](https://patents.google.com/patent/US6449117)).
- Maxtor patent: uses closed-loop smoothing of the current transition from acceleration to deceleration, because abrupt transitions excite vibration modes. — [US7082010](https://patents.google.com/patent/US7082010) (search-result summary; claims not read in full)
- Actuator resonance can be detected acoustically. A microphone recorded during seeks, followed by PSD peak extraction, matched laser-Doppler and dynamic-signal-analyzer results. This confirms that the seek sound carries the actuator mode peaks directly. — [IEEE, "HDD actuator resonance detection through acoustic signal analysis"](https://ieeexplore.ieee.org/document/908909) (abstract only)
- Lower-speed drives: the actuator dominates noise. Higher-speed drives: disk airflow turbulence dominates. — Search-result excerpt of [Vibration and noise analysis of computer hard disk drives, Measurement (Elsevier)](https://www.sciencedirect.com/science/article/abs/pii/S0263224105001132) (full text 403)

### Inferences
- In a bang-bang seek the coil current has three hard edges: 0→+Imax at start, +Imax→−Imax at the accel/decel switch, and −Imax→0 (into settle) at arrival. The mid-seek reversal is a 2×Imax step, the largest current step in the seek. Physically, the excitation looks like three impulses (not two) driving the same fixed modes. Whirr's current 2-impulse model omits the reversal. On short seeks (< ~1–2 ms) the three edges merge into one event. This is reasoning from the patents above, not a measurement of how audible the middle click is.
- "Settle" is closed-loop fine positioning, so arrival is followed by low-level ringing of the arm modes (the Roush note on arm modes excited at a "sudden stop" supports this). Synthesis should put the longest-decaying, highest-Q tail on the stop/settle event.
- Seek noise is a set of fixed tones, not filtered noise. A noise burst through low-Q bandpasses (Whirr's current design) loses this tonal "ping" and will sound flat and generic. A few high-Q resonators struck by a short impulse is closer to the physics.

### Gaps
- No source found with measured VCM current waveforms paired with an acoustic time trace. Whether the mid-seek reversal is separately audible is unverified.
- No coil-current magnitudes or actuator acceleration values (g, rad/s²) were found for desktop drives.

## 2. Measured spectra: frequencies, peaks, Q, decay, levels

### Takeaway
Seek noise energy (A-weighted) sits mainly in about 2–8 kHz. It comes from a few discrete peaks (actuator sway/torsion modes around 4.5 and 5.5 kHz in one measured drive, actuator "butterfly" modes around 4.8–6 kHz in typical designs and up to ~9 kHz in server actuators), on top of top-cover modes in roughly 1–6 kHz (one reported near 3.0 kHz). Seek raises drive sound power only modestly on modern drives: about +0.1 to +0.3 B (1–3 dB) on 2010s Seagates, and up to +0.9 B (9 dB) on mid-2000s drives without AAM.

### Cited Findings
- **Measured seek peaks:** The IEEE Trans. Magn. paper "Numerical Hard Disk Drive Seek Acoustic Transfer Analysis and Experimental Validation" reports these points:
  - New spectral peaks during seek at about 4.5 kHz and 5.5 kHz, attributed to actuator sway/torsion modes.
  - Idle-spectrum content in about 2–6 kHz tied to top-cover vibration.
  - Measurements up to 25.6 kHz in an anechoic chamber with a 12.0 dB(A) background.
  - Seek acoustics depend heavily on the seek-current spectrum and the mechanical design.
  - Source: search-index excerpts of [ResearchGate copy](https://www.researchgate.net/publication/224607928_Numerical_Hard_Disk_Drive_Seek_Acoustic_Transfer_Analysis_and_Experimental_Validation) (full text 403). The volume/year was given as vol. 45 no. 11, which would be Nov 2009, not 2010. Treat the citation details as unverified.
- **A-weighted band:** A-weighted HDD noise lies "mainly in 2–8 kHz". Disk-platter natural frequencies were measured at 359, 525, 650 and 1080 Hz. — Search excerpt of [Measurement (Elsevier), "Vibration and noise analysis of computer hard disk drives"](https://www.sciencedirect.com/science/article/abs/pii/S0263224105001132) (abstract-level, not verified in full text)
- **Butterfly mode** (in-plane first bending mode of the E-block, where arms and coil support swing about the pivot):
  - Example peak at about 4800 Hz ([US7298592](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/7298592)).
  - "May be centered at about 6 kHz in current designs" ([US7085108, pivot-bearing tolerance ring damping](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/7085108)).
  - Main resonance around 9 kHz for conventional server HDD actuators ([Toshiba Review vol. 66 no. 11](https://toshiba.semicon-storage.com/content/dam/toshiba-ss-v3/master/en/storage/technology-center/ToshibaReview_vol66n11.pdf)).
  - Higher pivot-bearing preload/stiffness raises the butterfly frequency.
  - A 5 kHz component in the coil current would excite a 5 kHz butterfly mode.
  - Source for the frequency claims: search-result excerpts of these patents.
- **Cover mode:** a top-cover mode near 3.025 kHz sits close to the 3 kHz electromagnetic-ripple harmonic of a 10K rpm motor, within a problem band of about 1–6 kHz. — Search excerpt of [Motor noise generation and prediction for high spinning speed HDD](https://www.researchgate.net/publication/225697843_Motor_noise_generation_and_prediction_for_high_spinning_speed_hard_disk_drive)
- A patent states that HDD acoustic emissions are generally targeted at about 200–4000 Hz. A separate patent describes drum-like "diaphragm" modes of the top cover and base plate that amplify spindle/actuator frequencies when they coincide. — Search excerpts of [US6407879](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/6407879) and related patents
- **Perceived seek band (anecdotal):** an SPCR forum reply says seek noise "tends to be in the 500–2 kHz range". This is a forum opinion, not a measurement, but it may reflect the in-case, distance-filtered sound. — [SPCR search excerpt](https://www.silentpcreview.com/article250-page2.html)
- **Sound power, Seagate Desktop HDD / Barracuda 7200.14** (ISO 7779, overall A-weighted sound power, cover up):
  - Multi-disc: idle 2.4 B typical / 2.6 B max; seek 2.6 B typical / 2.7 B max.
  - Smaller models: idle 2.2 B; seek 2.4 B.
  - 1-disc: idle 2.2 B; seek 2.3 B.
  - So seek is +1 to +2 dB over idle.
  - [Seagate Desktop HDD Product Manual Rev. U](https://www.seagate.com/www-content/product-content/barracuda-fam/desktop-hdd/barracuda-7200-14/en-us/docs/100686584u.pdf)
- **Sound power, Barracuda 7200.11 1 TB:** idle about 2.9 B, performance seek about 3.2 B, quiet seek about 3.1 B (typical). Smaller models idle at about 2.5–2.6 B. — [Seagate 7200.11 manual via manualsonline mirror](https://powertool.manualsonline.com/manuals/mfg/seagate/720011.html?p=21) (third-party mirror; some table columns garbled)
- **Mid-2000s drive (SPCR, 2005):** idle / AAM seek / normal seek = 2.9 / 3.0 / 3.8 B. Normal seek is +9 dB over idle; AAM reduces that to +1 dB. — [SPCR Maxtor DiamondMax 10 / Hitachi 7K250 review, search excerpt](https://silentpcreview.com/article244-page1.html)
- **Design targets:** set-top-box drives target <30 dBA sound power, with seek "virtually indistinguishable over idle (less than 2 dBA louder)". — [Jiang & Macioce, Roush](https://cdn.mediavalet.com/usva/roush/Rsrqc_YhbU-GP6sYr323gg/4WWZaqVt6EKK92EQL0k7_A/Original/Data-Storage.pdf)
- **SPCR measured SPL:** one Samsung drive measured 17 dBA idle and 18 dBA seek at 1 m. SPCR noted seek is "somewhat more audible than the 1 dBA gain suggests". The quietest desktop drives set a floor of about 20–22 dBA at 1 m. — [SPCR search excerpts](https://www.silentpcreview.com/article617-page1.html)

### Inferences
- The +1 dB gain in overall dBA understates how audible seeks are. Seeks are transient and tonal in a 2–8 kHz region where hearing is sensitive, while idle energy is steadier and partly lower in frequency. Synthesis should make seeks stand out through spectral and temporal contrast (tonal pings in 3–7 kHz), not through loudness.
- Suggested mode set for synthesis, inferred by combining the sources:
  - 1–2 actuator modes at about 4–6 kHz, the most prominent.
  - A higher actuator/coil mode at about 7–9 kHz, weaker.
  - 1–2 cover/housing modes at about 1.5–3.5 kHz.
  - Optional weak PCB/cavity content at about 0.5–1.5 kHz.
  - Very little below 300–400 Hz from the bare drive. The base plate is not very resonant, and platter modes at 359–1080 Hz are excited mainly by spindle and airflow.
  - This is consistent with the user's report that a bass-heavy modal model sounded unnatural.
- Q/decay: no measured Q values were found. Damped actuator/cover modes with constrained-layer damping and laminated arms plausibly have loss factors of a few percent. As a rough synthesis starting point, assume Q ≈ 20–60 (decay to −60 dB in about 5–30 ms at 4–6 kHz). This is an inference and should be tuned by ear, but it is much higher Q than "low-Q" bandpasses.

### Gaps
- No published seek spectrum plot was read directly. The 4.5/5.5 kHz peaks come from search-index excerpts.
- No measured modal damping ratios, Q values or T60 decay times were found for actuator, cover or PCB modes.
- No 1/3-octave seek spectra from SPCR/StorageReview/AnandTech were retrievable (SPCR returned 403).

## 3. Temporal shape: seek duration vs length, mid-seek reversal, settle, timbre

### Takeaway
On a 2010s 7200 rpm 3.5" drive, a seek lasts about 1.0 ms track-to-track (1.2 ms write) and about 8.5 ms average (9.5 ms write), plus settle. Short seeks scale with √distance and long seeks roughly linearly with distance (because of the coast phase). Settle is 1–3 ms. Very short seeks are dominated by settle. Timbre differences between "tick" and "clack/zip" are physically explained by the same fixed modes struck by edges spaced farther apart in time, not by a change in pitch.

### Cited Findings
- Seagate Desktop HDD (7200.14), 7200 rpm:
  - Track-to-track seek 1.0 ms (read) / 1.2 ms (write).
  - Average seek 8.5 ms (read) / 9.5 ms (write).
  - Average rotational latency 4.16 ms.
  - Track-to-track is the average of all single-track seeks. Average is a random average of at least 5000 seeks, less overhead.
  - [Seagate Desktop HDD Product Manual Rev. U](https://www.seagate.com/www-content/product-content/barracuda-fam/desktop-hdd/barracuda-7200-14/en-us/docs/100686584u.pdf)
- "Very short seeks (less than, say, two to four cylinders) are dominated by the settle time (1–3 milliseconds). In fact, a seek may not even occur; the head may just resettle into position on a new track." — [Ruemmler & Wilkes 1994](https://pages.cs.wisc.edu/~dusseau/Classes/CS537-F05/Readings/ruemmler94introduction.pdf)
- "Short seeks (less than 200–400 cylinders) spend almost all of their time in the constant-acceleration phase, and their time is proportional to the square root of the seek distance plus the settle time. Long seeks spend most of their time moving at a constant speed, taking time that is proportional to distance plus a constant overhead." As track density increases, settle takes a growing fraction of total seek time. — [Ruemmler & Wilkes 1994](https://pages.cs.wisc.edu/~dusseau/Classes/CS537-F05/Readings/ruemmler94introduction.pdf)
- 1990s reference points: HP C2200A (5.25", 4002 rpm, 1449 cylinders) and HP 97560 (5.25", 4002 rpm, 1935 cylinders) had average 8 KB access times of 33.6 ms and 22.8 ms. — [Ruemmler & Wilkes 1994, Table 1](https://pages.cs.wisc.edu/~dusseau/Classes/CS537-F05/Readings/ruemmler94introduction.pdf)
- Seek trajectory formulas: acceleration time = √(2d/a). The coast portion is (remaining distance)/v_max. Long seeks add a coast at "constant maximum design speed". — Search excerpts of [US6501613](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/6501613) and [US7430093](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/7430093)
- Arm modes are "excited whenever the rotary actuated arm comes to a sudden stop". This supports ringing at arrival. — [Jiang & Macioce, Roush](https://cdn.mediavalet.com/usva/roush/Rsrqc_YhbU-GP6sYr323gg/4WWZaqVt6EKK92EQL0k7_A/Original/Data-Storage.pdf)
- Modal tones stay fixed in frequency at different seek rates. — [Jiang & Macioce, Roush](https://cdn.mediavalet.com/usva/roush/Rsrqc_YhbU-GP6sYr323gg/4WWZaqVt6EKK92EQL0k7_A/Original/Data-Storage.pdf)

### Inferences
- Synthesis timing model derived from the above (parameters inferred; tune to taste):
  - Total seek time T(d) ≈ t_settle + k·√d for d below the coast threshold, and ≈ a + b·d above it.
  - Anchors for a 7200 rpm drive: T(1 track) ≈ 1.0 ms; T(~1/3 stroke) ≈ 8.5 ms.
  - Full stroke is commonly about 2× average, so roughly 16–20 ms. This is not sourced; see Gaps.
  - Event placement: impulse A at t=0 (start), impulse B at the accel→decel reversal, impulse C at arrival (end of slowdown), then a low-level settle micro-chatter of 1–3 ms.
  - On short seeks with no coast, B sits at the midpoint between A and C.
  - On long seeks, A→B is the acceleration time, B is followed by coast (near-zero current, so near silence apart from residual ringing), and the deceleration ramp and C come later. In a coast-phase seek, the reversal is actually two transitions: accel→coast and coast→decel.
- Timbre vs length (inference): with fixed modes,
  - Track-to-track (≈1 ms): A, B and C collide into one short "tick".
  - Medium seeks (3–8 ms): two or three distinct transients a few ms apart produce a "clack" or a fast double-tick.
  - Rapid sequences of random seeks at 100+ seeks/s produce the familiar "chatter/grinding". Seek rate, not pitch, carries the character.
  - A slight level change with seek length is plausible, since longer seeks reach higher velocity and full current. Pitch should not change much.
- Head inertia makes stop events plausibly stronger than start events (Roush ties arm-mode excitation specifically to "sudden stop"). Weight impulse C higher than A.

### Gaps
- No full-stroke (max) seek spec was found in the Seagate 7200.14 manual text that was extracted. The 16–20 ms full-stroke figure is from general knowledge and is unsourced here.
- No acoustic time-trace measurement of a single seek was found showing the separate start, reversal and stop transients, or the settle ring-down length.

## 4. AAM and quiet seek: what they change and why they are quieter

### Takeaway
AAM/quiet-seek modes lower the peak current and smooth the current transitions (less jerk). They do not change the modal frequencies. The result is a seek-level reduction of roughly 6–9 dB with about 10% slower random access. This shows that the loud, "clicky" character comes from the sharp current edges (high-frequency harmonic content) exciting the actuator modes.

### Cited Findings
- AAM is an optional ATA feature trading seek speed for quieter seeks. Lower values mean quieter, slower seeks. — [Wikipedia, Automatic acoustic management](https://en.wikipedia.org/wiki/Automatic_acoustic_management); [ghacks](https://www.ghacks.net/2006/07/06/silence-or-speed-up-your-hard-drive/)
- On the most-quiet setting (128), average random access time rose about 10%. — [search excerpt, ghacks/Hitachi Feature Tool article](https://www.ghacks.net/2007/03/14/reduce-hard-drive-noise/)
- On a Hitachi Deskstar 7K1000.B, quiet mode measured 43 dB and fast mode 49 dB in Tom's Hardware's setup. Fast mode gave up to about 20% better I/O at low queue depth. — [Tom's Hardware, "Acoustically Manage Your Hard Drive"](https://www.tomshardware.com/reviews/terabyte-hitachi-acoustic,2084.html) (search excerpt; page body not retrievable)
- SPCR 2005 data: idle 2.9 B, AAM seek 3.0 B, normal seek 3.8 B. — [SPCR article244](https://silentpcreview.com/article244-page1.html) (search excerpt)
- Seagate 7200.11 1 TB: performance seek 3.2 B vs quiet seek 3.1 B. Seagate's quiet-seek benefit in that generation was small. — [manualsonline mirror](https://powertool.manualsonline.com/manuals/mfg/seagate/720011.html?p=21)
- Mechanism: the quiet-seek patents use gradual or sinusoidal acceleration and deceleration profiles instead of square waves ([US4937689](https://patents.google.com/patent/US4937689), [US6441988](https://patents.google.com/patent/US6441988)). Others limit current in the initial seek stage ([US6449117](https://patents.google.com/patent/US6449117)) or smooth the accel→decel transition ([US7082010](https://patents.google.com/patent/US7082010)).

### Inferences
- What makes a seek "loud and clicky" is broadband, step-like excitation edges reaching 3–9 kHz modes. A synthesis "AAM/quiet" knob could lengthen the excitation impulses (e.g., from <0.1 ms to ~0.5–1 ms raised-cosine), which low-passes the excitation, and reduce gain by about 6 dB. It should not move the resonator frequencies. An "old/performance" mode would do the opposite: sharper edges and stronger high modes.
- The current model uses sub-ms noise impacts. If they are smoothed or long, they act like AAM and suppress the clickiness, which may contribute to the "flat" complaint.

### Gaps
- No published spectra comparing AAM-on and AAM-off seeks were found (which bands drop most).

## 5. Other characteristic sounds: spindle, load/unload, recalibration, click of death

### Takeaway
Idle sound is a steady tonal series at the rotation frequency (7200 rpm gives 120 Hz; 5400 rpm gives 90 Hz) and its harmonics, plus electromagnetic/commutation tones that can reach kHz (one 7200 rpm drive had a 5760 Hz tone, which is 48 × 120 Hz), bearing tones (louder with ball bearings than FDB), and airflow hiss. Head load/unload onto the ramp gives a single audible click. The click of death is repeated sweep-and-park cycles while the drive retries.

### Cited Findings
- Idle tone fundamental = rpm/60, so about 120 Hz for 7200 rpm. Idle noise is attributed to the spindle motor and ball bearings. — [Guri et al., DiskFiltration, arXiv:1608.03431](https://arxiv.org/pdf/1608.03431) (search-result excerpt; the PDF text could not be extracted)
- A 7200 rpm drive had an "unacceptable" tone at 5760 Hz from stator excitation by commutation pulses. — [US5847476, Audible noise reduction in a disc drive](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/5847476) (search excerpt)
- Pure tones link to magnet-pole count and stator harmonics, and become prominent when an electromagnetic frequency nears a structural resonance. — [US8917479](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/8917479) (search excerpt)
- A 3.5" FDB spindle at 7200 rpm showed amplified peaks when the current frequency approached motor natural frequencies, most clearly at 14–20 kHz. — [Chulalongkorn thesis](https://digital.car.chula.ac.th/chulaetd/67169) (abstract)
- Idle level depends on bearing quality, spin speed and disk-stack mass. The industry moved to FDB for acoustics. — [Jiang & Macioce, Roush](https://cdn.mediavalet.com/usva/roush/Rsrqc_YhbU-GP6sYr323gg/4WWZaqVt6EKK92EQL0k7_A/Original/Data-Storage.pdf)
- Higher-speed drives are dominated by disk airflow turbulence. — [Measurement (Elsevier) excerpt](https://www.sciencedirect.com/science/article/abs/pii/S0263224105001132)
- SPCR notes that a drive measures 2–3 dBA lower when the listener or mic faces the drive edge, because the high-frequency whine is directional. — [SPCR search excerpt](https://www.silentpcreview.com/node/207)
- Load/unload: almost all modern drives ramp-load. Head load and park sounds are audible in normal operation. A single click at power-up can be normal. — [Wikipedia, Click of death](https://en.wikipedia.org/wiki/Click_of_death); [Gillware](https://www.gillware.com/?p=6136)
- Click of death: when heads cannot read the firmware or servo data, they sweep, return to the ramp and retry repeatedly until power-off. — [Gillware](https://www.gillware.com/?p=97365); [Rossmann Group](https://rossmanngroup.com/symptoms/clicking-hard-drive). The term originated with Iomega Zip drives. — [Indiana University KB](https://kb.iu.edu/d/ahhd)
- SMART offline activity during idle can raise acoustics to operational (seek) levels. — [Seagate manual](https://www.seagate.com/www-content/product-content/barracuda-fam/desktop-hdd/barracuda-7200-14/en-us/docs/100686584u.pdf)

### Inferences
- 5760 Hz = 48 × 120 Hz. This suggests the commutation tone is a high integer harmonic of rotation, so synthesizing spindle whine as a sparse harmonic comb (120 Hz fundamental, plus a few kHz-range commutation-related lines) plus broadband airflow noise is physically grounded. The 5400 rpm equivalent would be 90 Hz and 4320 Hz, by scaling, not measured.
- A ramp unload is a full-stroke move ending in a mechanical contact with the plastic ramp. It should sound like a long seek plus an extra contact transient. A power-on recalibration is a series of sweeps across the stroke.

### Gaps
- No measured relative levels (dB) were found for load/unload clicks vs seeks.
- No measured spectrum of spindle bearing tones (ball-pass frequencies) was found for a specific desktop drive.

## 6. 1990s vs 2000s/2010s drives

### Takeaway
Early drives (through about the early 1990s) used stepper actuators with a pulsed "zip" sound. Voice-coil drives replaced them and are quieter but "chatter" on rapid seeks. Mid-2000s voice-coil drives without AAM had much louder seeks (about +9 dB over idle) than 2010s drives (+1–3 dB). Older drives were also larger and slower: 1990s 5.25" 4002 rpm drives had 23–34 ms average access versus about 8.5 ms average seek plus 4.16 ms latency later.

### Cited Findings
- Stepper head positioning was abandoned in the early 1990s in favour of voice coils. — [Vogons forum](https://www.vogons.org/viewtopic.php?p=553632) (anecdotal)
- The voice coil "is quieter due to the lack of the 'zip' of the pulsed stepping, but can still chatter if performing rapid seeks". — [Vogons forum](https://www.vogons.org/viewtopic.php?p=553670) (anecdotal user report)
- 1994-era drives (HP C2200A, HP 97560): 5.25", 4002 rpm, average 8 KB access 33.6 / 22.8 ms. — [Ruemmler & Wilkes 1994](https://pages.cs.wisc.edu/~dusseau/Classes/CS537-F05/Readings/ruemmler94introduction.pdf)
- Smaller platters and lighter, stiffer arms mean shorter seeks. — [Ruemmler & Wilkes 1994](https://pages.cs.wisc.edu/~dusseau/Classes/CS537-F05/Readings/ruemmler94introduction.pdf)
- Drives got quieter historically as ball bearings improved, then moved to FDB. — [Jiang & Macioce, Roush](https://cdn.mediavalet.com/usva/roush/Rsrqc_YhbU-GP6sYr323gg/4WWZaqVt6EKK92EQL0k7_A/Original/Data-Storage.pdf)
- Normal-vs-AAM seek of 3.8 vs 3.0 B (2005), against Seagate 2010s seek being only 0.1–0.2 B over idle. — [SPCR](https://silentpcreview.com/article244-page1.html); [Seagate](https://www.seagate.com/www-content/product-content/barracuda-fam/desktop-hdd/barracuda-7200-14/en-us/docs/100686584u.pdf)

### Inferences
- An "old-school" preset should use slower seeks (2–3× longer durations), louder and sharper seek transients (performance mode, less damping, so higher Q and slightly lower mode frequencies from larger, heavier arms), audible ball-bearing spindle tones, and possibly 5400 rpm or 3600–4500 rpm fundamentals. A stepper preset would replace one smooth move with a train of discrete step clicks at the step rate (the "zip"). The step rate is unsourced.

### Gaps
- No measured spectra or levels for stepper-era drives were found, and no stepper step rates (steps/s).

## 7. Drive-in-a-case sound

### Takeaway
Much of what people remember is structure-borne seek vibration driving case panels and drive cages. Decoupling a drive by suspension reduced seek noise by about 12 dBA in one test, while spinning platters contributed only about +2 dBA. The case adds low-mid "thunk" content from panel resonances and the hard mount, which the bare drive radiates weakly.

### Cited Findings
- In a soundproof box with the meter at 10 cm, rubber-band suspension cut seek noise (WD Gold, small-block writes) by about 12 dBA against an in-case-like hard mount. The platters themselves added only about +2 dBA. — [HWCooling.net](https://www.hwcooling.net/en/?p=7404)
- Users report that the side panel and drive cage pick up and amplify drive vibration. Suspension or soft pads reduce seek noise much more than grommets. — [AnandTech forums](https://forums.anandtech.com/threads/do-rubber-grommets-really-decrease-case-noise.1307889/latest); [Tom's Hardware forums](https://forums.tomshardware.com/threads/how-to-avoid-resonant-vibrations-of-harddisks-in-a-case.3884195/post-23522477) (anecdotal)
- Inside the drive, structure-borne transmission through rigid screws, amplified by housing resonances, is a primary path. — [Jiang & Macioce, Roush](https://cdn.mediavalet.com/usva/roush/Rsrqc_YhbU-GP6sYr323gg/4WWZaqVt6EKK92EQL0k7_A/Original/Data-Storage.pdf)
- Seek reaction torque: the VCM accelerates the arm, so an equal and opposite reaction acts on the base. This rotational vibration is why drives and enclosures are specified for rotational vibration. — Inferred mechanism; the Seagate manual gives operating vibration specs (e.g., 0.25 G at 350–500 Hz) but does not discuss reaction torque. [Seagate manual](https://www.seagate.com/www-content/product-content/barracuda-fam/desktop-hdd/barracuda-7200-14/en-us/docs/100686584u.pdf)

### Inferences
- An "in-case" layer for Whirr could convolve or filter the seek excitation through a few low-Q, low-mid panel modes (roughly 100–800 Hz) at modest level, plus a short early-reflection/box coloration. The ~12 dBA difference suggests case coupling can dominate the bare drive's radiation. This argues for a small amount of low-mid body, but tied to the case, not to the drive's own modes. The earlier bass-heavy model may have put this energy in the drive's own modes or at too high a level.
- The SPCR forum's "500–2 kHz" perception plausibly reflects this case-coupled, off-axis sound. The bare-drive A-weighted measurements say 2–8 kHz. A realistic blend probably needs both bands: kHz pings from the drive plus a damped low-mid knock from the case.
- Reaction torque at each current edge is broadband and low-frequency. This physically justifies adding a short low-mid thump at the start and stop impulses when the "mounted in case" option is on.

### Gaps
- No measured case-panel resonance frequencies or transfer functions (drive cage to panel) were found.
- No measured spectra of in-case vs bare-drive seeks were found. The HWCooling article's charts were not in the retrievable text.

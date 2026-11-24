# Procedural / physically informed synthesis of short mechanical impacts and clicks (applied to HDD seek sounds)

Scope note: These notes cover synthesis methods and perceptual factors for realistic mechanical clicks, plus a concrete recipe for Whirr's seek sounds. Whirr v1 used 4 damped sinusoids and sounded tonal, like a woodblock, and too bassy. v2 is noise bursts through about 7 bandpasses (Q 3 to 8), and the user calls it "flat". Every numeric value with no citation next to it is marked as an inference. Several PDFs (van den Doel & Pai; Klatzky, Pai & Krotkov; Avanzini & Rocchesso SMC04) were extracted to text locally and read directly. ClatterDrive parameters were read from its source code on GitHub (master branch, fetched 2026-11-23).

## Modal synthesis for impacts: modes, damping, excitation, noise transient, strike position

### Takeaway
The standard physically informed model is excitation × modal resonator bank. Each mode is a decaying sinusoid whose decay rate is proportional to frequency (d_n = ρ·f_n), and ρ (internal friction) carries the material. Excitation is a short force pulse, and its duration T sets hardness and brightness: shorter means brighter and harder. The pulse shape itself matters little. Hard impacts also contain micro-collisions (rapid re-contacts), which can be imitated with a short burst of impulses. Whirr v2 replaces the modal bank with very low-Q noise filters, so it has none of the decaying-partial structure that carries material identity.

### Cited Findings
- Modal model: a vibrating object is a bank of damped oscillators excited by an external force. Frequencies and dampings come from the object's geometry and material, and the modes' gains (amplitudes) come from the contact location. — [van den Doel & Pai, "Modal Synthesis for Vibrating Objects"](https://persianney.com/kvdoelcsubc/publications/modalpaper.pdf)
- Damping law: following Wildes & Richards and Krotkov & Klatzky, "the dampings d_n are just proportional to the modal frequencies f_n, i.e., d_n = ρ f_n", with ρ set by internal friction. Small ρ gives relatively undamped, metal-like models, and large ρ gives highly damped plastic- or wood-like models. The relation is "only approximately valid" in real objects, but it evokes material convincingly in perception studies. — [van den Doel & Pai](https://persianney.com/kvdoelcsubc/publications/modalpaper.pdf)
- Mode count: the bell demo has a slider for 1 to 50 modes. Sorting modes by importance gives graceful degradation when fewer are used. The paper gives no single "enough" number. — [van den Doel & Pai](https://persianney.com/kvdoelcsubc/publications/modalpaper.pdf)
- Mode gains depend on the strike location. Measured models store gains at K contact points (the UBC ACME robot recorded impacts at many surface points) and interpolate between three points. — [van den Doel & Pai](https://persianney.com/kvdoelcsubc/publications/modalpaper.pdf)
- Excitation: the two main characteristics of an impact are energy transfer (force magnitude) and hardness (force duration). Experiments with several force profiles showed "the exact details of the shape are relatively unimportant". The suggested BangForce is F(t) = F_max(1 − cos(2πt/T)) for 0 ≤ t ≤ T. A duration of about 50 ms reads as "a very soft 'thud'", and anything longer is too smeared to be audible. — [van den Doel & Pai](https://persianney.com/kvdoelcsubc/publications/modalpaper.pdf)
- Micro-collisions: "there are sequences of very fast contact separations and collisions during hard impacts", caused by modal vibration. They "can be simulated by a short burst of impulse trains at the dominant modal frequencies". — [van den Doel & Pai](https://persianney.com/kvdoelcsubc/publications/modalpaper.pdf)
- Nonlinear contact (Hunt–Crossley / Marhefka–Orin): f = k·x^α + λ·x^α·ẋ (elastic plus dissipative term, compression x). Example hammer values are m = 10⁻² kg, k = 1.5·10¹¹ N/m^α, μ = 0.6 s/m, α = 2.8 (close to piano-hammer felt), v_in = 1 to 4 m/s. Contact time depends on μ, α, m/k and impact velocity, and is "almost independent" of the dissipative component. — [Avanzini & Rocchesso, SMC 2004](https://air.unimi.it/retrieve/dfa8b99e-f744-748b-e053-3a05fe0a3a96/avanzini_smc04_finalsub.pdf); [Avanzini & Rocchesso, DAFx-01](https://avanzini.di.unimi.it/downloads/publications/avanzini_dafx01_revised.pdf)
- Perceived hardness tracks the spectral centroid of the attack transient (Freed). The centroid is "strongly correlated to the contact time", and as contact time grows the initial centroid "bump" drops. The centroid also depends on the dissipative term and rises for low α. — [Avanzini & Rocchesso, SMC 2004](https://air.unimi.it/retrieve/dfa8b99e-f744-748b-e053-3a05fe0a3a96/avanzini_smc04_finalsub.pdf); [Papetti et al., DAFx-09](https://avanzini.di.unimi.it/downloads/publications/papetti_dafx09.pdf)
- PhISEM (Cook): for sounds made of many random collisions, the sum of exponentially decaying noise events equals one noise source times one decaying envelope. Body resonances are a biquad, plus one extra biquad per extra weak resonance. A maraca needs 2 random numbers, 2 exponential decays and 1 biquad per sample. Collision probability is roughly constant, giving exponentially distributed waiting times. — [Scavone, McGill PhISM notes](https://caml.music.mcgill.ca/~gary/618/week12/phism.html); [Csound STKShakers](https://csound.com/docs/manual/STKShakers.html)
- Commuted synthesis: when exciter, resonator and body are approximately linear time-invariant, the body IR can be pre-convolved with the excitation and stored as an "aggregate excitation" table. The most heavily damped modes go into the table, and the least damped can stay as recursive filters. — [J. O. Smith, PASP: Commuted Synthesis](https://ccrma.stanford.edu/~jos/pasp05/Commuted_Synthesis_Strings.html); [JOS: extracting parametric resonators](https://ccrma.stanford.edu/~jos/pasp/Extracting_Parametric_Resonators_Nonparametric.html)

### Inferences
- In this framework, v2 (white noise → Q 3 to 8 bandpasses) is a noise-excited, very heavily damped resonator bank. With Q ≤ 8, every band dies within a few cycles. The ear hears no partials with their own decay slopes, so the material and object cue is missing. That plausibly explains "flat". v1 had the opposite problem: 4 sparse, long-lived, low partials, which read as a tuned woodblock.
- The mapping from Q to decay rate for a 2-pole resonator is amplitude ∝ exp(−π f t / Q). Then t_e (1/e time) = Q/(π f), and d_n = ρ f_n means a constant Q across modes. So "damping ∝ frequency" is the same as using one Q for every mode, which is what v2 does, only at too low a value. (Derived from the Klatzky equations below.)
- Most HDD-click realism will come from: (a) a short, bright, hard contact excitation (T ≈ 0.05 to 0.3 ms, raised cosine or Hunt–Crossley shaped) rather than a sub-ms white-noise burst; (b) 10 to 30 inharmonic modes with a few clearly ringing partials; (c) micro-bounce sub-impulses; (d) per-instance variation of mode gains (strike position). The T range is an inference: metal-on-metal contact in a small mechanism should be far shorter than the 50 ms "thud", and a 0.1 ms raised-cosine pulse has its first spectral null near 20 kHz, so it is effectively flat up to Nyquist at 48 kHz.
- Avanzini/Papetti suggest an upgrade path: drive the modal bank with a Hunt–Crossley contact (α ≈ 1.5 to 3) so that a harder or faster hit automatically gives a shorter contact and a brighter attack. Seeks of different lengths, and so different velocities, then get brightness changes for free. For an offline renderer, a precomputed raised-cosine pulse with T and amplitude both linked to "impact velocity" approximates this well enough.

### Gaps
- van den Doel & Pai's FoleyAutomatic (SIGGRAPH 2001) and Cook's book *Real Sound Synthesis for Interactive Applications* were not read directly, so mode counts or recipes specific to them are not captured. The modal-paper notes above come from the companion "Modal Synthesis for Vibrating Objects" chapter.
- No source gave measured contact durations for metal-on-metal contacts at HDD scale (actuator crash stop, latch).

## Material perception: metal vs plastic vs wood, and what an aluminum/steel HDD implies

### Takeaway
Under the linear damping model, material is cued mainly by the frequency-independent decay parameter τ_d = 1/(π·tanφ), where the 1/e decay time of a mode is t_e = τ_d / f. In Klatzky et al., the 50% category boundaries were roughly τ_d ≈ 2.9 (rubber), 3.2 (wood), 126 (glass) and 450 (steel). Whirr v2's Q 3 to 8 is τ_d ≈ 1 to 2.5, which falls in the rubber/cardboard region. Raw aluminum and steel have tiny loss factors (bell-like), but an assembled, screwed and mounted drive is dominated by joint damping (η ≈ 0.03 to 0.07), which puts realistic HDD decays in a "hard but damped metal" zone, τ_d ≈ 5 to 100. Note that Giordano & McAdams found weaker support for damping as a cue with real recorded plates.

### Cited Findings
- Model: b(f) = π·tan(φ)·f. Then t_e = 1/(π f tanφ), and τ_d = 1/(π tanφ) is a hypothesized shape-invariant material constant. — [Klatzky, Pai & Krotkov 2000](https://www.cs.ubc.ca/labs/lci/papers/docs2000/pai-KlaPai00.pdf)
- Stimuli used τ_d ≈ 3, 9, 30, 95, 300 (equal log steps). Decay played "a substantially larger role" than frequency in similarity judgments. Decay rate, not total energy or duration, drove judgments. — [Klatzky, Pai & Krotkov 2000](https://www.cs.ubc.ca/labs/lci/papers/docs2000/pai-KlaPai00.pdf)
- Category task (rubber, wood, glass, steel): the critical log τ_d giving 50% assignment was .46, .50, 2.10 and 2.65 for rubber, wood, glass and steel respectively. As τ_d rose, glass and steel responses rose. Frequency also mattered: "glass" rose with frequency and "rubber" fell with it. — [Klatzky, Pai & Krotkov 2000](https://www.cs.ubc.ca/labs/lci/papers/docs2000/pai-KlaPai00.pdf)
- Conflicting evidence: with real recorded impacts on steel, glass, wood and plexiglass plates, listeners reliably separated the gross categories (steel/glass vs wood/plexiglass). Within a category they relied mainly on frequency, and there was "overall poor support" for damping as the key cue. Signal duration explained the results equally well. — [Giordano & McAdams 2006, JASA 119(2)](https://eprints.gla.ac.uk/68504) (via search summary)
- Material loss factors vary widely by source. Aluminum is listed at 0.0001 to 0.02 (COMSOL) or 2 to 3 × 10⁻⁴ (*Principles of Vibration*), and steel at 0.0001 to 0.01 or 5 to 8 × 10⁻⁴. A "metal structure with joints" is 0.03 to 0.07, and joints, boundaries and bearings dominate damping in built structures. η = 2ζ. — [COMSOL damping blog](https://www.comsol.com/blogs/damping-in-structural-dynamics-theory-and-sources/?setlang=1); [GlobalSpec / Principles of Vibration App. C](https://www.globalspec.com/reference/74164/203279/appendix-c-assorted-material-constants); [SolidWorks viscous damping ratios](https://help.solidworks.com/2017/English/SolidWorks/cworks/r_viscous_damping_ratios.htm)
- Seagate describes normal head movement as a "light, intermittent click" and parking as a single louder, "hard click". It also says the mounting surface (e.g., a wooden desk) can "act like a speaker". — [Seagate KB](https://www.seagate.com/support/kb/identifying-hard-drive-sounds-and-determining-what-they-mean/)

### Inferences
- Conversion: for a 2-pole resonator, Q = π·τ_d = 1/tanφ ≈ 1/η. (From t_e = τ_d/f and t_e = Q/(πf).)
  - v2 at Q 3 to 8 → τ_d ≈ 1 to 2.5, below Klatzky's rubber and wood boundaries. This is the most likely physical explanation of "flat / dead / cardboard".
  - Raw aluminum (η ~ 3·10⁻⁴) → Q ~ 3000 → bell. That is unrealistic for a mounted drive.
  - Jointed metal structure (η 0.03 to 0.07) → Q ≈ 15 to 33, τ_d ≈ 5 to 10.
  - Small, stiff, well-clamped parts (actuator arm, cover plate modes) plausibly sit at η ≈ 0.005 to 0.02 → Q ≈ 50 to 200, τ_d ≈ 16 to 64. In the "glass/metal-leaning but not ringing" zone, this would read as a hard metal tick.
- Practical target: give the seek bank a spread of Qs, with 2 to 5 "ringing" partials at Q 60 to 250 (1 to 6 kHz) and the remaining partials/body at Q 10 to 40. With t_e = Q/(πf), a 3 kHz mode at Q 150 has t_e ≈ 16 ms and a 300 Hz body mode at Q 15 has t_e ≈ 16 ms. That keeps the whole click under about 50 ms (to −40 dB) while still being "metallic". These are starting values to tune by ear.
- Avoid v1's bassiness by keeping modes below about 500 Hz at low gain (−12 to −20 dB re the main partials) and short. The perceived click "body" should sit around 1 to 5 kHz, since a drive is small and stiff (inference, consistent with ClatterDrive putting actuator modes at 820 to 1810 Hz and cover modes up to 1.28 kHz; see below).
- Following Giordano & McAdams, frequency content (centroid and spacing) also matters a lot, so tune both the mode frequencies and the Qs, not just the damping.

### Gaps
- No measured modal data (frequencies, Q) for a real 3.5" HDD casting, cover, or actuator arm was found. Patent literature only says the VCM/actuator assembly is stiff, with natural frequency > 3.5 kHz ([US 6140791](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/6140791)).
- Lakatos, McAdams & Caussé and Wildes & Richards were not read directly.

## Andy Farnell, *Designing Sound*: click / switch recipes and principles

### Takeaway
Farnell's switch practical builds realistic clicks as composites. Several short noise→bandpass sub-clicks are offset in time (0, 30, 140, 150 ms) at different centres (3 to 7 kHz, Q 8), all feeding a shared resonant "body" made from a 700 Hz bandpass in a delay-feedback loop. A version made from summed sines gives a modal "plastic" click. A multi-event structure plus a body resonance is exactly what a single noise-burst bank is missing.

### Cited Findings
- Practical 19 (Switches) offers three levels of detail: a simple click from noise plus one bandpass; a click from "several sines added to give a modal 'plastic' click"; and a composite switch of filtered noise plus additive clicks. — [Farnell, Designing Sound, Practical 19 (MIT Press companion)](https://mitp-content-server.mit.edu/books/content/sectbyfn/books_pres_0/8375/designing_sound.zip/practical19.html)
- Concrete patch values read from that page's Pd patches (Farnell, Practical 19):
  - **switch001:** noise → bp~ 5000 Hz, Q 12. Envelope: 1 ms attack, 20 ms decay, applied twice, so the amplitude is effectively squared, giving a faster-than-linear tail.
  - **switchclick abstraction:** noise → bandpass, Q 8. Arguments are attack ms, decay ms and centre Hz.
  - **switch3 (push button):** 4 sub-clicks, each with a 1 ms attack: 0 ms at 4 kHz with 20 ms decay; 30 ms at 3 kHz with 50 ms decay; 140 ms at 4 kHz with 20 ms decay; 150 ms at 7 kHz with 20 ms decay. All are summed into a "body" bus with a 50 ms delay line and a 700 Hz bandpass (Q 3) in the feedback loop at 0.1 gain.
  - **shortping:** two sines at 10.5 kHz and 9.453 kHz with a 50 ms multiplicatively steepened decay.
  - **slideclunk:** three-phasor "pnoise" → 1 kHz highpass → two one-pole lowpasses.
  - **slideswitch:** events at 0, 200 and 300 ms, plus a 25 ms feedback delay with a 400 Hz lowpass at 0.3 feedback.

  — [MIT Press companion](https://mitp-content-server.mit.edu/books/content/sectbyfn/books_pres_0/8375/designing_sound.zip/practical19.html)

### Inferences
- The structural lessons for HDD seeks: (1) a click is several sub-events, not one; (2) each sub-event has its own spectral centre; (3) all of them excite a shared body resonance; (4) steepened (squared) envelopes sound more "mechanical" than linear or exponential ones. Farnell's sub-click spacing (tens of ms) fits switches. For a seek, the spacing should be the seek time (about 1 to 15 ms), and settle sub-events should be about 0.3 to 3 ms apart (inference; see the HDD section).
- Farnell's bandpass Q of 8 to 12 at 3 to 7 kHz works for a *plastic* switch. For a *metal* HDD, push some components to higher Q, per the material section.

### Gaps
- The book's text discussion (Chapter on "behavioural vs physical" models, and practicals on motors and machines) was not retrieved, only the companion patch pages. A relay-specific recipe was not found.

## Perceptual realism: variation, transient shape, space, dynamics, nonlinearity

### Takeaway
"Alive" comes from (1) per-instance micro-variation of every parameter, not just pitch; (2) a crisp, very short attack whose brightness scales with intensity; (3) keeping natural dynamics instead of peak-normalizing every hit; (4) placing the source in a body and space (enclosure, desk, small room); (5) small irregularities such as micro-bounces, rattles and settle wobbles. Game-audio practice uses about ±10% pitch (±1.6 semitones) and 3 or more variants. A single physical object should vary far less in pitch.

### Cited Findings
- Game-audio rule of thumb: pitch randomization of ±0.1 multiplier (0.9 to 1.1) is described as an "industry standard". Use at least 3 variants, since 2 random variants become monotonous. — [Uppsala game-design blog on pitch variation](https://babel.speldesign.uu.se/2018/03/01/2018-03-01-maximizing-your-audio-budget-using-pitch-variation/); [Game Developer: The power of pitch shifting](https://gamedeveloper.com/audio/the-power-of-pitch-shifting)
- Modulate volume and pitch only "a tiny bit", or the source sounds like it is moving. Use more pitch variation than volume variation. — [GameDev Academy FMOD tutorial](https://gamedevacademy.org/hey-listen-sound-design-with-unity-fmod-part-2/)
- Repetitive sources (footsteps, gunshots, several per second) are the worst repetition cases, and pitch shifting mitigates them. — [Game Developer](https://gamedeveloper.com/audio/the-power-of-pitch-shifting)
- Hardness and brightness: the attack's spectral centroid correlates with contact time, and perceived hardness follows that centroid. — [Avanzini & Rocchesso SMC 2004](https://air.unimi.it/retrieve/dfa8b99e-f744-748b-e053-3a05fe0a3a96/avanzini_smc04_finalsub.pdf)
- Micro-collisions during hard impacts. — [van den Doel & Pai](https://persianney.com/kvdoelcsubc/publications/modalpaper.pdf)
- Mounting and space: the drive's sound is amplified by the mounting surface ([Seagate](https://www.seagate.com/support/kb/identifying-hard-drive-sounds-and-determining-what-they-mean/)). ClatterDrive models this with separate base, cover, actuator, enclosure and desk modal banks, and offers acoustic presets for bare drive, PC case, external enclosure, and drive on desk ([ClatterDrive source](https://github.com/alexyorke/clatterdrive)).
- Klatzky et al. found that decay rate, not total energy, drove similarity. They had to equalize energy in Experiment 2 because faster decays and higher frequencies otherwise gave shorter, lower-energy sounds. — [Klatzky, Pai & Krotkov 2000](https://www.cs.ubc.ca/labs/lci/papers/docs2000/pai-KlaPai00.pdf)

### Inferences
- **Variation budget for one physical drive** (inference: smaller than the game-audio ±10%, because it is the same object):
  - Global mode-frequency scale ±0.5 to 1.5% per hit. Thermal and strike-position effects are small; whole-bank pitch shifts larger than about 3% will sound like a different drive.
  - Per-mode gain ±2 to 4 dB (models strike position or arm angle). This gives the strongest "same object, different hit" impression.
  - Per-mode decay ±10 to 20%.
  - Excitation width T ±30%, linked to level: louder means shorter T and brighter.
  - Overall level ±1.5 to 3 dB, plus systematic level by seek distance.
  - Sub-event timing jitter ±5 to 15%.
  - Random noise seed per instance.
  - Bank size: at least 8 to 16 rendered variants per seek class, and never the same variant twice in a row (round-robin or shuffle without repeat).
- **Don't peak-normalize per buffer.** Peak normalization flattens the natural loudness differences between short and long seeks and between soft and hard events. A good fix is to normalize the whole bank to one reference (or to loudness), then scale each variant by a physical intensity factor. Use per-voice gain in AVAudioEngine only for the global mix.
- **Transient:** no pre-ring (use causal IIR resonators, or minimum-phase filters if FIR). Attack in less than 0.1 ms; the excitation is the attack.
- **Space:** add early reflections and a short tail. Options are a 5 to 30 ms small-room or enclosure IR, or a tiny FDN or a few taps at 1 to 8 ms, mixed about 12 to 20 dB below the dry signal. Fully dry, close-mic-like synthesis is a known source of "artificial" (inference). A drive inside a case also loses top end: ClatterDrive's case preset lowpasses at 3.6 kHz and the bare-drive preset at 6.2 kHz.
- **Nonlinearity and "dirt":** add very low-level broadband noise and hum underneath (spindle and air), so clicks are not on digital silence. Add mild amplitude-dependent soft clipping, or a rattle (a secondary impulse triggered when the body displacement exceeds a threshold), for hard parks only. Both are inferences; no source quantified them for HDDs.

### Gaps
- No GDC or peer-reviewed source gave numeric dB ranges for volume randomization. The ±dB values above are inferences.
- No study was found on JND for frequency jitter between repeated mechanical clicks.

## HDD-specific procedural designs (ClatterDrive and others)

### Takeaway
ClatterDrive is the only substantial open procedural HDD model found. Its structure is event-driven contact and reaction forces, then a two-envelope (fast minus slow exponential) contact pulse, then source routing into five damped modal banks (base, cover, actuator, enclosure, desk), then radiation (structure plus airborne), then a final HP/LP filter. Its modal tables give concrete starting frequencies, but its damping ratios (ζ 0.026 to 0.135, Q ≈ 4 to 19) are fairly low, and the code labels them "engineering priors", not measurements. The repo has no license (GitHub API reports license null), so use it as reference only and do not copy code. Patents confirm that seek noise comes from abrupt VCM current changes ("jerks") at seek start and end, with VCM current spectrum spanning DC to several kHz.

### Cited Findings
- ClatterDrive synthesizes procedurally from runtime events (seek, park, wake, transfer) with no prerecorded HDD samples. Its model tiers are "physical_state", "physical_model" and "artistic_calibration". — [ClatterDrive README](https://github.com/alexyorke/clatterdrive); [demo](https://alexyorke.github.io/clatterdrive/)
- Contact pulse (`physics.step_stiffness_damping_contact`): the fast state is "local contact spring response" and the slow state is "mounting/body relaxation subtracted from it". Output = fast − slow, each updated as (state + excitation)·exp(−dt/τ). Wedge or servo reaction events use τ_fast = 0.22 ms and τ_slow = 1.35 ms (slow input ×0.58). Contact or park events use τ_fast = 0.34 ms and τ_slow = 2.60 ms (×0.72), both divided by mount_damping (0.70 to 1.55 by preset). — [ClatterDrive `clatterdrive/audio/core.py`, `physics.py`](https://github.com/alexyorke/clatterdrive)
- Event force magnitudes (normalized): park stop contact 0.40; park latch 0.22; calibration latch 0.18; head load (ramp release) 0.26; voice-coil force transfer = |Δtorque| × 0.56 in seek mode (0.10 track-follow, 0.30 other); sequential track-change tick 0.045 × gain. Healthy heads never inject head/media contact impulses. — [ClatterDrive `physics.py`](https://github.com/alexyorke/clatterdrive)
- Modal tables, written as (Hz, damping ratio ζ, gain), for the "desktop-engineering-v1" calibration:
  - **base:** (72, .095, .92), (118, .082, .74), (168, .070, .56), (248, .060, .34)
  - **cover:** (212, .055, .44), (412, .048, .28), (576, .042, .24), (822, .038, .18), (1208, .034, .12)
  - **actuator:** (980, .036, .40), (1325, .032, .56), (1680, .028, .34)
  - Other drive calibrations scale these: actuator ranges from 820 to 1100 to 1420 Hz up to 1040 to 1410 to 1810 Hz.
  - Shared **enclosure** modes: (58, .120), (96, .104), (146, .088), (220, .074).
  - Shared **desk** modes: (44, .135), (82, .110), (142, .094).
  - Each bank is discretized as an exact damped 2-pole state update (decay = exp(−ζ ω_n / fs)).
  — [ClatterDrive `clatterdrive/audio/calibration.py`, `core.py`](https://github.com/alexyorke/clatterdrive)
- Routing (non-startup): actuator force = 0.24·wedge + 0.18·|actuator velocity| + 0.10·contact + … ; desk force = desk_coupling·(0.44·base + 0.18·cover + 0.58·wedge + 0.26·contact). Airborne output includes 0.22·actuator_gain·actuator_signal and 0.12·cover_gain·cover_signal. — [ClatterDrive `physics.py`](https://github.com/alexyorke/clatterdrive)
- Acoustic presets (final HP/LP; desk/enclosure coupling): bare_drive_lab 35 Hz/6.2 kHz, desk .06, encl .08; mounted_in_case 55 Hz/3.6 kHz, desk .32, encl 1.15, mount damping 1.35; external_enclosure 60 Hz/3.0 kHz; drive_on_desk 48 Hz/3.9 kHz, desk .44. — [ClatterDrive `clatterdrive/profiles.py`](https://github.com/alexyorke/clatterdrive)
- ClatterDrive's own docs say its numbers are "normalized broad assumptions until measured inertia/mount transfer data exists". Its modal bank is a "plausible model" whose "gains are calibrated for sound". — [ClatterDrive `physics.py` docstrings](https://github.com/alexyorke/clatterdrive)
- Seek mechanics (patents): bang-bang seeks produce square current waveforms whose high harmonics excite head-gimbal and structure resonances ([US 6441988](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/6441988)). Abrupt current changes at seek start and end cause vibration ([US 6148240](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/6148240); [US 7082010](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/7082010)). Even with sinusoidal acceleration, "jerks" at seek start and end still generate noise ([US 7289290](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/7289290)). Seek current spectrum spans DC to several kHz ([US 6930853](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/6930853)). The VCM is rigid with natural frequency > 3.5 kHz ([US 6140791](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/6140791)). One prior approach attenuated seek components above about 2.5 kHz ([US 5291110](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/5291110)). Seek acoustics are typically about 45 to 50 dB, with seeks adding about 5 to 10 dB of sound power ([US 6148240](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/6148240), patent background).
- A Hackaday-covered retro dongle synthesizes seek-like clicks from the HDD activity LED. The article attributes the sound to the head "coming to stop abruptly on a sector". — [Hackaday 2022](https://hackaday.com/2022/09/26/tiny-dongle-brings-the-hard-drives-song-back-to-updated-retrocomputers); also [HDDSynth on GitHub](https://github.com/MaverickUK/HDDSynth) (not inspected)

### Inferences
- **A seek should be (at least) a two-event gesture:** an acceleration-onset "jerk" click, a short VCM "coast" buzz, then a deceleration/settle click. The settle click is usually the louder one, followed by 1 to 3 tiny settle ticks or servo wobble. This follows from the patents' "jerks at start and end". The claim that the end click is louder is a sound-design inference, consistent with the "head stopping abruptly" description.
- ClatterDrive's frequencies are useful as a low/mid body layer. For a crisp desktop-HDD "tick", Whirr also needs content above 2 kHz (the VCM > 3.5 kHz resonance; head-gimbal resonances). Note that ClatterDrive's own LP of 3.6 to 6.2 kHz removes much of that. Whirr's 7.5 kHz LP is reasonable for a bare or desk drive.
- ClatterDrive's fast-minus-slow exponential pulse is a cheap band-limited contact force: about a 0.2 to 0.3 ms rise/fall with a slower negative recovery. It is an alternative to the raised-cosine pulse.

### Gaps
- No SuperCollider, Max, or Web Audio HDD patches were found, and no film or game foley write-up with concrete HDD synthesis parameters.
- No measured HDD seek spectra (with frequency peaks) were found in accessible sources. Only patents describing mechanisms were found.
- Typical seek timings (track-to-track about 0.5 to 1 ms, average about 8 to 9 ms, full stroke about 15 to 20 ms for 7200 rpm desktop drives) come from general knowledge, not a source fetched here. Verify them against a drive datasheet.

## Hybrid approaches: recorded excitation or IRs, CC0 recordings, granular use

### Takeaway
The best realism per unit of effort is probably hybrid. Keep the procedural seek event structure and modal bank, but derive mode frequencies and Qs (or a short body/enclosure IR) from a real CC0 HDD recording. Then convolve the synthesized excitation with that IR (commuted synthesis), which fits Whirr's offline pre-rendering well. Pure sample playback gives realism but limited control and variation. Fully procedural gives control but needs careful tuning.

### Cited Findings
- Commuted synthesis: excitation and body IR are pre-convolved into an "aggregate excitation" table. The lightly damped modes can stay parametric (recursive filters) and the heavily damped ones go into the table. — [J. O. Smith, PASP](https://ccrma.stanford.edu/~jos/pasp05/Commuted_Synthesis_Strings.html); [JOS: parametric resonators from nonparametric](https://ccrma.stanford.edu/~jos/pasp/Extracting_Parametric_Resonators_Nonparametric.html)
- Measured modal models: the UBC ACME robot recorded impacts at many points on objects and fitted modal models (frequencies, dampings, gains) from them. — [van den Doel & Pai](https://persianney.com/kvdoelcsubc/publications/modalpaper.pdf)
- Freesound CC0 hard-drive recordings (found with the CC0 license filter; individually verified where noted):
  - "MTrk_Internal Hard Drive Defrag_Clicks Clanks_2_FSP4824.wav" by ericstrausser (#114173). Verified **Creative Commons 0**; 48 kHz, 24-bit stereo WAV. The mic was placed *inside* a noisy drive during a defrag. The page lists duration 1:00.06, while the search card showed about 6 s, so check. Siblings are #114172 and #114174. — [Freesound 114173](https://freesound.org/people/ericstrausser/sounds/114173/)
  - "1990s Compaq Hard Drive, Spooling Up, Turning Off – Close Perspective Memory Access Noise" by jaegrover (#262872, about 18 s, "clicking"). — [Freesound](https://freesound.org/people/jaegrover/sounds/262872/)
  - "hard disk drive (Seagate, 1999)" by viertelnachvier (#321503, about 17 s, mentions heads). — [Freesound](https://freesound.org/people/viertelnachvier/sounds/321503/)
  - "PC Hard Drive noises" by sad3d (#500168, about 11 s). — [Freesound](https://freesound.org/people/sad3d/sounds/500168/)
  - "Skreechy hard drive" by neopolitansixth (#563344); spin-up and shutdown clips #331710, #432147, #110552 (useful for spindle and park).

  All of these were listed under the CC0 license filter. — [Freesound search, CC0 filter](https://freesound.org/search/?q=hard+drive&f=license%3A%22Creative+Commons+0%22)
- Freesound's CC0 is the CC Zero 1.0 public-domain dedication. — [Freesound FAQ](https://www.freesound.org/help/faq)

### Inferences
- **Trade-offs:**
  - *Pure samples* are authentic, but their mic placement and noise floor are baked in, each one is a single drive, it is hard to vary seek length, and app bundle size is an issue (fine for CC0, though attribution is good practice).
  - *Fully procedural* gives full control, tiny size, and infinite variation, but risks "synthetic" unless modes, Qs and the event structure are right.
  - *Hybrid* (modes or IR extracted from a CC0 recording, procedural events and variation) is likely the best of both. The ericstrausser in-drive recordings are well suited to extracting actuator and cover modes, since the mic was inside the drive.
- **Extraction recipe (inference):**
  1. Isolate 10 to 20 clean seek clicks.
  2. Average their magnitude spectra to find stable peaks; these are the modes.
  3. Estimate each peak's decay with a bandpass-and-envelope fit, or with ESPRIT/Prony.
  4. Use those as the modal table, *or* use a de-noised 20 to 60 ms click tail directly as an FIR "body IR". Convolve it with synthesized excitations and micro-bounce trains of varying T and amplitude, which is commuted synthesis.

### Gaps
- Licenses for every listed Freesound item except #114173 were inferred from the CC0 search filter, not from each page. Verify per item before bundling.
- No published HDD enclosure or case impulse responses were found.

## Recommended improved synthesis recipe for seeks (addressing "flat")

### Takeaway
Replace "two white-noise blips → 7 low-Q bandpasses → normalize" with a structured event and a modal bank:

1. A seek is a gesture: start jerk, then VCM coast buzz, then stop/settle click, then 1 to 3 settle ticks.
2. Each event uses a short shaped contact pulse plus a micro-bounce train.
3. Pulses excite a 12 to 24 mode inharmonic modal bank with mixed Qs (a few ringing metal partials at Q 60 to 250, the rest at Q 10 to 40) and decay ∝ 1/f.
4. A low-gain short body/desk layer is added.
5. Then comes a short early-reflection space, and gentle LP/HP.
6. Per-instance micro-variation is applied, and the bank is loudness-normalized, not peak-normalized per buffer.

Every number below is an inference and starting point, grounded in the cited models above.

### Cited Findings
- Building blocks used: d_n = ρ f_n damping ([van den Doel & Pai](https://persianney.com/kvdoelcsubc/publications/modalpaper.pdf)); τ_d category thresholds ([Klatzky et al. 2000](https://www.cs.ubc.ca/labs/lci/papers/docs2000/pai-KlaPai00.pdf)); raised-cosine contact pulse and micro-collision trains ([van den Doel & Pai](https://persianney.com/kvdoelcsubc/publications/modalpaper.pdf)); contact time → centroid → hardness ([Avanzini & Rocchesso](https://air.unimi.it/retrieve/dfa8b99e-f744-748b-e053-3a05fe0a3a96/avanzini_smc04_finalsub.pdf)); multi-event composite click with shared body resonance ([Farnell Practical 19](https://mitp-content-server.mit.edu/books/content/sectbyfn/books_pres_0/8375/designing_sound.zip/practical19.html)); start and end seek jerks ([US 7289290](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/7289290)); body/desk/enclosure modal layers and fast−slow contact pulse ([ClatterDrive](https://github.com/alexyorke/clatterdrive)); commuted body IR ([JOS](https://ccrma.stanford.edu/~jos/pasp05/Commuted_Synthesis_Strings.html)); variation practice ([Uppsala](https://babel.speldesign.uu.se/2018/03/01/2018-03-01-maximizing-your-audio-budget-using-pitch-variation/)).

### Inferences
**Concrete recipe (48 kHz, offline). All values are starting points, to tune by ear.**

1. **Event timeline per seek** (distance d ∈ [0, 1]):
   - **Seek time:** t_seek ≈ 0.8 + 14·√d ms. A square-root profile suits bang-bang seeks; this is an inference.
   - **Event A (accel jerk)** at t = 0: amplitude a_A = 0.35 to 0.6 × a_B.
   - **Coast buzz** from 0 to t_seek: band-limited noise (bandpass about 0.8 to 3 kHz, Q about 1) at −24 to −30 dB re the click peak, with a raised-cosine envelope. Optionally amplitude-modulate it with a sinusoid at the coil-current harmonic, or omit it for short seeks. This represents VCM current and structure-borne excitation.
   - **Event B (decel/settle stop)** at t = t_seek: this is the main click. Its amplitude scales with √d: 0.6 + 0.4·√d.
   - **Settle ticks:** 1 to 3 events at t_seek + 0.4 to 3 ms, each 8 to 16 dB below B, with geometric spacing and jitter.
   - **Track-to-track or sequential ticks:** event B only, at −10 to −16 dB.
2. **Excitation for each event:**
   - **Contact pulse:** F(t) = 1 − cos(2πt/T), with T = 0.06 to 0.25 ms (shorter for louder events, e.g. T = 0.25 − 0.15·amp ms). Alternatively use ClatterDrive-style fast − slow exponentials with τ_f ≈ 0.2 to 0.35 ms and τ_s ≈ 1.3 to 2.6 ms.
   - **Micro-bounce train:** 2 to 4 extra pulses at 0.15 to 0.8 ms spacing, amplitudes decaying ×0.3 to 0.5 each, spacing randomized ±20%.
   - **Contact grit:** an optional 0.2 to 0.5 ms noise burst highpassed at about 3 kHz, at −10 to −18 dB re pulse. This is the "contact" component that sits on top of the modal ring.
3. **Modal bank (main "drive" resonator)**, implemented as 2-pole resonators: y[n] = 2r cos(ω) y[n−1] − r² y[n−2] + g·x[n], with r = exp(−π f / (Q·fs)).
   - **Ringing metal partials:** 3 to 6 modes, inharmonic, spread over 1.2 to 6.5 kHz (e.g. centred near 1.3, 2.1, 3.4, 4.6, 5.9 kHz; per-drive "personality" seeds pick and fix these). Q 60 to 250 (τ_d ≈ 20 to 80), gains 0 to −10 dB.
   - **Damped cluster:** 8 to 16 modes over 0.6 to 7 kHz, Q 12 to 40 (τ_d ≈ 4 to 13; the jointed-metal regime), gains −6 to −18 dB with a gentle tilt of about −3 dB/oct above 3 kHz.
   - **Body/case layer:** 3 to 5 modes at 150 to 900 Hz (ClatterDrive cover range 184 to 1280 Hz), Q 8 to 20, gains −14 to −24 dB. Keep these low to avoid v1's bassiness.
   - **Optional desk/enclosure layer** at 45 to 250 Hz (ClatterDrive desk 44 to 142 Hz, enclosure 58 to 220 Hz), Q 4 to 8, −20 to −30 dB. Enable it only in "on desk" or "in case" presets.
   - **Strike-position variation:** different events (A vs B vs settle) use different gain vectors, because the arm hits at different points. Per instance, multiply each mode gain by 10^(N(0, 3 dB)/20).
4. **Space:** a short stereo early-reflection network (4 to 8 taps at 0.7 to 9 ms, gains −8 to −18 dB, slightly different L/R), or convolution with a 20 to 80 ms small-enclosure or desk IR. Wet about −14 dB. Alternatively use a commuted, pre-convolved body IR extracted from the CC0 in-drive recording.
5. **Output EQ:** HP 60 to 120 Hz (2nd order). LP 7 to 9 kHz for a bare or desk drive, or about 3.5 to 4.5 kHz for an in-case preset (cf. ClatterDrive presets).
6. **Variation per rendered buffer** (at least 8 to 16 per class, shuffled without immediate repeats):
   - global frequency ±1%
   - per-mode frequency ±0.3%
   - per-mode Q ±15%
   - per-mode gain ±3 dB
   - T ±30%
   - bounce count and spacing random
   - overall level ±2 dB
   - sub-event timing ±10%
   - a different noise seed
7. **Levels:** normalize the bank by integrated loudness (or by a fixed reference event), *not* per-buffer peak. Keep d-dependent loudness differences of roughly 6 to 10 dB between track-to-track ticks and full-stroke seeks.
8. **Background bed:** a quiet spindle/air bed under the clicks, so clicks never start from digital silence. Typically a separate layer in Whirr.

**Quick A/B diagnostics for "flat":** (a) raise Q on 3 to 5 bands to 80 to 200 and drop the rest to −10 dB; (b) replace noise excitation with a 0.1 ms raised-cosine pulse plus 2 bounces; (c) remove per-buffer peak normalization; (d) add a second, quieter event before the main one. If (a) gives the biggest improvement, the Klatzky τ_d diagnosis is confirmed.

### Gaps
- None of these parameter values have been validated against a recording of a real drive. Validate them by extracting modes from the CC0 in-drive recordings (ericstrausser #114172 to #114174) and comparing spectrograms of synthesized vs real seeks.
- No source quantified how many modes are perceptually sufficient for a small metal mechanism. 12 to 24 is a judgment call based on van den Doel's 1 to 50 slider and graceful-degradation remark.

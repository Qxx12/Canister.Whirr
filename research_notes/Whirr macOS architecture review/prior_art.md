# Prior Art for Whirr: HDD-Sound Emulators, Input-Sound Apps, Disk-Activity Indicators

Research date: 2026-11-23. Scope: projects comparable to Whirr (a macOS tool that plays mechanical hard-drive sounds in response to real disk I/O). Every claim below has a source. Anything not confirmed by a source is listed under Gaps.

## 1. HDD-sound emulators (software, hardware, emulators): what they do, how they detect events, how they play sound, how they run and ship

### Takeaway
Existing HDD-sound tools use one of three event sources:
- **Polling OS disk counters.** DiskClick polls C-drive activity through psutil.
- **Intercepting file operations.** ClatterDrive runs a WebDAV server that you mount, so only traffic through its URL makes sound.
- **Reading the physical HDD LED signal.** HDD Clicker and HDD Synth take this route.

Nearly all of them play recorded samples in two layers: a continuous spin/idle loop, plus seek/access clips triggered by events. Emulators (MAME, 86Box, DOSBox Staging, WinUAE/FS-UAE) have exact seek and step information, so they can choose samples by step rate or seek distance. ClatterDrive is the one notable project that synthesizes the sound procedurally from a physical model.

### Cited Findings

**ClatterDrive (github.com/alexyorke/clatterdrive)**
- It is a WebDAV-backed simulator that "makes an ordinary directory feel and sound like a mechanical hard drive." The README presents it as entertainment, not an accurate model of storage or acoustics — [ClatterDrive README](https://github.com/alexyorke/clatterdrive)
- Event source: the user has to read and write through the WebDAV URL (default `http://127.0.0.1:8080`). Using the backing folder directly skips both the latency and the audio. "This is not a real block device or kernel filesystem." Events come from WebDAV operations: mkdir/listing, uploads, downloads, overwrites, deletes, fragmented reads, and wake-from-standby — [ClatterDrive README](https://github.com/alexyorke/clatterdrive)
- It includes a raw block-I/O extension API (`clatterdrive/block_frontend.py`) for future WinFsp/FUSE/NBD adapters. "no privileged WinFsp, FUSE, NBD, or kernel integration is bundled" — [ClatterDrive README](https://github.com/alexyorke/clatterdrive)
- It injects real latency. The model covers zoned transfer rates, platter/head geometry, rotational phase, seek-distance calibration, request ordering, NCQ, and filesystem-layout profiles (`ntfs_like`, `ext4_like`, `apfs_like`). Drive presets include `desktop_7200_internal` and `seagate_ironwolf_pro_16tb` — [ClatterDrive README](https://github.com/alexyorke/clatterdrive)
- Sound: it "synthesizes drive noise procedurally from the same runtime events" and does "not use prerecorded HDD sound effects." The audio model has three tiers:
  - physical state: spindle phase/RPM, actuator position/velocity
  - physical model: normalized mechanics, source routing, modal radiation, gain staging
  - "artistic calibration," kept as an audit tier

  Acoustic presets are `bare_drive_lab`, `mounted_in_case`, `external_enclosure`, and `drive_on_desk`. Output goes through PortAudio device selection and can be teed to WAV — [ClatterDrive README](https://github.com/alexyorke/clatterdrive)
- Runtime and distribution: the backend is a Python 3.12+ CLI (`clatterdrive serve`, `profiles --json`, `doctor --json`, managed with `uv`). The Windows launcher is native WPF ("not Tkinter, Electron, or a browser shell"). The macOS launcher is native SwiftUI, shipped as per-arch DMGs that are signed and notarized only when Developer ID secrets are configured. The macOS launcher copies `mount_webdav` commands to the clipboard instead of mounting automatically. A Docker image is available for headless use — [ClatterDrive README](https://github.com/alexyorke/clatterdrive)
- Performance: the repo has a real-time audio benchmark, an "optimized renderer," and a documented "buffering tradeoff" (`docs/realtime-audio.md`). The README gives no CPU figures — [ClatterDrive README](https://github.com/alexyorke/clatterdrive)
- Limitations the README states: out-of-band edits are "only partially reconciled," state is not crash-consistent, and the acoustic models are not reference-grade without measured per-unit constants — [ClatterDrive README](https://github.com/alexyorke/clatterdrive)

**DiskClick (deervo, itch.io)**
- It "monitors the disk activity on your C drive" and plays old-HDD sounds. It is Python 3.12 with psutil and pystray as listed dependencies. Windows gets a full EXE; other OSes need the Python setup. It is pay-what-you-want, and the latest version is 0.1.6 (devlog dated 12 June 2025) — [DiskClick itch.io page](https://deervo.itch.io/diskclick)
- Sound-set format: one folder per set, with `looping.wav` for idle/ambient and `load.wav`, `load2.wav`, ... for activity, played in randomized order. Bundled sets include floppies and novelty sounds, and users can add their own — [DiskClick itch.io page](https://deervo.itch.io/diskclick)
- Downloads are large: zip archives grew from 11 MB (v0.0.3) to about 125 MB (v0.1.4) — [DiskClick itch.io page](https://deervo.itch.io/diskclick)
- Community-thread titles show these problems: a "Disk activity threshold exceeded!" error in 0.1.4, a missing EXE in 0.1.6, a version with no clicking, Linux errors, and "Runs on macOS Sonoma but produces no disk sounds" (v0.1.1) — [DiskClick itch.io page](https://deervo.itch.io/diskclick)
- User reports, per search-result summaries (the threads themselves were not fetched): volume levels across sample files are "very unbalanced," a bad-sector sound loops until the program is reset, and users want a pause option. The developer plans to redo the samples — [DiskClick community](https://deervo.itch.io/diskclick/community); [winclassic thread](https://winclassic.net/thread/2090/diskclick-emulate-hard-drive-sounds); [VOGONS](https://www.vogons.org/viewtopic.php?p=1234641)
- Later releases reportedly added a drive-age slider and randomizing the hard drive (search-result summary) — [DiskClick devlog v0.1.6](https://deervo.itch.io/diskclick/devlog/965169/v016)

**Hardware: HDD Clicker / HDD Synth / FDD Synth**
- HDD Clicker / "HDD Sound Simulator" by Matthias Werner (retrokits.de) is a small ATtiny board with a piezo speaker. It plugs into the drive-activity LED header and plays clicks that mimic head seeks. No build details are published — [Hackaday 2022](https://hackaday.com/2022/09/26/tiny-dongle-brings-the-hard-drives-song-back-to-updated-retrocomputers); [retrokits.de](https://www.retrokits.de/index.php/hdd-clicker-v0-2/)
- Hackaday commenters describe a SCSI emulator that uses wavetable samples from real drives, mixed with frequency sweeps, and picks seek sounds by how far the simulated head moves. These are commenters' claims — [Hackaday 2022](https://hackaday.com/2022/09/26/tiny-dongle-brings-the-hard-drives-song-back-to-updated-retrocomputers)
- HDD Synth by Peter Bridger (MaverickUK) is "Sample based recreation" covering spin-up at power-on, idle hum, access clicks and crackles, and spin-down at power-off. Sample packs live on an SD card and can be replaced. It has volume control and a "balance" setting for the idle-vs-access mix. It detects activity "via HDD LED" and shows activity and volume on an OLED — [HDDSynth GitHub](https://github.com/MaverickUK/HDDSynth)
- Per search summaries: it is an ISA card built on a Raspberry Pi Pico, with WAVs taken from original drives. Release is targeted for Q4 2026, and a Win9x/XP companion app is in development. FDD Synth is the floppy counterpart, a 3.5" bay unit aimed at machines using Gotek solid-state floppy replacements — [strifestreams HDD Synth](https://strifestreams.com/hddsynth); [FDDSynth GitHub](https://github.com/MaverickUK/FDDSynth); [VOGONS beta post](https://www.vogons.org/viewtopic.php?p=1419170)

**Emulators**
- MAME (floppy sound added in 0.165, improved in 0.177): `floppy_sound_device` derives from `samples_device`. Each drive type uses 10 WAVs:
  - spin: `spin_start_empty`, `spin_start_loaded`, `spin_empty`, `spin_loaded`; spin loops should match the 200 ms rotation period
  - `spin_end`: under 100 ms
  - `step_1_1`: at least 75 ms, starting immediately
  - seek: `seek_2ms`, `seek_6ms`, `seek_12ms`, `seek_20ms`

  — [Ninerpedia: MAME floppy sound emulation](https://ninerpedia.org/wiki/MAME_Floppy_sound_emulation)
- MAME's selection logic: a single step plays the step sample. If another step arrives before that sample finishes, playback switches to the seek sample that matches the computed step rate, then resumes the step sample's tail at the end (the "tu-roooo-p" effect). If no rate matches, it uses the nearest seek sample with its pitch adjusted, which the author says degrades quality because harmonics differ by rate. A missing file disables floppy sound entirely. The author chose samples because simulating drive resonances is complex — [Ninerpedia](https://ninerpedia.org/wiki/MAME_Floppy_sound_emulation)
- 86Box: floppy sounds arrived in v5.2. Hard-disk sounds arrived in v6.0 (31 May 2026) from the same contributor. They are "based on recordings," configured in the hard-disk settings separately from the model presets, and "Recordings from three 3600 RPM disk models are currently available" — [86Box v6.0 release notes](https://86box.net/2026/05/31/86box-v6-0.html); [86Box v5.2](https://86box.net/2025/10/26/86box-v5-2.html)
- An earlier 86Box commit listed "typical 5400 RPM 3.5" HDD motor and seeking sounds" as future plans — [86Box mirror commit](https://gitea.dlitz.net/mirror/86Box/src/commit/99a745f49aeff3ca2695ae64861da7e64aec6e5f)
- DOSBox Staging has `[disknoise]` with `floppy_disk_noise` and `hard_disk_noise`, each set to `off`, `seek-only`, or `on` (seek plus spin). It ships built-in FLAC samples, which users can replace in `resources/disk-noises` as long as they are 22 kHz. Volume is controlled only through the `DISKNOISE` mixer channel. The docs recommend setting `hard_disk_speed` below maximum so the noise matches the drive's pace — [DOSBox Staging manual: disk noise](https://www.dosbox-staging.org/0.83/manual/sound/disk-noise/)
- WinUAE/FS-UAE use sample-based floppy sounds supplied as a separate zip, with named sets such as A500Real and ST — [FS-UAE floppy_drive_0_sounds](https://fs-uae.net/docs/options/floppy_drive_0_sounds/)
- PCem has a community patch that adds floppy head noise from samples. It "only works properly with a 100ms sound buffer" — [PCem forum patch](https://pcem-emulator.co.uk/phpBB3/viewtopic.php?p=16590)

**Linux scripts**
- No packaged Linux tool turned up. A 2007 linux-audio-dev thread ("bash vs disk activity") covers polling `/proc/diskstats` counters for a whole device (e.g. `sda`) and diffing successive reads to detect activity — [linux-audio-dev 2007](https://lists.linuxaudio.org/archives/linux-audio-dev/2007-October/018926.html)
- DiskClick's Python setup is the de facto cross-platform route, but its community reports "errors running on Linux" — [DiskClick itch.io](https://deervo.itch.io/diskclick)

### Inferences
- The standard architecture is a continuous spin loop plus event-triggered access samples, chosen at random or by seek rate or distance. Hobby software (DiskClick), hardware (HDD Synth), and emulators (MAME, 86Box, DOSBox Staging) all converge on it, so a sample-based design for Whirr matches what users already know.
- A host-side tool like Whirr or DiskClick only sees aggregate I/O counters, not seek distance or LBA. That puts it in the same position as the LED-header devices (HDD Clicker, HDD Synth): it only knows "activity on/off and roughly how much." Emulators and ClatterDrive can model seek distance because they own the I/O path. Whirr would have to invent seek-distance variation, for example by randomizing it or scaling it with throughput.
- DiskClick's "no sounds on macOS Sonoma" report suggests that generic cross-platform counter polling (likely psutil) does not map cleanly onto macOS. A native IOKit reader avoids that risk (see section 3).
- Recurring user complaints point to concrete requirements: unbalanced sample loudness (normalize the packs), stuck or looping sounds (watchdog and voice limits), the lack of a pause toggle, and download size (DiskClick is about 125 MB).
- ClatterDrive's WebDAV design makes the sound accurate, but it only reacts to I/O you route through it. Whirr's "real disk I/O" goal is a different design point: ambient, system-wide, and passive.

### Gaps
- No primary source found for DiskClick's exact polling method or interval. psutil is a listed dependency, but its use is unconfirmed.
- The 86Box HDD sound implementation (sample selection, seek-distance mapping) was not found at source level. The VOGONS discussion (p=1404859) returned 403.
- DOSBox-X's own HDD/floppy sound feature was not confirmed. Only the DOSBox Staging fork's docs were found.
- No Windows tool using ETW or performance counters to drive sound was found, apart from DiskClick's unconfirmed mechanism.
- HDD Synth's internal audio pipeline (DAC, mixing) is not documented in the README fetched. Pricing is unknown.
- No CPU or latency measurements were found for any HDD-sound tool.

## 2. Keyboard and input-sound tools (Klack, Mechvibes, rustyvibes, and similar): event source, audio API, latency, UI model, CPU complaints

### Takeaway
The macOS keystroke-sound category has moved from Electron (Mechvibes 2) to native code: Swift for Klack, Rust for Mechvibes 3 and rustyvibes. "Lower resource use than Electron" and "lower latency" are the main selling points. The paid native app (Klack, $4.99) is a menu bar app with a volume control, a toggle shortcut, sleep and idle triggers, and output-device handling. Its changelog is dominated by latency cuts and fixes for audio-output reliability (freezes, hangs, device switching).

### Cited Findings

**Klack (Henrik Ruscon, Mac App Store)**
- Basics: $4.99, Mac-only, 12.4 MB, currently requires macOS 15+. Earlier versions required 13 and 14 — [Klack App Store](https://apps.apple.com/us/app/klack/id6446206067)
- UI model: a menu bar app with a show-in-menu-bar option. Volume comes as presets (soft/balanced/loud) or an optional slider, and a global toggle shortcut was added in v1.2.1 — [Klack App Store](https://apps.apple.com/us/app/klack/id6446206067); [9to5Mac](https://9to5mac.com/2023/04/05/klack-app-mechanical-keyboard-sound-effects-for-mac/)
- Features:
  - sound: up/down keystroke sounds, randomized pitching, switch sets, and spatial 3D audio with AirPods (v2.0.0)
  - control: output device selection, AppleScript support, notifications, and usage stats
  - automation: "sleep triggers," an idle mode that lets the Mac sleep normally, a calendar trigger, and muting based on volume feedback (v2.1.4)

  — [Klack App Store](https://apps.apple.com/us/app/klack/id6446206067)
- Latency and CPU per the changelog: "Reduced latency immensely" (v1.6), latency decreased further (v1.7.1), 0% CPU when disabled (v1.4.1), and lower resource use in v1.6 and v1.7.1 — [Klack App Store](https://apps.apple.com/us/app/klack/id6446206067)
- Reliability: many releases fix freezes, hangs, and crashes around sound output (v1.3.1, v1.6.1, v2.0.1, v2.1.2), and output handling was fixed repeatedly — [Klack App Store](https://apps.apple.com/us/app/klack/id6446206067)
- Permissions: Accessibility access is added automatically (needed for global key capture). Notification permission is also requested — [Klack App Store](https://apps.apple.com/us/app/klack/id6446206067)
- User worry: commenters raised the concern that the OS might delay the click behind the actual keystroke and pointed to "Loud Typer" as a low-latency alternative — [Boing Boing BBS](https://bbs.boingboing.net/t/klack-a-mac-app-that-emits-a-satisfying-sound-whenever-you-press-a-key/256596)
- A separate app, "Klakk," claims "Less than 10ms response time." Do not mix it up with Klack — [Klakk on MacUpdate](https://klakk.macupdate.com)

**Mechvibes**
- Mechvibes 2 was Electron and is now archived. Mechvibes 3 is a rewrite in Rust with the Dioxus 0.7 UI framework, rodio and Symphonia for audio, and Windows Raw Input, evdev, or rdev for input capture. These details are from the repo at github.com/hainguyents13/mechvibes as fetched — [Mechvibes GitHub](https://github.com/hainguyents13/mechvibes)
- macOS needs Accessibility plus Input Monitoring permissions, and the menu bar icon shows each permission's status. The tray icon shows when sound is muted. Start-at-login works on Windows and macOS. The macOS build is "experimental," ad-hoc signed, not notarized, and untested by the maintainer on real hardware — [Mechvibes GitHub](https://github.com/hainguyents13/mechvibes)
- Audio design: sounds are decoded when a pack loads, play on a dedicated audio thread, and support up to 32 overlapping sounds ("Low-latency, polyphonic sound") — [Mechvibes GitHub](https://github.com/hainguyents13/mechvibes)
- Pack format: `config.json`. In "single" mode, one audio file holds every sound and each key maps to a `[start_ms, end_ms]` slice (a sprite), with separate down and up slices. In "multi" mode, each key has its own file — [Mechvibes GitHub](https://github.com/hainguyents13/mechvibes)

**rustyvibes**
- A Rust CLI: `rustyvibes <soundpack_path> -v <volume>`. On macOS it asks for Input Monitoring permission on first launch, and you add your terminal app if you denied it. It uses Mechvibes packs, though "Certain custom soundpacks may not work," and a packfixer tool exists. It never uses the network — [rustyvibes GitHub](https://github.com/KunalBagaria/rustyvibes)
- It claims to be "upto 10x-100x more resource efficient" than Electron-based Mechvibes. No benchmark is given, so this is the author's unverified claim — [rustyvibes GitHub](https://github.com/KunalBagaria/rustyvibes)

**Audio API notes (Apple platforms)**
- Apple developer forum threads say AVAudioEngine's reported latency and buffer-duration properties seem inaccurate. A 2018 Core Audio list post claimed a latency floor of about 100 ms with AVAudioEngine on iOS and moved to AUGraph. This is dated and unverified for current macOS — [Apple Dev Forums 672323](https://developer.apple.com/forums/thread/672323); [coreaudio-api 2018](https://lists.apple.com/archives/coreaudio-api/2018/Jul/msg00019.html)
- AirPods' actual output latency differs from AVAudioEngine's prediction and changes over time — [Apple Dev Forums 679274](https://developer.apple.com/forums/thread/679274)

### Inferences
- For Whirr, the relevant pattern is a native menu bar app (Swift or Rust) that preloads and decodes samples, plays from a dedicated real-time audio thread with a polyphony cap, and has 0% CPU when disabled. Electron is a known reputational negative in this category.
- Whirr has an advantage here: reading disk counters through IOKit needs no Accessibility or Input Monitoring permission (see section 3), so it skips the onboarding friction that every keystroke app documents.
- Latency matters less for Whirr than for keystroke apps, because users cannot feel disk I/O the way they feel a key press. A delay of tens of milliseconds is probably fine. Output-device robustness (AirPods connect and disconnect, device switches, sleep and wake) is where Klack spent much of its bug-fix effort, so Whirr should expect the same.
- Klack's feature set (sleep triggers, idle mode, calendar trigger, mute-on-volume-feedback, output-device picker) is a good reference list for "be quiet at the right times."

### Gaps
- Klack's audio API (AVAudioEngine vs Core Audio/AudioUnit) is not publicly documented, and no measured latency figure exists.
- No CPU or memory measurements were found for Mechvibes 2 (Electron) vs native apps. Search returned only generic Electron CPU threads.
- Thock, Kbsound, and KeyboardSound were not researched for lack of tool budget.
- No Hacker News discussion of Klack's architecture was found.

## 3. Disk-activity indicators on macOS (BlinkenDisk, Stats, iStat Menus, Disk LED apps): how they read I/O and how often

### Takeaway
The documented open-source mechanism on macOS is polling IOKit `IOBlockStorageDriver` statistics, the cumulative bytes read and written per physical device. Stats polls these every 1 second and resets its baselines on wake. BlinkenDisk (Dave Plummer, Swift, menu bar LED) is the closest in spirit to Whirr, but its polling method and interval were not confirmed.

### Cited Findings
- Stats (exelban), the `ActivityReader` in `Modules/Disk/readers.swift`:
  - It maps each mounted volume to its media with `DADiskCreateFromVolumePath`, then `DADiskCopyIOMedia`.
  - It walks parents in `kIOServicePlane` to the `kIOBlockStorageDriverClass` object, with a 256-entry limit, and only accepts the result if every branch resolves to one driver.
  - It reads `kIOBlockStorageDriverStatisticsKey`, using the `BytesRead` and `BytesWritten` sub-keys.
  - It computes rates from deltas over elapsed time. The code reads no operations-count key.

  — [Stats readers.swift](https://raw.githubusercontent.com/exelban/stats/master/Modules/Disk/readers.swift)
- Stats polling: `setInterval(1)` gives about one read per second. Samples are cleared on pause, stop, and `NSWorkspace.didWakeNotification` to avoid bogus rates. Per-process disk I/O comes from `proc_pid_rusage` (`ri_diskio_bytesread` and `ri_diskio_byteswritten`), also at a 1 s interval — [Stats readers.swift](https://raw.githubusercontent.com/exelban/stats/master/Modules/Disk/readers.swift)
- BlinkenDisk (davepl/BlinkenDisk) is a small Swift menu bar utility. It shows a red LED that lights on I/O for the local drives you pick. The source is on GitHub and no compiled builds are mentioned. Its custom license allows personal non-commercial use, does not allow distributing modified versions without permission, and requires permission for commercial use. The author says Claude and Codex wrote much of the code — [tinyapps.org blog](https://tinyapps.org/blog/disk-activity-led-macos.html); [Trendshift listing](https://trendshift.io/repositories/39627)
- Commercial or older alternatives:
  - Disk LED Pro: a paid menu bar app showing real-time read and write activity per drive.
  - Disktivity: $1.99, copyright 2012.
  - Apple Activity Monitor: can show disk activity in its Dock icon.

  — [Disk LED Pro](https://apps.apple.com/app/id511699451); [Disktivity](https://apps.apple.com/us/app/disktivity/id523532678?mt=12); [Apple Activity Monitor guide](https://support.apple.com/guide/activity-monitor/actmntr1005)
- tinyapps also notes that Windows HDD-activity tray apps are far smaller (about 8 KB vs about 250 KB) and mostly open source — [tinyapps.org blog](https://tinyapps.org/blog/disk-activity-led-macos.html)

### Inferences
- A 1 s poll, like Stats uses, is fine for a graph but far too coarse for a sound that should feel tied to the I/O. An LED or sound tool probably needs about 20 to 100 ms polling of the same IOKit counters. Reading one CFDictionary property per device should be cheap, but no source quantified it. The IOKit `IOBlockStorageDriver` statistics dictionary also exposes operation counts and latency totals (keys exist in IOKit headers), which could drive "number of seeks." Stats does not use them, so this needs verification.
- Apple Silicon Macs have internal NVMe/APFS storage, so the counters show SSD I/O. Whirr is mapping real but silent I/O onto imagined mechanics, which is the same concept as DiskClick on SSD-based PCs.
- Resetting baselines on wake (as Stats does) is a pitfall worth copying. Otherwise the first delta after sleep produces a burst.

### Gaps
- BlinkenDisk's exact API and poll interval are unconfirmed. Its README and source were not fetched.
- iStat Menus' disk reading method and interval were not found. It is closed source.
- No benchmark of IOKit statistics polling cost at high frequency was found.

## 4. Procedural sound design for HDD sounds: decomposition, synthesis references, sample-based vs procedural tradeoffs

### Takeaway
Real HDD noise splits into two parts:
- **Idle/spindle noise:** spindle motor and bearings, rich in harmonics and noise-like rather than a pure tone, and it gets worse as the drive ages.
- **Seek noise:** the actuator and voice-coil motor, where a few structural-resonance tones are excited by seek current profiles, and the head stopping on a track makes the click.

Almost all shipping projects use recorded samples, because procedural modeling of resonances is hard. ClatterDrive is the main exception, with a physically based procedural model.

### Cited Findings
- The two acoustic sources are idle noise, from the spindle motor and its ball bearings, and seek noise, from the actuator moving during seek, read, and write. This is the DiskFiltration paper, which modulated seek noise deliberately as a covert channel — [DiskFiltration, arXiv 1608.03431](https://arxiv.org/pdf/1608.03431)
- Commenters note that spindle whine is many harmonics rather than one fundamental at the RPM, so it sounds more like white noise and is harder to synthesize parametrically. They also say the seek click comes from the head stopping abruptly — [Hackaday 2022 (comments)](https://hackaday.com/2022/09/26/tiny-dongle-brings-the-hard-drives-song-back-to-updated-retrocomputers)
- Patent literature: square-wave seek current profiles contain high-frequency harmonics that excite mechanical resonance in the head-gimbal assembly. This motivated "quiet seek" profiles, so modern drives seek more quietly than old ones — [US 7660070 Quiet high performance seek](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/7660070); [US 5847476 Audible noise reduction](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/5847476)
- VOGONS 86Box discussion, quoted via search snippet because the page returned 403:
  - "a more-or-less continuous spindle sound, and then on top of that would be sounds from head activity, depending mostly on the distance of a seek"
  - idle spindle sound changes with drive age and bearing wear

  — [VOGONS](https://www.vogons.org/viewtopic.php?p=1404859)
- MAME's author chose samples over simulation because simulating drive resonances is complex. Pitch-shifting seek samples to other rates sounds unnatural because real harmonics differ by rate, so record several rate-specific seek samples — [Ninerpedia](https://ninerpedia.org/wiki/MAME_Floppy_sound_emulation)
- ClatterDrive models spindle phase/RPM and actuator position/velocity, then applies modal radiation and enclosure-coupling presets. Its README says it is not reference-grade without measured drive constants — [ClatterDrive README](https://github.com/alexyorke/clatterdrive)
- Hardware sample-based devices model full lifecycle states: spin-up, idle hum, access clicks and crackles, and spin-down — [HDDSynth GitHub](https://github.com/MaverickUK/HDDSynth)

### Inferences
- A practical Whirr design is hybrid: a recorded spindle loop (with spin-up and spin-down) plus a pool of recorded seek and click samples, varied procedurally. Variation could include random sample choice, small pitch and gain jitter, density scaled by I/O rate, and optional "long seek" vs "short seek" sets. This follows MAME and DiskClick while avoiding the machine-gun repetition of single samples.
- Full procedural synthesis (ClatterDrive-style) removes sample licensing and size issues (DiskClick is about 125 MB), but it takes much more effort to sound right.
- Sample provenance and licensing matter. 86Box and HDD Synth both record real drives, and VOGONS hosts community recording sets.

### Gaps
- No published academic paper on synthesizing HDD sounds for sound design was found. Andy Farnell's *Designing Sound* and similar texts were not checked.
- No spectral measurements (spindle fundamental, click spectra) were collected.

## 5. Common user expectations: menu bar toggle vs no UI, volume, muting on battery, calls, fullscreen, or Do Not Disturb

### Takeaway
Comparable apps converge on these baseline controls:
- a menu bar or tray icon with a mute toggle and mute-state indication
- a global hotkey
- volume (presets or a slider)
- start-at-login
- pack selection, including custom packs

Klack also offers sleep and idle triggers, a calendar trigger, mute based on system volume feedback, and output-device selection. That is the closest analogue to "be quiet during meetings." Explicit battery-aware muting or Focus/DND integration was not found documented in any comparable tool.

### Cited Findings
- Klack:
  - menu bar access and an on/off toggle, plus a global shortcut (originally Cmd+Ctrl+K)
  - volume presets soft/balanced/loud, or a slider
  - sleep triggers, idle mode, a calendar trigger, and mute-on-volume-feedback
  - output-device selection

  — [9to5Mac](https://9to5mac.com/2023/04/05/klack-app-mechanical-keyboard-sound-effects-for-mac/); [Klack App Store](https://apps.apple.com/us/app/klack/id6446206067)
- Mechvibes 3: the tray icon reflects mute state, there is single-instance behavior, start-at-login, and the menu bar shows permission status — [Mechvibes GitHub](https://github.com/hainguyents13/mechvibes)
- DiskClick users requested a pause option — [DiskClick community (search summary)](https://deervo.itch.io/diskclick/community)
- HDD Synth exposes a "balance" between idle and access sounds as well as volume — [HDDSynth GitHub](https://github.com/MaverickUK/HDDSynth)
- DOSBox Staging lets users choose `seek-only` vs `on` (spin plus seek). Some users want clicks without the constant hum — [DOSBox Staging manual](https://www.dosbox-staging.org/0.83/manual/sound/disk-noise/)
- A 2025 blog post titled "Beep to get your attention (but not if you're on a call)" shows a pattern of suppressing sounds while on a call. Only the title was seen in search results; the content was not fetched — [po-ru.com](https://po-ru.com/2025/07/23/beep-to-get-your-attention-but-not-if-youre-on-a-call)

### Inferences
- Minimum viable controls for Whirr:
  - a menu bar icon showing state, with a click or hotkey to mute
  - a volume slider
  - an idle/spin-loop toggle or balance control (the HDD Synth "balance" and DOSBox "seek-only" precedent)
  - pack selection
  - launch at login
- Differentiators that no comparable tool seems to document:
  - auto-mute while the microphone is in use or a call is active
  - respect for Focus/DND
  - mute on battery
  - mute when headphones are disconnected, or follow the default output device

  Klack's calendar and sleep triggers show that users of this category value automatic quieting.
- A constant spindle loop is the most likely source of annoyance (whine, battery drain from a running audio engine). Stopping the audio engine entirely when idle or muted mirrors Klack's "0% CPU when disabled."

### Gaps
- No user surveys or issue-tracker analysis quantifying the demand for DND, battery, or call muting were found.
- No source found for Klack's exact semantics of "mutes based on volume feedback" or its calendar trigger.

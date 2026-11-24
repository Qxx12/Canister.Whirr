# Timing and rhythm of HDD seek sounds under real workloads

Scope: what temporal pattern of seek sounds a listener hears from a busy, idle, or variously loaded hard drive, and concrete rules for reproducing it from coarse per-33 ms ops/bytes counters (no LBAs). Items marked **[Inference]** are my own derivations from the cited numbers, not stated by a source.

## 1. Seek-time distributions, rotational latency, and the maximum audible seek rate

### Takeaway
A modern 3.5" 7200 rpm drive takes about 1 ms for a track-to-track seek, 8.5–9 ms for an average seek and about 21 ms for a full stroke. Rotation adds 0–8.33 ms, 4.17 ms on average. Seek time grows with the square root of distance for short and medium seeks and linearly for long ones. A drive therefore tops out at about 75–100 fully random seeks/s, and more only when seeks are short or reordered. In 1990s drives every figure is 1.5–4x slower, so their seek "clicks" are fewer, longer and more distinct.

### Cited Findings
- **Seek mechanics.** A seek has four phases: a speedup (the arm accelerates to the halfway point or to a maximum velocity), a coast at maximum velocity (long seeks only), a slowdown, and a settle. Seeks of fewer than 2–4 cylinders are dominated by the settle time of 1–3 ms ("a seek may not even occur; the head may just resettle"). Seeks shorter than 200–400 cylinders are almost all constant acceleration, so their time is proportional to √distance plus settle. Long seeks take time proportional to distance plus a constant. Seeks need 30–40 g of acceleration, and halving seek time requires quadrupling the power — [Ruemmler & Wilkes, "An Introduction to Disk Drive Modeling", IEEE Computer 1994](https://www.cs.cmu.edu/~natassa/courses/15-721/papers/IEEEComputer.DiskModel.pdf)
- **Measured seek curves (early-90s 4002 rpm drives).** HP C2200A: t = 3.45 + 0.597√d ms for d < 616 cylinders, and 10.8 + 0.012d ms beyond that (1449 cylinders). HP 97560: t = 3.24 + 0.400√d ms for d < 383, and 8.00 + 0.008d ms beyond (1962 cylinders). Track switch costs 2.5 ms and 1.6 ms respectively. The read settle can be up to 0.75 ms shorter than the write settle, and a head switch takes 0.5–1.5 ms, about one third to one half of a settle — [Ruemmler & Wilkes 1994](https://www.cs.cmu.edu/~natassa/courses/15-721/papers/IEEEComputer.DiskModel.pdf)
- **What "average seek" means.** "Independent seeks are rare in practice. Shorter seeks are much more common", and how much more common depends on the workload and the OS. With uniformly random requests, the mean seek distance is one third of the full stroke — [Ruemmler & Wilkes 1994](https://www.cs.cmu.edu/~natassa/courses/15-721/papers/IEEEComputer.DiskModel.pdf)
- **Seagate Barracuda 7200.12 (7200 rpm).** Track-to-track is 1.0 ms read and 1.2 ms write. Average seek is 8.5 ms read and 9.5 ms write. Average latency is 4.16 ms — [Seagate 7200.12 product manual](https://www.seagate.com/staticfiles/support/disc/manuals/desktop/Barracuda%207200.12/100529369h.pdf) (seen in a search snippet; the full-stroke value was not visible).
- **WD Caviar WDxx00KS / WD4000KD (7200 rpm, ~2006).** Full stroke is 21 ms. Average read seek is 8.9 ms and 8.7 ms. Track-to-track is 2.0 ms and 0.6 ms. Average latency is 4.2 ms. WD advertises "SoftSeek" for lower seek noise — [WD datasheet](https://images10.newegg.com/UploadFilesForNewegg/itemintelligence/WD/22-144-701/WD2500KS.pdf). The WD800JD also lists a 21 ms full stroke and 4.2 ms latency — [manualsonline](https://office.manualsonline.com/manuals/mfg/western_digital/wd800jd.html?p=2)
- **Rotation.** Average rotational latency is half a revolution: about 4.17 ms at 7200 rpm, 3 ms at 10k and 2 ms at 15k. Typical random IOPS are about 75–100 for 7.2k SATA and about 175–210 for 15k SAS. An 8.5 ms seek gives about 79 IOPS — [PC Server & Parts IOPS calculator](https://pcserverandparts.com/iops-calculator/). The formula IOPS = 1/(avg seek + avg latency) is used in [AppDynamics/Splunk KB](https://community.splunk.com/t5/AppDynamics-Knowledge-Base/Computing-RAID-IOPS/ta-p/716263), and a worked example at 7200 rpm gives about 90 IOPS in [Rickard Nobel](https://rickardnobel.se/storage-performance-iops-latency-throughput/)
- **Era presets in 86Box (full-stroke / track-to-track / rpm).**

  | Preset | Full stroke | Track-to-track | rpm |
  |---|---|---|---|
  | 1983 MFM | 80 ms | 10 ms | 3600 |
  | 1989 | 40 ms | 8 ms | 3500 |
  | 1992 | 30 ms | 6 ms | 3600 |
  | 1994 | 26 ms | 5 ms | 4500 |
  | 1996 | 24 ms | 3 ms | 5400 |
  | 1998 | 20 ms | 2 ms | 5400 |
  | 2000 | 15 ms | 2 ms | 7200 |
  | 2004 | 12 ms | 1 ms | 10000 |
  | Seagate ST-225 | 65 ms | 8 ms | 3600 |

  — [86Box src/disk/hdd.c `hdd_speed_presets`](https://github.com/86Box/86Box/blob/master/src/disk/hdd.c)
- **Acoustic management.** AAM quiet mode limits the maximum seek velocity. That raises average seek time, and some seeks then miss their rotation and wait a full extra revolution. The most-quiet setting (128) raised random access time by about 10% — [Wikipedia: Automatic acoustic management](https://en.wikipedia.org/wiki/Automatic_acoustic_management). Tom's Hardware measured larger access-time losses in quiet mode — [Tom's Hardware](https://www.tomshardware.com/reviews/terabyte-hitachi-acoustic,2084.html)

### Inferences
- **[Inference] Hard ceiling on seek rate.** Fully random rates are about 1000/(8.5 + 4.17) ≈ 79/s at 7200 rpm. A 5400 rpm drive (latency 5.56 ms, seek around 11–12 ms) manages about 55–60/s. A 1992-era 3600 rpm drive (latency 8.33 ms, average seek about 15–20 ms) manages about 35–40/s. So Whirr's 80 seeks/s cap is plausible for a 7200 rpm drive doing random work. Above about 100–150/s it is only believable if the seeks are very short (track-to-track plus rotation) or reordered by NCQ.
- **[Inference] Seeks per 33 ms tick.** One 33 ms tick fits at most about 2–3 random seeks at 7200 rpm, about 2 at 5400 rpm, and about 1 on a 1990s drive. Emitting more seeks than this per tick sounds like a machine gun rather than a disk.
- **[Inference] Sound length tracks seek time.** The audible event lasts about as long as the seek: about 1 ms for track-to-track, which is mostly the settle "tick"; about 3–6 ms for short seeks (√d); and 15–25 ms for a full stroke, which has a coast phase and a heavier "clunk". Long seeks spend more energy (30–40 g speedup and slowdown), so they should be louder accents. Short seeks should be soft ticks.
- **[Inference] Parametric seek curve to synthesize from.** t(d) = t_settle + a·√d for d < d_b, and b + c·d beyond. Fit it to track-to-track ≈ 1 ms, one-third stroke ≈ 8.5 ms and full stroke ≈ 21 ms for a 7200 rpm drive. Here d is a normalized fraction of the stroke, 0–1.

### Gaps
- No full-stroke figure was confirmed for the Seagate 7200.12, and no 5400 rpm datasheet (for example WD Green) was retrieved. The 5400 rpm and 1990s IOPS values above are arithmetic, not measurements.
- No StorageReview database numbers were retrieved.

## 2. What different workloads sound like and why

### Takeaway
How a workload sounds is set by its seek-distance mix and its arrival burstiness, more than by its operation rate. No source gives an acoustic description of each workload; the mechanical facts (read-ahead, caching, burstiness, metadata writes) let us derive one. Sequential I/O produces almost no seeks. Random small I/O saturates the drive at the IOPS ceiling. Metadata and journal activity produces back-and-forth long seeks.

### Cited Findings
- **Low-level UNIX traces.** Ruemmler & Wilkes traced every low-level disk access on three HP-UX systems over two months — [Ruemmler & Wilkes, "UNIX disk access patterns", USENIX Winter 1993 / HPL-92-152](https://www.cs.fsu.edu/~awang/courses/cop5611_s2017/hpux.pdf) (the full text could not be retrieved; it returned 404). A later disk-level study, summarized in a search snippet whose exact source was not confirmed, reports that, as in the HP study, it found "a high degree of burstiness" and a write-dominated workload (candidate source: [UConn SPECTS'04](https://snsl.engr.uconn.edu/wp-content/uploads/sites/2477/2018/06/spects04.pdf)).
- **Read-ahead and caching.** Read-ahead serves sequential reads from cache, so about 50% of HP 97560 requests completed in 3 ms or less. A single read-ahead buffer helps only one sequential stream: two interleaved sequential streams get "no benefit at all" unless the cache is segmented. With immediate reporting, back-to-back writes complete without waiting for the platter — [Ruemmler & Wilkes 1994](https://www.cs.cmu.edu/~natassa/courses/15-721/papers/IEEEComputer.DiskModel.pdf)
- **Characteristics that vary by environment.** Arrival rate, service time, sequentiality and mean idle-interval length all depend on the environment, so there is no single "typical" pattern — [Riska & Riedel, "Disk Drive Level Workload Characterization", USENIX 2006](https://www.usenix.org/legacy/event/usenix06/tech/full_papers/riska/riska_html/index.html)
- **86Box: sequential transfers still tick.** Every change of cylinder triggers a seek sound, including cylinder crossings during continuous (sequential) read-ahead and write-cache flushes. Same-cylinder head switches do not — [86Box hdd.c `hdd_seek_get_time`](https://github.com/86Box/86Box/blob/master/src/disk/hdd.c)

### Inferences
- **[Inference] Sequential read or write (large bytes/op, for example ≥128 KiB).** Only track or cylinder switches at the end of each track, which are quiet settle ticks of about 1 ms. The tick rate is at most one per revolution (≤120/s at 7200 rpm), usually far less audible than seeks, so it reads as a soft "purr" or near-silence over the spindle hum. An occasional real seek (file fragmentation, metadata update) adds a sparse accent every few hundred ms to seconds.
  - Calculated from the 86Box "2000 7200 rpm" preset (350 sectors per track × 6 heads ≈ 1 MiB per cylinder): a 60 MB/s sequential read crosses about 60 cylinders/s, roughly one tick every 17 ms.
- **[Inference] File copy on one disk.** The drive alternates between reading the source and writing the destination, each in chunks equal to the OS copy buffer or writeback batch. Expect a periodic long-seek pair (source→destination, destination→source) every chunk, with quiet sequential transfer between: a regular "chk … chk … chk" at a few Hz. The period is chunk size divided by throughput (for example 1–8 MB at 50–100 MB/s gives 10–160 ms).
- **[Inference] Random small I/O (≤16 KiB/op): database, swap thrash, app launch, antivirus scan.** Seeks are back to back at the IOPS ceiling, 75–150/s. Gaps are seek time plus a random rotational wait of U(0, 8.33 ms). That gives an irregular but dense "crunch/grind" with no silences. Antivirus and indexing look like random reads mixed with metadata seeks: bursts per file, with gaps where the CPU parses.
- **[Inference] OS boot.** Bursts of random reads with short silences while the CPU works, then sequential runs for large binaries. A characteristic "clatter, pause, clatter".
- **[Inference] Defragmentation.** Long read-at-A then write-at-B cycles. Each move is a long seek followed by sequential transfer, so the rhythm is a regular accent pattern at roughly 1–10 Hz.
- **[Inference] Journal and metadata updates.** A journaling filesystem writes to the journal area and later checkpoints to the home location. Each sync produces at least one long seek to the journal and one back: the "chk-chk" pair.

### Gaps
- I found no published recordings or acoustic studies that tie specific workloads to sounds. The workload descriptions above are mechanical derivations.
- I did not retrieve the R&W 1993 statistics (fraction of zero-distance seeks, metadata share of writes, burst lengths).

## 3. Command queuing (NCQ/TCQ), elevator scheduling, and write-cache flushes

### Takeaway
Queuing and elevator scheduling shorten seeks and make them same-direction sweeps, which gives higher, more even rates of softer ticks plus an occasional long return seek. OS writeback creates periodic write bursts: about every 5 s on Linux and ext4, and about every 1 s with the Windows lazy writer.

### Cited Findings
- **NCQ.** NCQ reorders pending commands to minimize head repositioning — [TechSpot on the Barracuda 7200.7 NCQ](https://www.techspot.com/news/16561-seagate-barracuda-72007-ncq-hard-drive-reviewed.html). Seagate and Intel showed a 7200.7 with NCQ at queue depth 32 on random I/O matching or beating a 10k rpm drive in IOPS — [CDRinfo](https://cdrinfo.com/d7/content/seagate-claims-sata-ncq-can-beat-10k-sata). Tom's Hardware found the claims overstated but saw an advantage for every queuing-capable drive — [Tom's Hardware](https://www.tomshardware.com/reviews/command-queuing-turbo-charge-sata,922-8.html). A 2007 Linux test found one drive and firmware combination that did not reorder at all — [LKML](https://lists.openwall.net/linux-kernel/2007/06/24/62)
- **Linux writeback.** The flusher threads wake every `dirty_writeback_interval = 5 * 100` centiseconds (5 s) and write data dirty for longer than `dirty_expire_interval = 30 * 100` centiseconds (30 s). Background writeback starts at 10% of available memory dirty, and writers are throttled at 20% — [linux mm/page-writeback.c](https://github.com/torvalds/linux/blob/master/mm/page-writeback.c); semantics in [kernel sysctl/vm docs](https://docs.kernel.org/admin-guide/sysctl/vm.html)
- **ext4.** The default `commit=` is 5 seconds: the running journal transaction is committed at least every 5 s — [Linux ext4 admin guide](https://github.com/torvalds/linux/blob/master/Documentation/admin-guide/ext4.rst)
- **Windows lazy writer.** The cache manager runs a lazy writer "every second" that queues "one-eighth of the pages that have not been flushed recently" and queues more if needed. Metadata is always cached — [Microsoft Learn: File Caching](https://learn.microsoft.com/en-us/windows/win32/fileio/file-caching)
- **macOS / XNU.** `sync_timeout_seconds = 5` exists, but it is the timeout bounding the in-kernel `sync_internal()` used for power management, not a periodic flush interval — [xnu bsd/vfs/vfs_syscalls.c](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/vfs/vfs_syscalls.c)

### Inferences
- **[Inference] Elevator/NCQ effect on sound.** With queue depth ≥4, order the seeks within a burst monotonically by position: many short same-direction steps (√d, so 2–4 ms and quieter), then one long return seek at the end of the sweep as the accent. Raise the effective rate ceiling to about 1.3–2x the random-IOPS ceiling. This is the main "rhythm" ingredient a uniform Poisson stream lacks.
- **[Inference] Periodic flush pulses.** Under light write load, writes reach the disk as a burst every 5 s (Linux/ext4) or about every 1 s (Windows). macOS will show its own cadence in Whirr's measured counters; no fixed interval was found. Since Whirr measures real counters, these pulses arrive naturally. The synthesizer should render each pulse as a cluster (long seek in, several short ones, long seek out) rather than spreading its ops uniformly across the 33 ms tick.

### Gaps
- No controlled measurements of seek-distance distributions with and without NCQ.
- No documented macOS periodic writeback interval for APFS or HFS+ on HDD. A historical 30 s `update` daemon is my unverified recollection.

## 4. Idle behaviors: parking, recalibration, spin-down

### Takeaway
An idle drive is not silent. You hear the spindle hum and occasional events: a head unload "click" after a fixed idle timeout (8 s on WD Green and Red), the load click plus small delay on the next access, periodic thermal recalibration seeks on older drives, and spin-down or spin-up under power management.

### Cited Findings
- **WD Green/Red idle3 timer.** The default is 0x50 (80 × 0.1 s = 8 s) — [NETGEAR community](https://community.netgear.com/t5/ReadyNAS-Hardware-Compatibility/WD-Red-drives-park-their-heads-like-WD-Green-drives/td-p/869565). The load/unload rating is 300,000 cycles, and light use can produce 100+ cycles per hour — [StorageReview](https://www.storagereview.com/news/how-to-stop-excessive-load-cycles-on-the-western-digital-2tb-caviar-green-wd20ears-with-wdidle3). Users report counts above 1 million — [TrueNAS forum](https://www.truenas.com/community/goto/post?id=378917) (anecdotal).
- **Thermal recalibration.** Many drives recalibrate "every degree C (or so)" while warming up, then at a longer periodic interval once at temperature — FAQ quoted in [fedora-list 2004](https://listman.redhat.com/archives/fedora-list/2004-December/msg06332.html). Some drives recalibrate at fixed intervals even under load, while others postpone it until idle — [SIGCAT '97 document](https://discmaster.textfiles.com/file/36067/SIGCAT%2097%20-%20Conference%20on%20Convergence.ISO/Docs/00013/0132a.htm?html=true). Late-1990s "AV drives" deferred recalibration so it would not interrupt streams or CD burning — [Wikipedia: AV drive](https://en.wikipedia.org/wiki/AV_drive)
- **Spindle states in 86Box.** 86Box models the spindle as STOPPED, STARTING, RUNNING and STOPPING, with separate start, loop and stop samples — [86Box hdd_audio.c](https://github.com/86Box/86Box/blob/master/src/disk/hdd_audio.c)

### Inferences
- **[Inference] Idle-state machine.**
  - Idle for more than T_park (8 s for "green" drives, longer or never for desktop drives): play an unload click.
  - On the next I/O after parking: play a load click plus a 10–20 ms delay before the first seek.
  - Optional "vintage" mode: one or more recalibration seek sweeps every few minutes while idle, with no published interval found, so make it configurable.
- **[Inference] Housekeeping ticks.** Even an "idle" macOS system produces small metadata writes, such as Spotlight and logs, appearing as isolated single seeks or pairs every few seconds. Whirr's background-subtraction may currently be removing exactly these characteristic sparse ticks.

### Gaps
- No vendor document gave recalibration intervals in minutes, or desktop-drive APM or unload timeouts. Laptop APM timers are vendor-specific and were not found.

## 5. Clustering, accents, inter-seek intervals, and published trace statistics

### Takeaway
Real disk traffic is bursty and spatially local. Seeks come in trains of short seeks punctuated by occasional long ones, separated by idle gaps of very different lengths. A homogeneous Poisson process at a smoothed rate has none of this, which is very likely why the result sounds "flat".

### Cited Findings
- **Short seeks dominate.** Shorter seeks are much more common than the independent-request model predicts — [Ruemmler & Wilkes 1994](https://www.cs.cmu.edu/~natassa/courses/15-721/papers/IEEEComputer.DiskModel.pdf)
- **Burstiness.** HP-UX disk traces show a high degree of burstiness (secondary summary; see the Gaps in section 2) — [Ruemmler & Wilkes 1993](https://www.cs.fsu.edu/~awang/courses/cop5611_s2017/hpux.pdf)
- **MSR Cambridge traces.** One-week block traces of 36 volumes on enterprise servers (2007) — [SNIA IOTTA](https://iotta.snia.org/traces/block-io/388). These volumes show substantial idle periods — [Narayanan et al., "Write Off-Loading"](https://www.cs.fsu.edu/~awang/courses/cis6935_s2012/write-offloading.pdf). A later analysis finds MSRC burstiness non-Gaussian, while request inter-arrival intervals are "almost uncorrelated" — per a search snippet attributed to [NSF PAR paper](https://par.nsf.gov/servlets/purl/10515025) (not read in full). MSRC is less active than AliCloud or TencentCloud volumes — [arXiv 2203.10766](https://web3.arxiv.org/pdf/2203.10766)
- **Idle intervals depend on the environment** — [Riska & Riedel 2006](https://www.usenix.org/legacy/event/usenix06/tech/full_papers/riska/riska_html/index.html)

### Inferences
- **[Inference] Use a two-level process.** Burst onsets come from the measured op counts. Inside a burst, the seeks follow a locality chain:
  - First seek of a burst: "long" (uniform 0.1–1.0 of the stroke), loud accent.
  - Following seeks: geometric run length (mean 3–8), mostly distance 0 or short (<1% of stroke), soft ticks.
  - Each later seek has a 10–20% chance of another long jump (switching file, metadata, or journal).
  - Burst end: optional return seek, since a journal write followed by a home-location write produces A→B→A.
- **[Inference] Spacing inside a burst.**
  - Random small I/O: gap = t_seek(d) + U(0, T_rev) + transfer, where T_rev = 8.33 ms at 7200 rpm and transfer = bytes/op ÷ media rate (about 100–150 MB/s for a 2010s 7200 rpm drive).
  - Near-sequential I/O with small skips: the rotational wait is nearly a full revolution (the head just passed the sector), so gaps cluster near T_rev + t_seek. That gives an audible periodicity at about 120 Hz / k, a "pulse" quantized to revolution multiples.
- **[Inference] Rate-adaptive fallback.** If no source gives distance histograms, a defensible mix is 40–60% "zero or very short", 25–40% short/medium, and 5–20% long, with the long share rising for random small-op workloads and falling for sequential. Tune this by ear; it is not measured data.

### Gaps
- I could not retrieve concrete seek-distance histograms, inter-arrival distributions or idle-period distributions (R&W 1993, DiskSim parameter files, MSR analyses). DiskSim documentation was not reached.

## 6. How emulators and sound gadgets decide when and which sound to play

### Takeaway
86Box 5.x/6.x drives its HDD sound from the emulated disk's timing model. It plays one seek sample whenever the head changes cylinder, rate-limited to one onset per track-to-track time per drive, mixes up to 8 overlapping voices, and loops a spindle sample with start and stop samples. It does not vary the sample by seek distance. Distance affects only the emulated timing, and therefore the spacing between sounds. I found no implementation details for the other emulators or gadgets.

### Cited Findings
- **Trigger.** `hdd_seek_get_time()` computes seek time as `cyl_switch_usec + full_stroke_usec * cyl_diff / phy_cyl (+ avg_rotation_lat_usec for reads/writes)`, a linear model. It calls `hdd_audio_seek()` whenever `new_cylinder != cur_cylinder`. Sequential ("continuous") accesses use the cylinder or head-switch time, or the sector time, and still trigger the sound on cylinder change. A fixed 50 µs overhead applies to same-cylinder accesses — [86Box hdd.c](https://github.com/86Box/86Box/blob/master/src/disk/hdd.c)
- **Rate limit and polyphony.** `hdd_audio_seek()` returns early if cylinder_diff is 0. It computes `min_seek_spacing = cyl_switch_usec × 48 kHz`, which equals the preset's track_seek_ms. It skips the new seek if any active voice started less than that long ago. Otherwise it starts a free voice out of `HDD_MAX_SEEK_VOICES_PER_HDD = 8`. One `seek_track_file` sample with a volume is used for every seek, regardless of distance — [86Box hdd_audio.c](https://github.com/86Box/86Box/blob/master/src/disk/hdd_audio.c). The timing fields come from presets: `cyl_switch_usec = head_switch_usec = track_seek_ms*1000`, `full_stroke_usec = full_stroke_ms*1000`, `avg_rotation_lat_usec = (60/rpm)/2` — [86Box hdd.c](https://github.com/86Box/86Box/blob/master/src/disk/hdd.c)
- **Spindle and profiles.** Profiles are defined in INI with `rpm`, `spindlemotor_start/loop/stop_file` and volumes. Spin-up starts the start sample, then the loop — [86Box hdd_audio.c](https://github.com/86Box/86Box/blob/master/src/disk/hdd_audio.c). The docs say the Audio option "emulates the mechanical sounds of a real hard drive" — [86Box docs](https://86box.readthedocs.io/en/v6.0/_sources/settings/hdd.rst.txt)
- **Write cache and read-ahead.** The write cache in 86Box defers writes and flushes them when a non-sequential request arrives. Read-ahead continues in the background, so seek sounds come from the background flush and read-ahead activity too, not only from host commands — [86Box hdd.c](https://github.com/86Box/86Box/blob/master/src/disk/hdd.c)
- **FS-UAE.** Has per-drive floppy sound sets (`floppy_drive_0_sounds`) but no HDD sounds found — [FS-UAE docs](https://fs-uae.net/docs/options/floppy_drive_0_sounds/)
- **DiskClick.** A Windows app that plays HDD sounds from C: activity. Its v0.1.6 rewrote the activity measurement and changed the sample fade-in/out delay, with no algorithm disclosed — [DiskClick devlog](https://deervo.itch.io/diskclick/devlog/965169/v016)

### Inferences
- **[Inference] Main lesson from 86Box.** The rhythm comes for free from a timing model: sounds are spaced by simulated seek + rotation + transfer time, and the rate limit at the track-to-track time prevents unrealistically dense onsets. Whirr can borrow this by running a lightweight "virtual head" simulation, with a head position and a timeline, driven by the measured op counts.

### Gaps
- Not examined: MAME, PCem, DOSBox Staging and WinUAE HDD sound code, if any exists; HDD Clicker and HDDSynth hardware logic. No sources were retrieved, so I cannot summarize them.

## 7. Heuristics for a believable rhythm from ops/s and bytes/s only

### Takeaway
Replace "Poisson at a rate ∝ excess ops" with a virtual-drive simulator. Classify each tick by bytes/op, turn ops into seek *events* using a locality chain, and place events on a timeline with gaps derived from the seek curve and rotational latency. Cap throughput at the drive's mechanical ceiling and let a backlog carry over between ticks. All the rules below are **[Inference]**, built from the numbers in sections 1–6.

### Cited Findings
- Seek curve shape (√d then linear), settle 1–3 ms, track switch 1.6–2.5 ms — [Ruemmler & Wilkes 1994](https://www.cs.cmu.edu/~natassa/courses/15-721/papers/IEEEComputer.DiskModel.pdf)
- 7200 rpm: track-to-track about 1 ms, average 8.5 ms, full stroke 21 ms, latency 4.16–4.2 ms — [Seagate 7200.12 manual](https://www.seagate.com/staticfiles/support/disc/manuals/desktop/Barracuda%207200.12/100529369h.pdf); [WD datasheet](https://images10.newegg.com/UploadFilesForNewegg/itemintelligence/WD/22-144-701/WD2500KS.pdf)
- Onset rate-limit at track_seek_ms, 8-voice polyphony — [86Box hdd_audio.c](https://github.com/86Box/86Box/blob/master/src/disk/hdd_audio.c)
- OS flush cadences: 5 s on Linux and ext4, 1 s with the Windows lazy writer — [page-writeback.c](https://github.com/torvalds/linux/blob/master/mm/page-writeback.c); [ext4 docs](https://github.com/torvalds/linux/blob/master/Documentation/admin-guide/ext4.rst); [Microsoft Learn](https://learn.microsoft.com/en-us/windows/win32/fileio/file-caching)

### Inferences
1. **Classify each tick** with b = bytes/op:
   - b ≥ 256 KiB: sequential. p_seek per op is about 0.02–0.1, the rest are track-switch ticks at a rate of throughput ÷ bytes per track (about 1–2 MB per track or cylinder on 2010s drives; use the 86Box-style geometry).
   - 32–256 KiB: mixed. p_seek is about 0.3–0.6.
   - b ≤ 16–32 KiB: random. p_seek is about 0.8–1.0.
   - Also, a high write-only share with few ops every 1–5 s means a flush or journal burst. Render it as a cluster with a long seek in and out.
2. **Seek count.** n_seek = ops × p_seek, plus any carried backlog. Clamp to the mechanical budget: Σ(t_seek + t_rot + t_xfer) ≤ 33 ms. Push the excess into the next tick. This makes saturation sound like a continuous, evenly dense grind instead of a louder or faster blur, and it makes the sound lag slightly behind the burst.
3. **Seek distances** from a Markov "locality chain" carried across ticks: the state is the current head position, 0–1.
   - The first seek after idle (more than 100–200 ms with no ops) is long (uniform jump).
   - Each later seek is "stay local" with p ≈ 0.7–0.85 (|Δ| ~ Exponential with mean 0.5–2% of the stroke) or "jump" otherwise.
   - With high ops/tick (queue depth effectively ≥4), sort the tick's local seeks monotonically (elevator) and add one return jump at the sweep end.
4. **Timing within the tick.** Start time of seek k+1 = end of seek k + t_rot + t_xfer.
   - t_seek(d) = 1.0 + 7.5·√(d / 0.33) ms for d < 0.33; otherwise linear from 8.5 ms at 0.33 to 21 ms at 1.0. This is a 7200 rpm fit to the datasheet points.
   - t_rot is drawn from U(0, 8.33 ms) for random ops. For near-sequential ops, use (T_rev − small), which quantizes to revolutions.
   - t_xfer = b / (100–150 MB/s).
   - Never place onsets closer than track-to-track time (about 1 ms modern, 2–10 ms vintage), following 86Box.
5. **Accent and timbre per seek.** Amplitude and "weight" rise with d: a short seek is a soft settle tick; a long seek is a louder thunk with a coast segment of length ≈ t_seek. Optional AAM "quiet" mode makes long seeks about 10–30% longer and softer.
6. **Idle layer.**
   - Spindle loop always.
   - Park click after T_park of no ops (8 s for "green" drives, configurable).
   - Unpark click plus about 15 ms delay before the first seek after a park.
   - Vintage drives: optional thermal-recal sweep every N minutes.
7. **Era presets.** Scale every time constant with presets such as the 86Box set: for example a 1992 drive with 6 ms track-to-track, 30 ms full stroke and 3600 rpm (T_rev 16.7 ms) gives a slower, chunkier rhythm capped near 35–40 seeks/s.

### Gaps
- None of these heuristics has been validated against recordings of real drives paired with traces. Validate by ear against reference recordings, for example by recording a real drive under fio random, sequential and mixed loads while logging iostat at 30 Hz.

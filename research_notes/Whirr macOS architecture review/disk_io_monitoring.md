# System-wide Disk I/O Monitoring on macOS (for Whirr: unprivileged per-user Swift CLI, ~20–50 ms reaction)

Note on evidence: besides web sources, several claims below come from **local experiments run on 2026-11-23** on the developer's own machine: Apple Silicon (arm64), `sw_vers` reports macOS **27.2** (build 26B123; note this is newer than the macOS 15/26 targets in the brief), SIP enabled, ordinary non-root user, unsandboxed Swift binary built with `swiftc -O`. They are labelled "[Local test]". Probe source: `<scratchpad>/iotest/probe.swift` (scratch, may be cleared). A "Source" for those items is the local SDK header or the test itself, not a URL.

## Q1. How IOBlockStorageDriver "Statistics" polling works; privileges; OS-version changes

### Takeaway
Every block device's `IOBlockStorageDriver` publishes a "Statistics" dictionary of 64-bit cumulative counters (bytes, ops, total time, errors, retries for read and write). Any unprivileged, unsandboxed process can read it with `IOServiceGetMatchingServices` + `IORegistryEntryCreateCFProperty`. It needs no root, entitlement or TCC prompt, and it worked as of macOS 27.2 on Apple Silicon. This is the same data `iostat`, Stats and BlinkenDisk use.

### Cited Findings
- The public SDK header `IOKit/storage/IOBlockStorageDriver.h` defines `kIOBlockStorageDriverStatisticsKey "Statistics"` and sub-keys (BytesRead/BytesWritten/Reads/Writes/TotalRead/WriteTime/LatentRead/WriteTime/Errors/Retries), each an OSNumber in that table. It is still present in the current Xcode SDK. — [Local test: `$SDK/System/Library/Frameworks/IOKit.framework/Headers/storage/IOBlockStorageDriver.h` lines 44–92]; historical copy: [opensource.apple.com xnu IOBlockStorageDriver.h](https://opensource.apple.com/source/xnu/xnu-124.1/iokit/IOKit/storage/IOBlockStorageDriver.h.auto.html)
- Kernel implementation (IOStorageFamily): `init()` creates each counter as `OSNumber::withNumber(0ULL, 64)` (64-bit). It puts them in an OSDictionary and calls `setProperty(kIOBlockStorageDriverStatisticsKey, statistics)` **once**. Later updates change the same OSNumber objects in place, so a registry read always sees current values. — [apple-oss-distributions/IOStorageFamily IOBlockStorageDriver.cpp](https://raw.githubusercontent.com/apple-oss-distributions/IOStorageFamily/main/IOBlockStorageDriver.cpp)
- Updates happen **per I/O, at completion**: `prepareRequestCompletion()` calls `addToBytesTransferred(actualByteCount, timeInNanoseconds, 0, isWrite)`, which increments the op count and adds bytes and time. Failed and short I/Os also call `incrementErrors`. — [IOBlockStorageDriver.cpp](https://raw.githubusercontent.com/apple-oss-distributions/IOStorageFamily/main/IOBlockStorageDriver.cpp)
- Note: in that source, latent time is always passed as 0. [Local test] `ioreg` shows `"Latency Time (Read/Write)"=0` on the internal NVMe, while `"Total Time"` is non-zero. Use Bytes/Operations, not Latency.
- [Local test] As a normal user, `ioreg -c IOBlockStorageDriver` and a Swift binary calling `IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOBlockStorageDriver"))` + `IORegistryEntryCreateCFProperty(..., "Statistics")` returned live counters on Apple Silicon / macOS 27.2. Example for the internal SSD: Bytes (Read)=1.377 TB, Bytes (Write)=665 GB, Ops (Read)=49.9 M. There was no prompt, no root and no entitlement.
- On Apple Silicon the internal-SSD driver chain is `AppleANS3CGv2Controller → IOEmbeddedNVMeBlockDevice (NS_01@1) → IOBlockStorageDriver → "APPLE SSD AP0512R Media" (IOMedia, disk0)`. The built-in SD slot has its own driver (`AppleSDXCBlockStorageDevice → IOBlockStorageDriver`, all zeros with no card). — [Local test: `ioreg -p IOService -t`]
- An Apple Developer Forums thread (Nov 2025, "API for disk throughput?") asks for a non-`iostat` API usable from a notarized app. The replies: "You can get this information from IOKit… You can even get this information from the sandbox" (user Etresoft). The accepted answer points to Apple's `iostat` source. No Apple DTS engineer replied. — [developer.apple.com/forums/thread/806293](https://developer.apple.com/forums/thread/806293)
- Stats (exelban/stats) reads these counters with no root check, sudo or privilege escalation, using only public DiskArbitration and IORegistry reads. — [exelban/stats Modules/Disk/readers.swift](https://raw.githubusercontent.com/exelban/stats/master/Modules/Disk/readers.swift)
- Third-party libraries use the same path (Rust `sysinfo` macOS `disk.rs`; gopsutil `iostat_darwin.c`). — [docs.rs sysinfo disk.rs](https://docs.rs/crate/sysinfo/0.39.1/source/src/unix/apple/macos/disk.rs); [gopsutil iostat_darwin.c](https://github-redirect.dependabot.com/shirou/gopsutil/blob/360136f40562e030fb6c558d2c15d03afe4bf970/disk/iostat_darwin.c)

### Inferences
- Works unprivileged on Intel too. The IOStorageFamily code is architecture-neutral; only the driver chain above it differs (e.g. AHCI/NVMe/T2 `IONVMeBlockStorageDevice` instead of `IOEmbeddedNVMeBlockDevice`). Not tested locally on Intel.
- I found no evidence of TCC or privacy gating of IORegistry storage statistics in macOS 14, 15, 26 or 27. The local test shows it still works on 27.2, which postdates 26, so a regression in 15 or 26 is very unlikely.
- Sandbox: the forum post claims it works sandboxed. That is unverified, and it doesn't matter for Whirr, which is unsandboxed.

### Gaps
- No official Apple prose documentation or DTS statement guarantees "Statistics" as stable API. It is only defined in a public header and used by Apple's own `iostat`.
- I did not verify on Intel/T2 hardware, or on macOS 14/15/26 specifically. I tested only 27.2.
- I could not read the final ~18 KB of IOBlockStorageDriver.cpp (fetch truncation). I saw no stats notification in the part I read.

## Q2. Update granularity, meaningful poll rate, CPU/energy cost, notification alternative

### Takeaway
The counters are live, updated at each I/O completion with no batching. A 20–33 ms poll therefore sees activity within one poll period plus under 1 ms. No push notification exists for counter changes, so polling is required. Measured cost is about 30 µs CPU per poll of all drivers, or about 0.7–0.8% of one core at 30 Hz on Apple Silicon. That is acceptable, but it is not free for a battery-sensitive background tool.

### Cited Findings
- Per-I/O completion updates, no `messageClients`/`registerService`/`setProperty` on stat change, meaning **no IOKit interest notification fires when stats change**. — [IOBlockStorageDriver.cpp](https://raw.githubusercontent.com/apple-oss-distributions/IOStorageFamily/main/IOBlockStorageDriver.cpp)
- [Local test, latency] Polling every 1 ms for 4.5 s with deliberate 64 KB `F_NOCACHE` reads and writes plus `F_FULLFSYNC` every 200 ms:
  - Read counters changed +0.2 to +0.6 ms after `pread` returned. Write byte counters changed before `fcntl(F_FULLFSYNC)` returned (the write I/O completes before the flush).
  - Distinct counter changes ranged from 848 to 1,527 per 4.5 s. The minimum gap between changes was 1.03 ms, which is the polling resolution.
  - Conclusion: counters move at sub-millisecond granularity, with no batching window.
- [Local test, background noise] Even on an "idle" desktop, the internal SSD counters changed hundreds of times per second at 1 ms polling. That works out to 190–340 change events/s from system daemons, logging, APFS metadata and similar sources. A naive "any change → sound" trigger would fire nearly constantly. Thresholds (bytes per window) or rate shaping are needed.
- [Local test, cost] With 2 drivers, `IORegistryEntryCreateCFProperty` on "Statistics" cost about 31.6 µs wall and CPU per poll with cached service handles. It cost about 32.3 µs when re-running `IOServiceGetMatchingServices` each poll, so re-enumeration adds little. A real 30 Hz loop (`usleep(33ms)`) for 10 s used 0.075–0.090 s CPU, or 0.67–0.80% of one core. That is higher per poll (~250–300 µs) than the tight loop, probably because wake-up overhead and low-clock efficiency cores dominate (inferred, not measured).
- `iostat` rejects intervals below 1 s (`"wait time is < 1"`), so it can't serve sub-second sampling. — [apple-oss-distributions/system_cmds iostat.c](https://raw.githubusercontent.com/apple-oss-distributions/system_cmds/main/iostat/iostat.c)
- BlinkenDisk's README describes a 50 ms Foundation Timer, and the source confirms `pollIntervalSec: TimeInterval = 0.050`, no timer tolerance, `.common` run-loop mode, and a 10 ms LED flash. — [davepl/BlinkenDisk](https://github.com/davepl/BlinkenDisk); [StatusController.swift](https://raw.githubusercontent.com/davepl/BlinkenDisk/main/Sources/BlinkenDisk/StatusController.swift). This conflicts with a secondary report that it "monitors disk queues at 120Hz" ([tinyapps.org](https://tinyapps.org/blog/disk-activity-led-macos.html)). The source code (50 ms) is authoritative for the current version.
- Stats polls at 1 s (`setInterval(1)`). — [Stats readers.swift](https://raw.githubusercontent.com/exelban/stats/master/Modules/Disk/readers.swift)

### Inferences
- A 20–33 ms poll is meaningful: detection latency is about the poll period, with sub-ms counter lag. Going faster than ~16 ms buys little perceptually and raises wake-ups.
- To cut energy use: use a `DispatchSourceTimer` with a small leeway (e.g. 5 ms), cache service handles, and read only Bytes/Ops. Consider adaptive polling, slowing to e.g. 4–10 Hz after N idle seconds or when muted. Each poll is a Mach IPC round-trip to the kernel serializing an OSDictionary, which is why it costs tens of µs rather than ns.
- `IORegistryEntryCreateCFProperties` (all properties) would cost more than the single-key `IORegistryEntryCreateCFProperty`. Prefer the latter. This is inferred and was not benchmarked.

### Gaps
- I did not measure energy impact (powermetrics, Energy Impact in Activity Monitor) or idle-wakeup counts at 30 Hz.
- I did not benchmark on Intel.

## Q3. Alternatives compared (privileges, latency, granularity, cost)

### Takeaway
Only two methods are both system-wide and usable unprivileged: IORegistry block-driver statistics and (partially) per-process `proc_pid_rusage` sweeps. Every true event-stream mechanism needs root and/or entitlements: kdebug/ktrace (fs_usage), DTrace (blocked further by SIP) and Endpoint Security. FSEvents misses reads and adds coalescing latency. IORegistry polling is the right choice.

### Cited Findings
- **iostat**: it walks `IOMedia` with `kIOMediaWholeKey=true`, takes the parent in `kIOServicePlane`, and keeps it if it conforms to `IOBlockStorageDriver`. It reads "Statistics" via `IORegistryEntryCreateCFProperties`, summing BytesRead/Written, Reads/Writes and LatentRead/WriteTime. It handles hot-plug with `IOServiceAddMatchingNotification` (`kIOFirstMatchNotification` / `kIOTerminatedNotification`). Its minimum interval is 1 s. In short, it is the same data source with extra text formatting. — [system_cmds iostat.c](https://raw.githubusercontent.com/apple-oss-distributions/system_cmds/main/iostat/iostat.c)
- **fs_usage / ktrace (kdebug)**: [Local test] as a normal user, `fs_usage -f diskio` prints "'fs_usage' must be run as root...". `ktrace trace` prints "ktrace must be run as root when tracing the current system". In exchange, these give per-I/O, per-process, real-time events. `sudo fs_usage -f diskio` is the usual "which process is doing I/O" tool. — [cloudstreet-dev macOS disk-io guide](https://cloudstreet-dev.github.io/macOS-and-Unix/part12-performance/disk-io.html)
- **DTrace**: [Local test] `csrutil status` reports SIP enabled. With SIP on, DTrace kernel/io providers are restricted, and DTrace needs root anyway. Not viable for a per-user tool. (The SIP restriction on DTrace is well known, but I did not fetch a primary source this session. Treat it as a gap for exact provider limits.)
- **Endpoint Security**: the SDK header `ESTypes.h` lists `es_new_client` failures as `ES_NEW_CLIENT_RESULT_ERR_NOT_ENTITLED` ("not properly entitled"), `ERR_NOT_PERMITTED` ("lacks TCC approval"), `ERR_NOT_PRIVILEGED` ("not running as root") and `ERR_TOO_MANY_CLIENTS`. So it needs the restricted `com.apple.developer.endpoint-security.client` entitlement, root and Full Disk Access. Its events are file-system operations (open, write, close, etc.), not block I/O, so cached reads would still generate events with no disk activity. — [Local test: `$SDK/usr/include/EndpointSecurity/ESTypes.h` lines 387–395]; [Apple ES Client docs](https://developer.apple.com/documentation/endpointsecurity/client)
- **FSEvents**: the SDK `FSEvents.h` describes a "latency" parameter giving how long to wait after an event before delivering it. `kFSEventStreamCreateFlagNoDefer` changes this so the first event after a quiet period is delivered immediately, and later events coalesce. FSEvents reports namespace and content **changes**, not reads, and has no byte counts. It is unprivileged for the user's own paths. — [Local test: `FSEvents.h` lines 80, 222–230]; [FSEventStreamCreate docs](https://developer.apple.com/documentation/coreservices/1443980-fseventstreamcreate)
- **libproc `proc_pid_rusage` (RUSAGE_INFO_V4: `ri_diskio_bytesread/byteswritten`)**: [Local test] sweeping all 635 PIDs as a normal user took 1.3 ms total. It **failed with EPERM for 198 PIDs** (root/other-user daemons, e.g. Spotlight, backupd, kernel_task) and succeeded for 436. That makes it per-process and logical (it counts I/O charged to the process), but blind to most system daemons when unprivileged, and much more expensive per tick than one IORegistry read.
- **Activity Monitor**: Apple's guide says the Disk tab shows the number of reads/writes and data read/written. Apple does not document the source. — [Activity Monitor User Guide: View disk activity](https://support.apple.com/en-ae/guide/activity-monitor/actmntr1005). A user reports it gives a cumulative figure across all devices. — [Apple Discussions thread 250895904](https://discussions.apple.com/thread/250895904)
- **IOReport (private framework)**: it is used unprivileged by tools like macmon for GPU/CPU power and residency channels. I found no evidence it exposes NAND/disk bandwidth channels. — [macmon sources.rs](https://docs.rs/crate/macmon/latest/source/src/sources.rs); [netdata macOS collector](https://learn.netdata.cloud/docs/collecting-metrics/collectors/operating-systems/macos)
- **host_statistics64 / vm_stat**: these give VM paging counts (pageins/pageouts, swapins/swapouts). [Local test] `vm_stat` works unprivileged. They capture only paging I/O, a small subset of disk activity.

### Inferences
Summary comparison (privileges / latency / granularity / cost):

| Method | Privilege | Latency | Granularity | Cost / verdict |
|---|---|---|---|---|
| IORegistry IOBlockStorageDriver "Statistics" poll | none (user, unsandboxed; probably sandbox too) | poll period + <1 ms | per physical device, bytes+ops, read/write split | ~30 µs/poll; ~0.7% core @30 Hz. **Best fit** |
| `iostat` subprocess | none | ≥1 s | per disk | text parsing, process overhead. No |
| fs_usage / ktrace / kdebug | root | real-time | per I/O, per process, per file | heavy. No (root) |
| DTrace io provider | root + SIP-restricted | real-time | per I/O | No |
| Endpoint Security | root + restricted entitlement + FDA | real-time | file ops, not block I/O | No |
| FSEvents | none (own files) | ≥ latency param, coalesced | path changes, no reads, no bytes | Misses reads. No |
| proc_pid_rusage sweep | none, but EPERM on ~30% of PIDs | poll | per process, logical bytes | 1.3 ms per sweep. Blind to daemons. Supplement only |
| host_statistics64 (vm_stat) | none | poll | paging only | cheap, but partial. Optional supplement |
| IOReport (private) | none for some channels | poll | no known disk channel | private API. No |

### Gaps
- Activity Monitor and iStat Menus are closed source, so their exact data source is not confirmed. Both very likely use the same IOKit statistics, but I found no source stating so.
- I fetched no primary Apple source on DTrace's SIP restrictions on macOS 15/26.
- The ES and FSEvents Apple doc pages rendered without body text via fetch. The facts above rely on the local SDK headers instead.

## Q4. What existing disk-activity tools use (with source)

### Takeaway
All the open-source indicators read the same IOKit IOBlockStorageDriver statistics: Stats (1 s poll, deduplicated by driver), BlinkenDisk (50 ms poll, LED on any counter change) and Apple's own iostat (1 s minimum). Their main differences are how they map volumes to drivers and whether they handle hot-plug and sleep.

### Cited Findings
- **Stats (exelban/stats), `ActivityReader`**:
  - It lists mounted volumes, then gets each volume's IOMedia via `DADiskCreateFromVolumePath` → `DADiskCopyIOMedia`.
  - `getDeviceIOParent` walks `kIOServicePlane` parents (max 256 entries) to the `kIOBlockStorageDriverClass`. It returns a driver only if all branches resolve to one driver.
  - It keys samples by `IORegistryEntryGetRegistryEntryID`, so several APFS volumes on one physical disk aren't double-counted.
  - It reads `kIOBlockStorageDriverStatisticsBytesReadKey/BytesWrittenKey` and computes rate = Δbytes/Δt from `DispatchTime.now().uptimeNanoseconds`.
  - It returns 0 if the counter went backward or there is no previous sample. It resets samples on `didWakeNotification`, on pause and on stop.
  - It polls at 1 s. — [Stats readers.swift](https://raw.githubusercontent.com/exelban/stats/master/Modules/Disk/readers.swift)
- **BlinkenDisk (Dave Plummer, Swift, macOS 12+, personal non-commercial license)**:
  - `DiskMonitor.swift` matches `IOServiceMatching("IOBlockStorageDriver")` and finds the child with `Whole=true` and a BSD Name.
  - It reads "Bytes (Read)/(Write)" and "Operations (Read)/(Write)". If any changed, it flashes the LED (10 ms default).
  - It does **not cache** handles: every `readStats` re-runs `IOServiceGetMatchingServices` and walks children.
  - It has no hot-plug notifications, but uses DiskArbitration for friendly names.
  - — [BlinkenDisk repo](https://github.com/davepl/BlinkenDisk); [DiskMonitor.swift](https://raw.githubusercontent.com/davepl/BlinkenDisk/main/Sources/BlinkenDisk/DiskMonitor.swift); [StatusController.swift](https://raw.githubusercontent.com/davepl/BlinkenDisk/main/Sources/BlinkenDisk/StatusController.swift)
- Release coverage: BlinkenDisk was described in a May 2026 blog post as a menu-bar red LED lit on local-drive I/O. — [tinyapps.org](https://tinyapps.org/blog/disk-activity-led-macos.html)
- **iostat**: see Q3. It goes IOMedia (Whole) → parent IOBlockStorageDriver and uses IOKit matching notifications for hot-plug. — [iostat.c](https://raw.githubusercontent.com/apple-oss-distributions/system_cmds/main/iostat/iostat.c)
- **Other projects** read the same per-device cumulative `Bytes (Read)`/`Bytes (Write)` counters: syswatch, sysinfo and gopsutil. — [syswatch disk_macos.rs](https://docs.rs/crate/syswatch/0.7.2/source/src/collect/disk_macos.rs); [sysinfo](https://docs.rs/crate/sysinfo/0.39.1/source/src/unix/apple/macos/disk.rs)
- Other commercial disk-LED apps exist (Disktivity, Disk LED Pro, DriveLight). Their implementation is not public. — [Disktivity App Store](https://apps.apple.com/us/app/disktivity/id523532678?mt=12); [DriveLight App Store](https://apps.apple.com/us/app/drivelight/id6446650999?mt=12)

### Inferences
- BlinkenDisk's design (50 ms poll, "any counter delta → flash") is the closest precedent to Whirr. Whirr should copy its approach but cache handles, as iostat and Stats do (BlinkenDisk re-enumerates every poll), and add a noise threshold (see Q2 background noise).

### Gaps
- iStat Menus and Activity Monitor implementations are unverified (closed source).

## Q5. Apple Silicon / APFS / SSD considerations, instance selection, double counting

### Takeaway
Block-driver counters measure physical device I/O after the unified buffer cache and APFS. Cached reads generate no events, and writes appear when they are flushed, which is often deferred or coalesced. Pick physical drivers only and exclude virtual ones such as disk images. On Apple Silicon, synthesized APFS containers have no driver of their own, but mounted disk images do and will double-count.

### Cited Findings
- [Local test] On Apple Silicon / macOS 27.2, only **2** IOBlockStorageDriver instances existed: the internal NVMe (disk0) and the empty SD slot. The synthesized APFS containers `disk1`, `disk2` and `disk3` (`diskutil list`: "synthesized", "Physical Store disk0s2") have **no** IOBlockStorageDriver. Matching the class directly therefore does not double-count APFS containers.
- [Local test] Attaching a 20 MB APFS `.dmg` (`hdiutil attach`) created a **third** IOBlockStorageDriver, with parent chain `IOHDIXHDDriveOutKernel → IODiskImageBlockStorageDeviceOutKernel → IOBlockStorageDriver`. Writing 5 MB to the image raised that driver's Bytes (Write) to 5,308,416. The same data is eventually written to the backing file on disk0, so summing all drivers **double-counts** disk-image I/O. It also shows the driver set changes at runtime: after detaching, the count went back to 2.
- Stats handles APFS volumes → shared physical driver by deduplicating on registry entry ID. — [Stats readers.swift](https://raw.githubusercontent.com/exelban/stats/master/Modules/Disk/readers.swift)
- Bytes are counted from `actualByteCount` at completion, including on error. — [IOBlockStorageDriver.cpp](https://raw.githubusercontent.com/apple-oss-distributions/IOStorageFamily/main/IOBlockStorageDriver.cpp)
- [Local test] Deliberate `F_NOCACHE` 64 KB I/Os showed up as counter deltas of 64 KB or more (e.g. 65,536 / 229,376 / 286,720 B write deltas), mixed with concurrent system I/O.

### Inferences
- Cached reads (file data already in the unified buffer cache) produce zero block I/O, so Whirr will be silent for "reads" served from RAM. That matches the "physical disk sound" metaphor and is arguably correct.
- APFS and the VFS delay and coalesce buffered writes, so writes from an app appear as fewer, larger bursts at flush or sync time (local test: write bytes posted before `F_FULLFSYNC` returned). Exact APFS flush intervals were not found.
- Recommended selection: enumerate IOBlockStorageDriver and skip drivers whose provider is a disk-image device. Checks could be the parent class name containing "DiskImage" or "HDIX", or the device's "Protocol Characteristics" → "Physical Interconnect" = "Virtual Interface" (the latter is unverified this session). Optionally restrict to Internal/External physical interconnect, and dedupe by registry entry ID.
- Internal SSD and external (USB/Thunderbolt) disks each get their own driver. Whirr can sound per-device or aggregate.

### Gaps
- I did not test the "Protocol Characteristics" key on Apple Silicon or the disk-image device, or external USB/Thunderbolt SSDs, Fusion drives, or RAID sets (iostat's source itself has "XXX What about RAID devices?").
- I found no primary source on APFS write-back and flush timing on macOS 15/26.

## Q6. Pitfalls: counter wraparound, hot-plug, sleep/wake

### Takeaway
Wraparound is a non-issue with 64-bit counters. The real pitfalls are drivers appearing and disappearing (USB disks, DMGs, SD cards), counters resetting when a device re-attaches, and a burst of deltas or stale handles after sleep/wake. Handle them iostat- and Stats-style: matching notifications, keying by registry ID, and treating negative deltas as zero.

### Cited Findings
- Counters are 64-bit OSNumbers. — [IOBlockStorageDriver.cpp](https://raw.githubusercontent.com/apple-oss-distributions/IOStorageFamily/main/IOBlockStorageDriver.cpp). Arithmetic: 2^64 B at a sustained 7 GB/s is about 83 years, so wraparound is practically impossible. (This is my own calculation from the 64-bit width.)
- iostat registers `IOServiceAddMatchingNotification` for `kIOFirstMatchNotification` and `kIOTerminatedNotification` to add and remove drives. — [iostat.c](https://raw.githubusercontent.com/apple-oss-distributions/system_cmds/main/iostat/iostat.c)
- BlinkenDisk has no hot-plug handling. Callers must re-enumerate, and `readStats` returns nil for a vanished disk. — [DiskMonitor.swift](https://raw.githubusercontent.com/davepl/BlinkenDisk/main/Sources/BlinkenDisk/DiskMonitor.swift)
- Stats resets its samples on `NSWorkspace.didWakeNotification`. It returns 0 when a counter goes backward or there's no previous sample, and drops entries for drivers no longer seen. — [Stats readers.swift](https://raw.githubusercontent.com/exelban/stats/master/Modules/Disk/readers.swift)
- [Local test] A newly attached disk image's driver started at 0 and its registry ID was new (`0x1000dead1`). A re-attached device therefore appears as a new driver with fresh counters.

### Inferences
- Recommended handling:
  - Use IOKit matching notifications (first-match and terminated on IOBlockStorageDriver) on an `IONotificationPort` attached to the run loop or dispatch queue.
  - Key state by registry entry ID, and treat a first sample or negative delta as 0.
  - Drop the first delta after wake to avoid a "catch-up" burst sound. For a CLI with no NSWorkspace, use `IORegisterForSystemPower` to get sleep/wake messages.
  - Pause or slow polling while asleep. Timers don't fire during sleep anyway.
- [Local test] Background noise on the system disk is high (hundreds of counter changes per second). The main UX pitfall is therefore over-triggering rather than missing I/O. Use byte and op thresholds, separate read and write sounds, and rate-limit playback.

### Gaps
- I didn't verify whether internal-SSD counters persist or reset across sleep/wake on Apple Silicon. They are expected to persist because the driver isn't torn down, but this was not tested.
- I didn't verify whether a CLI process (no app bundle) is subject to timer coalescing or App Nap-like throttling in the background on macOS 26/27. No source was found.

# Audio playback on macOS for a lightweight background sound-effect process (Whirr)

Scope: short, frequent, low-latency, procedurally synthesized HDD sounds (seek clicks, chatter, grinding) triggered by events from a background process (CLI or agent). Targets macOS 15 Sequoia and 26 Tahoe on Apple Silicon. Research date: 2026-11-23. Several key sources are old: TN2321 is from the OS X 10.9 era, and the Rogue Amoeba post dates from 2013. Those are flagged where used.

**Overall recommendation (synthesized; reasoning in the sections below):** Use one long-lived output graph. Either (a) AVAudioEngine with a fixed pool of pre-connected AVAudioPlayerNodes that play pre-rendered AVAudioPCMBuffer variations, or (b) a single AVAudioSourceNode or AudioQueue/AUHAL render callback that mixes pre-rendered sample arrays from a lock-free voice list. Request a 256-frame IO buffer. Start the output lazily on the first event and stop it after roughly 5–15 s of silence. Follow the default output device, or the alert device as an option, through property listeners and the configuration-change notification. Never use afplay, NSSound or AudioServices for high-rate triggers. Thock, the most mature open-source keyboard-sound app, ships exactly this pattern on AudioQueue: a 256-frame buffer and a 10 s idle stop.

---

## Q1. API comparison and trigger-to-sound latency

### Takeaway
No source publishes a rigorous head-to-head ms benchmark for all of these APIs on macOS. The evidence supports a clear ranking, though. A persistent, already-running output (AVAudioEngine with player nodes or a source node, an AUHAL/DefaultOutput callback, or AudioQueue) gives latency bounded by the IO buffer plus device latency, roughly 5–15 ms on built-in output at 256–512 frames. Per-trigger APIs such as NSSound, AVAudioPlayer, AudioServicesPlaySystemSound and afplay add setup and warm-up costs that range from tens of ms to many hundreds of ms. AVAudioPlayerNode is fast only if nodes are attached, connected and playing up front and never reconfigured.

### Cited Findings
- **Buffer = latency, 1:1.** "The size of the I/O buffer is directly related to the latency of the I/O system. It is a one to one relationship." The macOS default IO buffer was 512 frames, rising to 4096 if the app sets the power-saving hint. (OS X 10.9-era doc; may be outdated.) — [Apple TN2321](https://developer.apple.com/library/archive/technotes/tn2321/_index.html)
- **AVAudioSourceNode render block** runs under real-time constraints when rendering to a device. WWDC19 presents it as the way to supply procedural audio to AVAudioEngine. — [WWDC19 session 510 "What's New in AVAudio"](https://developer.apple.com/videos/play/wwdc2019/510/)
- **Deadline math:** at 44.1 kHz with a 512-frame buffer the callback has about 11 ms. Missing the deadline produces a dropout. — [Orestis Papadopoulos, AVAudioSourceNode blog (2020)](https://orjpap.github.io/swift/real-time/audio/avfoundation/2020/06/19/avaudiosourcenode.html)
- **AVAudioPlayerNode.play() cost:** one developer measured `play()` taking "close to 20 ms" when nodes were connected with a new format right before playing (iOS 9/10, old). The fix was a fixed pool of pre-connected player nodes that are never reconfigured. — [Apple Dev Forums thread 68603](https://developer.apple.com/forums/thread/68603)
- **Engine/player startup:** about 370 ms to start 16 player nodes on an older iPad, about 200 ms in the simulator. These figures include player setup, not just `engine.start()`. — [Apple Dev Forums thread 123485](https://developer.apple.com/forums/thread/123485)
- **AudioOutputUnitStart** was observed at about 500 ms in one iOS Push-to-Talk scenario. That is a special case, but it shows start cost can be large. — [Apple Dev Forums thread 814137](https://developer.apple.com/forums/thread/814137)
- **AudioComponentInstanceNew** took 2–3 s on several Macs in one report. This is the cost of instantiating an audio unit and argues for creating units once and keeping them. — [Apple Dev Forums thread 756760](https://developer.apple.com/forums/thread/756760)
- **AudioQueue start:** a Core Audio list reply says Apple makes no guarantees about AudioQueue startup latency. — [coreaudio-api list, Jul 2012](https://lists.apple.com/archives/coreaudio-api/2012/Jul/msg00007.html) (via search summary; the page returned 502 on fetch)
- **AVAudioPlayer:** Apple forum guidance says AVAudioPlayer is the supported simple player except when "very low-latency sounds" are required. A tutorial notes "a noticeable small delay" on tap-triggered playback. One developer reported about 500 ms with AVFoundation's player (anecdotal). — [Apple Dev Forums thread 111642](https://developer.apple.com/forums/thread/111642); [Kodeco audio tutorial](https://www.kodeco.com/?p=69369); [SO mirror: play sound without latency iOS](https://kiwix.lema.org/stackoverflow.com_en_all_2023-11/questions/35689772/play-sound-without-latency-ios)
- **AudioServicesPlaySystemSound:** intended for short uncompressed files of 30 s or less. It plays at system volume with no programmatic volume control. First playback can be delayed. — [Apple Audio Services docs](https://developer.apple.com/documentation/audiotoolbox/audio-services.md); [Core iOS book excerpt (O'Reilly)](https://www.oreilly.com/library/view/the-core-ios/9780133510119/ch03lev2sec19.html)
- **afplay:** no measured startup latency was found. It is a blocking CLI meant for one-shot playback of an existing file. Each call spawns a process and opens a new audio client. — [flaviocopes: play a sound from the macOS command line](https://flaviocopes.com/how-to-play-a-sound-from-the-macos-command-line/)
- **First-play warm-up on macOS** (lazy device/context init) was reported at "often 0.5–1+ seconds" in the Defold engine. This is an analogy for any API that opens the device per sound. — [Defold forum](https://forum.defold.com/t/big-delay-playing-sounds-the-first-time-desktop/82587)
- **Thock** (open source, about 1k stars, active Nov 2026) says it uses a custom AudioQueue engine with sub-10 ms latency. The source confirms `AudioQueueNewOutput` with 3 buffers, a default `audioBufferSize` of 256 frames, and app-side mixing of pre-loaded PCM ("PCMSound"/"ActiveSound"). — [deepwiki summary of Thock](https://deepwiki.com/kamillobinski/thock) (third-party summary); [Thock source: SoundManager.swift](https://github.com/kamillobinski/thock/blob/main/Thock/Managers/SoundManager.swift), [SettingsManager.swift](https://github.com/kamillobinski/thock/blob/main/Thock/Managers/SettingsManager.swift)

### Inferences
- **Approximate ranking**, lowest to highest trigger-to-sound latency on built-in speakers with the output already running:
  1. A raw AUHAL/DefaultOutput callback, an AVAudioSourceNode, or AudioQueue with app-side mixing. Latency is one IO buffer (256 frames ≈ 5.3 ms at 48 kHz; 512 ≈ 10.7 ms) plus device and safety-offset latency, plus up to one buffer of scheduling jitter. The jitter comes from when the event lands relative to the IO cycle.
  2. AVAudioPlayerNode `scheduleBuffer(..., at: nil)` on an already-playing node. Same order of magnitude, plus a little scheduling overhead. Clacky deliberately avoids per-trigger `stop()`/`play()` for latency reasons.
  3. AudioServicesPlaySystemSound/PlayAlertSound, NSSound, AVAudioPlayer (prepared). The latency is unquantified but goes through higher-level machinery. These APIs can't play procedurally generated audio without first writing a file (SystemSound) or building an NSSound from data.
  4. Spawning afplay. Process spawn, file open, audio client creation and possible device warm-up on every event. Unsuitable for "frequent" sounds.
- AudioQueue latency is bounded by enqueue granularity. Thock gets low latency by keeping three tiny 256-frame buffers cycling and mixing into them itself, not by enqueuing one buffer per sound.
- For procedurally synthesized HDD sounds, the two good shapes are (a) pre-rendered variation buffers played through a player-node pool and (b) one render callback that mixes voices. Both have the same latency class. (b) has fewer moving parts and fewer AVFoundation edge cases, and gives exact control.

### Gaps
- I found no rigorous, published ms measurements for NSSound, AudioServicesPlaySystemSound or afplay trigger latency on Apple Silicon or macOS 15/26. Recommend measuring with a loopback or a microphone plus `mach_absolute_time` stamps.
- No authoritative number exists for `AVAudioEngine.start()` cold or warm latency on macOS. The forum figures are iOS and old.
- Device-side latency (`kAudioDevicePropertyLatency` + `kAudioDevicePropertySafetyOffset` + stream latency) for MacBook built-in speakers was not found in a citable source. Query these properties at runtime.

---

## Q2. Idle CPU/energy of a running output; keep running vs start/stop on demand

### Takeaway
A running output engine is not free. It wakes the CPU every IO cycle even when rendering silence, and coreaudiod holds a sleep-preventing power assertion while any client's output is running. Apple explicitly says to pause or stop the engine when no audio is needed. Stopping the player nodes is not enough. The proven pattern is lazy start plus an idle timeout. Thock defaults to stopping its AudioQueue after 10 s of silence and restarts on the next event, so only the first sound after idle pays the startup cost.

### Cited Findings
- Apple: pausing or stopping all player nodes "doesn't pause or stop the engine or the underlying hardware". You must explicitly pause or stop the engine. "When your app doesn't need to play audio, pause or stop the engine to minimize power consumption." `stop()` also releases prepared resources. `pause()` keeps them, so resuming is cheaper. — [AVAudioEngine docs](https://developer.apple.com/documentation/avfaudio/avaudioengine.md); [pause()](https://developer.apple.com/documentation/avfaudio/avaudioengine/pause().md); [stop()](https://developer.apple.com/documentation/avfaudio/avaudioengine/stop().md)
- "The size of the I/O buffer controls the rate at which the audio stack will wake the CPU in order to perform I/O. Therefore, the I/O buffer size will nearly always be the dominant factor affecting audio stack power usage." Batching work lets "the CPU... drop into deeper sleep states for longer periods". — [Apple TN2321](https://developer.apple.com/library/archive/technotes/tn2321/_index.html)
- Muted nodes still cost CPU. One developer reported 4 muted tone-generator chains adding about 15% CPU. Detaching nodes to save CPU caused clicks and pops. — search summary of Apple Dev Forums AVAudioEngine threads ([tag listing](https://origin-devforums.apple.com/forums/tags/avaudionode)) (anecdotal)
- On iOS, Firefox found that "Audio CPU Activity" stayed at a steady 0.8% forever after an audio suspend/resume left the output running. — [Mozilla bug 1220378](https://bugzilla.mozilla.org/show_bug.cgi?id=1220378)
- **Sleep:** while output runs, `coreaudiod` holds a `PreventUserIdleSystemSleep` assertion attributed to the client PID, visible via `pmset -g assertions`. Users trace "Mac won't sleep" to apps that leave audio running, including Remote Desktop, Unity and Spotify. — [MacRumors: coreaudiod spamming PreventUserIdleSystemSleep](https://forums.macrumors.com/threads/mac-studio-sleep-issue-coreaudiod-spamming-my-log-with-released-preventuseridlesystemsleep.2456169); [Microsoft Tech Community](https://techcommunity.microsoft.com/idea/azurevirtualdesktop/microsoft-remote-desktop-v10-7-9-2011-macos---triggers-preventuseridlesystemslee/3616556); [dev.to: Unity keeps your Mac awake](https://dev.to/tetra2000/unity-keeps-your-mac-staying-awake-maybe-you-can-fix-this-p9f)
- A developer found that coreaudiod's power assertion cannot be lowered by the client (`kIOReturnNotPermitted`), and that `kAudioHardwarePropertySleepingIsAllowed` did not help. — [Apple Dev Forums thread 130042](https://developer.apple.com/forums/thread/130042)
- **Thock's implementation:** `defaultIdleTimeoutSeconds = 10.0` ("Set to 0 to disable idle timeout (queue always runs)"). On timeout it calls `AudioQueueStop(queue, true)`. It calls `AudioQueueStart` again when the next sound arrives and replays the triggering sound once the queue is running. — [Thock SettingsManager.swift](https://github.com/kamillobinski/thock/blob/main/Thock/Managers/SettingsManager.swift); [Thock SoundManager.swift](https://github.com/kamillobinski/thock/blob/main/Thock/Managers/SoundManager.swift)
- **Clacky's implementation** (AVAudioEngine) is the opposite design. The engine and all 16 player nodes start once and "stay running". It shows no idle stop in the source, which is lower latency but means a permanent running output. — [Clacky AudioEngine.swift](https://github.com/jasonzh0/Clacky/blob/main/Clacky/Core/AudioEngine.swift)
- A macOS developer notes they must stop and tear down AVAudioEngine when idle so other apps can use audio properly. — [Apple Dev Forums thread 732811](https://developer.apple.com/forums/thread/732811)

### Inferences
- For a background daemon that may sit idle for hours, a permanently running output is the wrong default. It prevents idle sleep, keeps waking the CPU at about 94–188 Hz (48 kHz / 512 or 256 frames), and makes the app show up in Energy Impact and `pmset` assertions. Use lazy start plus an idle stop:
  - Start the output on the first event. Keep it running while events keep coming, since HDD chatter comes in bursts.
  - After N seconds with no active voices (5–15 s; Thock uses 10 s), call `engine.pause()` (keeps resources, faster resume) or `AudioOutputUnitStop` / `AudioQueueStop`. Use `stop()` only when you also want to release resources.
  - Accept that the first sound after idle may be late by the restart cost. Typically this is tens of ms when nodes and units are already instantiated. It can be far longer if you also re-create units, so never tear down the graph on idle; only stop IO. Either drop that first sound or play it late. Thock plays it late.
  - Optionally pre-warm: if the event source gives a hint (e.g., the process starts heavy IO), start the output slightly ahead.
- Use 256 frames while active (latency matters for clicks). The battery cost is only paid during bursts because of the idle stop.

### Gaps
- No Apple-published measurement of idle CPU% or energy for a running AVAudioEngine or AUHAL rendering silence on Apple Silicon. Measure with Instruments' Energy/Power profiler or `powermetrics` and `pmset -g assertions`.
- I could not confirm on macOS 26 whether `engine.pause()` (vs `stop()`) releases coreaudiod's sleep assertion. Verify with `pmset -g assertions`.

---

## Q3. IO buffer size (kAudioDevicePropertyBufferFrameSize): latency vs CPU

### Takeaway
Set the buffer per device with `kAudioDevicePropertyBufferFrameSize`, within `kAudioDevicePropertyBufferFrameSizeRange`. Latency scales one-to-one with buffer size, and so do wakeups per second. 256 frames (≈5.3 ms at 48 kHz) suits clicky SFX. 512 is the classic default (≈10.7 ms). Larger values save power but feel laggy. The buffer is a per-device setting, and coreaudiod generally runs the device at the smallest size any client requests, so a small request can raise power for the whole device.

### Cited Findings
- Set it with `kAudioDevicePropertyBufferFrameSize` (HAL `AudioObjectSetPropertyData`, or `AudioUnitSetProperty` on AUHAL). Query the range with `kAudioDevicePropertyBufferFrameSizeRange`. If you go above the default you must raise `kAudioUnitProperty_MaximumFramesPerSlice` on each AU, or the AUs fail with `kAudioUnitErr_TooManyFramesToProcess`. — [Apple TN2321](https://developer.apple.com/library/archive/technotes/tn2321/_index.html)
- Default 512 frames. The power hint `kAudioHardwarePowerHintFavorSavingPower` (or Info.plist `AudioHardwarePowerHint` = "Favor Saving Power") raises it to 4096. Latency-sensitive apps (games, DAWs) should use "the largest buffer possible without breaking the specific use case requirements"; moving from 512 to 1024 gives "measurable power savings". (10.9-era.) — [Apple TN2321](https://developer.apple.com/library/archive/technotes/tn2321/_index.html)
- `kAudioUnitProperty_MaximumFramesPerSlice` defaults to 1024 frames, with 256 suggested for low latency. This is a different property from the device buffer size. — [Apple QA1533](https://developer.apple.com/library/mac/qa/qa1533/_index.html); [Apple docs](https://developer.apple.com/documentation/audiotoolbox/kaudiounitproperty_maximumframesperslice.md)
- Jeff Moore (Apple Core Audio): the property is in frames, and the right IO size depends on the app. A larger size means fewer IOProc calls per second. — [coreaudio-api list, Feb 2010](https://lists.apple.com/archives/coreaudio-api/2010/Feb/msg00269.html)
- A recent report says "Designed for iPad" apps on macOS 27 get `ioBufferDuration` pinned at 512 regardless of request. That applies to iPad apps only, not native macOS processes. — [Apple Dev Forums thread 853348](https://developer.apple.com/forums/thread/853348)
- Thock exposes buffer size as a user setting (default 256) and rebuilds its AudioQueue when it changes. — [Thock SettingsManager.swift](https://github.com/kamillobinski/thock/blob/main/Thock/Managers/SettingsManager.swift)
- Per-cycle render time scales with the IO buffer duration: a few ms at small buffers, over 20 ms at the default (iOS context). — [Apple Dev Forums thread 123540](https://developer.apple.com/forums/thread/123540)

### Inferences
- **AVAudioEngine on macOS** has no `AVAudioSession.setPreferredIOBufferDuration`. Set the buffer on the output node's underlying unit: `engine.outputNode.audioUnit` plus `AudioUnitSetProperty(kAudioDevicePropertyBufferFrameSize, kAudioUnitScope_Global, 0, ...)`. Alternatively set it on the device via `AudioObjectSetPropertyData` before starting. Re-apply it after every device change, because a new device has its own setting.
- Don't set the power hint to "Favor Saving Power" for this app; it would push the buffer to 4096 (≈85 ms). Rely on the idle stop for power savings instead.
- **CPU:** cost per buffer is roughly constant overhead plus per-sample work. Halving the buffer doubles wakeups but not the DSP work. For a few voices of pre-rendered sample playback the work is trivial, so wakeup frequency dominates. That reinforces stopping IO when idle.

### Gaps
- No current, citable statement of the default buffer size on Apple Silicon built-in output under macOS 15/26, or of the exact min of `BufferFrameSizeRange`. Query at runtime.
- I found no source here confirming how coreaudiod arbitrates conflicting per-client buffer sizes on modern macOS. The "smallest wins" behaviour is commonly stated but uncited.

---

## Q4. Output device changes and Bluetooth latency

### Takeaway
Expect the default output to change (AirPods connect, headphones plugged in, display audio). With AVAudioEngine the engine stops, uninitializes itself and posts `AVAudioEngineConfigurationChange` when the hardware sample rate or channel count changes. You must restart it, and often rebuild connections whose formats changed. Lower-level code should register `AudioObjectAddPropertyListener` on `kAudioHardwarePropertyDefaultOutputDevice`, plus `kAudioHardwarePropertyDefaultSystemOutputDevice` if following the alert device, and `kAudioHardwarePropertyDevices`, then re-point the unit or queue (`kAudioOutputUnitProperty_CurrentDevice` / `kAudioQueueProperty_CurrentDevice`). Bluetooth output adds roughly 140–300+ ms that the app cannot remove.

### Cited Findings
- Apple: "When the audio engine's I/O unit observes a change to the audio input or output hardware's channel count or sample rate, the audio engine stops, uninitializes itself, and issues this notification." — [AVAudioEngineConfigurationChange docs](https://developer.apple.com/tutorials/data/documentation/foundation/nsnotification/name-swift.struct/avaudioengineconfigurationchange.md)
- Developers report having to stop the engine, re-attach and reconnect player nodes, then restart. Some say a plain stop/start or `reset()` doesn't fix AirPods route switches. Others re-create the engine to pick up new formats, because mismatched formats can crash. — [Apple Dev Forums thread 772380](https://developer.apple.com/forums/thread/772380); [thread 769907 (config change clears player node)](https://developer.apple.com/forums/thread/769907); [thread 745534](https://developer.apple.com/forums/thread/745534)
- `AVAudioEngine.start()` can return success while the engine remains stopped and immediately posts a config-change notification. Check `isRunning` after starting. — [Apple Dev Forums thread 825253](https://developer.apple.com/forums/thread/825253)
- On macOS you can point AVAudioEngine's output at a specific device by setting `kAudioOutputUnitProperty_CurrentDevice` on `outputNode.audioUnit`. This is an old, unofficial thread. — [coreaudio-api list, Sep 2019](https://lists.apple.com/archives/coreaudio-api/2019/Sep/msg00003.html)
- **Thock** listens via `AudioObjectAddPropertyListener` on `kAudioHardwarePropertyDevices` and `kAudioHardwarePropertyDefaultOutputDevice`. It tracks devices by UID (`kAudioDevicePropertyDeviceUID`) and checks output capability via `kAudioDevicePropertyStreamConfiguration`. On any change it disposes and re-creates the AudioQueue (`reinitializeAudioQueue`) and binds it to the chosen device through `kAudioQueueProperty_CurrentDevice`. It also has a headphone-jack change handler. — [Thock AudioDeviceManager.swift](https://github.com/kamillobinski/thock/blob/main/Thock/Managers/AudioDeviceManager.swift); [SoundManager.swift](https://github.com/kamillobinski/thock/blob/main/Thock/Managers/SoundManager.swift)
- Using Continuity with AirPods can interfere with programmatically setting the default output device. — [Apple Dev Forums thread 763583](https://developer.apple.com/forums/thread/763583)
- **Bluetooth latency:** keyboard-sound trigger-to-ear measurements (iOS, 2019) were AirPods 1 about 274 ms, AirPods 2 about 178 ms, AirPods Pro about 144 ms. AirPods Pro 2 improved further, but there is still "too much latency for audio feedback to feel snappy". — [MacRumors summary of Stephen Coyle tests](https://www.macrumors.com/2019/12/23/airpods-pro-bluetooth-latency/); [9to5Mac AirPods Pro 2 latency test (2022)](https://9to5mac.com/2022/11/15/airpods-pro-2-latency-test/); [iMore](https://www.imore.com/airpods/airpods-pro-2-latency-is-much-better-but-will-still-disappoint-heres-why)
- Developer reports on Apple platforms: about 215–220 ms initially with AirPods, then drifting down, with actual latency differing from what the API reports. Another report saw 300–400 ms through the macOS 14.2 audio-tap API on BT devices. — [Apple Dev Forums thread 679274](https://developer.apple.com/forums/thread/679274); [thread 770218](https://developer.apple.com/forums/thread/770218)

### Inferences
- **Recommended handling:**
  - Default: follow the system default output (or the alert device; see Q6).
  - Register HAL listeners on the system object for the default-device selector(s) and the device list. Dispatch handling off the HAL notification thread to your own serial queue.
  - On change: stop IO, re-point (`CurrentDevice`) or rebuild the unit, re-apply the buffer size, re-read the sample rate, and re-render or resample cached buffers if the rate changed. If the output was running, restart it. If idle, just mark it dirty and rebuild lazily on the next event.
  - With AVAudioEngine, also observe `AVAudioEngineConfigurationChange`.
- Rendering pre-rendered buffers at a fixed internal rate (e.g., 48 kHz) and letting the output unit's converter resample avoids re-rendering on rate changes. AVAudioEngine's mixer does this automatically; with AUHAL, set the input-scope stream format and the AU converts.
- **Bluetooth:** there is no API to reduce A2DP/AAC latency. Document it as a caveat. Optionally detect a BT transport (`kAudioDevicePropertyTransportType == kAudioDeviceTransportTypeBluetooth`) and either warn, offer a "mute on Bluetooth" setting, or route sound effects to built-in speakers as Thock's device picker allows. Mic-capable BT headsets in HFP mode sound worse; output-only use keeps A2DP.

### Gaps
- No citable 2025–2026 measurement of AirPods Pro 2/3 or AirPods 4 latency on macOS 15/26 specifically.
- It is unconfirmed whether macOS 26 posts `AVAudioEngineConfigurationChange` for a default-device switch when the format is unchanged. Some reports suggest it doesn't always fire, so HAL listeners remain the robust signal.

---

## Q5. Real-time safety in Swift; pre-render vs live synthesis

### Takeaway
Real-time render callbacks (AVAudioSourceNode, AUHAL render callback) must not allocate, lock, call libdispatch, do ObjC/Swift dynamic dispatch that may allocate, log, or touch reference-counted Swift objects. Swift makes this easy to violate implicitly through ARC retain/release, copy-on-write arrays, closures, existentials and generics metadata. The common and safest practice is to pre-render many randomized variations into plain Float buffers on a background thread. The real-time callback then only mixes from preallocated memory with lock-free voice triggers, an SPSC ring buffer of events. AudioQueue callbacks are not the hard real-time IO thread, which is why Thock gets away with NSLock-based mixing there.

### Cited Findings
- WWDC19: AVAudioSourceNode's render block runs under real-time constraints when rendering to a device. Avoid blocking calls such as memory allocation, libdispatch and mutex waits. — [WWDC19 session 510](https://developer.apple.com/videos/play/wwdc2019/510/)
- Michael Tyson's widely cited list of audio mistakes leads with holding locks on the audio thread (`pthread_mutex_lock`, `@synchronized`) and discusses priority inversion and memory allocation. — [A Tasty Pixel / AudioKit Pro: "Four common mistakes in audio development"](https://audiokitpro.com/?p=25649)
- Swift Forums "Realtime threads with Swift": community consensus is that Swift's implicit allocation and ARC make guaranteed RT safety hard. People report pops from Swift allocations on audio threads, and verify generated code (e.g., in Godbolt) for runtime calls. — [Swift Forums thread](https://forums.swift.org/t/realtime-threads-with-swift/40562)
- Shared state between the control thread and an AVAudioSourceNode closure is a recurring problem; actors are not RT-safe for this. — [Swift Forums: Combining Actors and AVAudioSourceNode](https://forums.swift.org/t/combining-actors-and-avaudiosourcenode/49577)
- Apple Dev Forums: memory management guidance for real-time audio components. — [thread 106375](https://developer.apple.com/forums/thread/106375)
- **Clacky** pre-decodes all sounds into `AVAudioPCMBuffer`s at load and converts them to one canonical format so graph and buffers always agree. It only calls `scheduleBuffer(.interrupts)` at trigger time, on a `userInteractive` serial queue, never on the render thread. It deliberately leaves `AVAudioUnitVarispeed` out of the chain and applies only gain jitter. — [Clacky AudioEngine.swift](https://github.com/jasonzh0/Clacky/blob/main/Clacky/Core/AudioEngine.swift)
- **Thock** preloads sounds into `PCMSound` objects and mixes "ActiveSound" voices with pitch variation, gains and optional spatial rendering into AudioQueue buffers. It guards voices with `NSLock`s (`activeSoundsLock`, `volumeLock`, `queueStateLock`) and uses Accelerate. — [Thock SoundManager.swift](https://github.com/kamillobinski/thock/blob/main/Thock/Managers/SoundManager.swift)

### Inferences
- **For Whirr:**
  - **Pre-render.** At startup, or lazily on a utility queue, synthesize a bank of variations: e.g., 32–64 seek clicks of varied pitch, decay and noise seed, and several chatter and grind loops or fragments. Store them as `UnsafeMutableBufferPointer<Float>` or `ContiguousArray<Float>` held in a never-mutated, retained container. A few hundred ms of mono 48 kHz Float32 is about 100 KB per second of audio, so a large bank costs a few MB at most.
  - **Live parameters only.** In the callback, do sample playback plus cheap per-voice gain, pan and, optionally, linear-interp pitch. Don't run live noise filters or modal synthesis in the callback unless it is written in C/C++ or carefully audited Swift with `@inline(__always)` and no class references. Optional Swift 6 performance annotations exist but are underscored/experimental.
  - **Triggers.** The event thread writes `(soundID, gain, pan, rate)` into a preallocated lock-free SPSC ring (e.g., swift-atomics or a C ring buffer). The callback drains it into a fixed-size voice array, e.g., 16–32 voices with voice stealing.
- If using AVAudioPlayerNode instead, all the RT-safety burden sits inside Apple's code. Your code only calls `scheduleBuffer` from a normal thread, which is the main appeal for a Swift-only codebase. The downsides are less control over per-voice DSP and more AVFoundation graph edge cases on device change.
- A middle ground with less risk is AudioQueue with app-side mixing, as in Thock. Its callback isn't on the hard RT IO thread, so occasional locks are tolerated, at the cost of AudioQueue's less precise timing.

### Gaps
- No official Apple statement on which Swift constructs are RT-safe. Apple's guidance is generic: no alloc, locks or dispatch.
- I couldn't confirm the current status of Swift's `@_noLocks`/`@_noAllocation` performance annotations or of RealtimeSanitizer support for Swift in Xcode 26.

---

## Q6. CLI process restrictions, permissions, system volume, mute, Focus, alert device

### Takeaway
I found no evidence that audio output needs TCC permission. Microphone input does, and Thock's permission prompt is for key monitoring, not playback. A plain CLI or LaunchAgent binary can use AVAudioEngine, AUHAL or AudioQueue. Output follows the system volume and mute of the device it plays on. AudioServicesPlayAlertSound alone honors the separate alert volume. Focus modes don't mute arbitrary app audio. For "sound effects" semantics, Rogue Amoeba argues apps should play SFX on the user's chosen Sound Effects device, `kAudioHardwarePropertyDefaultSystemOutputDevice`. For Whirr, the ambient HDD soundscape is arguably content rather than UI alerts, so offer both: default to the main output, with an option to follow the alert device.

### Cited Findings
- `kAudioHardwarePropertyDefaultSystemOutputDevice` is the device chosen in System Settings > Sound > "Play sound effects through" (older wording "Play alerts and sound effects through"). Rogue Amoeba (2013): "many applications do not currently play their sound effects properly, ignoring the user's Sound Effects output selection." — [Rogue Amoeba: Playing Sound Effects the Right Way](https://weblog.rogueamoeba.com/2013/09/12/playing-sound-effects-the-right-way/); [coreaudio-api list 2007](https://lists.apple.com/archives/coreaudio-api/2007/Jun/msg00022.html); [coreaudio-api list 2012](https://lists.apple.com/archives/coreaudio-api/2012/Sep/msg00029.html)
- `AudioServicesPlayAlertSound` plays on the alert device "and honor[s] the user's alert volume setting". NSSound routed to the alert device plays on the right device but does not respect alert volume. — [Rogue Amoeba](https://weblog.rogueamoeba.com/2013/09/12/playing-sound-effects-the-right-way/); [Michael Tsai summary, incl. SpamSieve dev note](https://mjtsai.com/blog/2013/09/13/playing-sound-effects-the-right-way/)
- System sound playback goes to the Default System Output Device. AudioServicesPlaySystemSound plays at the current system audio volume with no programmatic volume control. — [Apple TN2102](https://developer.apple.com/library/archive/technotes/tn2102/_index.html); [Apple Audio Services docs](https://developer.apple.com/documentation/audiotoolbox/audio-services.md)
- Thock asks for Accessibility permission for its key monitoring, not for audio. Klakk describes using CoreAudio for playback and CoreGraphics for keyboard monitoring. — [deepwiki: Thock](https://deepwiki.com/kamillobinski/thock); [Klakk App Store listing](https://apps.apple.com/us/app/klakk-keyboard-sounds/id6754638652?l=pt-BR)
- Thock also polls music apps via `osascript` every 3 s to auto-mute while music plays. This is a UX pattern worth noting, though it costs subprocess spawns and needs Automation permission. — [Thock AudioMonitor.swift](https://github.com/kamillobinski/thock/blob/main/Thock/Services/AudioMonitor.swift)

### Inferences
- **No TCC for output.** This is based on the absence of any TCC category for audio playback and on all surveyed apps prompting only for input or monitoring. A non-bundled CLI can play audio, but without a bundle it has no Info.plist (no `AudioHardwarePowerHint` key, no Energy Impact display name) and shows up as a bare process name in `pmset -g assertions` and Activity Monitor. Shipping it as a minimal .app or LaunchAgent with a bundle ID gives nicer attribution.
- **Volume and mute.** Output through AUHAL or AVAudioEngine is scaled by the device's master volume and silenced by mute automatically. No extra handling is needed. Provide an in-app gain for relative level.
- **Alert device option.** To use it, resolve `kAudioHardwarePropertyDefaultSystemOutputDevice` and set `kAudioOutputUnitProperty_CurrentDevice` or `kAudioQueueProperty_CurrentDevice`. Listen for changes on that selector. The user's alert volume is not applied automatically with this route; only AudioServicesPlayAlertSound applies it. Because AudioServices can't do low-latency, procedural, high-rate playback, that trade-off is acceptable.
- **Focus.** I found no evidence that Focus or Do Not Disturb mutes app audio streams; it filters notifications. Whirr could optionally observe Focus or screen-lock state itself.

### Gaps
- No Apple primary source explicitly states "audio output requires no TCC permission". This is inferred.
- Unverified on macOS 26: whether "Play sound effects through" still maps exactly to `kAudioHardwarePropertyDefaultSystemOutputDevice` (very likely, but uncited for 26), and whether Focus has any audio-muting interaction.
- Unverified whether a LaunchAgent running before user login, or in a background session, can open the user's output device. Sessions without a GUI login may lack access to coreaudiod's per-user devices.

---

## Q7. How existing keyboard-sound apps implement playback on macOS

### Takeaway
Native Swift apps converge on a persistent engine with pre-decoded PCM and voice pooling. Thock uses AudioQueue with its own mixer, a 256-frame buffer, a 10 s idle stop, HAL device listeners and per-device selection. Clacky uses AVAudioEngine with 16 always-running AVAudioPlayerNodes and `scheduleBuffer(.interrupts)`. Klack is closed source; its changelogs only say latency and resource usage were repeatedly reduced. Mechvibes is Electron, using Web Audio via Howler-style playback, which is heavy for this use case.

### Cited Findings
- **Thock** (Swift, menu bar, ~1,037 stars, last push 2026-11-04):
  - Uses AudioToolbox `AudioQueueNewOutput` with 3 buffers and a configurable 256-frame default.
  - Mixes preloaded PCM voices itself, with pitch variation, gain, soft clipping and spatial audio.
  - Stops the queue after an idle timeout (10 s default) and restarts on demand.
  - Listens to `kAudioHardwarePropertyDefaultOutputDevice` and `kAudioHardwarePropertyDevices` and re-creates the queue on device change.
  - Claims sub-10 ms latency.
  — [GitHub kamillobinski/thock](https://github.com/kamillobinski/thock); [SoundManager.swift](https://github.com/kamillobinski/thock/blob/main/Thock/Managers/SoundManager.swift); [AudioDeviceManager.swift](https://github.com/kamillobinski/thock/blob/main/Thock/Managers/AudioDeviceManager.swift); [deepwiki](https://deepwiki.com/kamillobinski/thock)
- **Clacky** (Swift, menu bar):
  - One `AVAudioEngine` with a fixed pool of 16 `AVAudioPlayerNode`s that are started once and "stay running".
  - `play()` only calls `scheduleBuffer(..., options: [.interrupts])` on a round-robin voice via a `userInteractive` serial queue; there is no per-trigger `stop()`/`play()`, which "would otherwise force a stop/restart cycle".
  - Buffers are decoded and converted to one canonical Float32 format.
  - `AVAudioUnitVarispeed` pitch jitter was intentionally removed from the chain.
  - CGEventTap for key events. Loads Mechvibes packs, including .ogg.
  — [GitHub jasonzh0/Clacky](https://github.com/jasonzh0/Clacky); [AudioEngine.swift](https://github.com/jasonzh0/Clacky/blob/main/Clacky/Core/AudioEngine.swift)
- **Klack** (closed source, App Store): release notes repeatedly cite "decreased latency even further" and, in a 2024 update, "reduced latency immensely". There are no technical details. — [Klack on the App Store](https://apps.apple.com/us/app/klack/id6446206067); [9to5Mac on Klack](https://9to5mac.com/2023/04/05/klack-app-mechanical-keyboard-sound-effects-for-mac/)
- **Klakk:** "utilizes CoreAudio for professional-grade audio playback and CoreGraphics for efficient keyboard monitoring". — [Klakk App Store listing](https://apps.apple.com/us/app/klakk-keyboard-sounds/id6754638652?l=pt-BR)
- **Mechvibes** is an Electron app; its Homebrew cask is an Intel build that needs Rosetta on Apple Silicon. Rustyvibes and clickclack are Rust CLI alternatives. — [Homebrew mechvibes cask](https://formulae.brew.sh/cask/mechvibes); [rustyvibes docs.rs](https://docs.rs/rustyvibes/); [clickclack crate](https://lib.rs/crates/clickclack)

### Inferences
- Thock is the closest analogue to Whirr's needs (a background process, frequent short sounds, battery awareness). Its design choices are a validated template: AudioQueue or a callback-based mixer, about 256 frames, idle stop at about 10 s, HAL device listeners, device pinning by UID.
- Clacky's always-on AVAudioEngine is simpler but would leave a permanent running output and sleep assertion. Fine for an app used only while typing; less suitable for an always-resident daemon unless an idle pause is added.
- A plausible Whirr architecture, combining both:
  - AUHAL (`kAudioUnitSubType_HALOutput`, or `DefaultOutput` when following the default device) with a C or audited-Swift render callback mixing pre-rendered variation buffers from a lock-free trigger ring.
  - 256-frame buffer, set via `kAudioDevicePropertyBufferFrameSize`.
  - Lazy start; stop after about 10 s of silence while keeping the AU instantiated.
  - HAL listeners for the default or alert device and for the device list.
  - Optional "mute on Bluetooth" setting.
  - AVAudioEngine plus AVAudioSourceNode is an equivalent, slightly higher-level option. Use `engine.pause()` for the idle stop and also handle `AVAudioEngineConfigurationChange`.

### Gaps
- Klack's internals are unknown (closed source).
- The kbsound / "Kbsound" app named in the brief was not located in searches.
- No published latency or energy benchmarks comparing these apps.

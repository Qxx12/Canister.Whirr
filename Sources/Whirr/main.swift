import Foundation

let usage = """
whirr \(Whirr.version): the sound of a mechanical hard drive, driven by your Mac's real disk activity.

Usage: whirr <command>

  start              Start Whirr now and at every login
  stop               Stop Whirr and remove it from login
  restart            Restart the running agent
  status             Show whether Whirr is running and its settings

  mute | unmute      Silence or resume sounds (polling stops while muted)
  toggle             Switch between muted and unmuted
  volume [0-100]     Show or set the volume (default \(Int((Config().volume * 100).rounded())))
  sensitivity [x]    Show or set how eagerly activity makes sound (0.25-4, default 1)
  haptics [on|off|n] Show or set a trackpad hum that follows the seeks;
                     n sets its strength (75-150%, default 85) and turns it on

  demo               Play a few sample sounds and exit
  monitor            Print live disk activity levels without playing sound
  run [--verbose]    Run in the foreground (what the login agent runs)
  version            Print the version
"""

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("whirr: \(message)\n".utf8))
    exit(1)
}

func refuseRoot() {
    if getuid() == 0 {
        fail("run this as your normal user, not with sudo. Whirr is a per-user agent.")
    }
}

func updateConfig(_ change: (inout Config) -> Void) -> Config {
    var config = Config.load()
    change(&config)
    do { try config.save() } catch { fail("could not save settings: \(error.localizedDescription)") }
    return config
}

// MARK: - Commands

func start() {
    refuseRoot()
    if ProcessInfo.processInfo.environment["SSH_CONNECTION"] != nil {
        print("Note: you're connected over SSH. Whirr plays sound in the logged-in desktop session.")
    }
    let binary = LaunchAgent.binaryPath()
    let changed: Bool
    do { changed = try LaunchAgent.writePlist(binary: binary) } catch {
        fail("could not write \(Paths.launchAgent.path): \(error.localizedDescription)")
    }

    if LaunchAgent.isLoaded {
        if changed {
            // Reload so launchd picks up the new plist. Wait until the old job
            // is really gone: bootstrapping too early fails with error 5.
            LaunchAgent.bootoutAndWait()
        } else {
            LaunchAgent.kickstart(restart: false)
            report()
            return
        }
    }
    LaunchAgent.enable()
    var (status, output) = LaunchAgent.bootstrap()
    // launchd can still be finishing a previous unload; retry briefly.
    for _ in 0..<4 where status != 0 && LaunchAgent.loginItemStatus != .requiresApproval && !LaunchAgent.isLoaded {
        Thread.sleep(forTimeInterval: 0.5)
        (status, output) = LaunchAgent.bootstrap()
    }
    if status != 0 && !LaunchAgent.isLoaded {
        if LaunchAgent.loginItemStatus == .requiresApproval {
            fail("""
            macOS is blocking Whirr from running in the background.
            Turn it on in System Settings > General > Login Items & Extensions, then run `whirr start` again.
            """)
        }
        fail("launchctl bootstrap failed (\(status)): \(output.trimmingCharacters(in: .whitespacesAndNewlines))")
    }
    // Give launchd a moment to spawn the process before reporting.
    Thread.sleep(forTimeInterval: 0.3)
    report()
}

func stop() {
    refuseRoot()
    let wasInstalled = FileManager.default.fileExists(atPath: Paths.launchAgent.path)
    let wasLoaded = LaunchAgent.isLoaded
    if wasLoaded { LaunchAgent.bootoutAndWait() }
    LaunchAgent.removePlist()
    print(wasInstalled || wasLoaded ? "Whirr stopped and removed from login." : "Whirr isn't running.")
}

func restart() {
    refuseRoot()
    if LaunchAgent.isLoaded {
        LaunchAgent.kickstart(restart: true)
        Thread.sleep(forTimeInterval: 0.3)
        report()
    } else {
        start()
    }
}

func report() {
    let config = Config.load()
    let state = LaunchAgent.state
    switch state {
    case .loaded(let pid?):
        if let holder = InstanceLock.holder, holder != pid_t(pid) {
            print("""
            Whirr's login agent (pid \(pid)) is waiting: another copy (pid \(holder)) is playing,
            probably a `whirr run` in a terminal. The agent takes over when it exits.
            """)
        } else {
            print("Whirr is running (pid \(pid)).")
        }
    case .loaded(nil):
        print("Whirr is installed but not running. See \(Paths.log.path).")
    case .installedNotLoaded, .notInstalled:
        if let holder = InstanceLock.holder {
            // Not managed by launchd, but a copy is playing: a manual `whirr run`.
            print("""
            Whirr is running in the foreground (pid \(holder)), probably a `whirr run` in a terminal.
            It isn't running as a login agent; `whirr start` sets that up.
            """)
        } else if case .notInstalled = state {
            print("Whirr is not running. Run `whirr start`.")
        } else if LaunchAgent.isDisabled || LaunchAgent.loginItemStatus == .requiresApproval {
            print("""
            Whirr is installed but switched off.
            Turn it on in System Settings > General > Login Items & Extensions, then run `whirr start`.
            """)
        } else {
            print("Whirr is installed but not loaded. Run `whirr start`.")
        }
    }
    print("Volume \(Int((config.volume * 100).rounded()))%, sensitivity \(config.sensitivity)\(config.muted ? ", muted" : "")")
    print("Output: \(AudioOutput.describeDefaultOutput())")
    print("Haptics: \(config.hapticsSummary) (\(Haptics.describeTrackpads()))")
}

func demo() {
    let queue = DispatchQueue(label: "whirr.demo", qos: .userInteractive)
    let bank = SoundBank()
    let config = Config.load()
    let audio = AudioOutput(queue: queue, format: bank.format) { _ in }
    audio.volume = Float(config.volume)
    let haptics = Haptics(queue: queue) { _ in }
    haptics.enabled = config.haptics
    haptics.strength = config.hapticStrength
    print("Playing on \(AudioOutput.describeDefaultOutput())…")
    if config.haptics {
        print("Haptics on: rest a finger on the trackpad (\(Haptics.describeTrackpads())).")
    }

    // Single seeks from track-to-track to full stroke, then a burst of busy I/O.
    var schedule: [(TimeInterval, Double, Float)] = []
    var time = 0.0
    for distance in [0.002, 0.04, 0.33, 1.0] {
        for _ in 0..<2 {
            schedule.append((time, distance, Float(decibels(SoundBank.level(distance: distance)))))
            time += 0.4
        }
        time += 0.2
    }
    var sonifier = Sonifier()
    let busy = DiskCounters(readOps: 150, writeOps: 50, readBytes: 4_000_000, writeBytes: 1_000_000)
    for _ in 0..<60 {
        for event in sonifier.update(delta: busy, dt: Daemon.pollInterval) {
            schedule.append((time + event.delay, event.distance, event.gain))
        }
        time += Daemon.pollInterval
    }
    // Play from one strict timer: separate asyncAfter calls seconds ahead may
    // be coalesced by the system and fire in clumps, which bunched the busy
    // burst into a few chords.
    schedule.sort { $0.0 < $1.0 }
    let start = mach_absolute_time()
    let end = time + 0.5
    var next = 0
    let timer = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
    timer.schedule(deadline: .now(), repeating: .milliseconds(2), leeway: .milliseconds(1))
    timer.setEventHandler {
        let elapsed = Double(mach_absolute_time() - start) / Double(AudioOutput.hostTicks(1))
        while next < schedule.count, schedule[next].0 <= elapsed {
            let (_, distance, gain) = schedule[next]
            audio.play(bank.buffer(distance: distance), gain: gain)
            haptics.play(gain: gain, delay: audio.outputLatency)
            next += 1
        }
        if elapsed >= end {
            audio.stop()
            exit(0)
        }
    }
    timer.resume()
    dispatchMain()
}

func showOrSet(_ arguments: ArraySlice<String>, name: String, get: (Config) -> String,
               set: (inout Config, Double) -> Bool) {
    guard let raw = arguments.first else {
        print("\(name.capitalized): \(get(Config.load()))")
        return
    }
    guard let value = Double(raw.trimmingCharacters(in: CharacterSet(charactersIn: "%"))) else {
        fail("\(name) must be a number")
    }
    var valid = true
    let config = updateConfig { valid = set(&$0, value) }
    guard valid else { fail("\(name) out of range") }
    print("\(name.capitalized): \(get(config))")
}

// MARK: - Dispatch

let arguments = CommandLine.arguments.dropFirst()
switch arguments.first {
case "start": start()
case "stop": stop()
case "restart": restart()
case "status": report()
case "mute":
    _ = updateConfig { $0.muted = true }
    print("Muted.")
case "unmute":
    _ = updateConfig { $0.muted = false }
    print("Unmuted.")
case "toggle":
    let config = updateConfig { $0.muted.toggle() }
    print(config.muted ? "Muted." : "Unmuted.")
case "volume":
    showOrSet(arguments.dropFirst(), name: "volume", get: { "\(Int(($0.volume * 100).rounded()))%" }) { config, value in
        guard (0...100).contains(value) else { return false }
        config.volume = value / 100
        return true
    }
case "sensitivity":
    showOrSet(arguments.dropFirst(), name: "sensitivity", get: { "\($0.sensitivity)" }) { config, value in
        guard (0.25...4).contains(value) else { return false }
        config.sensitivity = value
        return true
    }
case "haptics":
    let trackpads = Haptics.describeTrackpads()
    switch arguments.dropFirst().first {
    case nil:
        print("Haptics: \(Config.load().hapticsSummary) (\(trackpads))")
    case "on":
        let config = updateConfig { $0.haptics = true }
        print("Haptics: \(config.hapticsSummary) (\(trackpads)). Felt while a finger rests on the trackpad.")
    case "off":
        _ = updateConfig { $0.haptics = false }
        print("Haptics: off")
    case let raw?:
        guard let percent = Double(raw.trimmingCharacters(in: CharacterSet(charactersIn: "%"))) else {
            fail("haptics takes `on`, `off` or a strength from 75 to 150")
        }
        guard (75...150).contains(percent) else { fail("haptic strength must be 75-150 (below 75 it can't be felt)") }
        let config = updateConfig {
            $0.haptics = true
            $0.hapticStrength = percent / 100
        }
        print("Haptics: \(config.hapticsSummary) (\(trackpads))")
    }
case "demo": demo()
case "monitor":
    print("Watching disk activity (Ctrl-C to stop). The floor is the learned idle level.")
    Daemon(verbose: true, silent: true).run()
case "run":
    refuseRoot()
    // The login agent waits for a foreground `whirr run` to finish instead
    // of exiting: a clean exit would never be restarted by launchd
    // (KeepAlive only restarts after a failure). A manual run just leaves.
    if InstanceLock.isLoginAgent {
        if !InstanceLock.acquire(wait: false) {
            let who = InstanceLock.holder.map { " (pid \($0))" } ?? ""
            InstanceLock.log("waiting for another Whirr\(who) to exit, probably a `whirr run` in a terminal")
            _ = InstanceLock.acquire(wait: true)
            InstanceLock.log("the other Whirr exited; taking over")
        }
    } else if !InstanceLock.acquire(wait: false) {
        let who = InstanceLock.holder.map { " (pid \($0))" } ?? ""
        print("Another Whirr is already running\(who).")
        exit(0)
    }
    Daemon(verbose: arguments.contains("--verbose"), silent: false).run()
case "version", "--version", "-v":
    print("whirr \(Whirr.version)")
case nil, "help", "--help", "-h":
    print(usage)
default:
    print(usage)
    exit(1)
}

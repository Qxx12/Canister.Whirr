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
  volume [0-100]     Show or set the volume
  sensitivity [x]    Show or set how eagerly activity makes sound (0.25-4, default 1)

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
    switch LaunchAgent.state {
    case .loaded(let pid?):
        print("Whirr is running (pid \(pid)).")
    case .loaded(nil):
        print("Whirr is installed but not running. See \(Paths.log.path).")
    case .installedNotLoaded:
        if LaunchAgent.isDisabled || LaunchAgent.loginItemStatus == .requiresApproval {
            print("""
            Whirr is installed but switched off.
            Turn it on in System Settings > General > Login Items & Extensions, then run `whirr start`.
            """)
        } else {
            print("Whirr is installed but not loaded. Run `whirr start`.")
        }
    case .notInstalled:
        print("Whirr is not running. Run `whirr start`.")
    }
    print("Volume \(Int((config.volume * 100).rounded()))%, sensitivity \(config.sensitivity)\(config.muted ? ", muted" : "")")
    print("Output: \(AudioOutput.describeDefaultOutput())")
}

func demo() {
    let queue = DispatchQueue(label: "whirr.demo", qos: .userInteractive)
    let bank = SoundBank()
    let config = Config.load()
    let audio = AudioOutput(queue: queue, format: bank.format) { _ in }
    audio.volume = Float(config.volume)
    print("Playing on \(AudioOutput.describeDefaultOutput())…")

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
    let start = DispatchTime.now()
    for (offset, distance, gain) in schedule {
        queue.asyncAfter(deadline: start + offset) { audio.play(bank.buffer(distance: distance), gain: gain) }
    }
    queue.asyncAfter(deadline: start + time + 0.5) {
        audio.stop()
        exit(0)
    }
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
case "demo": demo()
case "monitor":
    print("Watching disk activity (Ctrl-C to stop). The floor is the learned idle level.")
    Daemon(verbose: true, silent: true).run()
case "run":
    refuseRoot()
    guard InstanceLock.acquire() else {
        print("Another Whirr is already running.")
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

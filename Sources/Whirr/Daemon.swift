import Darwin
import notify
import Foundation

/// The long-running process: polls disk activity, turns it into seek sounds,
/// and follows config changes posted by the CLI.
final class Daemon {
    /// About 30 polls per second: frequent enough that a click lands within a
    /// few tens of milliseconds of the I/O, at well under 1% of one core.
    static let pollInterval: TimeInterval = 1.0 / 30

    private let queue = DispatchQueue(label: "whirr.daemon", qos: .userInteractive)
    private let verbose: Bool
    private let silent: Bool

    private var monitor: DiskMonitor!
    private var sonifier = Sonifier()
    private var bank: SoundBank!
    private var audio: AudioOutput!
    private var haptics: Haptics!
    private var config = Config()
    private var pollTimer: DispatchSourceTimer?
    private var lastTick: UInt64 = 0
    private var notifyToken: Int32 = 0
    private var signalSources: [DispatchSourceSignal] = []

    // Verbose reporting.
    private var reportElapsed: TimeInterval = 0
    private var reportPeak = 0.0
    private var reportClicks = 0

    /// - Parameters:
    ///   - verbose: print activity levels twice a second.
    ///   - silent: never play sound (for `whirr monitor`).
    init(verbose: Bool, silent: Bool) {
        self.verbose = verbose
        self.silent = silent
    }

    func run() -> Never {
        installSignalHandlers()
        queue.async { self.setUp() }
        dispatchMain()
    }

    private func setUp() {
        log("whirr \(Whirr.version) starting (pid \(getpid()))")
        bank = SoundBank()
        audio = AudioOutput(queue: queue, format: bank.format) { [weak self] in self?.log($0) }
        haptics = Haptics(queue: queue) { [weak self] in self?.log($0) }
        monitor = DiskMonitor(queue: queue)
        monitor.onDrivesChanged = { [weak self] added, removed in
            if let added { self?.log("disk: watching \(added)") }
            if let removed { self?.log("disk: \(removed) removed") }
        }
        monitor.start()

        notify_register_dispatch(Whirr.configChanged, &notifyToken, queue) { [weak self] _ in
            self?.applyConfig()
        }
        applyConfig()
    }

    private func applyConfig() {
        let new = Config.load()
        if new != config || pollTimer == nil {
            log("config: volume \(Int((new.volume * 100).rounded()))%, sensitivity \(new.sensitivity)"
                + "\(new.haptics ? ", haptics \(Int((new.hapticStrength * 100).rounded()))%" : "")\(new.muted ? ", muted" : "")")
        }
        config = new
        audio.volume = Float(config.volume)
        haptics.enabled = config.haptics && !silent
        haptics.strength = config.hapticStrength
        sonifier.sensitivity = config.sensitivity
        // `whirr monitor` (silent) keeps watching even when sound is muted.
        if config.muted && !silent {
            stopPolling()
            audio.stop()
            haptics.stop()
        } else {
            startPolling()
        }
    }

    // MARK: - Polling

    private func startPolling() {
        guard pollTimer == nil else { return }
        monitor.resetBaselines()
        _ = monitor.poll()
        sonifier.reset()
        lastTick = mach_absolute_time()

        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.setEventHandler { [weak self] in self?.tick() }
        timer.schedule(deadline: .now() + Self.pollInterval, repeating: Self.pollInterval, leeway: .milliseconds(3))
        timer.resume()
        pollTimer = timer
    }

    private func stopPolling() {
        pollTimer?.cancel()
        pollTimer = nil
    }

    private func tick() {
        let now = mach_absolute_time()
        let dt = Double(now - lastTick) / Double(AudioOutput.hostTicks(1))
        lastTick = now

        // A long gap means the Mac slept (timers don't fire during sleep).
        // Drop the counters that piled up so they don't play as one burst.
        if dt > 1 {
            monitor.resetBaselines()
            _ = monitor.poll()
            sonifier.reset()
            log("resumed after \(Int(dt)) s pause")
            return
        }

        let delta = monitor.poll()
        let events = sonifier.update(delta: delta, dt: dt)
        if !silent {
            for event in events {
                audio.play(bank.buffer(distance: event.distance), gain: event.gain, delay: event.delay)
                haptics.play(gain: event.gain, delay: event.delay + audio.outputLatency)
            }
        }
        if verbose { report(dt: dt, clicks: events.count) }
    }

    private func report(dt: TimeInterval, clicks: Int) {
        reportElapsed += dt
        reportPeak = max(reportPeak, sonifier.intensity)
        reportClicks += clicks
        guard reportElapsed >= 0.5 else { return }
        let s = sonifier
        let line = String(
            format: "ops/s %6.0f (floor %4.0f)   MB/s %7.2f (floor %5.2f)   intensity %.2f   sounds %d",
            s.opsRate, s.floorOps, s.bytesRate / 1_000_000, s.floorBytes / 1_000_000, reportPeak, reportClicks
        )
        print(line)
        reportElapsed = 0
        reportPeak = 0
        reportClicks = 0
    }

    // MARK: - Process

    private func installSignalHandlers() {
        for sig in [SIGTERM, SIGINT] {
            signal(sig, SIG_IGN)
            let source = DispatchSource.makeSignalSource(signal: sig, queue: queue)
            source.setEventHandler { [weak self] in
                self?.stopPolling()
                self?.audio?.stop()
                self?.log("stopping")
                exit(0)
            }
            source.resume()
            signalSources.append(source)
        }
    }

    private func log(_ message: String) {
        let stamp = Self.timestamp.string(from: Date())
        FileHandle.standardError.write(Data("\(stamp) \(message)\n".utf8))
    }

    private static let timestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}

/// Ensures only one copy of the agent plays at a time.
enum InstanceLock {
    private static var descriptor: Int32 = -1

    /// Takes the lock. With `wait`, blocks until another Whirr process
    /// releases it; otherwise returns false at once if it's held. The holder
    /// writes its PID into the lock file so others can say who's playing.
    static func acquire(wait: Bool) -> Bool {
        if descriptor < 0 {
            try? FileManager.default.createDirectory(at: Paths.support, withIntermediateDirectories: true)
            descriptor = open(Paths.lock.path, O_CREAT | O_RDWR, 0o644)
        }
        guard descriptor >= 0 else { return true }
        guard flock(descriptor, wait ? LOCK_EX : LOCK_EX | LOCK_NB) == 0 else { return false }
        let pid = Data("\(getpid())\n".utf8)
        ftruncate(descriptor, 0)
        _ = pid.withUnsafeBytes { pwrite(descriptor, $0.baseAddress, pid.count, 0) }
        return true
    }

    /// The PID of the Whirr process playing now, if any. The lock must
    /// actually be held: the file keeps the last holder's PID after it
    /// exits, and that number may since belong to an unrelated process.
    static var holder: pid_t? {
        guard isHeld,
              let text = try? String(contentsOf: Paths.lock, encoding: .utf8),
              let pid = pid_t(text.trimmingCharacters(in: .whitespacesAndNewlines)),
              pid > 0, kill(pid, 0) == 0 || errno == EPERM
        else { return nil }
        return pid
    }

    /// True if some process holds the lock right now. (Probes with a separate
    /// descriptor, so it's meant for other processes such as `whirr status`.)
    private static var isHeld: Bool {
        let fd = open(Paths.lock.path, O_RDONLY)
        guard fd >= 0 else { return false }
        defer { close(fd) }
        if flock(fd, LOCK_EX | LOCK_NB) == 0 {
            flock(fd, LOCK_UN)
            return false
        }
        return errno == EWOULDBLOCK
    }

    /// Writes a timestamped line to stderr (the agent's log), like Daemon.log.
    static func log(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        FileHandle.standardError.write(Data("\(formatter.string(from: Date())) \(message)\n".utf8))
    }

    /// True when launchd started this process as Whirr's login agent.
    static var isLoginAgent: Bool {
        ProcessInfo.processInfo.environment["XPC_SERVICE_NAME"] == Whirr.label
    }
}

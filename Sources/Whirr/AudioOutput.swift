import AVFoundation
import AudioToolbox
import CoreAudio
import Foundation

/// Low-latency playback of short pre-rendered buffers.
///
/// One AVAudioEngine feeds a fixed pool of player nodes that are connected
/// once and kept playing; a trigger only schedules a buffer on the next voice.
/// The engine starts on the first sound and pauses after `idleTimeout`
/// seconds of silence, because a running output keeps the CPU waking every
/// IO cycle and makes coreaudiod hold a sleep-preventing power assertion
/// (verified with `pmset -g assertions`: held while running, released on pause).
///
/// When the output device changes (AirPods connect, headphones plugged in)
/// the engine is rebuilt the next time a sound plays.
///
/// All methods must be called on the queue passed to `init`.
final class AudioOutput {
    private let queue: DispatchQueue
    private let format: AVAudioFormat
    private let voiceCount: Int
    private let idleTimeout: TimeInterval
    private let log: (String) -> Void

    private var engine: AVAudioEngine?
    private var players: [AVAudioPlayerNode] = []
    private var nextVoice = 0
    private var needsRebuild = true
    private var startedAt: UInt64 = 0
    private var builtAt: UInt64 = 0
    /// Bumped by `stop()`, so sounds deferred before a mute don't play after it.
    private var generation = 0
    private var configObserver: NSObjectProtocol?
    private var idleTimer: DispatchSourceTimer?
    private var deviceListener: AudioObjectPropertyListenerBlock?

    /// IO buffer size requested from the output device: 256 frames is about
    /// 5 ms at 48 kHz. Smaller buffers cost more CPU wake-ups; larger ones
    /// add delay.
    private let bufferFrames: UInt32 = 256

    var volume: Float = 0.2 {
        didSet { engine?.mainMixerNode.outputVolume = volume }
    }

    var isRunning: Bool { engine?.isRunning ?? false }

    init(queue: DispatchQueue, format: AVAudioFormat, voices: Int = 32, idleTimeout: TimeInterval = 3,
         log: @escaping (String) -> Void) {
        self.queue = queue
        self.format = format
        self.voiceCount = voices
        self.idleTimeout = idleTimeout
        self.log = log
        listenForDefaultDeviceChanges()
    }

    deinit {
        if let block = deviceListener {
            var address = Self.defaultOutputAddress
            AudioObjectRemovePropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &address, queue, block)
        }
        teardown()
    }

    /// Plays `buffer` on the next voice, `delay` seconds from now.
    func play(_ buffer: AVAudioPCMBuffer, gain: Float, delay: TimeInterval = 0) {
        guard ensureRunning() else { return }
        armIdleTimer()

        var when: AVAudioTime?
        if delay > 0.002 {
            // Right after a (re)start the nodes' clocks may not be valid yet, so
            // host-time scheduling is unreliable. Keep the timing anyway by
            // waiting on our own queue, then playing at once.
            let settled = mach_absolute_time() - startedAt > Self.hostTicks(0.05)
            guard settled else {
                let scheduledIn = generation
                queue.asyncAfter(deadline: .now() + delay) { [weak self] in
                    guard let self, self.generation == scheduledIn else { return }
                    self.play(buffer, gain: gain, delay: 0)
                }
                return
            }
            when = AVAudioTime(hostTime: mach_absolute_time() + Self.hostTicks(delay))
        }
        let player = players[nextVoice]
        nextVoice = (nextVoice + 1) % players.count
        player.volume = gain
        player.scheduleBuffer(buffer, at: when, options: .interrupts, completionHandler: nil)
    }

    /// Stops the engine now (used when muting).
    func stop() {
        generation += 1
        idleTimer?.cancel()
        idleTimer = nil
        if let engine, engine.isRunning {
            engine.stop()
            log("audio: stopped")
        }
    }

    // MARK: - Engine lifecycle

    private func ensureRunning() -> Bool {
        if needsRebuild {
            teardown()
            build()
        }
        guard let engine else { return false }
        if engine.isRunning { return true }

        applyBufferSize(engine)
        do {
            try engine.start()
        } catch {
            log("audio: engine failed to start: \(error.localizedDescription)")
            needsRebuild = true
            return false
        }
        // start() can succeed while the engine stops again straight away.
        guard engine.isRunning else {
            log("audio: engine stopped right after starting; will rebuild")
            needsRebuild = true
            return false
        }
        for player in players where !player.isPlaying { player.play() }
        startedAt = mach_absolute_time()
        return true
    }

    private func build() {
        let engine = AVAudioEngine()
        players = (0..<voiceCount).map { _ in AVAudioPlayerNode() }
        for player in players {
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
        }
        engine.mainMixerNode.outputVolume = volume
        engine.prepare()

        configObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange, object: engine, queue: nil
        ) { [weak self, weak engine] _ in
            self?.queue.async {
                guard let self, let engine, engine === self.engine else { return }
                // A device switch rebuilds the engine straight away (see the
                // HAL listener); the new engine often reports a configuration
                // change while it settles. Rebuilding again would cut off
                // sounds for nothing: if the engine did stop, ensureRunning()
                // restarts it, and rebuilds only if that fails.
                guard mach_absolute_time() - self.builtAt > Self.hostTicks(0.5) else { return }
                self.log("audio: output configuration changed; will rebuild")
                self.needsRebuild = true
            }
        }
        self.engine = engine
        builtAt = mach_absolute_time()
        needsRebuild = false
        nextVoice = 0
        log("audio: engine ready on \(Self.describeDefaultOutput())")
    }

    private func teardown() {
        if let observer = configObserver {
            NotificationCenter.default.removeObserver(observer)
            configObserver = nil
        }
        if let engine {
            engine.stop()
            for player in players { engine.detach(player) }
        }
        players = []
        engine = nil
    }

    private func armIdleTimer() {
        if idleTimer == nil {
            let timer = DispatchSource.makeTimerSource(queue: queue)
            timer.setEventHandler { [weak self] in self?.idle() }
            timer.schedule(deadline: .now() + idleTimeout, leeway: .milliseconds(300))
            timer.resume()
            idleTimer = timer
        } else {
            idleTimer?.schedule(deadline: .now() + idleTimeout, leeway: .milliseconds(300))
        }
    }

    private func idle() {
        idleTimer?.cancel()
        idleTimer = nil
        // pause() releases coreaudiod's sleep assertion just like stop(), but
        // keeps the engine prepared, so the next start() is faster (measured
        // on macOS 27.2: ~6-9 ms after pause vs ~7-16 ms after stop).
        if let engine, engine.isRunning {
            // Not logged: this happens every few seconds in normal use and
            // would grow the agent's log without bound.
            engine.pause()
        }
    }

    private func applyBufferSize(_ engine: AVAudioEngine) {
        guard let unit = engine.outputNode.audioUnit else { return }
        var frames = bufferFrames
        let status = AudioUnitSetProperty(
            unit, kAudioDevicePropertyBufferFrameSize, kAudioUnitScope_Global, 0,
            &frames, UInt32(MemoryLayout<UInt32>.size)
        )
        if status != noErr { log("audio: could not set buffer size (\(status))") }
    }

    // MARK: - Output device

    private static var defaultOutputAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )

    private func listenForDefaultDeviceChanges() {
        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            guard let self else { return }
            self.log("audio: default output changed to \(Self.describeDefaultOutput())")
            self.needsRebuild = true
            // Rebuild now if sound is playing, so the next click isn't lost.
            if self.isRunning { _ = self.ensureRunning() }
        }
        var address = Self.defaultOutputAddress
        let status = AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &address, queue, block)
        if status == noErr { deviceListener = block }
    }

    static func describeDefaultOutput() -> String {
        var device = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = defaultOutputAddress
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &device) == noErr
        else { return "unknown output" }

        var name: Unmanaged<CFString>?
        size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        address.mSelector = kAudioObjectPropertyName
        let nameStatus = AudioObjectGetPropertyData(device, &address, 0, nil, &size, &name)
        let label = nameStatus == noErr ? (name?.takeRetainedValue() as String? ?? "output") : "output"

        var transport: UInt32 = 0
        size = UInt32(MemoryLayout<UInt32>.size)
        address.mSelector = kAudioDevicePropertyTransportType
        AudioObjectGetPropertyData(device, &address, 0, nil, &size, &transport)
        let bluetooth = transport == kAudioDeviceTransportTypeBluetooth || transport == kAudioDeviceTransportTypeBluetoothLE
        return bluetooth ? "\(label) (Bluetooth: expect ~150–250 ms extra delay)" : label
    }

    // MARK: - Time

    private static let timebase: mach_timebase_info_data_t = {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        return info
    }()

    static func hostTicks(_ seconds: TimeInterval) -> UInt64 {
        UInt64(seconds * 1_000_000_000 * Double(timebase.denom) / Double(timebase.numer))
    }
}

import Darwin
import Foundation
import IOKit

/// A low hum on the Force Touch trackpad that follows the drive's seeks,
/// so the trackpad feels like a drive vibrating while it works.
///
/// AppKit's NSHapticFeedbackManager is meant for feedback inside a
/// foreground app's own UI. Whirr has no UI, so it drives the trackpad's
/// actuator directly through the private MultitouchSupport framework (as
/// tools like HapticKey do). The framework is opened with dlopen: if a future
/// macOS drops or changes it, haptics turn into a no-op and sound carries on.
///
/// Each seek that plays starts a short burst of a 60 Hz sine, defined in the
/// same format as the driver's built-in actuations (read with
/// MTActuatorGetProductionPlist). Bursts are at least as far apart as they
/// are long, so a busy disk runs them together into a continuous hum and a
/// lone seek is one soft thrum. Longer seeks hum a little stronger, as they
/// sound louder.
///
/// Why this shape, from trying alternatives on a MacBook Pro trackpad: any
/// single pulse (the built-in 6 ms knocks, or a wide 40 ms bump) feels like
/// the trackpad clicking rather than a disk vibrating; the built-in firm
/// modes and 120 Hz sines are audible; a 60 Hz sine is felt but not heard,
/// and only from an amplitude of about 0.2.
///
/// Every trackpad that supports actuation is used (a MacBook's built-in one
/// and a Magic Trackpad), so the hum lands under whichever one the user is
/// touching. You only feel it while a finger rests on the trackpad.
///
/// All methods must be called on the queue passed to `init`.
final class Haptics {
    private let queue: DispatchQueue
    private let log: (String) -> Void

    /// One burst of hum: a sine at this frequency, this long, at this
    /// amplitude (driver units) for an average seek at strength 1.
    private let humKHz = 0.06
    private let burstMS = 35.0
    private let humAmplitude = 0.2
    /// The quietest and loudest seeks hum at these fractions of
    /// `humAmplitude`. The range is narrow because much below 0.15 the hum
    /// can't be felt at all.
    private let quietScale = 0.8
    private let loudScale = 1.2
    /// Closest two bursts may start: one burst length, so back-to-back
    /// bursts join up without overlapping (the trackpad refuses overlaps).
    private var minimumGap: TimeInterval { burstMS / 1000 }
    /// How often to look for trackpads again when none is open (e.g. a Magic
    /// Trackpad connecting later).
    private let rescanInterval: TimeInterval = 10

    private var actuators: [CFTypeRef] = []
    /// Bursts built so far, by amplitude in hundredths.
    private var bursts: [Int: CFTypeRef] = [:]
    /// Failed actuations in a row; a busy trackpad can refuse one now and then.
    private var failures = 0
    private var lastScan: UInt64 = 0
    private var scanned = false
    private var lastBurst: UInt64 = 0
    /// Bursts waiting for their sound to be heard: (host time, amplitude),
    /// fired by one strict timer. A plain asyncAfter may be coalesced with
    /// other timers and fire late in clumps, which would bunch bursts up and
    /// drop most of them under `minimumGap`.
    private var pending: [(at: UInt64, amplitude: Double)] = []
    private var timer: DispatchSourceTimer?

    var enabled = false {
        didSet { if !enabled { stop() } }
    }

    /// Scales `humAmplitude`; see `Config.hapticStrength` for the range and default.
    var strength = 1.0 {
        didSet { if strength != oldValue { bursts = [:] } }
    }

    init(queue: DispatchQueue, log: @escaping (String) -> Void) {
        self.queue = queue
        self.log = log
    }

    deinit {
        timer?.cancel()
        closeAll()
    }

    /// Hums along with a seek of `gain` (linear) that will be heard `delay` seconds from now.
    func play(gain: Float, delay: TimeInterval = 0) {
        guard enabled, gain > 0 else { return }
        // SoundBank.level runs from -16 dB (track switch) to 0 dB (full stroke).
        let level = 20 * log10(Double(gain))
        let loudness = min(max((level + 16) / 16, 0), 1)
        let amplitude = humAmplitude * strength * (quietScale + (loudScale - quietScale) * loudness)

        guard delay > 0.002 else { burst(amplitude); return }
        let at = mach_absolute_time() + AudioOutput.hostTicks(delay)
        let index = pending.firstIndex { $0.at > at } ?? pending.endIndex
        pending.insert((at, amplitude), at: index)
        if index == 0 { armTimer() }
    }

    /// Drops pending bursts (used when muting or turning haptics off).
    func stop() {
        pending.removeAll()
        timer?.cancel()
        timer = nil
    }

    private func armTimer() {
        timer?.cancel()
        guard let next = pending.first else { timer = nil; return }
        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
        timer.setEventHandler { [weak self] in self?.firePending() }
        let now = mach_absolute_time()
        let wait = next.at > now ? Double(next.at - now) / Double(AudioOutput.hostTicks(1)) : 0
        timer.schedule(deadline: .now() + wait, leeway: .milliseconds(1))
        timer.resume()
        self.timer = timer
    }

    private func firePending() {
        let now = mach_absolute_time()
        while let first = pending.first, first.at <= now + AudioOutput.hostTicks(0.001) {
            pending.removeFirst()
            if enabled { burst(first.amplitude) }
        }
        armTimer()
    }

    /// A description of the trackpads haptics would use, for `whirr status`.
    static func describeTrackpads() -> String {
        guard Library.shared != nil else { return "not supported on this macOS" }
        let devices = Self.actuationDevices()
        if devices.isEmpty { return "no Force Touch trackpad found" }
        return devices.map(\.name).joined(separator: ", ")
    }

    // MARK: - Actuation

    private func burst(_ amplitude: Double) {
        let now = mach_absolute_time()
        guard now - lastBurst >= AudioOutput.hostTicks(minimumGap) else { return }
        guard let library = Library.shared else { return }
        openIfNeeded(library, now: now)
        guard !actuators.isEmpty, let actuation = hum(library, amplitude: amplitude) else { return }
        lastBurst = now

        var failed = false
        for actuator in actuators {
            // Flags 0: no Light/Medium/Firm preset, so the burst plays as
            // defined, unscaled.
            if library.actuate(actuation, actuator, 0, 1, 1) != 0 { failed = true }
        }
        failures = failed ? failures + 1 : 0
        if failures >= 3 {
            // The trackpad went away (Magic Trackpad disconnected) or the
            // handle went stale over sleep: look again next time.
            log("haptics: trackpad stopped responding; will look again")
            failures = 0
            closeAll()
        }
    }

    /// A burst of hum at `amplitude`, built once per hundredth and reused.
    private func hum(_ library: Library, amplitude: Double) -> CFTypeRef? {
        let key = Int((amplitude * 100).rounded())
        if let cached = bursts[key] { return cached }
        let unity: [String: Double] = ["Light": 1, "Medium": 1, "Firm": 1]
        let definition: [String: Any] = [
            "BaseWaveform": ["Type": "Gaussian", "DurationMS": 6.0, "Amplitude": 0.0],
            "Tones": [[
                "Type": "Sine", "FrequencykHz": humKHz, "Amplitude": Double(key) / 100,
                "DurationMS": burstMS, "DelayMS": 0.0,
            ]],
            "BaseMultipliers": unity,
            "ToneMultipliers": unity,
        ]
        guard let actuation = library.makeActuation(definition as CFDictionary, 0)?.takeRetainedValue() else {
            log("haptics: the trackpad driver rejected the hum")
            return nil
        }
        bursts[key] = actuation
        return actuation
    }

    private func openIfNeeded(_ library: Library, now: UInt64) {
        guard actuators.isEmpty else { return }
        guard !scanned || now - lastScan >= AudioOutput.hostTicks(rescanInterval) else { return }
        let wasScanned = scanned
        scanned = true
        lastScan = now

        var names: [String] = []
        for device in Self.actuationDevices() {
            guard let actuator = library.create(device.id)?.takeRetainedValue() else { continue }
            guard library.open(actuator) == 0 else { continue }
            actuators.append(actuator)
            names.append(device.name)
        }
        if !names.isEmpty {
            log("haptics: using \(names.joined(separator: ", "))")
        } else if !wasScanned {
            log("haptics: no Force Touch trackpad found")
        }
    }

    private func closeAll() {
        if let library = Library.shared {
            for actuator in actuators { _ = library.close(actuator) }
        }
        actuators = []
    }

    // MARK: - Devices

    private struct Device {
        var id: UInt64
        var name: String
    }

    /// Multitouch devices whose IORegistry entry says they can actuate.
    private static func actuationDevices() -> [Device] {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("AppleMultitouchDevice"), &iterator)
            == KERN_SUCCESS else { return [] }
        defer { IOObjectRelease(iterator) }

        func property(_ service: io_object_t, _ key: String) -> Any? {
            IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
        }
        var devices: [Device] = []
        while case let service = IOIteratorNext(iterator), service != 0 {
            defer { IOObjectRelease(service) }
            guard property(service, "ActuationSupported") as? Bool == true,
                  let id = property(service, "Multitouch ID") as? NSNumber
            else { continue }
            let product = property(service, "Product") as? String ?? "trackpad"
            let name = product.contains("Internal") ? "built-in trackpad" : product
            devices.append(Device(id: id.uint64Value, name: name))
        }
        return devices
    }

    /// The MultitouchSupport functions Whirr uses, loaded at runtime. The
    /// signatures were read from the framework's disassembly (macOS 27).
    private struct Library {
        typealias Create = @convention(c) (UInt64) -> Unmanaged<CFTypeRef>?
        typealias Open = @convention(c) (CFTypeRef) -> Int32
        typealias Close = @convention(c) (CFTypeRef) -> Int32
        /// (definition, id) -> actuation
        typealias MakeActuation = @convention(c) (CFDictionary, UInt64) -> Unmanaged<CFTypeRef>?
        /// (actuation, actuator, preset flags, bump scale, tone scale) -> IOReturn
        typealias Actuate = @convention(c) (CFTypeRef, CFTypeRef, UInt32, Float, Float) -> Int32

        let create: Create
        let open: Open
        let close: Close
        let makeActuation: MakeActuation
        let actuate: Actuate

        static let shared: Library? = {
            let path = "/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport"
            guard let handle = dlopen(path, RTLD_NOW),
                  let create = dlsym(handle, "MTActuatorCreateFromDeviceID"),
                  let open = dlsym(handle, "MTActuatorOpen"),
                  let close = dlsym(handle, "MTActuatorClose"),
                  let makeActuation = dlsym(handle, "MTActuationCreateFromDictionary"),
                  let actuate = dlsym(handle, "MTActuationActuate")
            else { return nil }
            return Library(
                create: unsafeBitCast(create, to: Create.self),
                open: unsafeBitCast(open, to: Open.self),
                close: unsafeBitCast(close, to: Close.self),
                makeActuation: unsafeBitCast(makeActuation, to: MakeActuation.self),
                actuate: unsafeBitCast(actuate, to: Actuate.self)
            )
        }()
    }
}

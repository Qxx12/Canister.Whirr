import Darwin
import Foundation
import IOKit

/// A low hum on the Force Touch trackpad that follows the drive's seeks,
/// so the trackpad feels like a drive vibrating while it works.
///
/// AppKit's NSHapticFeedbackManager is meant for feedback inside a
/// foreground app's own UI. Whirr has no UI, so it drives the trackpad's
/// actuator directly through the private MultitouchSupport framework (as
/// tools like HapticKey do), opened with dlopen. Its function signatures were
/// read from the macOS 27 disassembly; a later macOS could change them without
/// renaming them, and calling one the old way could crash the agent. So
/// haptics only run on macOS versions in `verifiedMajorVersions`; elsewhere
/// they're off and `whirr status` says why (WHIRR_HAPTICS_UNVERIFIED=1
/// overrides that, for trying a new macOS). A missing framework or symbol
/// also just turns haptics off.
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
/// touching. You only feel it while a finger rests on the trackpad. While
/// bursts are playing, the IORegistry is checked every `rescanInterval` for
/// trackpads that connected or went away. Each trackpad is handled on its
/// own: one that keeps refusing is set aside (and retried later, quietly)
/// without taking the others down with it.
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
    /// How often to check for trackpads that connected or went away, while
    /// bursts are playing.
    private let rescanInterval: TimeInterval = 10
    /// A trackpad that keeps refusing is set aside for `rescanInterval`, then
    /// twice as long each time it fails again, up to this.
    private let maxBenchInterval: TimeInterval = 600

    /// An open trackpad.
    private struct Pad {
        let id: UInt64
        let name: String
        let actuator: CFTypeRef
        /// Refused actuations in a row; a busy trackpad can refuse one now and then.
        var failures = 0
    }
    private var pads: [Pad] = []
    /// Trackpads set aside after refusing repeatedly: when to try again and
    /// how long the last wait was. While a trackpad is here its trouble has
    /// been logged; leaving it (by working again) logs the recovery. Logged
    /// once each, so the agent's log can't grow without bound.
    private var benched: [UInt64: (until: UInt64, wait: TimeInterval)] = [:]
    /// Trackpads whose "using" line has been logged, so reopening is quiet.
    private var announced: Set<UInt64> = []
    /// Bursts built so far, by amplitude in hundredths.
    private var bursts: [Int: CFTypeRef] = [:]
    /// The driver refused the hum definition; it won't accept it later in
    /// this run either, so stop trying.
    private var rejected = false
    /// Whether the reason haptics can't run here has been logged.
    private var loggedUnavailable = false
    private var lastScan: UInt64 = 0
    private var scanned = false
    private var lastBurst: UInt64 = 0
    /// Bursts waiting for their sound to be heard: (host time, amplitude),
    /// fired by one strict timer. A plain asyncAfter may be coalesced with
    /// other timers and fire late in clumps, which would bunch bursts up and
    /// drop most of them under `minimumGap`.
    private var pending: [(at: UInt64, amplitude: Double)] = []
    /// Kept for the object's lifetime and re-armed for the next pending
    /// burst, rather than created per burst.
    private let timer: DispatchSourceTimer

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
        timer = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
        timer.schedule(deadline: .distantFuture)
        timer.setEventHandler { [weak self] in self?.firePending() }
        timer.resume()
    }

    deinit {
        timer.cancel()
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
        armTimer()
    }

    /// Points the timer at the earliest pending burst, or parks it.
    private func armTimer() {
        guard let next = pending.first else {
            timer.schedule(deadline: .distantFuture)
            return
        }
        let now = mach_absolute_time()
        let wait = next.at > now ? Double(next.at - now) / Double(AudioOutput.hostTicks(1)) : 0
        timer.schedule(deadline: .now() + wait, leeway: .milliseconds(1))
    }

    private func firePending() {
        let now = mach_absolute_time()
        while let first = pending.first, first.at <= now + AudioOutput.hostTicks(0.001) {
            pending.removeFirst()
            if enabled { burst(first.amplitude) }
        }
        armTimer()
    }

    /// macOS major versions whose MultitouchSupport signatures match `Library`.
    static let verifiedMajorVersions: Set<Int> = [27]

    /// Why haptics can't run on this Mac, or nil if they can.
    static var unavailableReason: String? {
        let major = ProcessInfo.processInfo.operatingSystemVersion.majorVersion
        if !verifiedMajorVersions.contains(major),
           ProcessInfo.processInfo.environment["WHIRR_HAPTICS_UNVERIFIED"] != "1" {
            return "not yet verified on macOS \(major); off"
        }
        if Library.loaded == nil { return "not supported on this macOS" }
        return nil
    }

    /// A description of the trackpads haptics would use, for `whirr status`.
    static func describeTrackpads() -> String {
        if let reason = unavailableReason { return reason }
        let devices = Self.actuationDevices()
        if devices.isEmpty { return "no Force Touch trackpad found" }
        return devices.map(\.name).joined(separator: ", ")
    }

    // MARK: - Actuation

    private func burst(_ amplitude: Double) {
        let now = mach_absolute_time()
        guard !rejected, now - lastBurst >= AudioOutput.hostTicks(minimumGap) else { return }
        guard let library = Library.shared else {
            if !loggedUnavailable, let reason = Self.unavailableReason {
                log("haptics: \(reason)")
                loggedUnavailable = true
            }
            return
        }
        rescanIfDue(library, now: now)
        guard !pads.isEmpty, let actuation = hum(library, amplitude: amplitude) else { return }
        lastBurst = now

        for index in pads.indices {
            // Flags 0: no Light/Medium/Firm preset, so the burst plays as
            // defined, unscaled.
            if library.actuate(actuation, pads[index].actuator, 0, 1, 1) == 0 {
                pads[index].failures = 0
                if benched.removeValue(forKey: pads[index].id) != nil {
                    log("haptics: \(pads[index].name) responding again")
                }
            } else {
                pads[index].failures += 1
            }
        }
        // A trackpad that refused three in a row went away (Magic Trackpad
        // disconnected), went stale over sleep, or is refusing for now: set
        // it aside and try it again later, waiting longer each time.
        for pad in pads where pad.failures >= 3 {
            _ = library.close(pad.actuator)
            let wait = benched[pad.id].map { min($0.wait * 2, maxBenchInterval) } ?? rescanInterval
            if benched[pad.id] == nil {
                log("haptics: \(pad.name) stopped responding; will keep trying quietly")
            }
            benched[pad.id] = (now + AudioOutput.hostTicks(wait), wait)
        }
        pads.removeAll { $0.failures >= 3 }
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
            log("haptics: the trackpad driver rejected the hum; haptics are off until Whirr restarts")
            rejected = true
            return nil
        }
        bursts[key] = actuation
        return actuation
    }

    /// Opens trackpads that appeared (or whose time out is over) and closes
    /// ones that went away. Runs at most every `rescanInterval`.
    private func rescanIfDue(_ library: Library, now: UInt64) {
        guard !scanned || now - lastScan >= AudioOutput.hostTicks(rescanInterval) else { return }
        let first = !scanned
        scanned = true
        lastScan = now

        let devices = Self.actuationDevices()
        let present = Set(devices.map(\.id))
        for pad in pads where !present.contains(pad.id) { _ = library.close(pad.actuator) }
        pads.removeAll { !present.contains($0.id) }
        // Forget trackpads that are gone, so reconnecting one is announced
        // and starts with a clean slate.
        announced.formIntersection(present)
        benched = benched.filter { present.contains($0.key) }

        for device in devices where !pads.contains(where: { $0.id == device.id }) {
            if let bench = benched[device.id], now < bench.until { continue }
            guard let actuator = library.create(device.id)?.takeRetainedValue(),
                  library.open(actuator) == 0
            else { continue }
            pads.append(Pad(id: device.id, name: device.name, actuator: actuator))
            if !announced.contains(device.id) && benched[device.id] == nil {
                log("haptics: using \(device.name)")
                announced.insert(device.id)
            }
        }
        if first && devices.isEmpty {
            log("haptics: no Force Touch trackpad found")
        }
    }

    private func closeAll() {
        if let library = Library.shared {
            for pad in pads { _ = library.close(pad.actuator) }
        }
        pads = []
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

        /// The functions, if this macOS is one haptics may run on.
        static let shared: Library? = unavailableReason == nil ? loaded : nil

        static let loaded: Library? = {
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

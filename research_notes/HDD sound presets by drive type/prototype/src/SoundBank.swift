import AVFoundation
import Foundation

/// Deterministic, fast random numbers so a drive's "voice" is reproducible.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

/// A standard normal sample (Box–Muller).
func gaussian<R: RandomNumberGenerator>(using rng: inout R) -> Double {
    let u1 = Double.random(in: Double.ulpOfOne..<1, using: &rng)
    let u2 = Double.random(in: 0..<1, using: &rng)
    return (-2 * log(u1)).squareRoot() * cos(2 * Double.pi * u2)
}

func decibels(_ db: Double) -> Double { pow(10, db / 20) }

/// One structural resonance of the drive (actuator arm, cover, casting).
struct Mode {
    var hz: Double
    var q: Double
    /// Initial amplitude of the ring, in dB relative to the strongest mode.
    var db: Double
}

/// Timing and voice of one kind of drive.
///
/// The default is a mid-2000s 7200 rpm desktop drive. Its resonances come
/// from measurements of CC0 recordings of a Maxtor DiamondMax 10 and a
/// WD1600JD (cross-checked against a Seagate ST3250823A), and its timing
/// from Seagate and WD datasheets. See reports/Realistic HDD sound synthesis.md.
struct DrivePreset {
    var rpm: Double
    /// Seek times in seconds: track-to-track, average (1/3 stroke), full stroke.
    var trackToTrack: Double
    var average: Double
    var fullStroke: Double
    /// Time the head takes to settle on the target track.
    var settle: Double
    /// Highest random seek rate the mechanics allow (1 / (avg seek + avg latency)).
    var maxSeekRate: Double
    var modes: [Mode]
    /// Output filters: how much top and bottom survive the trip to the ear.
    /// A drive inside a closed case sounds much duller (low-pass ~4 kHz).
    var lowPassHz: Double = 8_000
    var highPassHz: Double = 120
    /// The drive's body: the top cover and base casting flexing under each
    /// strike's reaction force. Big, damped plates (Q 6–14) in 300–1800 Hz
    /// that give a click its "tock" in the room. Close-miked recordings
    /// under-report them, so their frequencies come from plate physics and
    /// their levels from a target balance: the 250–1200 Hz body carries
    /// about as much energy as the 1.5–8 kHz click (−3 dB for the bright,
    /// small or quiet drives, +2 dB for the heavy old ones). Levels are dB
    /// re the strongest actuator mode and often exceed it: each plate ring
    /// is short and broad, while the click is many long, narrow rings.
    var body: [Mode] = []
    /// The low "thump" some older desktop drives make: reaction torque
    /// shaking the case or desk, arriving a few ms after the click.
    var thump: Thump? = nil
    /// The computer case around the drive, if any.
    var enclosure: Enclosure? = nil
    /// Stepper-motor actuator: a seek is a fixed-rate train of step impulses
    /// instead of start/stop strikes (measured on a Seagate ST-277N).
    var stepper: Stepper? = nil

    struct Stepper {
        /// Impulse spacing while stepping, then the slowing tail, seconds.
        var rate: Double = 0.0055
        var decel: [Double] = [0.0065, 0.0070]
        var tail: [Double] = [0.0105, 0.0135]
        var jitter: Double = 0.0005
        /// Extra level of the sub-650 Hz modes on single steps ("tok").
        var singleStepLowBoostDB: Double = 7
    }

    struct Thump {
        var hz: Double
        var q: Double
        /// Initial amplitude relative to the strongest mode.
        var db: Double
        /// Delay of the push after the start strike.
        var delay: ClosedRange<Double> = 0.005...0.010
    }

    var revolution: Double { 60 / rpm }

    /// A cover/casting body from its first plate mode: the next two modes
    /// sit at 1.6× and 2.4×, a little narrower and 3 and 6 dB softer.
    static func body(_ hz: Double, q: Double, db: Double) -> [Mode] {
        [Mode(hz: hz, q: q, db: db), Mode(hz: hz * 1.6, q: q + 1, db: db - 3), Mode(hz: hz * 2.4, q: q + 2, db: db - 6)]
    }

    /// Seek time for a move of `d` (fraction of the full stroke): settle plus
    /// a square-root law for short seeks, linear for long ones (Ruemmler &
    /// Wilkes 1994).
    func seekTime(_ d: Double) -> Double {
        if d <= 0 { return 0 }
        if d < 0.33 {
            return trackToTrack + (average - trackToTrack) * (d / 0.33).squareRoot()
        }
        return average + (fullStroke - average) * (d - 0.33) / 0.67
    }

    static let desktop2005 = DrivePreset(
        rpm: 7200,
        trackToTrack: 0.001, average: 0.0085, fullStroke: 0.021,
        settle: 0.001,
        maxSeekRate: 79,
        modes: [
            // Main actuator/cover cluster, 1.7–3.1 kHz, moderately damped.
            Mode(hz: 1_730, q: 28, db: 0),
            Mode(hz: 1_965, q: 24, db: -5),
            Mode(hz: 2_190, q: 30, db: -3),
            Mode(hz: 2_630, q: 34, db: -1),
            Mode(hz: 2_790, q: 26, db: -6),
            Mode(hz: 3_010, q: 32, db: -7),
            // Lightly damped partials that carry the 20–50 ms metallic tail.
            Mode(hz: 2_655, q: 110, db: -8),
            Mode(hz: 3_640, q: 80, db: -9),
            // Upper actuator / butterfly modes.
            Mode(hz: 5_470, q: 36, db: -7),
            Mode(hz: 5_710, q: 42, db: -6),
            Mode(hz: 6_250, q: 30, db: -10),
            // "Weight": low-mid modes instead of bass.
            Mode(hz: 1_114, q: 16, db: -7),
            Mode(hz: 991, q: 14, db: -10),
        ],
        body: body(560, q: 7, db: 7)
    )

    /// The same mid-2000s drive mounted inside a closed steel tower: the
    /// sound rings briefly inside the box and comes out muffled through the
    /// panels, with a little brighter leakage through vents and gaps, and a
    /// soft knock where the drive's vibration reaches the chassis.
    static let desktop2005InTower: DrivePreset = {
        var p = desktop2005
        p.lowPassHz = 9_000
        p.thump = nil  // the chassis path (Enclosure) carries the case's response
        p.enclosure = .tower
        return p
    }()

    /// A mid-2000s 2.5-inch 5400 rpm laptop drive inside a laptop on a desk,
    /// mounted facing down (see Enclosure.laptopOnDesk).
    /// Timing from typical 2.5-inch datasheets (about 12 ms average seek).
    /// No recording of a 2.5-inch drive was available, so the voice is the
    /// desktop drive's resonances scaled up 30% for a smaller, lighter
    /// actuator arm: an estimate, to be tuned by ear.
    static let laptop2005: DrivePreset = {
        var p = desktop2005
        p.rpm = 5400
        p.trackToTrack = 0.0018
        p.average = 0.012
        p.fullStroke = 0.024
        p.settle = 0.0012
        p.maxSeekRate = 57
        p.modes = desktop2005.modes.map { mode in
            var m = mode
            m.hz = min(m.hz * 1.3, 8_400)
            return m
        }
        p.lowPassHz = 9_500
        p.highPassHz = 250
        p.enclosure = .laptopOnDesk
        return p
    }()

    /// The same drive in a tower with a mesh front or vented side panel.
    static let desktop2005InVentedTower: DrivePreset = {
        var p = desktop2005InTower
        p.enclosure = .towerVented
        return p
    }()

    /// The voice Whirr uses unless told otherwise.
    static let `default` = quiet2010s

    /// A 2010s 7200 rpm drive (Seagate ST3000DM001 / WD30EZRX recordings):
    /// a higher, narrower, cleaner tick centred near 3.8 kHz.
    static let quiet2010s = DrivePreset(
        rpm: 7200,
        trackToTrack: 0.001, average: 0.0085, fullStroke: 0.021,
        settle: 0.001,
        maxSeekRate: 79,
        modes: [
            Mode(hz: 3_752, q: 32, db: 0),
            Mode(hz: 3_930, q: 36, db: -2),
            Mode(hz: 3_840, q: 100, db: -9),
            Mode(hz: 6_067, q: 32, db: -11),
            Mode(hz: 4_420, q: 28, db: -10),
            Mode(hz: 2_300, q: 22, db: -15),
            Mode(hz: 1_650, q: 20, db: -16),
        ],
        lowPassHz: 9_500,
        // A thinner cover with a damping label: a softer, shorter body.
        body: body(580, q: 6, db: 0)
    )

    /// A 2000 5400 rpm drive (Fujitsu MPF3102AT recording): lower and woodier,
    /// with energy at 0.9, 1.4 and 2.7 kHz and a shorter ring.
    static let desktop2000 = DrivePreset(
        rpm: 5400,
        trackToTrack: 0.0025, average: 0.0115, fullStroke: 0.022,
        settle: 0.0015,
        maxSeekRate: 57,
        modes: [
            Mode(hz: 888, q: 18, db: 0),
            Mode(hz: 1_378, q: 22, db: -2),
            Mode(hz: 2_659, q: 28, db: -3),
            Mode(hz: 2_668, q: 80, db: -11),
            Mode(hz: 1_150, q: 16, db: -8),
            Mode(hz: 1_960, q: 22, db: -9),
            Mode(hz: 3_420, q: 26, db: -12),
        ],
        lowPassHz: 7_000,
        body: body(560, q: 7, db: -4)
    )

    /// An early-1990s 3600 rpm IDE drive (Conner CFS420A recording): a
    /// mid-range clack at 0.76/1.9/2.7 kHz over a strong, late low thump.
    static let vintage1993 = DrivePreset(
        rpm: 3600,
        trackToTrack: 0.006, average: 0.017, fullStroke: 0.030,
        settle: 0.0025,
        maxSeekRate: 39,
        modes: [
            Mode(hz: 1_890, q: 26, db: 0),
            Mode(hz: 764, q: 14, db: -1),
            Mode(hz: 2_720, q: 30, db: -3),
            Mode(hz: 1_895, q: 90, db: -10),
            Mode(hz: 1_240, q: 18, db: -8),
            Mode(hz: 3_466, q: 30, db: -12),
        ],
        lowPassHz: 7_000,
        highPassHz: 80,
        // A thick cast cover: lower plate modes.
        body: body(480, q: 7, db: 3),
        thump: Thump(hz: 264, q: 4.5, db: 2, delay: 0.004...0.008)
    )
}

/// Procedurally synthesized seek gestures, rendered once at startup.
///
/// A seek is a gesture, not a single click. The voice-coil current's sharp
/// edges strike the drive's structural resonances: once when the arm starts
/// (strike A), more softly when the current reverses mid-seek (strike B),
/// and again when the arm stops on the target track (strike C), followed by
/// a few small settle ticks. Long seeks add a faint coast hiss between the
/// strikes. Each strike is a short raised-cosine force pulse with a couple of
/// micro-bounces and a touch of contact grit, driving a bank of 13 two-pole
/// resonators: a moderately damped cluster (Q 14–42) that makes the attack,
/// and two lightly damped partials (Q 80–110) that ring on for 20–50 ms and
/// give the sound its metal.
///
/// Gestures are pre-rendered for a set of seek distances with many
/// variations each, and normalized once for the whole bank (not per buffer),
/// so the level differences between strikes survive. Playback adds a
/// distance-based level. Rendering never happens on the audio thread.
final class SoundBank {
    static let sampleRate = 48_000.0
    /// Seek distances (fraction of full stroke) that get pre-rendered.
    /// 0 is a track switch: a single soft settle tick.
    static let distances: [Double] = [0, 0.002, 0.01, 0.04, 0.12, 0.33, 0.6, 1.0]

    let format: AVAudioFormat
    let preset: DrivePreset
    private var bins: [[AVAudioPCMBuffer]] = []
    private var lastVariant: [Int]
    private var rng: SplitMix64

    init(preset: DrivePreset = .default, seed: UInt64 = 0x57_68_69_72_72, variations: Int = 12) {
        let format = AVAudioFormat(standardFormatWithSampleRate: Self.sampleRate, channels: 1)!
        var synthRNG = SplitMix64(seed: seed)

        // This drive's personality: its modes sit slightly off the preset's.
        var voice = preset
        voice.modes = preset.modes.map { mode in
            var m = mode
            m.hz *= .random(in: 0.985...1.015, using: &synthRNG)
            return m
        }

        var rendered: [[[Float]]] = Self.distances.map { d in
            (0..<variations).map { _ in Self.renderGesture(distance: d, voice: voice, rng: &synthRNG) }
        }

        // One scale factor for the whole bank: the median 1/3-stroke seek
        // peaks at `referencePeak`; everything else keeps its relative level.
        let referenceBin = Self.distances.firstIndex(of: 0.33)!
        let peaks = rendered[referenceBin].map { $0.reduce(0) { max($0, abs($1)) } }.sorted()
        let scale = Self.referencePeak / max(peaks[peaks.count / 2], 1e-9)
        for b in rendered.indices {
            for v in rendered[b].indices {
                rendered[b][v] = rendered[b][v].map { $0 * scale }
            }
        }

        self.format = format
        self.preset = voice
        bins = rendered.map { $0.map { Self.makeBuffer($0, format: format) } }
        lastVariant = Array(repeating: -1, count: Self.distances.count)
        rng = SplitMix64(seed: seed ^ 0xA5A5_A5A5)
    }

    /// Peak of a typical 1/3-stroke seek before playback gain. A real drive
    /// is a quiet background sound; this keeps Whirr there at 50% volume.
    static let referencePeak: Float = 0.17

    /// A random variation of the gesture nearest to distance `d`, never the
    /// same variation twice in a row.
    func buffer(distance d: Double) -> AVAudioPCMBuffer {
        let bin = Self.distances.indices.min { abs(Self.distances[$0] - d) < abs(Self.distances[$1] - d) }!
        let list = bins[bin]
        var pick = Int.random(in: 0..<list.count, using: &rng)
        if pick == lastVariant[bin] { pick = (pick + 1) % list.count }
        lastVariant[bin] = pick
        return list[pick]
    }

    /// Playback level for a seek of distance `d`: longer seeks are louder,
    /// spanning 8 dB from the shortest to a full stroke (0 dB). A track
    /// switch (d = 0) is much quieter.
    static func level(distance d: Double) -> Double {
        d <= 0 ? -16 : -8 + 8 * d.squareRoot()
    }

    // MARK: - Synthesis

    private struct Strike {
        var time: Double      // seconds from gesture start
        var gain: Double      // linear
        var pulse: Double     // force pulse duration, seconds
    }

    private static func renderGesture<R: RandomNumberGenerator>(distance d: Double, voice: DrivePreset,
                                                                rng: inout R) -> [Float] {
        let sr = sampleRate
        func jitter(_ amount: Double) -> Double { 1 + Double.random(in: -amount...amount, using: &rng) }

        // Pulse length sets hardness: longer seeks hit harder and brighter.
        let basePulse = (0.25 - 0.15 * d.squareRoot()) / 1_000

        var strikes: [Strike] = []
        var coast: (start: Double, end: Double)?
        var moveTime = 0.0
        if d <= 0 {
            // Track switch: a single soft settle-type tick.
            strikes.append(Strike(time: 0, gain: 1, pulse: basePulse * jitter(0.3)))
        } else if let stepper = voice.stepper {
            // Impulse count grows with seek time, about one per 6 ms.
            let n = min(12, max(1, Int((voice.seekTime(d) * jitter(0.1) / 0.006).rounded())))
            var intervals: [Double] = []
            if n >= 2 {
                let tail = n >= 8 ? stepper.tail : []
                let decel = n >= 4 ? stepper.decel : []
                let core = max(0, n - 1 - tail.count - decel.count)
                intervals = Array(repeating: stepper.rate, count: core) + decel + tail
            }
            var t = 0.0
            for k in 0..<n {
                let gain = decibels((k < n - (n >= 8 ? 2 : 0) ? 0 : -3) + gaussian(using: &rng))
                strikes.append(Strike(time: t, gain: gain, pulse: basePulse * jitter(0.3)))
                if k < intervals.count {
                    t += intervals[k] + Double.random(in: -stepper.jitter...stepper.jitter, using: &rng)
                }
            }
            moveTime = t
        } else {
            let seek = voice.seekTime(d) * jitter(0.1)
            let move = max(0.0003, seek - voice.settle)
            moveTime = move
            strikes.append(Strike(time: 0, gain: 1, pulse: basePulse * jitter(0.3)))                     // A
            if move >= 0.002 {
                strikes.append(Strike(time: move / 2, gain: decibels(-10 + 2 * gaussian(using: &rng)),   // B
                                      pulse: basePulse * 1.5 * jitter(0.3)))
            }
            let stop = Strike(time: move, gain: decibels(.random(in: -5...1, using: &rng)),            // C
                              pulse: basePulse * jitter(0.3))
            strikes.append(stop)
            var settleTime = move
            var settleGap = Double.random(in: 0.0004...0.0012, using: &rng)
            for _ in 0..<Int.random(in: 1...3, using: &rng) {                                           // settle ticks
                settleTime += settleGap * jitter(0.2)
                settleGap *= 1.8
                strikes.append(Strike(time: settleTime, gain: stop.gain * decibels(.random(in: -16 ... -8, using: &rng)),
                                      pulse: basePulse * jitter(0.3)))
            }
            if move > 0.004 { coast = (0, move) }
        }

        let lastStrike = strikes.map(\.time).max() ?? 0
        let count = Int((lastStrike + 0.11 + (voice.enclosure?.tail ?? 0)) * sr)
        var excitation = [Double](repeating: 0, count: count)
        var grit = [Double](repeating: 0, count: count)

        // Each strike: a raised-cosine force pulse of unit area, plus 2–4
        // micro-bounces, plus a sliver of high-passed contact noise.
        func addPulse(at time: Double, width: Double, gain: Double) {
            let start = Int(time * sr)
            let n = max(2, Int(width * sr))
            for i in 0..<n where start + i < count {
                let shape = 1 - cos(2 * Double.pi * Double(i) / Double(n))
                excitation[start + i] += gain * shape / Double(n)
            }
        }
        for strike in strikes {
            addPulse(at: strike.time, width: strike.pulse, gain: strike.gain)
            var bounceTime = strike.time
            var bounceGain = strike.gain
            for _ in 0..<Int.random(in: 2...4, using: &rng) {
                bounceTime += Double.random(in: 0.00015...0.0008, using: &rng)
                bounceGain *= .random(in: 0.3...0.5, using: &rng)
                addPulse(at: bounceTime, width: strike.pulse * 0.7, gain: bounceGain)
            }
            let gritStart = Int(strike.time * sr)
            let gritLength = Int(Double.random(in: 0.0002...0.0005, using: &rng) * sr)
            let gritLevel = strike.gain * decibels(.random(in: -18 ... -10, using: &rng))
            var previous = 0.0
            for i in 0..<gritLength where gritStart + i < count {
                let noise = Double.random(in: -1...1, using: &rng)
                grit[gritStart + i] += gritLevel * (noise - previous) * exp(-Double(i) / Double(gritLength) * 3)
                previous = noise
            }
        }

        // The force on the drive's mounting, for the chassis path: each strike's
        // jolt, plus the arm's reaction push while accelerating and pull while
        // braking (two opposite smooth lobes). Longer seeks push harder.
        var force = [Double](repeating: 0, count: count)
        if voice.enclosure != nil {
            for strike in strikes {
                let start = Int(strike.time * sr)
                let n = max(2, Int(strike.pulse * sr))
                for i in 0..<n where start + i < count {
                    force[start + i] += 0.3 * strike.gain * (1 - cos(2 * Double.pi * Double(i) / Double(n))) / Double(n)
                }
            }
            if d > 0, moveTime > 0.0005 {
                let half = max(2, Int(moveTime / 2 * sr))
                let area = 1.2 * d.squareRoot() * jitter(0.2)
                for lobe in 0..<2 {
                    let sign = lobe == 0 ? 1.0 : -1.0
                    for i in 0..<half where lobe * half + i < count {
                        force[lobe * half + i] += sign * area * (1 - cos(2 * Double.pi * Double(i) / Double(half))) / Double(half)
                    }
                }
            }
        }

        // Coast: the voice coil's hiss while the arm travels, band-limited to
        // 1–4 kHz and fed through the same resonances.
        if let coast {
            var band = Biquad.bandPass(hz: 2_000, q: 0.7, sampleRate: sr)
            let a = Int(coast.start * sr), b = Int(coast.end * sr)
            let level = decibels(.random(in: -17 ... -12, using: &rng)) * 0.02
            for i in a..<min(b, count) {
                let shape = 1 - cos(2 * Double.pi * Double(i - a) / Double(b - a))
                excitation[i] += level * shape * band.process(Double.random(in: -1...1, using: &rng))
            }
        }

        // The resonator bank. Every strike in a gesture hits the arm at a
        // slightly different point, so each mode gets its own random gain.
        var out = [Double](repeating: 0, count: count)
        let globalTune = jitter(0.01)
        let singleStep = voice.stepper != nil && strikes.count == 1
        for mode in voice.modes {
            let hz = mode.hz * globalTune * jitter(0.003)
            let q = mode.q * jitter(0.15)
            let boost = singleStep && mode.hz < 650 ? voice.stepper!.singleStepLowBoostDB : 0
            let amplitude = decibels(mode.db + boost + 3 * gaussian(using: &rng))
            let omega = 2 * Double.pi * hz / sr
            let r = exp(-Double.pi * hz / (q * sr))
            let a1 = 2 * r * cos(omega), a2 = -r * r
            // Unit-area pulse in → ring of peak `amplitude` (impulse response a·rⁿ·sin(ω(n+1))).
            let g = amplitude * sin(omega)
            var y1 = 0.0, y2 = 0.0
            for i in 0..<count {
                let y = a1 * y1 + a2 * y2 + g * excitation[i]
                y2 = y1
                y1 = y
                out[i] += y
            }
        }
        for i in 0..<count { out[i] += grit[i] }

        // The body: cover and casting plates, driven through the casting by
        // a softer, longer version of each strike (the casting passes only
        // the low part of the jolt) plus the arm's push-pull reaction, which
        // makes short seeks knock deeper.
        if !voice.body.isEmpty {
            var push = [Double](repeating: 0, count: count)
            for strike in strikes {
                let start = Int(strike.time * sr)
                let n = max(2, Int(max(0.0006, strike.pulse * 2.5) * sr))
                for i in 0..<n where start + i < count {
                    push[start + i] += strike.gain * (1 - cos(2 * Double.pi * Double(i) / Double(n))) / Double(n)
                }
            }
            if d > 0, moveTime > 0.0005, voice.stepper == nil {
                let half = max(2, Int(moveTime / 2 * sr))
                let area = 0.4 * d.squareRoot() * jitter(0.2)
                for lobe in 0..<2 {
                    let sign = lobe == 0 ? 1.0 : -1.0
                    for i in 0..<half where lobe * half + i < count {
                        push[lobe * half + i] += sign * area * (1 - cos(2 * Double.pi * Double(i) / Double(half))) / Double(half)
                    }
                }
            }
            for mode in voice.body {
                let hz = mode.hz * globalTune * jitter(0.02)
                let q = mode.q * jitter(0.15)
                let omega = 2 * Double.pi * hz / sr
                let r = exp(-Double.pi * hz / (q * sr))
                let a1 = 2 * r * cos(omega), a2 = -r * r
                let g = decibels(mode.db + 2 * gaussian(using: &rng)) * sin(omega)
                var y1 = 0.0, y2 = 0.0
                for i in 0..<count {
                    let y = a1 * y1 + a2 * y2 + g * push[i]
                    y2 = y1
                    y1 = y
                    out[i] += y
                }
            }
        }

        // Optional low thump: a soft 1–2 ms push, a few ms after the start
        // strike, ringing a broad low resonance.
        if let thump = voice.thump, d > 0 {
            var push = [Double](repeating: 0, count: count)
            // A stepper's landing knock follows the last impulse, not the first.
            let origin = voice.stepper != nil ? lastStrike : 0
            let start = Int((origin + Double.random(in: thump.delay, using: &rng)) * sr)
            let n = Int(Double.random(in: 0.001...0.002, using: &rng) * sr)
            for i in 0..<n where start + i < count {
                push[start + i] = (1 - cos(2 * Double.pi * Double(i) / Double(n))) / Double(n)
            }
            let hz = thump.hz * jitter(0.05)
            let omega = 2 * Double.pi * hz / sr
            let r = exp(-Double.pi * hz / (thump.q * sr))
            // Longer seeks shake the case harder.
            let g = decibels(thump.db - 6 + 6 * d.squareRoot() + 2 * gaussian(using: &rng)) * sin(omega)
            var y1 = 0.0, y2 = 0.0
            for i in 0..<count {
                let y = 2 * r * cos(omega) * y1 - r * r * y2 + g * push[i]
                y2 = y1
                y1 = y
                out[i] += y
            }
        }

        // Inside a computer: ring in the case, then out through panels and vents.
        if let enclosure = voice.enclosure {
            out = enclosure.apply(out, force: force, sampleRate: sr)
        }

        // The room outside: a few early reflections from the desk and nearby
        // surfaces. Surfaces soak up the top, so the reflections come back
        // darker and the room adds weight rather than fizz.
        let dry = out
        var reflections = [Double](repeating: 0, count: count)
        for _ in 0..<5 {
            let delay = Int(Double.random(in: 0.0007...0.009, using: &rng) * sr)
            let gain = decibels(.random(in: -22 ... -14, using: &rng))
            for i in delay..<count { reflections[i] += gain * dry[i - delay] }
        }
        var absorb = Biquad.lowPass(hz: 4_000, q: 0.707, sampleRate: sr)
        for i in 0..<count { out[i] += absorb.process(reflections[i]) }

        // Heard from a little distance: soften the top; keep the drive's
        // low-mid body, cut only sub-bass the drive can't make.
        var lowPass = Biquad.lowPass(hz: voice.lowPassHz, q: 0.707, sampleRate: sr)
        var highPass = Biquad.highPass(hz: voice.highPassHz, q: 0.707, sampleRate: sr)
        let fade = Int(0.01 * sr)
        return (0..<count).map { i in
            let y = highPass.process(lowPass.process(out[i]))
            let tail = count - i
            return Float(y * (tail < fade ? Double(tail) / Double(fade) : 1))
        }
    }

    private static func makeBuffer(_ samples: [Float], format: AVAudioFormat) -> AVAudioPCMBuffer {
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count))!
        buffer.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { source in
            buffer.floatChannelData![0].update(from: source.baseAddress!, count: samples.count)
        }
        return buffer
    }
}

/// A second-order IIR filter (RBJ Audio EQ Cookbook forms).
struct Biquad {
    private var b0, b1, b2, a1, a2: Double
    private var x1 = 0.0, x2 = 0.0, y1 = 0.0, y2 = 0.0

    private init(b0: Double, b1: Double, b2: Double, a0: Double, a1: Double, a2: Double) {
        self.b0 = b0 / a0
        self.b1 = b1 / a0
        self.b2 = b2 / a0
        self.a1 = a1 / a0
        self.a2 = a2 / a0
    }

    /// Band-pass with 0 dB peak gain.
    static func bandPass(hz: Double, q: Double, sampleRate: Double) -> Biquad {
        let w = 2 * Double.pi * hz / sampleRate
        let alpha = sin(w) / (2 * q)
        return Biquad(b0: alpha, b1: 0, b2: -alpha, a0: 1 + alpha, a1: -2 * cos(w), a2: 1 - alpha)
    }

    static func lowPass(hz: Double, q: Double, sampleRate: Double) -> Biquad {
        let w = 2 * Double.pi * hz / sampleRate
        let alpha = sin(w) / (2 * q)
        let c = cos(w)
        return Biquad(b0: (1 - c) / 2, b1: 1 - c, b2: (1 - c) / 2, a0: 1 + alpha, a1: -2 * c, a2: 1 - alpha)
    }

    static func highPass(hz: Double, q: Double, sampleRate: Double) -> Biquad {
        let w = 2 * Double.pi * hz / sampleRate
        let alpha = sin(w) / (2 * q)
        let c = cos(w)
        return Biquad(b0: (1 + c) / 2, b1: -(1 + c), b2: (1 + c) / 2, a0: 1 + alpha, a1: -2 * c, a2: 1 - alpha)
    }

    mutating func process(_ x: Double) -> Double {
        let y = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        x2 = x1
        x1 = x
        y2 = y1
        y1 = y
        return y
    }
}

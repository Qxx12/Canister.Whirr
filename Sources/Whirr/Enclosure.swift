import Foundation

/// The computer case around the drive.
///
/// A desktop tower is a small, mostly metal room (about 20 × 45 × 45 cm).
/// Sound from the drive bounces between its panels every millisecond or so,
/// building a short, boxy reverberation. What reaches the listener then
/// takes three routes out:
///
/// - **Through the panels:** sheet steel passes low and mid frequencies and
///   blocks the highs (mass law), so this path is muffled. The panels also
///   resonate faintly at a few hundred Hz.
/// - **Through vents, the front bezel and gaps:** quieter but brighter, which
///   keeps some definition in the ticks.
/// - **Through the metal itself:** the drive is screwed to the chassis, so
///   each seek's reaction force (the strike edges, and the arm's
///   accelerate-then-brake push-pull) shakes the drive cage and panels, which
///   ring at their own resonances and radiate directly. A hard-mounted drive
///   measured ~12 dBA louder on seeks than a suspended one (HWCooling).
///
/// The reverberation is a small feedback delay network whose delay lengths
/// match path lengths inside a tower (0.3–1.2 m), with a gentle low-pass in
/// the loop because each bounce loses some top end. Everything is applied
/// offline, while the sound bank is rendered.
struct Enclosure {
    /// Reverberation time inside the case, in seconds.
    var reverbTime: Double
    /// High-frequency loss per bounce (loop low-pass cutoff, Hz).
    var bounceDamping: Double
    /// Direct sound relative to the reverberant field inside the case, dB.
    var directDB: Double
    /// Upper limit of what gets through the panels, Hz.
    var panelLowPass: Double
    /// Faint panel resonances.
    var panelModes: [Mode]
    var panelModeDB: Double
    /// Level and brightness of sound escaping through vents and gaps.
    var leakDB: Double
    var leakLowPass: Double
    /// Resonances of the drive cage and panels, shaken by the seek force.
    var chassisModes: [Mode]
    var chassisDB: Double
    /// Scales the internal reflection paths: 1 is a tower (0.3–1.2 m paths);
    /// a laptop's few-centimetre cavity is much smaller.
    var size: Double = 1
    /// Sound that leaves through a gap (e.g. under a laptop) and escapes at
    /// edges at different distances: delayed copies of the panel path.
    var exitTaps: [Tap] = []
    /// The surface the computer stands on, shaken through its feet.
    var deskModes: [Mode] = []
    var deskDB: Double = -120
    /// Rubber feet pass mostly low frequencies into the desk.
    var feetLowPass: Double = 800

    struct Tap {
        var delayMs: Double
        var db: Double
    }

    /// A closed steel tower with solid side panels.
    static let tower = Enclosure(
        reverbTime: 0.2, bounceDamping: 5_000, directDB: -3,
        panelLowPass: 1_600,
        panelModes: [Mode(hz: 185, q: 8, db: 0), Mode(hz: 330, q: 10, db: -2),
                     Mode(hz: 520, q: 9, db: -4), Mode(hz: 760, q: 10, db: -6)],
        panelModeDB: -18,
        leakDB: -9, leakLowPass: 4_500,
        chassisModes: chassisSteel, chassisDB: -4
    )

    /// Drive cage and steel panel resonances (inferred, not measured):
    /// weighted to the low mids, with little true bass.
    static let chassisSteel: [Mode] = [
        Mode(hz: 165, q: 10, db: -20),
        Mode(hz: 240, q: 14, db: -15),
        Mode(hz: 355, q: 18, db: -3),
        Mode(hz: 470, q: 20, db: 0),
        Mode(hz: 610, q: 22, db: -2),
        Mode(hz: 780, q: 25, db: -4),
        Mode(hz: 960, q: 24, db: -5),
        Mode(hz: 1_230, q: 28, db: -7),
        Mode(hz: 1_580, q: 30, db: -9),
        Mode(hz: 2_050, q: 30, db: -12),
    ]

    /// A tower with a mesh front or vented panel: more of the tick escapes.
    static let towerVented = Enclosure(
        reverbTime: 0.15, bounceDamping: 6_000, directDB: -1,
        panelLowPass: 2_200,
        panelModes: tower.panelModes,
        panelModeDB: -20,
        leakDB: -3, leakLowPass: 7_000,
        chassisModes: chassisSteel, chassisDB: -7
    )

    /// A laptop body: a thin, densely packed aluminium or plastic shell around
    /// a 2.5-inch drive under the palm rest. There's no room to echo: the
    /// cavity is a couple of centimetres tall, so reflections arrive within a
    /// fraction of a millisecond and only colour the sound ("boxy"), dying
    /// out in tens of milliseconds among the packed components. The thin
    /// shell blocks less than steel panels, so the sound is only moderately
    /// muffled, and keyboard gaps and vents let a fair share out directly.
    /// The drive sits on rubber-isolated brackets, so the chassis is shaken
    /// less, and the light shell rings higher and thinner than a tower.
    /// Values are inferred from the physics, not measured.
    static let laptop = Enclosure(
        reverbTime: 0.045, bounceDamping: 7_000, directDB: 0,
        panelLowPass: 3_000,
        panelModes: [Mode(hz: 620, q: 10, db: 0), Mode(hz: 1_050, q: 12, db: -2),
                     Mode(hz: 1_700, q: 12, db: -4)],
        panelModeDB: -20,
        leakDB: -5, leakLowPass: 6_500,
        chassisModes: [
            Mode(hz: 540, q: 14, db: -6),
            Mode(hz: 790, q: 18, db: -3),
            Mode(hz: 1_120, q: 20, db: 0),
            Mode(hz: 1_480, q: 22, db: -2),
            Mode(hz: 1_930, q: 24, db: -4),
            Mode(hz: 2_520, q: 26, db: -6),
            Mode(hz: 3_240, q: 26, db: -9),
        ],
        chassisDB: -12,
        size: 0.16
    )

    /// A laptop on a desk, as old laptops actually carried their drives: the
    /// 2.5-inch drive is mounted under the board facing down, so its sound
    /// goes into the few-millimetre gap between the laptop's bottom and the
    /// desk and escapes sideways at the edges (front edge nearest, sides and
    /// back later), muffled by the bottom panel. Little comes up through the
    /// keyboard: the board and keyboard deck sit in the way. Meanwhile the
    /// drive's vibration passes through the rubber feet into the desk, which
    /// acts as a sounding board in the low mids. (Mac speakers, by contrast,
    /// fire upward through the keyboard straight at the listener, so this
    /// path has to be built into the sound.) Values are inferred.
    static let laptopOnDesk: Enclosure = {
        var e = laptop
        e.panelLowPass = 2_200
        e.leakDB = -16
        e.leakLowPass = 4_500
        e.exitTaps = [Tap(delayMs: 0.35, db: 0), Tap(delayMs: 0.6, db: -3), Tap(delayMs: 0.95, db: -6)]
        e.deskModes = [
            Mode(hz: 180, q: 10, db: -8),
            Mode(hz: 260, q: 12, db: -4),
            Mode(hz: 340, q: 14, db: 0),
            Mode(hz: 450, q: 14, db: -2),
            Mode(hz: 590, q: 16, db: -4),
            Mode(hz: 760, q: 18, db: -7),
        ]
        e.deskDB = -4
        return e
    }()

    /// How much longer a sound gets once it rings inside the case.
    var tail: Double { reverbTime * 1.1 }

    /// - Parameters:
    ///   - input: the drive's airborne sound.
    ///   - force: the drive's mechanical force on its mounting, same length.
    func apply(_ input: [Double], force: [Double], sampleRate sr: Double) -> [Double] {
        let n = input.count

        // 1. The field inside the case: direct sound plus reverberation.
        let delaysMs = [0.83, 1.13, 1.37, 1.71, 2.03, 2.59, 3.07, 3.61]
        let lengths = delaysMs.map { max(1, Int($0 * size * sr / 1_000)) }
        let lines = lengths.count
        var buffers = lengths.map { [Double](repeating: 0, count: $0) }
        var positions = [Int](repeating: 0, count: lines)
        var damping = [Double](repeating: 0, count: lines)
        let gains = lengths.map { pow(10, -3 * Double($0) / sr / reverbTime) }
        let dampCoef = 1 - exp(-2 * Double.pi * bounceDamping / sr)
        var outs = [Double](repeating: 0, count: lines)
        var inside = [Double](repeating: 0, count: n)
        let direct = decibels(directDB)
        // Panels flex and soak up low frequencies on every bounce, so lows
        // must die quickly too, or the short loop builds up boom. A one-pole
        // high-pass per line does that; a high-pass on the way in keeps the
        // drive's own low end out of the cavity.
        let lowLoss = exp(-2 * Double.pi * 300 / sr)
        var hpIn = [Double](repeating: 0, count: lines), hpOut = [Double](repeating: 0, count: lines)
        var feedIn = Biquad.highPass(hz: 300, q: 0.707, sampleRate: sr)
        for i in 0..<n {
            var sum = 0.0
            for l in 0..<lines {
                outs[l] = buffers[l][positions[l]]
                sum += outs[l]
            }
            // Householder mixing keeps the network lossless before damping.
            let mix = sum * 2 / Double(lines)
            let source = feedIn.process(input[i]) / Double(lines)
            for l in 0..<lines {
                let feedback = (outs[l] - mix) * gains[l]
                damping[l] += dampCoef * (feedback - damping[l])
                hpOut[l] = lowLoss * (hpOut[l] + damping[l] - hpIn[l])
                hpIn[l] = damping[l]
                buffers[l][positions[l]] = source + hpOut[l]
                positions[l] = (positions[l] + 1) % lengths[l]
            }
            inside[i] = direct * input[i] + sum
        }

        // 2. Through the panels: steep low-pass, plus faint panel resonances.
        var panel = inside
        var lp1 = Biquad.lowPass(hz: panelLowPass, q: 0.6, sampleRate: sr)
        var lp2 = Biquad.lowPass(hz: panelLowPass * 1.4, q: 0.6, sampleRate: sr)
        for i in 0..<n { panel[i] = lp2.process(lp1.process(panel[i])) }
        if !exitTaps.isEmpty {
            let through = panel
            panel = [Double](repeating: 0, count: n)
            for tap in exitTaps {
                let delay = Int(tap.delayMs * sr / 1_000)
                let g = decibels(tap.db)
                for i in delay..<n { panel[i] += g * through[i - delay] }
            }
        }
        let modeGain = decibels(panelModeDB)
        for mode in panelModes {
            var resonator = Biquad.bandPass(hz: mode.hz, q: mode.q, sampleRate: sr)
            let g = modeGain * decibels(mode.db) * 4
            for i in 0..<n { panel[i] += g * resonator.process(inside[i]) }
        }

        // 3. Through vents and gaps: quieter, brighter, no bass.
        var leakHP = Biquad.highPass(hz: 400, q: 0.707, sampleRate: sr)
        var leakLP = Biquad.lowPass(hz: leakLowPass, q: 0.707, sampleRate: sr)
        let leak = decibels(leakDB)
        var output = (0..<n).map { i in panel[i] + leak * leakLP.process(leakHP.process(inside[i])) }

        // 4. Through the metal: the chassis rings when the drive shakes it.
        let chassis = decibels(chassisDB)
        for mode in chassisModes {
            let omega = 2 * Double.pi * mode.hz / sr
            let r = exp(-Double.pi * mode.hz / (mode.q * sr))
            let g = chassis * decibels(mode.db) * sin(omega)
            var y1 = 0.0, y2 = 0.0
            for i in 0..<n {
                let y = 2 * r * cos(omega) * y1 - r * r * y2 + g * force[i]
                y2 = y1
                y1 = y
                output[i] += y
            }
        }
        // 5. The desk: shaken through the feet, it radiates in the low mids.
        if !deskModes.isEmpty {
            var feet1 = Biquad.lowPass(hz: feetLowPass, q: 0.707, sampleRate: sr)
            var feet2 = Biquad.lowPass(hz: feetLowPass, q: 0.707, sampleRate: sr)
            let shaken = force.map { feet2.process(feet1.process($0)) }
            let desk = decibels(deskDB)
            for mode in deskModes {
                let omega = 2 * Double.pi * mode.hz / sr
                let r = exp(-Double.pi * mode.hz / (mode.q * sr))
                let g = desk * decibels(mode.db) * sin(omega)
                var y1 = 0.0, y2 = 0.0
                for i in 0..<n {
                    let y = 2 * r * cos(omega) * y1 - r * r * y2 + g * shaken[i]
                    y2 = y1
                    y1 = y
                    output[i] += y
                }
            }
        }
        return output
    }
}

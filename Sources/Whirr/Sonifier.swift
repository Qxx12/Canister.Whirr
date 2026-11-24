import Foundation

/// One seek to play: how far the head moves, how loud, and when (seconds
/// after the poll that produced it).
struct SeekEvent {
    var distance: Double
    var gain: Float
    var delay: TimeInterval
}

/// Turns raw disk counter deltas into seeks by driving a small virtual drive.
///
/// macOS only reports how many operations and bytes each disk did per poll,
/// not where on the disk they went. So Whirr runs a pretend hard drive: a head
/// at a position on the platter, a sweep direction, and a clock for when the
/// head is next free. Each burst of real activity becomes requests; each
/// request gets a target from a locality model (mostly short moves near the
/// last one, sometimes a long jump), and the head serves them one after
/// another, spaced by real seek times plus a wait for the platter to come
/// round. That gives the rhythm of a real drive: an accented long seek when
/// activity starts, runs of soft short seeks, irregular gaps, and a
/// mechanical ceiling of about 80 seeks a second.
///
/// A modern Mac's SSD is never quiet: daemons issue a steady trickle of small
/// I/O in short bursts. Whirr learns that background (a noise floor and the
/// typical per-poll spread) and only treats clear bursts above it as drive
/// work. Smaller blips occasionally produce a single ambient tick, the way an
/// idle drive ticks now and then.
///
/// Timing rules follow the report "Realistic HDD sound synthesis".
struct Sonifier {
    struct Tuning {
        /// Averaging window for the activity rate used to learn the floor.
        var smoothing: TimeInterval = 0.3
        /// How fast the noise floor falls to quieter activity, and rises to louder.
        var floorFall: TimeInterval = 3
        var floorRise: TimeInterval = 60
        /// Highest values the noise floor may learn (per second).
        var maxFloorOps: Double = 150
        var maxFloorBytes: Double = 2_000_000
        /// A poll counts as drive work when it exceeds the floor by this many
        /// typical deviations (and at least the minimum).
        var spread: Double = 3
        var minExcessOps: Double = 80
        var minExcessBytes: Double = 1024 * 1024
        /// Excess operations per second at which demand reaches ~63% of the ceiling.
        var saturationOps: Double = 3_000
        /// Chance that a below-threshold blip produces one ambient tick.
        var ambientChance: Double = 0.02
        /// Requests that would start more than this far in the future are
        /// dropped, so saturation sounds like a steady grind, not a lagging queue.
        var maxBacklog: TimeInterval = 0.12
        /// Quiet time after which the next request is a fresh, accented long seek.
        var idleGap: TimeInterval = 0.15
    }

    var tuning = Tuning()
    var preset: DrivePreset = .default
    /// How eagerly activity makes sound; 1 is normal, 2 twice as eager.
    var sensitivity: Double = 1

    // Floor learning (exposed for `whirr monitor`).
    private(set) var opsRate = 0.0
    private(set) var bytesRate = 0.0
    private(set) var floorOps: Double
    private(set) var floorBytes: Double
    /// Typical per-poll deviation of quiet activity.
    private(set) var spreadOps = 5.0
    private(set) var spreadBytes = 256.0 * 1024
    /// 0 (idle) to 1 (mechanical ceiling).
    private(set) var intensity = 0.0

    // The virtual drive.
    private var clock = 0.0
    private var head = 0.5
    private var headFree = 0.0
    private var lastOnset = -1.0
    private var lastActive = -1.0
    private var sweepUp = true
    private var demand = 0.0
    private var rng = SystemRandomNumberGenerator()

    init() {
        // Start with the floor high so the first seconds after launch are quiet
        // while it settles to this machine's real idle level.
        floorOps = tuning.maxFloorOps
        floorBytes = tuning.maxFloorBytes
    }

    /// Feeds one poll's worth of activity and returns the seeks to play.
    mutating func update(delta: DiskCounters, dt: TimeInterval) -> [SeekEvent] {
        guard dt > 0 else { return [] }
        let t = tuning
        clock += dt
        let ops = Double(delta.ops)
        let bytes = Double(delta.bytes)

        // 1. Learn the background.
        let blend = 1 - exp(-dt / t.smoothing)
        opsRate += (ops / dt - opsRate) * blend
        bytesRate += (bytes / dt - bytesRate) * blend
        func track(_ floor: inout Double, _ value: Double, cap: Double) {
            let tau = value < floor ? t.floorFall : t.floorRise
            floor += (value - floor) * (1 - exp(-dt / tau))
            floor = min(floor, cap)
        }
        track(&floorOps, opsRate, cap: t.maxFloorOps)
        track(&floorBytes, bytesRate, cap: t.maxFloorBytes)

        let baseOps = floorOps * dt
        let baseBytes = floorBytes * dt
        let thresholdOps = baseOps + max(t.spread * spreadOps, t.minExcessOps) / sensitivity
        let thresholdBytes = baseBytes + max(t.spread * spreadBytes, t.minExcessBytes) / sensitivity
        let active = ops > thresholdOps || bytes > thresholdBytes

        guard active else {
            // Quiet poll: learn its spread, let demand fade, maybe tick.
            let quietBlend = 1 - exp(-dt / 10)
            spreadOps += (abs(ops - baseOps) - spreadOps) * quietBlend
            spreadBytes += (abs(bytes - baseBytes) - spreadBytes) * quietBlend
            demand *= exp(-dt / 0.5)
            intensity *= exp(-dt / 0.3)
            if ops > 0, Double.random(in: 0..<1, using: &rng) < t.ambientChance * sensitivity {
                return place(distances: [shortMove()], gainOffset: -4, bytesPerOp: bytes / ops, sequential: false)
            }
            return []
        }

        // 2. Classify the work by transfer size.
        let excessOps = max(0, ops - baseOps)
        let excessBytes = max(0, bytes - baseBytes)
        let bytesPerOp = excessOps > 0 ? excessBytes / excessOps : excessBytes
        let seekShare: Double
        let sequential: Bool
        switch bytesPerOp {
        case ..<(32 * 1024): seekShare = 0.9; sequential = false        // random small I/O
        case ..<(256 * 1024): seekShare = 0.45; sequential = false      // mixed
        default: seekShare = 0.06; sequential = true                     // streaming
        }

        // 3. Demand: seeks per second, compressing SSD-scale op counts into
        //    what a mechanical drive could do.
        let effective = max(excessOps, excessBytes / (256 * 1024)) / dt * seekShare * sensitivity
        let rate = preset.maxSeekRate * (1 - exp(-effective / t.saturationOps))
        intensity = rate / preset.maxSeekRate
        demand += rate * dt

        var distances: [Double] = []
        let freshBurst = clock - lastActive > t.idleGap + dt
        lastActive = clock
        if freshBurst {
            // The first seek of a burst jumps somewhere new and plays at once.
            distances.append(longJump())
            demand = max(0, demand - 1)
        }
        while demand >= 1 {
            demand -= 1
            distances.append(nextMove(sequential: sequential))
        }

        // Streaming transfers: soft track-switch ticks, about one per
        // cylinder (~1 MiB) and at most one per revolution.
        if sequential {
            let switches = min(excessBytes / (1024 * 1024), dt / preset.revolution)
            var whole = Int(switches)
            if Double.random(in: 0..<1, using: &rng) < switches - Double(whole) { whole += 1 }
            distances.append(contentsOf: Array(repeating: 0, count: whole))
        }

        // 5. Elevator: a busy poll is served as one sweep plus a return.
        if distances.count >= 4 {
            distances = elevator(distances, keepFirst: freshBurst)
        }
        return place(distances: distances, gainOffset: 0, bytesPerOp: bytesPerOp, sequential: sequential,
                     immediateFirst: freshBurst)
    }

    /// Forgets activity and head timing, e.g. after sleep. The floor is kept.
    mutating func reset() {
        opsRate = 0
        bytesRate = 0
        intensity = 0
        demand = 0
        headFree = clock
        lastActive = -1
    }

    // MARK: - Head movement

    /// A move to a new target anywhere on the platter; returns the distance.
    private mutating func longJump() -> Double {
        let target = Double.random(in: 0...1, using: &rng)
        defer { head = target }
        return max(abs(target - head), 0.05)
    }

    /// A short move near the current position.
    private mutating func shortMove() -> Double {
        let step = min(0.2, -log(Double.random(in: Double.ulpOfOne..<1, using: &rng)) * 0.01)
        let target = min(1, max(0, head + (Bool.random(using: &rng) ? step : -step)))
        defer { head = target }
        return abs(target - head)
    }

    /// The next request's move: mostly local (often staying on the same
    /// track), sometimes a jump elsewhere.
    private mutating func nextMove(sequential: Bool) -> Double {
        let local = sequential ? 0.9 : 0.75
        guard Double.random(in: 0..<1, using: &rng) < local else { return longJump() }
        if Double.random(in: 0..<1, using: &rng) < 0.4 { return 0 }  // same track: rotation only
        return shortMove()
    }

    /// Re-orders a batch of moves as one sweep in the current direction,
    /// ending with a long return seek.
    private mutating func elevator(_ moves: [Double], keepFirst: Bool) -> [Double] {
        var batch = moves
        let first = keepFirst ? batch.removeFirst() : nil
        let travel = batch.filter { $0 > 0 }.sorted()
        let stays = batch.count - travel.count
        var swept = travel
        // Interleave rotation-only requests through the sweep.
        for _ in 0..<stays { swept.insert(0, at: Int.random(in: 0...swept.count, using: &rng)) }
        let span = travel.reduce(0, +)
        head = min(1, max(0, head + (sweepUp ? span : -span)))
        sweepUp.toggle()
        swept.append(min(1, max(0.1, span)))  // return seek
        return (first.map { [$0] } ?? []) + swept
    }

    // MARK: - Timing

    /// Serves moves on the virtual head's timeline. Moves of distance 0 are
    /// track switches: a soft tick only when streaming, otherwise silent
    /// (the head waits for rotation without moving).
    private mutating func place(distances: [Double], gainOffset: Double, bytesPerOp: Double, sequential: Bool,
                                immediateFirst: Bool = false) -> [SeekEvent] {
        var events: [SeekEvent] = []
        let transfer = min(bytesPerOp, 4 * 1024 * 1024) / 120_000_000
        for (index, d) in distances.enumerated() {
            let arrival = clock + (immediateFirst && index == 0 ? 0 : .random(in: 0...0.003, using: &rng))
            var start = max(headFree, arrival)
            if immediateFirst && index == 0 { start = clock }
            // Never two onsets closer than a track-to-track seek.
            start = max(start, lastOnset + preset.trackToTrack)
            guard start - clock <= tuning.maxBacklog else { break }

            let rotation = sequential
                ? preset.revolution - .random(in: 0...0.001, using: &rng)
                : .random(in: 0..<preset.revolution, using: &rng)
            headFree = start + preset.seekTime(d) + rotation + transfer

            if d == 0 && !sequential { continue }  // silent rotation wait
            lastOnset = start
            let db = SoundBank.level(distance: d) + gainOffset + 1.5 * gaussian(using: &rng)
            events.append(SeekEvent(distance: d, gain: Float(decibels(db)), delay: start - clock))
        }
        return events
    }
}

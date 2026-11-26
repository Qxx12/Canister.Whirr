import AVFoundation
import Foundation

// Offline renderer for Whirr drive presets: runs the real Sonifier against a
// scripted workload and mixes the real SoundBank gestures into a WAV file.

enum Daemon { static let pollInterval: TimeInterval = 1.0 / 30 }

struct Workload {
    /// Seeded so every preset hears the same "computer".
    var rng = SplitMix64(seed: 42)

    static func isIdle(_ t: Double) -> Bool {
        t < 1.6 || (t >= 4.2 && t < 5.0) || (t >= 8.2 && t < 9.2) || t >= 12.4
    }

    mutating func counters(at t: Double) -> DiskCounters {
        func r(_ range: ClosedRange<Double>) -> Double { Double.random(in: range, using: &rng) }
        func trickle() -> DiskCounters {
            // A Mac's background: a few small ops, sometimes a blip.
            let ops = r(0...1) < 0.1 ? UInt64(r(2...12)) : UInt64(r(0...3))
            return DiskCounters(readOps: ops / 2, writeOps: ops - ops / 2, readBytes: ops * 8192, writeBytes: ops * 4096)
        }
        switch t {
        case ..<1.6:
            return trickle()
        case ..<4.2:
            // App launch: bursty random small reads.
            if r(0...1) < 0.35 { return trickle() }
            let ops = UInt64(r(60...260))
            return DiskCounters(readOps: ops, writeOps: ops / 8, readBytes: ops * 16_384, writeBytes: ops * 2048)
        case ..<5.0:
            return trickle()
        case ..<8.2:
            // File copy: big sequential reads and writes, with metadata seeks.
            let chunks = UInt64(r(10...24))
            let meta = r(0...1) < 0.25 ? UInt64(r(40...120)) : 0
            return DiskCounters(readOps: chunks + meta, writeOps: chunks,
                                readBytes: chunks * 1_048_576 + meta * 4096, writeBytes: chunks * 1_048_576)
        case ..<9.2:
            return trickle()
        case ..<12.4:
            // Indexing / heavy random I/O: sustained small ops.
            let ops = UInt64(r(250...600))
            return DiskCounters(readOps: ops, writeOps: ops / 3, readBytes: ops * 8192, writeBytes: ops * 4096)
        default:
            return trickle()
        }
    }
}

func render(_ variant: Variant, outDir: URL) throws {
    let preset = variant.preset
    let name = variant.name
    let sr = SoundBank.sampleRate
    let bank = SoundBank(preset: preset)
    var sonifier = Sonifier()
    sonifier.preset = preset

    var events: [(time: Double, distance: Double, gain: Float)] = []
    // 1. A seek ladder: track-to-track up to full stroke, two of each.
    var time = 0.3
    for distance in [0.002, 0.04, 0.33, 1.0] {
        for _ in 0..<2 {
            events.append((time, distance, Float(decibels(SoundBank.level(distance: distance)))))
            time += 0.38
        }
        time += 0.15
    }
    time += 0.6

    // 2. Warm the floor up on idle trickle (not rendered), then the workload.
    var warm = Workload(rng: SplitMix64(seed: 7))
    for _ in 0..<Int(8 / Daemon.pollInterval) {
        _ = sonifier.update(delta: warm.counters(at: 0), dt: Daemon.pollInterval)
    }
    var workload = Workload()
    let workloadLength = 17.0
    var t = 0.0
    var activity: [(time: Double, level: Double)] = []
    while t < workloadLength {
        let delta = workload.counters(at: t)
        for e in sonifier.update(delta: delta, dt: Daemon.pollInterval) {
            events.append((time + t + e.delay, e.distance, e.gain))
        }
        // Rumble follows write load in particular.
        let writeRate = Double(delta.writeBytes) / Daemon.pollInterval
        activity.append((time + t, 0.8 * min(1, writeRate / 40_000_000) + 0.2 * sonifier.intensity))
        t += Daemon.pollInterval
    }
    // Prototype extras on the workload timeline.
    var extraRNG = SplitMix64(seed: 99)
    if let interval = variant.idleTickInterval {
        // PWL-style idle sweep: a medium seek on a fixed clock, heard only when idle.
        var tick = 0.9
        while tick < workloadLength {
            if Workload.isIdle(tick) { events.append((time + tick, 0.25, Float(decibels(-5)))) }
            tick += interval * Double.random(in: 0.97...1.03, using: &extraRNG)
        }
    }
    if variant.failing {
        // Click of death in the first idle stretch and the idle tail: two
        // full-stroke slaps 162 ms apart every ~510 ms.
        for (from, to) in [(0.1, 1.5), (13.0, 16.6)] {
            var c = from
            while c + 0.17 < to {
                events.append((time + c, 1.0, Float(decibels(3))))
                events.append((time + c + 0.162, 1.0, Float(decibels(1))))
                c += 0.51 * Double.random(in: 0.99...1.01, using: &extraRNG)
            }
        }
        // Under load: occasional read-retry trains (16 ms apart).
        for e in events where e.time > time && Double.random(in: 0..<1, using: &extraRNG) < 0.035 {
            for k in 1...Int.random(in: 6...14, using: &extraRNG) {
                events.append((e.time + 0.016 * Double(k), 0.002, Float(decibels(-4))))
            }
        }
    }
    let total = time + workloadLength + 0.3
    var entry: [String: Any] = [
        "name": name, "preset": presetJSON(preset), "start": time, "total": total,
        "events": events.sorted { $0.time < $1.time }.map { [($0.time * 1e5).rounded() / 1e5, $0.distance, (Double($0.gain) * 1e4).rounded() / 1e4] },
    ]
    if !variant.rumble.isEmpty {
        entry["rumble"] = ["bands": variant.rumble.map { [$0.hz, $0.q, $0.db] }, "levelDB": variant.rumbleDB,
                           "activity": activity.map { ($0.level * 1e4).rounded() / 1e4 }]
    }
    exportList.append(entry)

    var mix = [Float](repeating: 0, count: Int(total * sr))
    for e in events {
        let buffer = bank.buffer(distance: e.distance)
        let start = Int(e.time * sr)
        let data = buffer.floatChannelData![0]
        for i in 0..<Int(buffer.frameLength) where start + i < mix.count {
            mix[start + i] += data[i] * e.gain
        }
    }
    if !variant.rumble.isEmpty {
        let reference = Double(SoundBank.referencePeak) * decibels(SoundBank.level(distance: 0.33))
        var noise = SplitMix64(seed: 11)
        var bands = variant.rumble.map { Biquad.bandPass(hz: $0.hz, q: $0.q, sampleRate: sr) }
        let weights = variant.rumble.map { decibels($0.db) }
        var env = 0.0
        for i in mix.indices {
            let t = Double(i) / sr
            let k = min(activity.count - 1, max(0, Int((t - time) / Daemon.pollInterval)))
            let target = t < time ? 0 : activity[k].level
            env += (target - env) * (target > env ? 0.0006 : 0.00015)
            let x = Double.random(in: -1...1, using: &noise)
            var y = 0.0
            for b in bands.indices { y += weights[b] * bands[b].process(x) }
            mix[i] += Float(reference * decibels(variant.rumbleDB) * 4 * env * y)
        }
    }
    // Loudness-match tracks: scale so the 99.9th-percentile |sample| is -9 dBFS,
    // then soft-clip anything above -1 dBFS.
    let sorted = mix.map { abs($0) }.sorted()
    let p = sorted[Int(Double(sorted.count - 1) * 0.999)]
    let scale = Float(decibels(-9)) / max(p, 1e-9)
    let ceiling = Float(decibels(-1))
    for i in mix.indices {
        let x = mix[i] * scale
        mix[i] = abs(x) <= ceiling ? x : (x > 0 ? 1 : -1) * (ceiling + (1 - ceiling) * tanh((abs(x) - ceiling) / (1 - ceiling)))
    }

    let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sr, channels: 1, interleaved: false)!
    let out = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(mix.count))!
    out.frameLength = AVAudioFrameCount(mix.count)
    mix.withUnsafeBufferPointer { out.floatChannelData![0].update(from: $0.baseAddress!, count: mix.count) }
    let url = outDir.appendingPathComponent("\(name).wav")
    try? FileManager.default.removeItem(at: url)
    let settings: [String: Any] = [AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: sr, AVNumberOfChannelsKey: 1,
                                   AVLinearPCMBitDepthKey: 16, AVLinearPCMIsFloatKey: false]
    let file = try AVAudioFile(forWriting: url, settings: settings, commonFormat: .pcmFormatFloat32, interleaved: false)
    try file.write(from: out)
    print("\(name): \(events.count) events, \(String(format: "%.1f", total)) s")
}

let outDir = URL(fileURLWithPath: CommandLine.arguments[1])
let exportPath = ProcessInfo.processInfo.environment["WHIRR_EXPORT"]
let only = Set(CommandLine.arguments.dropFirst(2))
for variant in Presets.all where only.isEmpty || only.contains(variant.name) {
    try render(variant, outDir: outDir)
}
if let exportPath { try writeExport(to: exportPath) }

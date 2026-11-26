import Foundation

/// JSON export of presets and event timelines for the browser tuning bench.
var exportList: [[String: Any]] = []

func modesJSON(_ modes: [Mode]) -> [[Double]] { modes.map { [$0.hz, $0.q, $0.db] } }

func enclosureJSON(_ e: Enclosure) -> [String: Any] {
    [
        "reverbTime": e.reverbTime, "bounceDamping": e.bounceDamping, "directDB": e.directDB,
        "panelLowPass": e.panelLowPass, "panelModes": modesJSON(e.panelModes), "panelModeDB": e.panelModeDB,
        "leakDB": e.leakDB, "leakLowPass": e.leakLowPass, "chassisModes": modesJSON(e.chassisModes),
        "chassisDB": e.chassisDB, "size": e.size, "exitTaps": e.exitTaps.map { [$0.delayMs, $0.db] },
        "deskModes": modesJSON(e.deskModes), "deskDB": e.deskDB, "feetLowPass": e.feetLowPass,
    ]
}

func presetJSON(_ p: DrivePreset) -> [String: Any] {
    var d: [String: Any] = [
        "rpm": p.rpm, "trackToTrack": p.trackToTrack, "average": p.average, "fullStroke": p.fullStroke,
        "settle": p.settle, "maxSeekRate": p.maxSeekRate, "modes": modesJSON(p.modes),
        "lowPassHz": p.lowPassHz, "highPassHz": p.highPassHz, "body": modesJSON(p.body),
    ]
    if let t = p.thump { d["thump"] = ["hz": t.hz, "q": t.q, "db": t.db, "delay": [t.delay.lowerBound, t.delay.upperBound]] }
    if let s = p.stepper {
        d["stepper"] = ["rate": s.rate, "decel": s.decel, "tail": s.tail, "jitter": s.jitter,
                        "singleStepLowBoostDB": s.singleStepLowBoostDB]
    }
    let named: [(String, Enclosure)] = [("tower", .tower), ("towerVented", .towerVented),
                                        ("laptop", .laptop), ("laptopOnDesk", .laptopOnDesk)]
    if let e = p.enclosure {
        d["enclosure"] = named.first { $0.1.reverbTime == e.reverbTime && $0.1.leakDB == e.leakDB && $0.1.size == e.size }?.0 ?? "custom"
    }
    return d
}

func writeExport(to path: String) throws {
    let doc: [String: Any] = [
        "sampleRate": SoundBank.sampleRate,
        "referencePeak": Double(SoundBank.referencePeak),
        "distances": SoundBank.distances,
        "enclosures": ["tower": enclosureJSON(.tower), "towerVented": enclosureJSON(.towerVented),
                       "laptop": enclosureJSON(.laptop), "laptopOnDesk": enclosureJSON(.laptopOnDesk)],
        "drives": exportList,
    ]
    let data = try JSONSerialization.data(withJSONObject: doc, options: [.sortedKeys])
    try data.write(to: URL(fileURLWithPath: path))
}

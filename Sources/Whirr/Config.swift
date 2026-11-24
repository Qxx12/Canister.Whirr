import Darwin
import notify
import Foundation

enum Whirr {
    static let version = "0.1.0"
    static let label = "io.github.qxx12.whirr"
    /// Darwin notification the CLI posts after changing the config file.
    static let configChanged = "io.github.qxx12.whirr.config-changed"
}

enum Paths {
    static let home = FileManager.default.homeDirectoryForCurrentUser
    static let support = home.appendingPathComponent("Library/Application Support/Whirr", isDirectory: true)
    static let config = support.appendingPathComponent("config.json")
    static let lock = support.appendingPathComponent("whirr.lock")
    static let logs = home.appendingPathComponent("Library/Logs/Whirr", isDirectory: true)
    static let log = logs.appendingPathComponent("whirr.log")
    static let launchAgent = home.appendingPathComponent("Library/LaunchAgents/\(Whirr.label).plist")
}

/// User settings, shared between the CLI and the running agent through a
/// small JSON file. The CLI writes it and posts a Darwin notification; the
/// agent reloads on that notification.
struct Config: Codable, Equatable {
    /// 0-1, where 1 plays at `AudioOutput.fullScaleGain`.
    var volume: Double = 0.25
    /// Which scale `volume` is on. Files written before the volume range was
    /// capped have no such key; their volume was the raw mixer gain and is
    /// converted on load so it sounds the same.
    var volumeScale: Int = Config.currentVolumeScale
    static let currentVolumeScale = 2
    var muted: Bool = false
    var sensitivity: Double = 1.0
    /// Hum on the Force Touch trackpad along with the seeks.
    var haptics: Bool = false
    /// How strong the trackpad hum is, 0.75-1.5. The floor is where the
    /// quietest seeks still hum at about 0.12, near the least the trackpad's
    /// sine can be felt at; lower settings would seem broken, not fainter.
    var hapticStrength: Double = 0.85

    init() {}

    /// Missing keys keep their defaults, so a config file written by an
    /// older Whirr still loads with its settings.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Config()
        let scale = try container.decodeIfPresent(Int.self, forKey: .volumeScale) ?? 1
        if let saved = try container.decodeIfPresent(Double.self, forKey: .volume) {
            volume = scale >= Config.currentVolumeScale ? saved : saved / AudioOutput.fullScaleGain
        } else {
            volume = defaults.volume
        }
        volumeScale = Config.currentVolumeScale
        muted = try container.decodeIfPresent(Bool.self, forKey: .muted) ?? defaults.muted
        sensitivity = try container.decodeIfPresent(Double.self, forKey: .sensitivity) ?? defaults.sensitivity
        haptics = try container.decodeIfPresent(Bool.self, forKey: .haptics) ?? defaults.haptics
        hapticStrength = try container.decodeIfPresent(Double.self, forKey: .hapticStrength) ?? defaults.hapticStrength
    }

    static func load() -> Config {
        guard let data = try? Data(contentsOf: Paths.config),
              var config = try? JSONDecoder().decode(Config.self, from: data)
        else { return Config() }
        config.volume = min(max(config.volume, 0), 1)
        config.sensitivity = min(max(config.sensitivity, 0.25), 4)
        config.hapticStrength = min(max(config.hapticStrength, 0.75), 1.5)
        return config
    }

    /// "on, strength 85%" or "off", for the CLI.
    var hapticsSummary: String {
        haptics ? "on, strength \(Int((hapticStrength * 100).rounded()))%" : "off"
    }

    func save() throws {
        try FileManager.default.createDirectory(at: Paths.support, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(self).write(to: Paths.config, options: .atomic)
        notify_post(Whirr.configChanged)
    }
}

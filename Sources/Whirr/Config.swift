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
    var volume: Double = 0.2
    var muted: Bool = false
    var sensitivity: Double = 1.0
    /// Tap the Force Touch trackpad along with the louder seeks.
    var haptics: Bool = false
    /// How strong the trackpad hum is, 0.5-1.5. Below about 0.75 it fades out
    /// of feel (the trackpad's sine needs a minimum amplitude to be felt).
    var hapticStrength: Double = 0.85

    init() {}

    /// Missing keys keep their defaults, so a config file written by an
    /// older Whirr still loads with its settings.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Config()
        volume = try container.decodeIfPresent(Double.self, forKey: .volume) ?? defaults.volume
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
        config.hapticStrength = min(max(config.hapticStrength, 0.5), 1.5)
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

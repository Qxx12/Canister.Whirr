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

    static func load() -> Config {
        guard let data = try? Data(contentsOf: Paths.config),
              var config = try? JSONDecoder().decode(Config.self, from: data)
        else { return Config() }
        config.volume = min(max(config.volume, 0), 1)
        config.sensitivity = min(max(config.sensitivity, 0.25), 4)
        return config
    }

    func save() throws {
        try FileManager.default.createDirectory(at: Paths.support, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(self).write(to: Paths.config, options: .atomic)
        notify_post(Whirr.configChanged)
    }
}

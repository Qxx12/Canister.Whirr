import Foundation
import ServiceManagement

/// Installs and controls Whirr's per-user launch agent with the current
/// `launchctl` subcommands (bootstrap/bootout/kickstart/print in the
/// `gui/<uid>` domain); `load`/`unload` are legacy and unreliable on recent macOS.
enum LaunchAgent {
    enum State {
        case notInstalled
        case installedNotLoaded
        case loaded(pid: Int?)
    }

    static var domain: String { "gui/\(getuid())" }
    static var service: String { "\(domain)/\(Whirr.label)" }

    // MARK: - Plist

    static func plist(binary: String) -> [String: Any] {
        [
            "Label": Whirr.label,
            "ProgramArguments": [binary, "run"],
            "RunAtLoad": true,
            // Restart after a crash, but not after a clean exit.
            "KeepAlive": ["SuccessfulExit": false],
            // Unthrottled CPU and timers, like an app; Background or the
            // default class would add delay to polling and audio.
            "ProcessType": "Interactive",
            // Only in the logged-in GUI session, where audio output works.
            "LimitLoadToSessionType": "Aqua",
            "StandardOutPath": Paths.log.path,
            "StandardErrorPath": Paths.log.path,
        ]
    }

    /// Writes the plist if it differs from what's on disk. Returns true if it changed.
    static func writePlist(binary: String) throws -> Bool {
        let data = try PropertyListSerialization.data(fromPropertyList: plist(binary: binary), format: .xml, options: 0)
        if let existing = try? Data(contentsOf: Paths.launchAgent), existing == data { return false }
        try FileManager.default.createDirectory(
            at: Paths.launchAgent.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: Paths.logs, withIntermediateDirectories: true)
        try data.write(to: Paths.launchAgent, options: .atomic)
        return true
    }

    static func removePlist() {
        try? FileManager.default.removeItem(at: Paths.launchAgent)
    }

    // MARK: - State

    static var state: State {
        let (status, output) = launchctl("print", service)
        if status == 0 { return .loaded(pid: parsePID(output)) }
        return FileManager.default.fileExists(atPath: Paths.launchAgent.path) ? .installedNotLoaded : .notInstalled
    }

    static var isLoaded: Bool {
        if case .loaded = state { return true }
        return false
    }

    /// True if the service is marked disabled in launchd's override database.
    static var isDisabled: Bool {
        let (_, output) = launchctl("print-disabled", domain)
        return output.split(separator: "\n").contains { line in
            line.contains("\"\(Whirr.label)\"") && (line.contains("disabled") || line.contains("true"))
        }
    }

    /// What Background Task Management (System Settings > General > Login
    /// Items & Extensions) says about the plist.
    static var loginItemStatus: SMAppService.Status {
        SMAppService.statusForLegacyPlist(at: Paths.launchAgent)
    }

    private static func parsePID(_ output: String) -> Int? {
        for line in output.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("pid = ") { return Int(trimmed.dropFirst(6)) }
        }
        return nil
    }

    // MARK: - Control

    @discardableResult
    static func enable() -> (Int32, String) { launchctl("enable", service) }

    @discardableResult
    static func bootstrap() -> (Int32, String) { launchctl("bootstrap", domain, Paths.launchAgent.path) }

    @discardableResult
    static func bootout() -> (Int32, String) { launchctl("bootout", service) }

    @discardableResult
    static func kickstart(restart: Bool) -> (Int32, String) {
        restart ? launchctl("kickstart", "-k", service) : launchctl("kickstart", service)
    }

    @discardableResult
    static func launchctl(_ arguments: String...) -> (Int32, String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
        } catch {
            return (-1, error.localizedDescription)
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, String(decoding: data, as: UTF8.self))
    }

    // MARK: - Binary path

    /// The path launchd should run. Keeps symlinks such as Homebrew's
    /// `bin/whirr` (stable across upgrades), and rewrites a versioned
    /// Cellar path to Homebrew's `opt` link.
    static func binaryPath() -> String {
        let argv0 = CommandLine.arguments[0]
        var path: String
        if argv0.contains("/") {
            path = URL(fileURLWithPath: argv0, relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath))
                .standardizedFileURL.path
        } else {
            let dirs = (ProcessInfo.processInfo.environment["PATH"] ?? "").split(separator: ":")
            path = dirs.map { "\($0)/\(argv0)" }.first { FileManager.default.isExecutableFile(atPath: $0) }
                ?? Bundle.main.executablePath ?? argv0
        }
        // /opt/homebrew/Cellar/whirr/0.1.0/bin/whirr -> /opt/homebrew/opt/whirr/bin/whirr
        if let range = path.range(of: #"/Cellar/whirr/[^/]+/"#, options: .regularExpression) {
            path.replaceSubrange(range, with: "/opt/whirr/")
        }
        return path
    }
}

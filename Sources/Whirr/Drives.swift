import Foundation

/// A drive the user can pick: a voice plus the cases it fits in.
struct Drive {
    enum FormFactor: String {
        case fiveQuarter = "5.25-inch"
        case threeHalf = "3.5-inch"
        case twoHalf = "2.5-inch"

        /// Where a drive of this size can sit. The first is its usual home.
        var mounts: [Mount] {
            switch self {
            case .fiveQuarter, .threeHalf: [.bare, .tower, .vented]
            case .twoHalf: [.laptop, .bare]
            }
        }
    }

    let id: String
    let name: String
    let summary: String
    let formFactor: FormFactor
    let preset: DrivePreset

    var defaultMount: Mount { formFactor.mounts[0] }

    /// The voice to render for this drive in `mount`.
    func preset(in mount: Mount) -> DrivePreset {
        mount.apply(to: preset)
    }

    static let all: [Drive] = [
        Drive(id: "stepper1987", name: "Stepper (1987)",
              summary: "5.25-inch stepper motor: a buzzing \"brrrt\" of knocks per seek",
              formFactor: .fiveQuarter, preset: .stepper1987),
        Drive(id: "vintage1993", name: "Vintage IDE (1993)",
              summary: "slow, deliberate mid-range clacks over a late knock",
              formFactor: .threeHalf, preset: .vintage1993),
        Drive(id: "desktop2000", name: "Desktop (2000)",
              summary: "a low, woody 5400 rpm clack",
              formFactor: .threeHalf, preset: .desktop2000),
        Drive(id: "desktop2005", name: "Desktop (2005)",
              summary: "the classic metallic 7200 rpm chatter",
              formFactor: .threeHalf, preset: .desktop2005),
        Drive(id: "thunk2007", name: "Thunk (2007)",
              summary: "a booming low thunk under faint ticks (much of it below what a laptop speaker plays)",
              formFactor: .threeHalf, preset: .thunk2007),
        Drive(id: "quiet2010s", name: "Quiet (2010s)",
              summary: "a narrow, clean tick",
              formFactor: .threeHalf, preset: .quiet2010s),
        Drive(id: "laptop2007", name: "Laptop (2007)",
              summary: "faint, very short 2.5-inch ticks",
              formFactor: .twoHalf, preset: .laptop2007),
        Drive(id: "server10k", name: "Server 10K",
              summary: "a bright, long-ringing 10,000 rpm \"tsing\"",
              formFactor: .threeHalf, preset: .server10k),
        Drive(id: "server15k", name: "Server 15K",
              summary: "fast, ringing 15,000 rpm clicks that pack into chatter",
              formFactor: .threeHalf, preset: .server15k),
    ]

    static let `default` = named("quiet2010s")!

    /// Looks a drive up by id, case-insensitively. Older names map to the
    /// drive that replaced them.
    static func named(_ id: String) -> Drive? {
        let key = id.lowercased()
        let renamed = ["laptop2005": "laptop2007"][key] ?? key
        return all.first { $0.id.lowercased() == renamed }
    }
}

/// What surrounds the drive: nothing (bare on a desk), a computer case, or a laptop.
enum Mount: String, CaseIterable {
    case bare, tower, vented, laptop

    var description: String {
        switch self {
        case .bare: "bare on a desk"
        case .tower: "inside a closed steel tower"
        case .vented: "inside a tower with a mesh front"
        case .laptop: "inside a laptop on a desk"
        }
    }

    func apply(to preset: DrivePreset) -> DrivePreset {
        var p = preset
        switch self {
        case .bare:
            p.enclosure = nil
        case .tower, .vented:
            p.enclosure = self == .tower ? .tower : .towerVented
            // The panels do the muffling (Enclosure); outside, the usual distance roll-off.
            p.lowPassHz = 9_000
            p.thump = nil  // the chassis path (Enclosure) carries the case's response
        case .laptop:
            p.enclosure = .laptopOnDesk
        }
        return p
    }
}

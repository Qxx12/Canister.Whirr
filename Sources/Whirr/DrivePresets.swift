import Foundation

// The drives a user can pick (`whirr drive`), and the case around them
// (`whirr mount`). Voices are measured from openly licensed recordings; see
// reports/HDD sound presets by drive type.md for sources.

extension DrivePreset {
    /// 2007 3-platter 7200 rpm "boomer", measured from the CC0 Samsung T166
    /// HD501LJ (Freesound 167421): a late 207 Hz thunk with faint glassy ticks.
    static let thunk2007 = DrivePreset(
        rpm: 7200,
        trackToTrack: 0.0008, average: 0.0089, fullStroke: 0.020,
        settle: 0.001,
        maxSeekRate: 76,
        modes: [
            Mode(hz: 377, q: 28, db: 0), Mode(hz: 576, q: 60, db: -20),
            Mode(hz: 474, q: 40, db: -16), Mode(hz: 4_875, q: 300, db: -21),
            Mode(hz: 5_430, q: 250, db: -21), Mode(hz: 5_080, q: 105, db: -23),
            Mode(hz: 4_500, q: 300, db: -25), Mode(hz: 2_305, q: 210, db: -26),
            Mode(hz: 2_910, q: 275, db: -27), Mode(hz: 2_590, q: 125, db: -28),
            Mode(hz: 1_675, q: 140, db: -29),
        ],
        lowPassHz: 9_000,
        highPassHz: 70,
        // Already low and heavy; the cover adds only a little.
        body: body(560, q: 7, db: -9),
        thump: Thump(hz: 207, q: 22, db: 4, delay: 0.012...0.020)
    )

    /// 10k rpm server, measured from the CC0 Maxtor Atlas 10K V (Freesound 182366):
    /// bright 4.6–6.5 kHz ring with Q 170–300, a 1–2.3 kHz second knock.
    /// Timing from the Atlas 10K V manual (4.4 ms avg read, 11 ms full stroke).
    static let server10k = DrivePreset(
        rpm: 10_000,
        trackToTrack: 0.0005, average: 0.0044, fullStroke: 0.011,
        settle: 0.0008,
        maxSeekRate: 135,
        modes: [
            Mode(hz: 6_480, q: 225, db: 0), Mode(hz: 5_985, q: 225, db: -2),
            Mode(hz: 4_890, q: 170, db: -6), Mode(hz: 4_640, q: 220, db: -6),
            Mode(hz: 5_670, q: 280, db: -7), Mode(hz: 5_310, q: 280, db: -8),
            Mode(hz: 5_120, q: 250, db: -9), Mode(hz: 2_020, q: 95, db: -2),
            Mode(hz: 1_255, q: 80, db: -8), Mode(hz: 1_000, q: 50, db: -9),
            Mode(hz: 2_265, q: 150, db: -11), Mode(hz: 1_840, q: 75, db: -12),
            Mode(hz: 390, q: 38, db: -7),
        ],
        lowPassHz: 12_000,
        highPassHz: 120,
        // Heavy, stiff server casting.
        body: body(620, q: 8, db: 2),
        thump: Thump(hz: 199, q: 13, db: -5, delay: 0.012...0.022)
    )

    /// 15k rpm server, measured from the CC0 Fujitsu MBA3300RC (Freesound 182364):
    /// a ringing 3.6 kHz click with a 1.1 kHz body. Timing from the Cheetah 15K.7 manual.
    static let server15k = DrivePreset(
        rpm: 15_000,
        trackToTrack: 0.0002, average: 0.0034, fullStroke: 0.0066,
        settle: 0.0006,
        maxSeekRate: 185,
        modes: [
            Mode(hz: 3_605, q: 185, db: 0), Mode(hz: 6_120, q: 210, db: -2),
            Mode(hz: 1_145, q: 90, db: -4), Mode(hz: 4_750, q: 185, db: -5),
            Mode(hz: 6_340, q: 280, db: -5), Mode(hz: 3_750, q: 190, db: -5),
            Mode(hz: 1_285, q: 150, db: -6), Mode(hz: 3_425, q: 120, db: -6),
            Mode(hz: 4_295, q: 260, db: -7), Mode(hz: 336, q: 15, db: -7),
            Mode(hz: 2_520, q: 80, db: -9), Mode(hz: 1_010, q: 75, db: -10),
            Mode(hz: 2_205, q: 130, db: -10),
        ],
        lowPassHz: 11_000,
        highPassHz: 120,
        body: body(620, q: 8, db: 2)
    )

    /// Late-1980s 5.25" stepper-motor drive, measured from the CC0 Seagate
    /// ST-277N recording (Freesound 475216): a seek is 4-12 impulses ~5.5 ms
    /// apart (a ~180 Hz "brrrt"), each ringing a 0.9-1.43 kHz cluster, then a
    /// late 0.5-0.57 kHz landing knock; single steps are a darker "tok".
    /// Timing from the ST-277N manual (8 / 40 / 95 ms).
    static let stepper1987 = DrivePreset(
        rpm: 3600,
        trackToTrack: 0.008, average: 0.040, fullStroke: 0.095,
        settle: 0.015,
        maxSeekRate: 20,
        modes: [
            Mode(hz: 1_428, q: 30, db: 0), Mode(hz: 1_385, q: 30, db: -1),
            Mode(hz: 918, q: 22, db: -3), Mode(hz: 1_010, q: 38, db: -3),
            Mode(hz: 845, q: 30, db: -4), Mode(hz: 1_304, q: 30, db: -4),
            Mode(hz: 1_077, q: 30, db: -5), Mode(hz: 709, q: 25, db: -8),
            Mode(hz: 1_606, q: 30, db: -10), Mode(hz: 343, q: 20, db: -11),
            Mode(hz: 573, q: 23, db: -6), Mode(hz: 458, q: 30, db: -8),
        ],
        lowPassHz: 6_000,
        highPassHz: 120,
        // A 5.25-inch full-height casting and lid: big plates, low modes.
        body: body(330, q: 8, db: -3),
        thump: Thump(hz: 565, q: 23, db: -4, delay: 0.000...0.045),
        stepper: Stepper()
    )

    /// 2.5" 4200 rpm laptop drive, measured from the CC0 Fujitsu MHV2200BT
    /// recording (Freesound 143917): a faint, short 6.2-6.8 kHz tick with a
    /// weak 2.8 kHz pair; the low end comes from the laptop and desk (Mount.laptop).
    static let laptop2007: DrivePreset = {
        var p = DrivePreset(
            rpm: 4200,
            trackToTrack: 0.0015, average: 0.014, fullStroke: 0.022,
            settle: 0.0012,
            maxSeekRate: 47,
            modes: [
                Mode(hz: 6_380, q: 55, db: 0), Mode(hz: 6_190, q: 80, db: -7),
                Mode(hz: 2_766, q: 65, db: -6), Mode(hz: 6_750, q: 55, db: -10),
                Mode(hz: 2_879, q: 40, db: -11), Mode(hz: 5_380, q: 65, db: -15),
                Mode(hz: 5_970, q: 65, db: -15), Mode(hz: 4_810, q: 60, db: -16),
                Mode(hz: 7_105, q: 80, db: -16), Mode(hz: 9_280, q: 150, db: -18),
            ],
            lowPassHz: 12_000,
            highPassHz: 120,
            // A small, thin 2.5-inch cover.
            body: body(740, q: 7, db: 0)
        )
        return p
    }()
}

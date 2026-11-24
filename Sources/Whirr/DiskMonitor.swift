import Foundation
import IOKit

/// Cumulative (or delta) I/O counters for one or more block devices.
struct DiskCounters {
    var readOps: UInt64 = 0
    var writeOps: UInt64 = 0
    var readBytes: UInt64 = 0
    var writeBytes: UInt64 = 0

    var ops: UInt64 { readOps &+ writeOps }
    var bytes: UInt64 { readBytes &+ writeBytes }

    /// Per-field difference that treats a counter going backwards (driver reset) as zero.
    func delta(since old: DiskCounters) -> DiskCounters {
        func d(_ a: UInt64, _ b: UInt64) -> UInt64 { a >= b ? a - b : 0 }
        return DiskCounters(
            readOps: d(readOps, old.readOps),
            writeOps: d(writeOps, old.writeOps),
            readBytes: d(readBytes, old.readBytes),
            writeBytes: d(writeBytes, old.writeBytes)
        )
    }

    static func += (lhs: inout DiskCounters, rhs: DiskCounters) {
        lhs.readOps &+= rhs.readOps
        lhs.writeOps &+= rhs.writeOps
        lhs.readBytes &+= rhs.readBytes
        lhs.writeBytes &+= rhs.writeBytes
    }
}

/// Reads system-wide disk activity from the kernel's per-driver I/O counters.
///
/// Every `IOBlockStorageDriver` publishes a "Statistics" dictionary of 64-bit
/// counters that the kernel updates at each I/O completion. Reading them needs
/// no privileges. The kernel sends no notification when they change, so the
/// caller polls `poll()` on a timer. Drives that appear or disappear (USB
/// disks, SD cards) are tracked through IOKit matching notifications, and
/// disk images are skipped because their I/O is counted again on the disk
/// that backs them.
///
/// All methods must be called on the queue passed to `init`.
final class DiskMonitor {
    private struct Drive {
        let service: io_service_t
        let name: String
        var last: DiskCounters?
    }

    private let queue: DispatchQueue
    private var drives: [UInt64: Drive] = [:]
    private var notifyPort: IONotificationPortRef?
    private var addedIterator: io_iterator_t = 0
    private var removedIterator: io_iterator_t = 0

    /// Called (on the monitor's queue) when a drive is added or removed.
    var onDrivesChanged: ((_ added: String?, _ removed: String?) -> Void)?

    init(queue: DispatchQueue) {
        self.queue = queue
    }

    deinit {
        for drive in drives.values { IOObjectRelease(drive.service) }
        if addedIterator != 0 { IOObjectRelease(addedIterator) }
        if removedIterator != 0 { IOObjectRelease(removedIterator) }
        if let port = notifyPort { IONotificationPortDestroy(port) }
    }

    var driveNames: [String] { drives.values.map(\.name).sorted() }

    func start() {
        guard notifyPort == nil, let port = IONotificationPortCreate(kIOMainPortDefault) else { return }
        notifyPort = port
        IONotificationPortSetDispatchQueue(port, queue)
        let context = Unmanaged.passUnretained(self).toOpaque()

        IOServiceAddMatchingNotification(
            port, kIOFirstMatchNotification, IOServiceMatching("IOBlockStorageDriver"),
            { refcon, iterator in
                guard let refcon else { return }
                Unmanaged<DiskMonitor>.fromOpaque(refcon).takeUnretainedValue().drainAdded(iterator)
            },
            context, &addedIterator
        )
        IOServiceAddMatchingNotification(
            port, kIOTerminatedNotification, IOServiceMatching("IOBlockStorageDriver"),
            { refcon, iterator in
                guard let refcon else { return }
                Unmanaged<DiskMonitor>.fromOpaque(refcon).takeUnretainedValue().drainRemoved(iterator)
            },
            context, &removedIterator
        )
        // Draining the iterators enumerates the drives present now and arms the notifications.
        drainAdded(addedIterator)
        drainRemoved(removedIterator)
    }

    /// Returns the I/O done across all tracked drives since the previous call.
    /// The first reading of a drive only sets its baseline.
    func poll() -> DiskCounters {
        var total = DiskCounters()
        for (id, drive) in drives {
            guard let current = Self.readCounters(drive.service) else { continue }
            if let last = drive.last {
                total += current.delta(since: last)
            }
            drives[id]?.last = current
        }
        return total
    }

    /// Forgets the previous readings, so the next poll reports no activity.
    /// Used after sleep or a long pause so stale deltas don't play as a burst.
    func resetBaselines() {
        for id in drives.keys { drives[id]?.last = nil }
    }

    // MARK: - Drive tracking

    private func drainAdded(_ iterator: io_iterator_t) {
        while case let service = IOIteratorNext(iterator), service != 0 {
            if Self.isDiskImage(service) {
                IOObjectRelease(service)
                continue
            }
            var id: UInt64 = 0
            IORegistryEntryGetRegistryEntryID(service, &id)
            let name = Self.bsdName(service) ?? "drive-\(id)"
            if let old = drives[id] { IOObjectRelease(old.service) }
            // Keep the reference returned by the iterator; released on removal.
            drives[id] = Drive(service: service, name: name, last: nil)
            onDrivesChanged?(name, nil)
        }
    }

    private func drainRemoved(_ iterator: io_iterator_t) {
        while case let service = IOIteratorNext(iterator), service != 0 {
            var id: UInt64 = 0
            IORegistryEntryGetRegistryEntryID(service, &id)
            if let drive = drives.removeValue(forKey: id) {
                IOObjectRelease(drive.service)
                onDrivesChanged?(nil, drive.name)
            }
            IOObjectRelease(service)
        }
    }

    // MARK: - IOKit helpers

    private static func readCounters(_ service: io_service_t) -> DiskCounters? {
        guard
            let value = IORegistryEntryCreateCFProperty(service, "Statistics" as CFString, kCFAllocatorDefault, 0)?
                .takeRetainedValue(),
            let stats = value as? [String: Any]
        else { return nil }
        func number(_ key: String) -> UInt64 { (stats[key] as? NSNumber)?.uint64Value ?? 0 }
        return DiskCounters(
            readOps: number("Operations (Read)"),
            writeOps: number("Operations (Write)"),
            readBytes: number("Bytes (Read)"),
            writeBytes: number("Bytes (Write)")
        )
    }

    /// True when the driver sits on a disk image (a mounted .dmg), whose
    /// I/O is also counted on the physical disk that holds the image file.
    private static func isDiskImage(_ service: io_service_t) -> Bool {
        var entry = service
        IOObjectRetain(entry)
        defer { IOObjectRelease(entry) }
        for _ in 0..<8 {
            var parent: io_registry_entry_t = 0
            guard IORegistryEntryGetParentEntry(entry, kIOServicePlane, &parent) == KERN_SUCCESS else { break }
            IOObjectRelease(entry)
            entry = parent
            if let cls = IOObjectCopyClass(entry)?.takeRetainedValue() as String?,
               cls.contains("DiskImage") || cls.contains("HDIX") {
                return true
            }
        }
        return false
    }

    /// The BSD name ("disk0") of the whole-disk media below the driver, for logs.
    private static func bsdName(_ service: io_service_t) -> String? {
        IORegistryEntrySearchCFProperty(
            service, kIOServicePlane, "BSD Name" as CFString, kCFAllocatorDefault,
            IOOptionBits(kIORegistryIterateRecursively)
        ) as? String
    }
}

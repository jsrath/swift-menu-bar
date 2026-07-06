import Foundation
import IOKit.ps

final class BatteryMonitor {
    private var task: Task<Void, Never>?
    private let onUpdate: @MainActor (BatteryState) -> Void

    init(onUpdate: @escaping @MainActor (BatteryState) -> Void) {
        self.onUpdate = onUpdate
    }

    func start() {
        publish()

        task = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                guard !Task.isCancelled else { return }
                publish()
            }
        }
    }

    func stop() {
        task?.cancel()
    }

    private func publish() {
        guard let state = Self.read() else { return }
        Task { @MainActor in onUpdate(state) }
    }

    private static func read() -> BatteryState? {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let rawSources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef]
        else { return nil }

        for source in rawSources {
            guard let description = IOPSGetPowerSourceDescription(snapshot, source)?
                .takeUnretainedValue() as? [String: Any],
                let capacity = description[kIOPSCurrentCapacityKey] as? Int,
                let maxCapacity = description[kIOPSMaxCapacityKey] as? Int,
                maxCapacity > 0
            else { continue }

            let isCharging = description[kIOPSIsChargingKey] as? Bool ?? false
            return BatteryState(percentage: (capacity * 100) / maxCapacity, isCharging: isCharging)
        }

        return nil
    }
}

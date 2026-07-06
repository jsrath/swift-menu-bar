import AppKit
import Foundation
import Observation

@Observable
@MainActor
final class BarStore {
    private(set) var spaces: [YabaiSpace] = []
    private(set) var sheetText = ""
    private(set) var battery: BatteryState?

    private let yabai = YabaiClient()
    private var currentSpaceIndex = 1
    private var refreshTask: Task<Void, Never>?
    private var spacesTask: Task<Void, Never>?
    private var sheetTask: Task<Void, Never>?
    private var batteryMonitor: BatteryMonitor?

    func start() {
        batteryMonitor = BatteryMonitor { [weak self] state in
            guard let self, state != battery else { return }
            battery = state
        }
        batteryMonitor?.start()

        Task { await refreshSpaces(force: true) }
        startSpacesLoop()
        startSheetLoop()
    }

    func stop() {
        refreshTask?.cancel()
        spacesTask?.cancel()
        sheetTask?.cancel()
        batteryMonitor?.stop()
    }

    func scheduleSpaceRefresh() {
        refreshTask?.cancel()
        refreshTask = Task {
            try? await Task.sleep(for: .milliseconds(50))
            guard !Task.isCancelled else { return }
            await refreshSpaces(force: true)
        }
    }

    func refreshSpaces(force: Bool = false) async {
        guard let snapshot = await yabai.snapshot() else { return }
        currentSpaceIndex = snapshot.currentSpaceIndex
        guard force || snapshot.spaces != spaces else { return }
        spaces = snapshot.spaces
    }

    func selectSpace(_ space: YabaiSpace) {
        guard !space.hasFocus else { return }

        let targetIndex = space.index
        let fromIndex = currentSpaceIndex

        Task(priority: .userInitiated) {
            await yabai.focus(space: targetIndex, from: fromIndex)
            await refreshSpaces(force: true)
        }
    }

    func refreshSheet() async {
        guard let url = Configuration.sheetURL,
              let text = await SheetClient.fetch(from: url),
              text != sheetText else { return }
        sheetText = text
    }

    func openCalendar() {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.iCal") else { return }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }

    private func startSpacesLoop() {
        spacesTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }
                await refreshSpaces()
            }
        }
    }

    private func startSheetLoop() {
        sheetTask = Task {
            while !Task.isCancelled {
                await refreshSheet()
                try? await Task.sleep(for: .seconds(Configuration.shared.sheetRefreshInterval))
            }
        }
    }
}

import AppKit
import Foundation
import Observation

@Observable
@MainActor
final class BarStore {
    private(set) var spaces: [YabaiSpace] = []
    private(set) var sheetText = ""
    private(set) var battery: BatteryState?
    private(set) var vpnSnapshot = VPNSnapshot.empty

    private let yabai = YabaiClient()
    private var currentSpaceIndex = 1
    private var refreshTask: Task<Void, Never>?
    private var spacesTask: Task<Void, Never>?
    private var sheetTask: Task<Void, Never>?
    private var batteryMonitor: BatteryMonitor?
    private var vpnMonitor: VPNMonitor?
    private var wasFullScreen = false

    /// Called when the bar should hide (yabai full-screen entered) or show (exited).
    var onFullScreenChanged: ((Bool) -> Void)?

    func start() {
        batteryMonitor = BatteryMonitor { [weak self] state in
            guard let self, state != battery else { return }
            battery = state
        }
        batteryMonitor?.start()

        vpnMonitor = VPNMonitor { [weak self] snapshot in
            guard let self, snapshot != vpnSnapshot else { return }
            vpnSnapshot = snapshot
        }
        vpnMonitor?.start()

        Task { await refreshSpaces(force: true) }
        startSpacesLoop()
        startSheetLoop()
    }

    func stop() {
        refreshTask?.cancel()
        spacesTask?.cancel()
        sheetTask?.cancel()
        batteryMonitor?.stop()
        vpnMonitor?.stop()
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

        // Detect yabai full-screen: the focused space has is-native-fullscreen
        let isFullScreen = snapshot.spaces.first(where: \.hasFocus)?.isNativeFullscreen ?? false
        if isFullScreen != wasFullScreen {
            wasFullScreen = isFullScreen
            onFullScreenChanged?(isFullScreen)
        }

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

    func selectVPN(_ name: String) {
        Task {
            if vpnSnapshot.status.connectionName == name {
                await ViscosityClient.disconnect(name)
            } else {
                await ViscosityClient.connect(name)
            }
            vpnMonitor?.refresh()
            vpnMonitor?.scheduleBurstRefresh()
        }
    }

    func openSitacPrefill() {
        SitacClient.openPrefilledForm()
    }

    func refreshVPN() {
        vpnMonitor?.refresh()
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

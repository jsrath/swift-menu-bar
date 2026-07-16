import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = BarStore()
    private var panelController: BarPanelController?
    private var sigusr1Source: DispatchSourceSignal?
    private var fullScreenObservers: [NSObjectProtocol] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let resourceURL = Bundle.main.resourceURL {
            Configuration.ensureInstalled(from: resourceURL.appendingPathComponent("config.example.json"))
        }

        NSApp.setActivationPolicy(.accessory)

        store.start()
        panelController = BarPanelController(store: store)
        panelController?.show()

        // Hide the bar when yabai enters full-screen, show when it exits.
        store.onFullScreenChanged = { [weak panelController] isFullScreen in
            if isFullScreen {
                panelController?.hideWindows()
            } else {
                panelController?.showWindows()
            }
        }

        installSignalHandler()
        YabaiClient.syncExternalBar()
        YabaiClient.configure(appPID: ProcessInfo.processInfo.processIdentifier)

        observeFullScreen()
    }

    func applicationWillTerminate(_ notification: Notification) {
        store.stop()
        YabaiClient.removeSignals()
        YabaiClient.resetExternalBar()
        panelController?.hide()
        sigusr1Source?.cancel()
        for observer in fullScreenObservers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func installSignalHandler() {
        signal(SIGUSR1, SIG_IGN)

        let source = DispatchSource.makeSignalSource(signal: SIGUSR1, queue: .main)
        source.setEventHandler { [weak self] in
            self?.store.scheduleSpaceRefresh()
            self?.store.refreshVPN()
        }
        source.resume()
        sigusr1Source = source
    }

    private func observeFullScreen() {
        // Hide the bar when an app enters full-screen so it doesn't overlay movies/games
        fullScreenObservers.append(
            NotificationCenter.default.addObserver(
                forName: NSWindow.willEnterFullScreenNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let self else { return }
                self.panelController?.hideWindows()
            }
        )

        // Show the bar again when leaving full-screen; the reveal controller will
        // handle hiding/ghosting on its own 0.1s poll cycle.
        fullScreenObservers.append(
            NotificationCenter.default.addObserver(
                forName: NSWindow.didExitFullScreenNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let self else { return }
                self.panelController?.showWindows()
            }
        )
    }
}

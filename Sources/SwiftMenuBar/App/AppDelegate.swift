import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = BarStore()
    private var panelController: BarPanelController?
    private var sigusr1Source: DispatchSourceSignal?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let resourceURL = Bundle.main.resourceURL {
            Configuration.ensureInstalled(from: resourceURL.appendingPathComponent("config.example.json"))
        }

        NSApp.setActivationPolicy(.accessory)

        store.start()
        panelController = BarPanelController(store: store)
        panelController?.show()

        installSignalHandler()
        YabaiClient.syncExternalBar()
        YabaiClient.configure(appPID: ProcessInfo.processInfo.processIdentifier)
    }

    func applicationWillTerminate(_ notification: Notification) {
        store.stop()
        YabaiClient.removeSignals()
        YabaiClient.resetExternalBar()
        panelController?.hide()
        sigusr1Source?.cancel()
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
}

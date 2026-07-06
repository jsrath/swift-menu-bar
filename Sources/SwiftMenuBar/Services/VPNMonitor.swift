import AppKit
import Foundation

final class VPNMonitor {
    private var pollTask: Task<Void, Never>?
    private var publishGeneration = 0
    private var workspaceObserver: NSObjectProtocol?
    private let onUpdate: @MainActor (VPNSnapshot) -> Void

    init(onUpdate: @escaping @MainActor (VPNSnapshot) -> Void) {
        self.onUpdate = onUpdate
    }

    func start() {
        publish()

        pollTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }
                publish()
            }
        }

        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  app.bundleIdentifier == "com.viscosityvpn.Viscosity" else { return }
            self?.publish()
            self?.scheduleBurstRefresh()
        }
    }

    func stop() {
        pollTask?.cancel()
        if let workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(workspaceObserver)
        }
    }

    func refresh() {
        publish()
    }

    /// Poll quickly after a connect/disconnect so we catch OS-menu changes and Viscosity state lag.
    func scheduleBurstRefresh() {
        Task {
            for delay in [0.5, 1.0, 2.0, 4.0] {
                try? await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled else { return }
                publish()
            }
        }
    }

    private func publish() {
        publishGeneration += 1
        let generation = publishGeneration

        Task {
            let snapshot = await ViscosityClient.snapshot()
            guard generation == publishGeneration else { return }
            await MainActor.run {
                onUpdate(snapshot)
            }
        }
    }
}

import AppKit
import SwiftUI

@MainActor
final class BarPanelController {
    private var windows: [BarWindow] = []
    private let store: BarStore
    private let revealController = MenuBarRevealController()

    init(store: BarStore) {
        self.store = store
    }

    func show() {
        hide()

        for screen in NSScreen.screens {
            let frame = menuBarFrame(for: screen)
            let window = makeWindow(for: screen, frame: frame)
            windows.append(window)
            window.orderFrontRegardless()
            window.setFrame(frame, display: true)
        }

        revealController.start(windows: windows)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    func hide() {
        revealController.stop()
        for window in windows {
            window.orderOut(nil)
            window.close()
        }
        windows.removeAll()
    }

    @objc private func screensChanged() {
        show()
    }

    private func menuBarFrame(for screen: NSScreen) -> NSRect {
        let screenFrame = screen.frame
        let menuBarHeight = screenFrame.maxY - screen.visibleFrame.maxY
        let barHeight = min(Configuration.barHeight, menuBarHeight)

        return NSRect(
            x: screenFrame.origin.x,
            y: screenFrame.maxY - barHeight,
            width: screenFrame.width,
            height: barHeight
        )
    }

    private func makeWindow(for screen: NSScreen, frame: NSRect) -> BarWindow {
        let window = BarWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )

        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.statusWindow)) + 1)
        window.backgroundColor = Theme.nsBackground
        window.isOpaque = true
        window.hasShadow = false
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        window.hidesOnDeactivate = false
        window.isMovable = false
        window.isMovableByWindowBackground = false
        window.acceptsMouseMovedEvents = true

        let hostingView = ClickableHostingView(rootView: BarView(store: store))
        hostingView.frame = NSRect(origin: .zero, size: frame.size)
        hostingView.autoresizingMask = [.width, .height]

        if #available(macOS 14.0, *) {
            hostingView.safeAreaRegions = []
        }
        if #available(macOS 13.0, *) {
            hostingView.sizingOptions = []
        }

        window.contentView = hostingView
        window.setFrame(frame, display: true)

        return window
    }
}

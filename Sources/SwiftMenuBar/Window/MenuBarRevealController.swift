import AppKit
import QuartzCore

/// Hides the custom bar at the screen's top edge so the native auto-reveal menu bar
/// can draw on top. The bar stays in the menu-bar slot at all other times.
@MainActor
final class MenuBarRevealController {
    private var windows: [NSWindow] = []
    private var timer: Timer?
    private var isHiddenForReveal = false
    private var nativeMenuEngaged = false
    private var triggerZoneEnteredAt: Date?

    private let triggerZone: CGFloat = 4
    private let dwellDuration: TimeInterval = 0.3
    private let revealAnimationDuration: TimeInterval = 0.25
    private let pollInterval: TimeInterval = 0.1

    func start(windows: [NSWindow]) {
        self.windows = windows
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.update() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        setHiddenForReveal(false, animated: false)
        nativeMenuEngaged = false
        triggerZoneEnteredAt = nil
        windows = []
    }

    private func update() {
        let location = NSEvent.mouseLocation

        for window in windows {
            guard let screen = window.screen else { continue }
            let screenTop = screen.frame.maxY
            let menuBarHeight = screenTop - screen.visibleFrame.maxY

            let inTriggerZone = location.y >= screenTop - triggerZone
                && location.x >= screen.frame.minX
                && location.x <= screen.frame.maxX

            let inMenuBarStrip = location.y >= screenTop - menuBarHeight
                && location.x >= screen.frame.minX
                && location.x <= screen.frame.maxX

            if inTriggerZone {
                if triggerZoneEnteredAt == nil {
                    triggerZoneEnteredAt = Date()
                }
                if let enteredAt = triggerZoneEnteredAt,
                   Date().timeIntervalSince(enteredAt) >= dwellDuration {
                    nativeMenuEngaged = true
                }
            } else if !inMenuBarStrip {
                nativeMenuEngaged = false
                triggerZoneEnteredAt = nil
            } else if !nativeMenuEngaged {
                triggerZoneEnteredAt = nil
            }

            setHiddenForReveal(nativeMenuEngaged && inMenuBarStrip)
            return
        }
    }

    private func setHiddenForReveal(_ hidden: Bool, animated: Bool = true) {
        guard hidden != isHiddenForReveal else { return }
        isHiddenForReveal = hidden

        guard animated else {
            for window in windows {
                window.ignoresMouseEvents = hidden
                window.alphaValue = hidden ? 0 : 1
            }
            return
        }

        if hidden {
            for window in windows {
                window.ignoresMouseEvents = true
            }
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = revealAnimationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            for window in windows {
                window.animator().alphaValue = hidden ? 0 : 1
            }
        } completionHandler: {
            Task { @MainActor [weak self] in
                guard let self, !hidden else { return }
                for window in windows {
                    window.ignoresMouseEvents = false
                }
            }
        }
    }
}

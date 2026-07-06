import AppKit
import Foundation

@MainActor
final class VPNMenuTarget: NSObject {
    static let shared = VPNMenuTarget()

    var onSelect: ((String) -> Void)?

    @objc func selected(_ sender: NSMenuItem) {
        guard let name = sender.representedObject as? String else { return }
        onSelect?(name)
    }
}

@MainActor
enum VPNMenuPresenter {
    static func show(
        connections: [ViscosityConnection],
        from anchorView: NSView,
        onSelect: @escaping (String) -> Void
    ) {
        guard !connections.isEmpty else { return }

        let menu = NSMenu()
        for connection in connections {
            let item = NSMenuItem(
                title: connection.name,
                action: #selector(VPNMenuTarget.selected(_:)),
                keyEquivalent: ""
            )
            item.target = VPNMenuTarget.shared
            item.representedObject = connection.name
            item.state = connection.isConnected ? .on : .off
            menu.addItem(item)
        }

        VPNMenuTarget.shared.onSelect = onSelect

        // Measure the button at click time. In our flipped anchor view, maxY is the bottom edge.
        let point = NSPoint(x: anchorView.bounds.minX, y: anchorView.bounds.maxY + 2)
        menu.popUp(positioning: nil, at: point, in: anchorView)
    }
}

import AppKit
import SwiftUI

/// A transparent view that matches its SwiftUI layout size and can be used as a menu anchor.
struct ViewAnchorReader: NSViewRepresentable {
    @Binding var anchorView: NSView?

    func makeNSView(context: Context) -> MenuAnchorView {
        let view = MenuAnchorView()
        view.onAttach = { anchorView = $0 }
        return view
    }

    func updateNSView(_ nsView: MenuAnchorView, context: Context) {
        nsView.onAttach = { anchorView = $0 }
    }
}

/// Flipped to match SwiftUI coordinates: origin top-left, y grows downward.
final class MenuAnchorView: NSView {
    var onAttach: ((NSView) -> Void)?

    override var isFlipped: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        onAttach?(self)
    }

    override func layout() {
        super.layout()
        onAttach?(self)
    }
}

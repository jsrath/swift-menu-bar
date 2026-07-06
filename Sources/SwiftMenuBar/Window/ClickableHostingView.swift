import AppKit
import SwiftUI

/// Accepts the first mouse click without requiring the window to be activated first.
final class ClickableHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

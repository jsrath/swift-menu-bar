import AppKit
import SwiftUI

enum Theme {
    static let background = colorHex(0x0f0f0f)
    static let foreground = colorHex(0xf5f5f5)
    static let green = colorHex(0x8fc8BB)
    static let fireWidget = colorHex(0xEBCB8B)
    static let barOpacity = 1.0
    static let buttonRadius: CGFloat = 4
    static let buttonBorderWidth: CGFloat = 1

    static var nsBackground: NSColor {
        NSColor(red: 15 / 255, green: 15 / 255, blue: 15 / 255, alpha: 1)
    }
}

enum AppFont {
    static func primary(size: CGFloat) -> Font {
        let name = Configuration.shared.fontName
        if NSFont(name: name, size: size) != nil {
            return .custom(name, size: size)
        }
        return .system(size: size)
    }
}

private func colorHex(_ hex: UInt32) -> Color {
    Color(
        red: Double((hex >> 16) & 0xff) / 255,
        green: Double((hex >> 8) & 0xff) / 255,
        blue: Double(hex & 0xff) / 255
    )
}

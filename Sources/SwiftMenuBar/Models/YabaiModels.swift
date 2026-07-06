import Foundation

struct YabaiSpace: Codable, Identifiable, Equatable, Sendable {
    let id: Int
    let index: Int
    let label: String
    let display: Int
    let windows: [Int]
    let hasFocus: Bool
    let isVisible: Bool
    let isNativeFullscreen: Bool
    let firstWindow: Int?
    let lastWindow: Int?

    enum CodingKeys: String, CodingKey {
        case id, index, label, display, windows
        case hasFocus = "has-focus"
        case isVisible = "is-visible"
        case isNativeFullscreen = "is-native-fullscreen"
        case firstWindow = "first-window"
        case lastWindow = "last-window"
    }

    var trimmedLabel: String {
        label.trimmingCharacters(in: .whitespaces)
    }
}

struct YabaiDisplay: Codable, Equatable, Sendable {
    let id: Int
    let index: Int
    let hasFocus: Bool

    enum CodingKeys: String, CodingKey {
        case id, index
        case hasFocus = "has-focus"
    }
}

struct BatteryState: Equatable, Sendable {
    let percentage: Int
    let isCharging: Bool
}

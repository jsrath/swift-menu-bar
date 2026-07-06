import CoreGraphics
import Foundation

struct UserConfiguration: Codable, Sendable {
    var yabaiPath: String
    var sheetURL: String?
    var sheetRefreshInterval: TimeInterval
    var fontName: String
    var fontSize: Double
    var barHeight: Double

    static let `default` = UserConfiguration(
        yabaiPath: "/opt/homebrew/bin/yabai",
        sheetURL: nil,
        sheetRefreshInterval: 600,
        fontName: "Roboto",
        fontSize: 12,
        barHeight: 29
    )
}

enum Configuration {
    static let shared: UserConfiguration = load()

    static let signalLabel = "swift-menu-bar"
    static let legacySignalLabels = ["jeremy-menu-bar", "swift-menu-bar"]

    static var barHeight: CGFloat { CGFloat(shared.barHeight) }
    static var fontSize: CGFloat { CGFloat(shared.fontSize) }

    static var sheetURL: URL? {
        guard let string = shared.sheetURL else { return nil }
        return URL(string: string)
    }

    private static var configURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("SwiftMenuBar/config.json")
    }

    private static func load() -> UserConfiguration {
        let url = configURL
        guard let data = try? Data(contentsOf: url),
              let config = try? JSONDecoder().decode(UserConfiguration.self, from: data) else {
            return .default
        }
        return config
    }

    static func ensureInstalled(from exampleURL: URL) {
        let destination = configURL
        guard !FileManager.default.fileExists(atPath: destination.path) else { return }

        let directory = destination.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        if FileManager.default.fileExists(atPath: exampleURL.path) {
            try? FileManager.default.copyItem(at: exampleURL, to: destination)
        } else if let data = try? JSONEncoder().encode(UserConfiguration.default) {
            try? data.write(to: destination)
        }
    }
}

import Foundation

enum SheetClient {
    private static let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 15
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }()

    static func fetch(from url: URL) async -> String? {
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        guard let (data, _) = try? await session.data(for: request),
              let text = String(data: data, encoding: .utf8),
              !text.hasPrefix("<") else {
            return nil
        }

        return text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: " | ")
    }
}

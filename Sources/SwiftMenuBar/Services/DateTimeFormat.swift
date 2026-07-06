import Foundation

enum DateTimeFormat {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.setLocalizedDateFormatFromTemplate("EEEMMMd jm")
        return formatter
    }()

    static func string(from date: Date) -> String {
        formatter.string(from: date).replacingOccurrences(of: " at ", with: ", ")
    }
}

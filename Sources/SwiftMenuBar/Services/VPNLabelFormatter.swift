import Foundation

enum VPNLabelFormatter {
    static func initials(for name: String) -> String {
        guard !name.isEmpty else { return "" }

        if name == name.uppercased(), name.allSatisfy(\.isLetter) {
            return String(name.prefix(1))
        }

        return name
            .split { $0 == "-" || $0 == "_" || $0.isWhitespace }
            .filter { !$0.isEmpty }
            .map { String($0.prefix(1)).uppercased() }
            .joined()
    }
}

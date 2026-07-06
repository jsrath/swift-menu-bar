import Foundation

enum ProcessRunner {
    enum Error: Swift.Error {
        case launchFailed
        case nonZeroExit
        case invalidOutput
    }

    @discardableResult
    static func run(
        executable: URL,
        arguments: [String] = [],
        allowEmptyOutput: Bool = false
    ) throws -> Data {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else { throw Error.nonZeroExit }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard allowEmptyOutput || !data.isEmpty else { throw Error.invalidOutput }
        return data
    }

    static func runText(executable: URL, arguments: [String] = []) throws -> String {
        let data = try run(executable: executable, arguments: arguments)
        guard let text = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !text.isEmpty else {
            throw Error.invalidOutput
        }
        return text
    }
}

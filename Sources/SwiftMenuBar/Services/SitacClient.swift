import Foundation
import OSLog

enum SitacClient {
    private static let python = URL(
        fileURLWithPath: "/Users/jeremy/Library/CloudStorage/Dropbox/personal/residence/.venv/bin/python3"
    )
    private static let prefillScript = URL(
        fileURLWithPath: "/Users/jeremy/Library/CloudStorage/Dropbox/personal/residence/colombia/digital-nomad-2026/scripts/check-sitac-status.py"
    )
    private static let logDirectory = URL(
        fileURLWithPath: NSHomeDirectory()
    ).appendingPathComponent("Library/Logs/SwiftMenuBar", isDirectory: true)
    private static let logFile = logDirectory.appendingPathComponent("sitac-prefill.log")
    private static let logger = Logger(subsystem: "dev.swift-menu-bar", category: "sitac")
    private static let queue = DispatchQueue(label: "dev.swift-menu-bar.sitac")

    /// Retained so Foundation does not tear down the child when the caller returns.
    private static var runningProcess: Process?

    static func openPrefilledForm() {
        queue.async {
            if runningProcess?.isRunning == true {
                // Second click: short-lived process focuses the live session (no kill).
                _ = launchProcess(trackAsPrimary: false)
                return
            }
            _ = launchProcess(trackAsPrimary: true)
        }
    }

    @discardableResult
    private static func launchProcess(trackAsPrimary: Bool) -> Process? {
        prepareLogFile()

        let process = Process()
        process.executableURL = python
        process.arguments = [prefillScript.path(), "--prefill-only"]

        guard let output = appendHandle() else {
            logger.error("Could not open sitac-prefill.log for writing")
            return nil
        }
        process.standardOutput = output
        process.standardError = output

        process.terminationHandler = { finished in
            try? (finished.standardOutput as? FileHandle)?.close()
            queue.async {
                if runningProcess === finished {
                    runningProcess = nil
                }
            }
            let status = finished.terminationStatus
            if status != 0 {
                appendLog("prefill exited with status \(status)\n")
                logger.error("SITAC prefill exited with status \(status, privacy: .public) — see \(logFile.path, privacy: .public)")
            }
        }

        do {
            appendLog("--- launch \(ISO8601DateFormatter().string(from: Date())) ---\n")
            try process.run()
            if trackAsPrimary {
                runningProcess = process
            }
            return process
        } catch {
            appendLog("failed to launch prefill: \(error)\n")
            logger.error("SITAC prefill launch failed: \(String(describing: error), privacy: .public)")
            try? output.close()
            return nil
        }
    }

    private static func prepareLogFile() {
        try? FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true)
        if !FileManager.default.fileExists(atPath: logFile.path) {
            FileManager.default.createFile(atPath: logFile.path, contents: nil)
        }
    }

    private static func appendHandle() -> FileHandle? {
        prepareLogFile()
        guard let handle = try? FileHandle(forWritingTo: logFile) else { return nil }
        handle.seekToEndOfFile()
        return handle
    }

    private static func appendLog(_ message: String) {
        guard let handle = appendHandle() else { return }
        defer { try? handle.close() }
        if let data = message.data(using: .utf8) {
            handle.write(data)
        }
    }
}

import Foundation

struct VPNStatus: Equatable, Sendable {
    let connectionName: String?
    let label: String?
    let showsIndicator: Bool

    static let disconnected = VPNStatus(connectionName: nil, label: nil, showsIndicator: false)
}

enum ViscosityClient {
    private static let connectionsScript = """
    tell application "Viscosity"
        set output to ""
        repeat with conn in connections
            set output to output & name of conn & tab & state of conn & linefeed
        end repeat
        return output
    end tell
    """

    static func snapshot() async -> VPNSnapshot {
        let connections = await fetchConnections()
        guard let connected = connections.first(where: \.isConnected) else {
            return VPNSnapshot(status: .disconnected, connections: connections)
        }

        return VPNSnapshot(
            status: VPNStatus(
                connectionName: connected.name,
                label: VPNLabelFormatter.initials(for: connected.name),
                showsIndicator: isTrackedConnection(connected.name)
            ),
            connections: connections
        )
    }

    static func connect(_ name: String) async {
        await runViscosityCommand("connect", name: name)
    }

    static func disconnect(_ name: String) async {
        await runViscosityCommand("disconnect", name: name)
    }

    private static func fetchConnections() async -> [ViscosityConnection] {
        let executable = URL(fileURLWithPath: "/usr/bin/osascript")
        let args = ["-e", connectionsScript]

        let data = await Task.detached(priority: .utility) {
            try? ProcessRunner.run(executable: executable, arguments: args, allowEmptyOutput: true)
        }.value

        guard let data,
              let text = String(data: data, encoding: .utf8) else {
            return []
        }

        return text
            .split(whereSeparator: \.isNewline)
            .compactMap { line in
                let parts = line.split(separator: "\t", maxSplits: 1).map(String.init)
                guard parts.count == 2 else { return nil }
                let state = parts[1]
                let isConnected = state == "Connected" || state == "Connecting"
                return ViscosityConnection(name: parts[0], isConnected: isConnected)
            }
    }

    private static func runViscosityCommand(_ command: String, name: String) async {
        let escapedName = name.replacingOccurrences(of: "\"", with: "\\\"")
        let script = "tell application \"Viscosity\" to \(command) \"\(escapedName)\""
        let executable = URL(fileURLWithPath: "/usr/bin/osascript")

        _ = await Task.detached(priority: .userInitiated) {
            try? ProcessRunner.run(
                executable: executable,
                arguments: ["-e", script],
                allowEmptyOutput: true
            )
        }.value
    }

    private static func isTrackedConnection(_ name: String) -> Bool {
        if name == "NFL" { return true }
        if name.hasPrefix("chalkboard") { return true }
        return false
    }
}

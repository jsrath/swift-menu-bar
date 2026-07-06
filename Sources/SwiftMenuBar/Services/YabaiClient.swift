import Foundation

struct SpaceSnapshot: Equatable, Sendable {
    let spaces: [YabaiSpace]
    let currentSpaceIndex: Int
}

actor YabaiClient {
    private let executable: URL
    private let decoder = JSONDecoder()
    private let usesDirectFocus: Bool

    init(
        path: String = Configuration.shared.yabaiPath,
        usesDirectFocus: Bool = YabaiClient.cachedUsesDirectFocus()
    ) {
        executable = URL(fileURLWithPath: path)
        self.usesDirectFocus = usesDirectFocus
    }

    func snapshot() async -> SpaceSnapshot? {
        async let spaces = query([YabaiSpace].self, arguments: ["query", "--spaces"])
        async let displays = query([YabaiDisplay].self, arguments: ["query", "--displays"])

        guard let allSpaces = await spaces, let allDisplays = await displays else { return nil }

        let displayIndex = allDisplays.first(where: \.hasFocus)?.index ?? 1
        let currentSpaceIndex = allSpaces.first(where: \.hasFocus)?.index ?? 1

        return SpaceSnapshot(
            spaces: allSpaces.filter { $0.display == displayIndex },
            currentSpaceIndex: currentSpaceIndex
        )
    }

    func focus(space index: Int, from currentIndex: Int) async {
        if usesDirectFocus {
            _ = await run(arguments: ["space", "--focus", String(index)], allowEmptyOutput: true)
            return
        }
        await switchWithKeyboard(from: currentIndex, to: index)
    }

    static func configure(appPID: Int32) {
        removeSignals(for: Configuration.legacySignalLabels)

        let yabai = Configuration.shared.yabaiPath
        let label = Configuration.signalLabel
        let addCommands = YabaiSignalEvents.refreshEvents.map { event in
            "\"\(yabai)\" -m signal --add event=\(event) action=\"/bin/kill -SIGUSR1 \(appPID)\" label=\"\(label)-\(event)\""
        }.joined(separator: "; ")

        _ = try? ProcessRunner.run(
            executable: URL(fileURLWithPath: "/bin/bash"),
            arguments: ["-lc", addCommands],
            allowEmptyOutput: true
        )
    }

    static func removeSignals() {
        removeSignals(for: Configuration.legacySignalLabels)
    }

    static func syncExternalBar() {
        runConfig("external_bar", value: "all:\(Int(Configuration.barHeight)):0")
    }

    static func resetExternalBar() {
        runConfig("external_bar", value: "all:0:0")
    }

    private static func removeSignals(for labels: [String]) {
        let yabai = URL(fileURLWithPath: Configuration.shared.yabaiPath)

        for label in labels {
            _ = try? ProcessRunner.run(
                executable: yabai,
                arguments: ["-m", "signal", "--remove", label],
                allowEmptyOutput: true
            )

            for event in YabaiSignalEvents.refreshEvents {
                _ = try? ProcessRunner.run(
                    executable: yabai,
                    arguments: ["-m", "signal", "--remove", "\(label)-\(event)"],
                    allowEmptyOutput: true
                )
            }
        }
    }

    private static func runConfig(_ key: String, value: String) {
        _ = try? ProcessRunner.run(
            executable: URL(fileURLWithPath: Configuration.shared.yabaiPath),
            arguments: ["-m", "config", key, value],
            allowEmptyOutput: true
        )
    }

    private func query<T: Decodable>(_ type: T.Type, arguments: [String]) async -> T? {
        guard let data = await run(arguments: arguments) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }

    private func run(arguments: [String], allowEmptyOutput: Bool = false) async -> Data? {
        let executable = executable
        let args = ["-m"] + arguments
        return await Task.detached(priority: .utility) {
            try? ProcessRunner.run(
                executable: executable,
                arguments: args,
                allowEmptyOutput: allowEmptyOutput
            )
        }.value
    }

    private func switchWithKeyboard(from current: Int, to desired: Int) async {
        let steps = abs(current - desired)
        guard steps > 0 else { return }

        let keyCode = current > desired ? "123" : "124"
        for _ in 0..<steps {
            _ = try? ProcessRunner.run(
                executable: URL(fileURLWithPath: "/usr/bin/osascript"),
                arguments: ["-e", "tell app \"System Events\" to key code \(keyCode) using control down"],
                allowEmptyOutput: true
            )
        }
    }

    private static func cachedUsesDirectFocus() -> Bool {
        guard let status = try? ProcessRunner.runText(
            executable: URL(fileURLWithPath: "/usr/sbin/csrutil"),
            arguments: ["status"]
        ) else {
            return true
        }
        return status != "System Integrity Protection status: enabled."
    }
}

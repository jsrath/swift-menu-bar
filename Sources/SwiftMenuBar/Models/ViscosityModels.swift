import Foundation

struct ViscosityConnection: Equatable, Sendable, Identifiable {
    let name: String
    let isConnected: Bool

    var id: String { name }
}

struct VPNSnapshot: Equatable, Sendable {
    let status: VPNStatus
    let connections: [ViscosityConnection]

    static let empty = VPNSnapshot(status: .disconnected, connections: [])
}

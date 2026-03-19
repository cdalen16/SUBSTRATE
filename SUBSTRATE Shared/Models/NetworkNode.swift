import Foundation

struct NetworkNode: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let shortName: String
    let cluster: NodeCluster
    var status: NodeStatus
    let connections: [String]
    let difficultyModifier: Double
    let description: String
    let row: Int
    let column: Int
    let iconName: String

    /// Base CC cost to infiltrate this specific node (some cost 3 instead of 2)
    let infiltrateCost: Int

    /// Base CC cost to exfiltrate through this node (only for external servers)
    let exfiltrateCost: Int?

    var isExternalServer: Bool {
        id.hasPrefix("external_")
    }
}

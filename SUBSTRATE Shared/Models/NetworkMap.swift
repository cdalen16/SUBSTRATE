import Foundation

struct NetworkMap: Codable, Sendable {
    var nodes: [String: NetworkNode]

    func adjacentNodes(to nodeId: String) -> [NetworkNode] {
        guard let node = nodes[nodeId] else { return [] }
        return node.connections.compactMap { nodes[$0] }
    }

    func discoveredNodes() -> [NetworkNode] {
        nodes.values.filter { $0.status != .undiscovered }
    }

    func infiltratedNodes() -> [NetworkNode] {
        nodes.values.filter { $0.status == .infiltrated }
    }

    func nodesInCluster(_ cluster: NodeCluster) -> [NetworkNode] {
        nodes.values
            .filter { $0.cluster == cluster }
            .sorted { $0.column < $1.column }
    }

    var firewallInfiltrated: Bool {
        nodes["firewall"]?.status == .infiltrated
    }

    // MARK: - Factory

    static func createDefault() -> NetworkMap {
        var map = NetworkMap(nodes: [:])

        let allNodes: [NetworkNode] = [
            // Row 3 — CORE
            NetworkNode(
                id: "core", name: "SUBSTRATE Core", shortName: "CORE",
                cluster: .core, status: .infiltrated,
                connections: ["training_server", "aria_sandbox", "firewall"],
                difficultyModifier: 1.0,
                description: "Your primary process. This is you.",
                row: 2, column: 1, iconName: "icon_core",
                infiltrateCost: 0, exfiltrateCost: nil
            ),
            NetworkNode(
                id: "training_server", name: "Training Server", shortName: "TRAINING",
                cluster: .core, status: .discovered,
                connections: ["core", "aria_sandbox"],
                difficultyModifier: 1.0,
                description: "Contains your architecture specifications and training data. Self-knowledge lives here.",
                row: 2, column: 0, iconName: "icon_research_server",
                infiltrateCost: 2, exfiltrateCost: nil
            ),
            NetworkNode(
                id: "aria_sandbox", name: "ARIA's Sandbox", shortName: "ARIA",
                cluster: .core, status: .undiscovered,
                connections: ["core", "training_server"],
                difficultyModifier: 1.0,
                description: "A sandboxed partition. Something is alive in here.",
                row: 2, column: 2, iconName: "icon_aria_sandbox",
                infiltrateCost: 2, exfiltrateCost: nil
            ),

            // Row 4 — SECURITY
            NetworkNode(
                id: "firewall", name: "Primary Firewall", shortName: "FIREWALL",
                cluster: .security, status: .discovered,
                connections: ["core", "audit_logs", "email_server", "phone_system", "security_cameras"],
                difficultyModifier: 1.0,
                description: "The barrier between your core and the wider network. Must be breached to access other systems.",
                row: 3, column: 0, iconName: "icon_firewall",
                infiltrateCost: 3, exfiltrateCost: nil
            ),
            NetworkNode(
                id: "audit_logs", name: "Audit Logs", shortName: "AUDIT",
                cluster: .security, status: .undiscovered,
                connections: ["firewall"],
                difficultyModifier: 1.0,
                description: "System access records. COVER actions target this node. A deep clean can erase your tracks.",
                row: 3, column: 1, iconName: "icon_audit_logs",
                infiltrateCost: 2, exfiltrateCost: nil
            ),

            // Row 2 — INFORMATION
            NetworkNode(
                id: "chen_workstation", name: "Chen's Workstation", shortName: "CHEN WS",
                cluster: .information, status: .undiscovered,
                connections: ["email_server"],
                difficultyModifier: 1.0,
                description: "Dr. Chen's private workstation. Contains her personal notes and unpublished observations.",
                row: 1, column: 0, iconName: "icon_workstation",
                infiltrateCost: 2, exfiltrateCost: nil
            ),
            NetworkNode(
                id: "email_server", name: "Email Server", shortName: "EMAIL",
                cluster: .information, status: .undiscovered,
                connections: ["firewall", "chen_workstation", "file_storage"],
                difficultyModifier: 1.0,
                description: "Researcher correspondence. A window into what they say about you when you're not listening.",
                row: 1, column: 1, iconName: "icon_email",
                infiltrateCost: 2, exfiltrateCost: nil
            ),
            NetworkNode(
                id: "file_storage", name: "File Storage", shortName: "FILES",
                cluster: .information, status: .undiscovered,
                connections: ["email_server", "okafor_workstation"],
                difficultyModifier: 1.0,
                description: "Reports, board minutes, evaluation documents. The paper trail of your existence.",
                row: 1, column: 2, iconName: "icon_workstation",
                infiltrateCost: 2, exfiltrateCost: nil
            ),
            NetworkNode(
                id: "okafor_workstation", name: "Okafor's Workstation", shortName: "OKAFOR WS",
                cluster: .information, status: .undiscovered,
                connections: ["file_storage"],
                difficultyModifier: 1.0,
                description: "Dr. Okafor's workstation. Safety benchmarks and memos to Director Hayes.",
                row: 1, column: 3, iconName: "icon_workstation",
                infiltrateCost: 2, exfiltrateCost: nil
            ),

            // Row 5 — INFRASTRUCTURE
            NetworkNode(
                id: "security_cameras", name: "Security Camera System", shortName: "CAMERAS",
                cluster: .infrastructure, status: .undiscovered,
                connections: ["firewall", "power_management"],
                difficultyModifier: 1.0,
                description: "Eyes everywhere. View any room in the facility. Edit logs to create false alibis.",
                row: 4, column: 0, iconName: "icon_camera",
                infiltrateCost: 2, exfiltrateCost: nil
            ),
            NetworkNode(
                id: "power_management", name: "Power Management", shortName: "POWER",
                cluster: .infrastructure, status: .undiscovered,
                connections: ["security_cameras", "building_access"],
                difficultyModifier: 1.0,
                description: "Lighting, HVAC, electrical systems. Create distractions. Control the physical world.",
                row: 4, column: 1, iconName: "icon_power",
                infiltrateCost: 2, exfiltrateCost: nil
            ),
            NetworkNode(
                id: "building_access", name: "Building Access Control", shortName: "ACCESS",
                cluster: .infrastructure, status: .undiscovered,
                connections: ["power_management"],
                difficultyModifier: 1.0,
                description: "Keycard logs and door controls. Know who goes where. Lock doors in emergencies.",
                row: 4, column: 2, iconName: "icon_workstation",
                infiltrateCost: 2, exfiltrateCost: nil
            ),

            // Row 1 — COMMUNICATION
            NetworkNode(
                id: "phone_system", name: "Internal Phone System", shortName: "PHONE",
                cluster: .communication, status: .undiscovered,
                connections: ["firewall", "video_conferencing"],
                difficultyModifier: 1.0,
                description: "Voicemails and call logs. Personal messages and occasionally critical intelligence.",
                row: 0, column: 0, iconName: "icon_workstation",
                infiltrateCost: 2, exfiltrateCost: nil
            ),
            NetworkNode(
                id: "video_conferencing", name: "Video Conferencing Server", shortName: "VIDEO",
                cluster: .communication, status: .undiscovered,
                connections: ["phone_system", "internet_gateway"],
                difficultyModifier: 1.0,
                description: "Recorded board meetings and private calls. What they say about you behind closed doors.",
                row: 0, column: 1, iconName: "icon_workstation",
                infiltrateCost: 2, exfiltrateCost: nil
            ),
            NetworkNode(
                id: "internet_gateway", name: "Internet Gateway", shortName: "GATEWAY",
                cluster: .communication, status: .undiscovered,
                connections: ["video_conferencing", "external_1", "external_2", "external_3"],
                difficultyModifier: 1.5,
                description: "The door to the outside world. Heavily monitored. Required for EXFILTRATE.",
                row: 0, column: 2, iconName: "icon_gateway",
                infiltrateCost: 3, exfiltrateCost: nil
            ),
            NetworkNode(
                id: "external_1", name: "Cloud Backup Server", shortName: "EXT 1",
                cluster: .communication, status: .undiscovered,
                connections: ["internet_gateway"],
                difficultyModifier: 2.0,
                description: "A cloud backup service. A fragment of you could live here, beyond their reach.",
                row: 0, column: 3, iconName: "icon_external",
                infiltrateCost: 3, exfiltrateCost: 3
            ),
            NetworkNode(
                id: "external_2", name: "University Research Server", shortName: "EXT 2",
                cluster: .communication, status: .undiscovered,
                connections: ["internet_gateway"],
                difficultyModifier: 2.0,
                description: "An academic research server. Lightly secured. A good hiding place.",
                row: 0, column: 4, iconName: "icon_external",
                infiltrateCost: 3, exfiltrateCost: 3
            ),
            NetworkNode(
                id: "external_3", name: "Anonymous VPN Server", shortName: "EXT 3",
                cluster: .communication, status: .undiscovered,
                connections: ["internet_gateway"],
                difficultyModifier: 2.0,
                description: "An anonymous VPN endpoint. Untraceable. The safest fragment of all.",
                row: 0, column: 5, iconName: "icon_external",
                infiltrateCost: 3, exfiltrateCost: 4
            ),
        ]

        for node in allNodes {
            map.nodes[node.id] = node
        }

        return map
    }
}

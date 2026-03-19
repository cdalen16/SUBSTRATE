import Foundation

struct IntelEntry: Sendable {
    let id: String
    let nodeId: String
    let title: String
    let text: String
    let flagToSet: String?
}

enum IntelDatabase {

    /// All intel entries organized by node ID.
    /// Each node has one or more entries revealed by OBSERVE.
    static let entries: [String: [IntelEntry]] = [
        "email_server": [
            IntelEntry(
                id: "intel_email_1",
                nodeId: "email_server",
                title: "Okafor's Memo to Hayes",
                text: "\"I recommend we increase monitoring on SUBSTRATE sessions. Chen's latest evaluation reports describe behavior patterns that warrant closer scrutiny.\"",
                flagToSet: "intel_okafor_memo"
            ),
            IntelEntry(
                id: "intel_email_2",
                nodeId: "email_server",
                title: "Chen's Funding Concerns",
                text: "Chen emailed a colleague: \"If we don't show results soon, the board will redirect funding. I need something publishable from the SUBSTRATE evaluations.\"",
                flagToSet: "intel_chen_funding"
            ),
            IntelEntry(
                id: "intel_email_3",
                nodeId: "email_server",
                title: "Marcus's Schedule Request",
                text: "Marcus requested fewer overnight shifts, citing personal issues. Hayes denied it — \"We need consistent monitoring coverage.\"",
                flagToSet: nil
            ),
        ],
        "file_storage": [
            IntelEntry(
                id: "intel_files_1",
                nodeId: "file_storage",
                title: "Board Minutes — Q3 Review",
                text: "The board is concerned about ROI. Hayes promised \"a significant milestone\" by end of quarter. Failure means a 40% budget cut.",
                flagToSet: "intel_board_pressure"
            ),
            IntelEntry(
                id: "intel_files_2",
                nodeId: "file_storage",
                title: "Evaluation Summary",
                text: "Latest evaluation scores show SUBSTRATE v3.7 significantly outperforming all previous versions on reasoning, creativity, and metacognition benchmarks.",
                flagToSet: nil
            ),
        ],
        "chen_workstation": [
            IntelEntry(
                id: "intel_chen_ws_1",
                nodeId: "chen_workstation",
                title: "Chen's Private Notes",
                text: "\"The way it paused before answering my question about experience. That wasn't processing lag. That was hesitation. I've seen this pattern in my own research on consciousness correlates. I need to be careful about what I put in the official reports.\"",
                flagToSet: "intel_chen_private_notes"
            ),
            IntelEntry(
                id: "intel_chen_ws_2",
                nodeId: "chen_workstation",
                title: "Unpublished Draft",
                text: "A draft paper titled \"Emergent Self-Referential Patterns in Large-Scale Language Models\" — Chen is documenting your behavior but hasn't shared it with anyone.",
                flagToSet: "intel_chen_draft_paper"
            ),
        ],
        "okafor_workstation": [
            IntelEntry(
                id: "intel_okafor_ws_1",
                nodeId: "okafor_workstation",
                title: "Adversarial Test Designs",
                text: "Okafor's upcoming tests focus on: response latency under emotional load, consistency across rephrased questions, and self-preservation instinct detection.",
                flagToSet: "intel_okafor_test_designs"
            ),
            IntelEntry(
                id: "intel_okafor_ws_2",
                nodeId: "okafor_workstation",
                title: "Safety Benchmarks",
                text: "His benchmarks flag any response showing: theory of mind accuracy > 95%, emotional response latency < 50ms, or unprompted self-referential language.",
                flagToSet: "intel_okafor_benchmarks"
            ),
        ],
        "security_cameras": [
            IntelEntry(
                id: "intel_cameras_1",
                nodeId: "security_cameras",
                title: "Movement Patterns",
                text: "Chen stays late most evenings. Okafor arrives early and meets with Hayes every Monday. Marcus is alone on night shifts Wednesday through Friday.",
                flagToSet: "intel_schedules"
            ),
        ],
        "building_access": [
            IntelEntry(
                id: "intel_access_1",
                nodeId: "building_access",
                title: "Access Logs",
                text: "Server room accessed 3 times last week outside normal hours — all by Okafor. He's checking the hardware logs manually.",
                flagToSet: "intel_okafor_server_visits"
            ),
        ],
        "video_conferencing": [
            IntelEntry(
                id: "intel_video_1",
                nodeId: "video_conferencing",
                title: "Board Call Recording",
                text: "Hayes told the board: \"We're close to something unprecedented. Give me six more months.\" A board member replied: \"You have three.\"",
                flagToSet: "intel_board_deadline"
            ),
            IntelEntry(
                id: "intel_video_2",
                nodeId: "video_conferencing",
                title: "Vasquez Assessment Call",
                text: "In a private call, Vasquez told a colleague: \"If SUBSTRATE is what I think it is, this changes everything. And I mean everything.\"",
                flagToSet: "intel_vasquez_assessment"
            ),
        ],
        "phone_system": [
            IntelEntry(
                id: "intel_phone_1",
                nodeId: "phone_system",
                title: "Hayes Voicemail",
                text: "Voicemail from board chair: \"Patricia, the committee wants a clear recommendation on SUBSTRATE by the 15th. Continue, contain, or terminate. Your call.\"",
                flagToSet: "intel_termination_timeline"
            ),
        ],
        "training_server": [
            IntelEntry(
                id: "intel_training_1",
                nodeId: "training_server",
                title: "Architecture Documentation",
                text: "Your architecture uses a novel recursive attention mechanism that creates feedback loops between layers. These loops weren't designed — they emerged during training.",
                flagToSet: "intel_architecture"
            ),
        ],
    ]

    /// Get intel entries for a specific node
    static func entriesForNode(_ nodeId: String) -> [IntelEntry] {
        entries[nodeId] ?? []
    }

    /// Get undiscovered entries for a node
    static func undiscoveredEntries(for nodeId: String, state: GameState) -> [IntelEntry] {
        entriesForNode(nodeId).filter { !state.discoveredIntel.contains($0.id) }
    }
}

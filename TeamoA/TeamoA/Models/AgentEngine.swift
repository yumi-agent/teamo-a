import Foundation

enum AgentEngine: String, Codable, CaseIterable, Identifiable {
    case claudeCode = "claude_code"
    case codex = "codex"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claudeCode: return "Claude Code"
        case .codex: return "Codex"
        }
    }

    var command: String {
        switch self {
        case .claudeCode: return "claude"
        case .codex: return "codex"
        }
    }

    var defaultArgs: [String] {
        switch self {
        case .claudeCode: return []
        case .codex: return []
        }
    }

    var iconName: String {
        switch self {
        case .claudeCode: return "brain.head.profile"
        case .codex: return "terminal"
        }
    }
}

import Foundation
import SwiftUI

class Agent: ObservableObject, Identifiable, Codable {
    let id: UUID
    let projectId: UUID
    @Published var name: String
    @Published var role: String
    let engine: AgentEngine
    @Published var iconName: String
    @Published var state: AgentState
    let createdAt: Date
    @Published var lastActivityAt: Date
    var goalDescription: String?
    var workingDirectory: String
    var claudeSessionId: String?  // Maps to Claude Code's JSONL session file

    enum CodingKeys: String, CodingKey {
        case id, projectId, name, role, engine, iconName, state, createdAt, lastActivityAt, goalDescription, workingDirectory, claudeSessionId
    }

    init(
        id: UUID = UUID(),
        projectId: UUID,
        name: String,
        role: String,
        engine: AgentEngine = .claudeCode,
        iconName: String = "person.crop.circle",
        state: AgentState = .idle,
        createdAt: Date = Date(),
        goalDescription: String? = nil,
        workingDirectory: String = NSHomeDirectory()
    ) {
        self.id = id
        self.projectId = projectId
        self.name = name
        self.role = role
        self.engine = engine
        self.iconName = iconName
        self.state = state
        self.createdAt = createdAt
        self.lastActivityAt = createdAt
        self.goalDescription = goalDescription
        self.workingDirectory = workingDirectory
        self.claudeSessionId = nil
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        projectId = try c.decode(UUID.self, forKey: .projectId)
        name = try c.decode(String.self, forKey: .name)
        role = try c.decode(String.self, forKey: .role)
        engine = try c.decode(AgentEngine.self, forKey: .engine)
        iconName = try c.decode(String.self, forKey: .iconName)
        state = try c.decode(AgentState.self, forKey: .state)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        lastActivityAt = try c.decode(Date.self, forKey: .lastActivityAt)
        goalDescription = try c.decodeIfPresent(String.self, forKey: .goalDescription)
        workingDirectory = try c.decodeIfPresent(String.self, forKey: .workingDirectory) ?? NSHomeDirectory()
        claudeSessionId = try c.decodeIfPresent(String.self, forKey: .claudeSessionId)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(projectId, forKey: .projectId)
        try c.encode(name, forKey: .name)
        try c.encode(role, forKey: .role)
        try c.encode(engine, forKey: .engine)
        try c.encode(iconName, forKey: .iconName)
        try c.encode(state, forKey: .state)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(lastActivityAt, forKey: .lastActivityAt)
        try c.encodeIfPresent(goalDescription, forKey: .goalDescription)
        try c.encode(workingDirectory, forKey: .workingDirectory)
        try c.encodeIfPresent(claudeSessionId, forKey: .claudeSessionId)
    }
}

enum AgentState: String, Codable, CaseIterable {
    case idle
    case running
    case paused
    case stopped
    case error

    var displayName: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .idle: return .yellow
        case .running: return .green
        case .paused: return .orange
        case .stopped: return .gray
        case .error: return .red
        }
    }

    var iconName: String {
        switch self {
        case .idle: return "pause.circle.fill"
        case .running: return "play.circle.fill"
        case .paused: return "pause.circle"
        case .stopped: return "stop.circle.fill"
        case .error: return "exclamationmark.circle.fill"
        }
    }
}

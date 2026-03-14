import Foundation
import SwiftUI

class AgentSession: ObservableObject, Identifiable, Codable {
    let id: UUID
    let name: String
    let engine: AgentEngine
    let workingDirectory: String
    let createdAt: Date
    let backgroundColor: SessionColor

    @Published var state: SessionState
    @Published var lastActivityAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, engine, workingDirectory, createdAt, backgroundColor, state, lastActivityAt
    }

    init(
        id: UUID = UUID(),
        name: String,
        engine: AgentEngine,
        workingDirectory: String,
        backgroundColor: SessionColor = .blue,
        state: SessionState = .stopped,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.engine = engine
        self.workingDirectory = workingDirectory
        self.backgroundColor = backgroundColor
        self.state = state
        self.createdAt = createdAt
        self.lastActivityAt = createdAt
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        engine = try container.decode(AgentEngine.self, forKey: .engine)
        workingDirectory = try container.decode(String.self, forKey: .workingDirectory)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        backgroundColor = try container.decode(SessionColor.self, forKey: .backgroundColor)
        state = try container.decode(SessionState.self, forKey: .state)
        lastActivityAt = try container.decode(Date.self, forKey: .lastActivityAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(engine, forKey: .engine)
        try container.encode(workingDirectory, forKey: .workingDirectory)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(backgroundColor, forKey: .backgroundColor)
        try container.encode(state, forKey: .state)
        try container.encode(lastActivityAt, forKey: .lastActivityAt)
    }

    var elapsedTime: TimeInterval {
        Date().timeIntervalSince(createdAt)
    }

    var elapsedTimeFormatted: String {
        let elapsed = elapsedTime
        let hours = Int(elapsed) / 3600
        let minutes = (Int(elapsed) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

enum SessionColor: String, Codable, CaseIterable, Identifiable {
    case blue, purple, green, orange, red, pink, teal, indigo

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .blue: return .blue
        case .purple: return .purple
        case .green: return .green
        case .orange: return .orange
        case .red: return .red
        case .pink: return .pink
        case .teal: return .teal
        case .indigo: return .indigo
        }
    }

    var terminalBackground: NSColor {
        switch self {
        case .blue: return NSColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1.0)
        case .purple: return NSColor(red: 0.10, green: 0.05, blue: 0.15, alpha: 1.0)
        case .green: return NSColor(red: 0.03, green: 0.10, blue: 0.05, alpha: 1.0)
        case .orange: return NSColor(red: 0.12, green: 0.08, blue: 0.02, alpha: 1.0)
        case .red: return NSColor(red: 0.12, green: 0.03, blue: 0.03, alpha: 1.0)
        case .pink: return NSColor(red: 0.12, green: 0.05, blue: 0.08, alpha: 1.0)
        case .teal: return NSColor(red: 0.03, green: 0.10, blue: 0.10, alpha: 1.0)
        case .indigo: return NSColor(red: 0.05, green: 0.03, blue: 0.12, alpha: 1.0)
        }
    }
}

import Foundation
import SwiftUI

enum WorkspaceType: String, Codable, CaseIterable {
    case personal
    case team

    var displayName: String {
        switch self {
        case .personal: return "Personal"
        case .team: return "Team"
        }
    }

    var iconName: String {
        switch self {
        case .personal: return "person.fill"
        case .team: return "person.3.fill"
        }
    }

    var description: String {
        switch self {
        case .personal: return "For individual use with your own agents"
        case .team: return "Collaborate with multiple agents and team members"
        }
    }
}

class Workspace: ObservableObject, Identifiable, Codable {
    let id: UUID
    @Published var name: String
    @Published var workspaceType: WorkspaceType
    @Published var color: ProjectColor
    let workingDirectory: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, workspaceType, color, workingDirectory, createdAt
    }

    init(
        id: UUID = UUID(),
        name: String,
        workspaceType: WorkspaceType = .personal,
        color: ProjectColor = .blue,
        workingDirectory: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.workspaceType = workspaceType
        self.color = color
        self.workingDirectory = workingDirectory
        self.createdAt = createdAt
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        workspaceType = try c.decode(WorkspaceType.self, forKey: .workspaceType)
        color = try c.decode(ProjectColor.self, forKey: .color)
        workingDirectory = try c.decode(String.self, forKey: .workingDirectory)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(workspaceType, forKey: .workspaceType)
        try c.encode(color, forKey: .color)
        try c.encode(workingDirectory, forKey: .workingDirectory)
        try c.encode(createdAt, forKey: .createdAt)
    }
}

enum ProjectColor: String, Codable, CaseIterable, Identifiable {
    case pink, blue, green, purple, orange, red, teal, indigo

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .pink: return .pink
        case .blue: return .blue
        case .green: return .green
        case .purple: return .purple
        case .orange: return .orange
        case .red: return .red
        case .teal: return .teal
        case .indigo: return .indigo
        }
    }
}

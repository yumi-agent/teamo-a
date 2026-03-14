import Foundation
import SwiftUI

class Goal: ObservableObject, Identifiable, Codable {
    let id: UUID
    let projectId: UUID
    @Published var title: String
    @Published var description: String
    @Published var status: GoalStatus
    @Published var progress: Double
    let createdAt: Date
    @Published var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, projectId, title, description, status, progress, createdAt, updatedAt
    }

    init(
        id: UUID = UUID(),
        projectId: UUID,
        title: String,
        description: String = "",
        status: GoalStatus = .notStarted,
        progress: Double = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.projectId = projectId
        self.title = title
        self.description = description
        self.status = status
        self.progress = progress
        self.createdAt = createdAt
        self.updatedAt = createdAt
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        projectId = try c.decode(UUID.self, forKey: .projectId)
        title = try c.decode(String.self, forKey: .title)
        description = try c.decode(String.self, forKey: .description)
        status = try c.decode(GoalStatus.self, forKey: .status)
        progress = try c.decode(Double.self, forKey: .progress)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(projectId, forKey: .projectId)
        try c.encode(title, forKey: .title)
        try c.encode(description, forKey: .description)
        try c.encode(status, forKey: .status)
        try c.encode(progress, forKey: .progress)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(updatedAt, forKey: .updatedAt)
    }
}

enum GoalStatus: String, Codable, CaseIterable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case completed

    var displayName: String {
        switch self {
        case .notStarted: return "Not Started"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        }
    }

    var color: Color {
        switch self {
        case .notStarted: return .gray
        case .inProgress: return .blue
        case .completed: return .green
        }
    }

    var iconName: String {
        switch self {
        case .notStarted: return "circle"
        case .inProgress: return "circle.lefthalf.filled"
        case .completed: return "checkmark.circle.fill"
        }
    }
}

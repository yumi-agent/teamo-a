import Foundation
import SwiftUI

class Issue: ObservableObject, Identifiable, Codable {
    let id: UUID
    let projectId: UUID
    let goalId: UUID?
    let issueNumber: Int
    @Published var title: String
    @Published var description: String
    @Published var status: IssueStatus
    @Published var priority: IssuePriority
    @Published var assigneeId: UUID?
    @Published var assigneeName: String?
    let createdAt: Date
    @Published var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, projectId, goalId, issueNumber, title, description
        case status, priority, assigneeId, assigneeName, createdAt, updatedAt
    }

    init(
        id: UUID = UUID(),
        projectId: UUID,
        goalId: UUID? = nil,
        issueNumber: Int,
        title: String,
        description: String = "",
        status: IssueStatus = .todo,
        priority: IssuePriority = .medium,
        assigneeId: UUID? = nil,
        assigneeName: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.projectId = projectId
        self.goalId = goalId
        self.issueNumber = issueNumber
        self.title = title
        self.description = description
        self.status = status
        self.priority = priority
        self.assigneeId = assigneeId
        self.assigneeName = assigneeName
        self.createdAt = createdAt
        self.updatedAt = createdAt
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        projectId = try c.decode(UUID.self, forKey: .projectId)
        goalId = try c.decodeIfPresent(UUID.self, forKey: .goalId)
        issueNumber = try c.decode(Int.self, forKey: .issueNumber)
        title = try c.decode(String.self, forKey: .title)
        description = try c.decode(String.self, forKey: .description)
        status = try c.decode(IssueStatus.self, forKey: .status)
        priority = try c.decode(IssuePriority.self, forKey: .priority)
        assigneeId = try c.decodeIfPresent(UUID.self, forKey: .assigneeId)
        assigneeName = try c.decodeIfPresent(String.self, forKey: .assigneeName)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(projectId, forKey: .projectId)
        try c.encode(goalId, forKey: .goalId)
        try c.encode(issueNumber, forKey: .issueNumber)
        try c.encode(title, forKey: .title)
        try c.encode(description, forKey: .description)
        try c.encode(status, forKey: .status)
        try c.encode(priority, forKey: .priority)
        try c.encode(assigneeId, forKey: .assigneeId)
        try c.encode(assigneeName, forKey: .assigneeName)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(updatedAt, forKey: .updatedAt)
    }

    var issueTag: String {
        "TA-\(issueNumber)"
    }
}

enum IssueStatus: String, Codable, CaseIterable {
    case todo
    case inProgress = "in_progress"
    case blocked
    case done

    var displayName: String {
        switch self {
        case .todo: return "TODO"
        case .inProgress: return "IN PROGRESS"
        case .blocked: return "BLOCKED"
        case .done: return "DONE"
        }
    }

    var color: Color {
        switch self {
        case .todo: return .blue
        case .inProgress: return .orange
        case .blocked: return .red
        case .done: return .green
        }
    }

    var iconName: String {
        switch self {
        case .todo: return "circle"
        case .inProgress: return "circle.lefthalf.filled"
        case .blocked: return "xmark.circle"
        case .done: return "checkmark.circle.fill"
        }
    }
}

enum IssuePriority: String, Codable, CaseIterable {
    case critical, high, medium, low

    var displayName: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        }
    }
}

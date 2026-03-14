import Foundation
import SwiftUI

struct ActivityEvent: Identifiable, Codable {
    let id: UUID
    let projectId: UUID
    let agentName: String?
    let action: String
    let detail: String
    let timestamp: Date
    let issueTag: String?

    init(
        id: UUID = UUID(),
        projectId: UUID,
        agentName: String? = nil,
        action: String,
        detail: String = "",
        timestamp: Date = Date(),
        issueTag: String? = nil
    ) {
        self.id = id
        self.projectId = projectId
        self.agentName = agentName
        self.action = action
        self.detail = detail
        self.timestamp = timestamp
        self.issueTag = issueTag
    }

    var timeAgo: String {
        let interval = Date().timeIntervalSince(timestamp)
        let minutes = Int(interval / 60)
        if minutes < 1 { return "just now" }
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h ago" }
        let days = hours / 24
        return "\(days)d ago"
    }
}

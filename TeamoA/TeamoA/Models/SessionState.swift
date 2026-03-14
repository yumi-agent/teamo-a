import SwiftUI

enum SessionState: String, Codable {
    case running
    case idle
    case waiting
    case stopped

    var displayName: String {
        switch self {
        case .running: return "Running"
        case .idle: return "Idle"
        case .waiting: return "Waiting"
        case .stopped: return "Stopped"
        }
    }

    var color: Color {
        switch self {
        case .running: return .green
        case .idle: return .yellow
        case .waiting: return .orange
        case .stopped: return .gray
        }
    }

    var iconName: String {
        switch self {
        case .running: return "play.circle.fill"
        case .idle: return "pause.circle.fill"
        case .waiting: return "questionmark.circle.fill"
        case .stopped: return "stop.circle.fill"
        }
    }
}

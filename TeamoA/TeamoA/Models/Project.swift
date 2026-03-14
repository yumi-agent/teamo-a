import Foundation
import SwiftUI

class Project: ObservableObject, Identifiable, Codable {
    let id: UUID
    @Published var name: String
    @Published var color: ProjectColor
    let workingDirectory: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, color, workingDirectory, createdAt
    }

    init(
        id: UUID = UUID(),
        name: String,
        color: ProjectColor = .blue,
        workingDirectory: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.workingDirectory = workingDirectory
        self.createdAt = createdAt
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        color = try c.decode(ProjectColor.self, forKey: .color)
        workingDirectory = try c.decode(String.self, forKey: .workingDirectory)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
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

import SwiftUI

struct EngineIcon: View {
    let engine: AgentEngine
    var size: CGFloat = 16

    var body: some View {
        Image(systemName: engine.iconName)
            .font(.system(size: size))
            .foregroundColor(engineColor)
    }

    private var engineColor: Color {
        switch engine {
        case .claudeCode: return .orange
        case .codex: return .cyan
        }
    }
}

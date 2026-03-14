import SwiftUI

struct SessionCard: View {
    @ObservedObject var session: AgentSession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Color bar + header
            HStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(session.backgroundColor.color)
                    .frame(width: 4, height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(session.name)
                        .font(.headline)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        EngineIcon(engine: session.engine, size: 12)
                        Text(session.engine.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                StatusBadge(state: session.state)
            }

            Divider()

            // Details
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label {
                        Text(shortPath(session.workingDirectory))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } icon: {
                        Image(systemName: "folder")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Label {
                        Text(session.elapsedTimeFormatted)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } icon: {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.background)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(session.state == .waiting ? Color.orange.opacity(0.5) : Color.clear, lineWidth: 2)
        )
    }

    private func shortPath(_ path: String) -> String {
        let home = NSHomeDirectory()
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}

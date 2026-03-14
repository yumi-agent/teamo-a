import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @Binding var selectedSessionId: UUID?
    @Binding var showCreateSheet: Bool

    var body: some View {
        List(selection: $selectedSessionId) {
            // Dashboard link
            NavigationLink(value: nil as UUID?) {
                Label("Dashboard", systemImage: "square.grid.2x2")
            }

            Section("Active") {
                ForEach(activeSessions) { session in
                    NavigationLink(value: session.id) {
                        SidebarSessionRow(session: session)
                    }
                }
            }

            if !stoppedSessions.isEmpty {
                Section("Stopped") {
                    ForEach(stoppedSessions) { session in
                        NavigationLink(value: session.id) {
                            SidebarSessionRow(session: session)
                        }
                    }
                    .onDelete { indexSet in
                        let toRemove = indexSet.map { stoppedSessions[$0] }
                        toRemove.forEach { sessionStore.removeSession($0) }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItem {
                Button(action: { showCreateSheet = true }) {
                    Image(systemName: "plus")
                }
                .help("New Session (Cmd+N)")
                .keyboardShortcut("n")
            }

            ToolbarItem {
                Button(action: { selectedSessionId = nil }) {
                    Image(systemName: "square.grid.2x2")
                }
                .help("Dashboard")
            }
        }
    }

    private var activeSessions: [AgentSession] {
        sessionStore.sessions.filter { $0.state != .stopped }
    }

    private var stoppedSessions: [AgentSession] {
        sessionStore.sessions.filter { $0.state == .stopped }
    }
}

struct SidebarSessionRow: View {
    @ObservedObject var session: AgentSession

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(session.backgroundColor.color)
                .frame(width: 3, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.name)
                    .font(.system(size: 13))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    EngineIcon(engine: session.engine, size: 10)
                    Text(session.engine.displayName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Circle()
                .fill(session.state.color)
                .frame(width: 8, height: 8)
        }
    }
}

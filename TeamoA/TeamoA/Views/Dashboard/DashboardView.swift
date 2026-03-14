import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @Binding var selectedSessionId: UUID?
    @State private var searchText = ""

    private var filteredSessions: [AgentSession] {
        if searchText.isEmpty {
            return sessionStore.sessions
        }
        return sessionStore.sessions.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.engine.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Stats bar
            HStack(spacing: 24) {
                StatItem(
                    label: "Total",
                    count: sessionStore.sessions.count,
                    color: .primary
                )
                StatItem(
                    label: "Running",
                    count: sessionStore.runningSessions.count,
                    color: .green
                )
                StatItem(
                    label: "Waiting",
                    count: sessionStore.waitingSessions.count,
                    color: .orange
                )
                StatItem(
                    label: "Stopped",
                    count: sessionStore.stoppedSessions.count,
                    color: .gray
                )
                Spacer()
            }
            .padding()
            .background(.ultraThinMaterial)

            Divider()

            if sessionStore.sessions.isEmpty {
                EmptyDashboardView()
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 280, maximum: 400), spacing: 16)
                        ],
                        spacing: 16
                    ) {
                        ForEach(filteredSessions) { session in
                            SessionCard(session: session)
                                .onTapGesture {
                                    selectedSessionId = session.id
                                }
                        }
                    }
                    .padding()
                }
                .searchable(text: $searchText, prompt: "Search sessions...")
            }
        }
        .navigationTitle("Dashboard")
    }
}

struct StatItem: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.title2.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct EmptyDashboardView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "plus.rectangle.on.folder")
                .font(.system(size: 56))
                .foregroundColor(.secondary)
            Text("No Agent Sessions")
                .font(.title2)
            Text("Create a new session to get started.\nPress Cmd+N or click the + button in the sidebar.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

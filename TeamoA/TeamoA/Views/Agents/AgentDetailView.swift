import SwiftUI

struct AgentDetailView: View {
    @ObservedObject var agent: Agent
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var notificationService: NotificationService
    @EnvironmentObject var sessionManager: TerminalSessionManager
    @State private var showTerminal = true
    @State private var showAssignIssue = false
    @State private var showSearch = false
    @State private var searchText = ""
    @State private var searchResults: [Int] = []
    @State private var currentMatchIndex = 0

    var body: some View {
        VStack(spacing: 0) {
            agentHeader

            if showSearch {
                terminalSearchBar
            }

            Divider()

            if showTerminal {
                TerminalContainerView(agent: agent)
                    .id(agent.id) // Force full view recreation when agent changes
            } else {
                agentInfoView
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var agentHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: agent.iconName)
                .font(.system(size: 28))
                .foregroundColor(.secondary)
                .frame(width: 48, height: 48)
                .background(Circle().fill(Color.secondary.opacity(0.1)))

            VStack(alignment: .leading, spacing: 2) {
                Text(agent.name)
                    .font(.title2.bold())
                Text("\(agent.role) - \(agent.engine.displayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: { showAssignIssue = true }) {
                    Label("Assign Issue", systemImage: "plus.circle")
                }
                .buttonStyle(.bordered)

                Button(action: invokeAgent) {
                    Label(showTerminal ? "Hide Terminal" : "Invoke", systemImage: showTerminal ? "rectangle.compress.vertical" : "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)

                if agent.state == .running {
                    Button(action: pauseAgent) {
                        Label("Pause", systemImage: "pause.fill")
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                }

                if agent.state == .stopped {
                    Button(action: restartAgent) {
                        Label("Restart", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                }

                Button(action: {
                    showSearch.toggle()
                    if !showSearch {
                        searchText = ""
                        searchResults = []
                        currentMatchIndex = 0
                    }
                }) {
                    Image(systemName: showSearch ? "xmark" : "magnifyingglass")
                }
                .buttonStyle(.bordered)

                AgentStateBadge(state: agent.state)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .sheet(isPresented: $showAssignIssue) {
            AssignIssueSheet(agent: agent)
        }
    }

    private var terminalSearchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 12))

            TextField("Search terminal output...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .onSubmit { performSearch() }
                .onChange(of: searchText) { _ in performSearch() }

            if !searchResults.isEmpty {
                Text("\(currentMatchIndex + 1)/\(searchResults.count)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)

                Button(action: { navigateMatch(direction: -1) }) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)

                Button(action: { navigateMatch(direction: 1) }) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
            } else if !searchText.isEmpty {
                Text("No matches")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var agentInfoView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Latest Run")
                            .font(.headline)
                        Spacer()
                    }

                    if agent.state == .running {
                        HStack(spacing: 8) {
                            Circle().fill(.green).frame(width: 8, height: 8)
                            Text("running")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.green)
                            Text("Active now")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(nsColor: .controlBackgroundColor))
                        )
                    } else {
                        HStack(spacing: 8) {
                            Circle().fill(agent.state.color).frame(width: 8, height: 8)
                            Text(agent.state.displayName.lowercased())
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(agent.state.color)
                            Spacer()
                            Text(agent.lastActivityAt, style: .relative)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(nsColor: .controlBackgroundColor))
                        )
                    }
                }

                HStack(spacing: 16) {
                    AgentStatCard(title: "Assigned Issues", value: "\(store.issuesForAgent(agent.id).count)", color: .blue)
                    AgentStatCard(title: "Completed", value: "\(store.issuesForAgent(agent.id).filter { $0.status == .done }.count)", color: .green)
                    AgentStatCard(title: "In Progress", value: "\(store.issuesForAgent(agent.id).filter { $0.status == .inProgress }.count)", color: .orange)
                    AgentStatCard(title: "Blocked", value: "\(store.issuesForAgent(agent.id).filter { $0.status == .blocked }.count)", color: .red)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Assigned Issues")
                        .font(.headline)

                    let agentIssues = store.issuesForAgent(agent.id)
                    if agentIssues.isEmpty {
                        Text("No issues assigned to this agent")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(agentIssues) { issue in
                            HStack(spacing: 8) {
                                Image(systemName: issue.status.iconName)
                                    .foregroundColor(issue.status.color)
                                    .font(.system(size: 12))
                                Text(issue.issueTag)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.secondary)
                                Text(issue.title)
                                    .font(.system(size: 13))
                                    .lineLimit(1)
                                Spacer()
                                Text(issue.status.displayName.lowercased())
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(issue.status.color.opacity(0.15)))
                                    .foregroundColor(issue.status.color)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                Spacer()
            }
            .padding(24)
        }
    }

    private func performSearch() {
        guard !searchText.isEmpty else {
            searchResults = []
            currentMatchIndex = 0
            return
        }

        let session = sessionManager.session(
            for: agent, store: store,
            notificationService: notificationService
        )
        let lines = session.controller.outputLines
        let query = searchText.lowercased()
        var matches: [Int] = []

        for (index, line) in lines.enumerated() {
            if line.lowercased().contains(query) {
                matches.append(index)
            }
        }

        searchResults = matches
        if matches.isEmpty {
            currentMatchIndex = 0
        } else {
            // Jump to last match (most recent)
            currentMatchIndex = matches.count - 1
        }
    }

    private func navigateMatch(direction: Int) {
        guard !searchResults.isEmpty else { return }
        currentMatchIndex = (currentMatchIndex + direction + searchResults.count) % searchResults.count
    }

    private func invokeAgent() {
        showTerminal.toggle()
        if showTerminal && agent.state != .running {
            store.updateAgentState(agent, to: .running)
        }
    }

    private func pauseAgent() {
        store.updateAgentState(agent, to: .paused)
    }

    private func restartAgent() {
        sessionManager.destroySession(for: agent.id)
        store.updateAgentState(agent, to: .idle)
        showTerminal = true
    }
}

struct AgentStateBadge: View {
    let state: AgentState

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(state.color)
                .frame(width: 8, height: 8)
            Text(state.displayName.lowercased())
                .font(.caption2.bold())
                .foregroundColor(state.color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(state.color.opacity(0.12))
        )
    }
}

struct AgentStatCard: View {
    let title: String
    let value: String
    let color: SwiftUI.Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

struct AssignIssueSheet: View {
    @ObservedObject var agent: Agent
    @EnvironmentObject var store: ProjectStore
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Assign Issue to \(agent.name)")
                .font(.headline)

            let unassigned = store.currentIssues.filter { $0.assigneeId == nil && $0.status != .done }
            if unassigned.isEmpty {
                Text("No unassigned issues available")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List(unassigned) { issue in
                    Button(action: {
                        store.assignIssue(issue, to: agent)
                        dismiss()
                    }) {
                        HStack {
                            Text(issue.issueTag)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondary)
                            Text(issue.title)
                                .font(.system(size: 13))
                            Spacer()
                            Circle().fill(issue.priority.color).frame(width: 8, height: 8)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Button("Cancel") { dismiss() }
                .keyboardShortcut(.cancelAction)
        }
        .padding()
        .frame(width: 460, height: 300)
    }
}

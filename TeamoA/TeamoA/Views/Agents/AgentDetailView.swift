import SwiftUI

struct AgentDetailView: View {
    @ObservedObject var agent: Agent
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var notificationService: NotificationService
    @State private var showTerminal = true
    @State private var showAssignIssue = false

    var body: some View {
        VStack(spacing: 0) {
            // Agent Header
            agentHeader

            Divider()

            if showTerminal {
                // Terminal view — session persists via TerminalSessionManager
                TerminalContainerView(agent: agent)
            } else {
                // Info view
                agentInfoView
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var agentHeader: some View {
        HStack(spacing: 12) {
            // Agent icon
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

            // Action buttons
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

                // State badge
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

    private var agentInfoView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Latest Run
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

                // Stats
                HStack(spacing: 16) {
                    AgentStatCard(title: "Assigned Issues", value: "\(store.issuesForAgent(agent.id).count)", color: .blue)
                    AgentStatCard(title: "Completed", value: "\(store.issuesForAgent(agent.id).filter { $0.status == .done }.count)", color: .green)
                    AgentStatCard(title: "In Progress", value: "\(store.issuesForAgent(agent.id).filter { $0.status == .inProgress }.count)", color: .orange)
                    AgentStatCard(title: "Blocked", value: "\(store.issuesForAgent(agent.id).filter { $0.status == .blocked }.count)", color: .red)
                }

                // Assigned Issues
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

    private func invokeAgent() {
        showTerminal.toggle()
        if showTerminal && agent.state != .running {
            store.updateAgentState(agent, to: .running)
        }
    }

    private func pauseAgent() {
        store.updateAgentState(agent, to: .paused)
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
    let color: Color

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

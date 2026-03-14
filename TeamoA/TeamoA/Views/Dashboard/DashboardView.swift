import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: ProjectStore
    @State private var showCreateAgent = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                if let ws = store.currentWorkspace {
                    Text(ws.name)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

                if store.currentAgents.isEmpty {
                    emptyStateView
                } else {
                    populatedView
                }
            }
            .padding(24)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("Dashboard")
        .sheet(isPresented: $showCreateAgent) {
            CreateAgentView()
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 60)

            Image(systemName: "person.badge.plus")
                .font(.system(size: 56))
                .foregroundColor(.blue.opacity(0.6))

            Text("Create your first agent")
                .font(.title2.bold())

            Text("Agents are AI-powered workers that help you\nachieve your goals. Each agent runs in its own\nterminal session.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .font(.system(size: 14))

            Button(action: { showCreateAgent = true }) {
                Label("Create Agent", systemImage: "plus")
                    .font(.headline)
                    .frame(width: 180)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Populated View

    private var populatedView: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Stats Cards
            HStack(spacing: 16) {
                StatCard(
                    value: "\(store.currentAgents.count)",
                    title: "Agents Enabled",
                    subtitle: "\(store.runningAgentsCount) running, \(store.pausedAgentsCount) paused",
                    icon: "person.3",
                    color: .blue
                )
                StatCard(
                    value: "\(store.openIssuesCount)",
                    title: "Open Issues",
                    subtitle: "\(store.blockedIssuesCount) blocked",
                    icon: "circle.dotted",
                    color: .orange
                )
                StatCard(
                    value: "\(store.goalsCompletedCount)/\(store.goalsTotalCount)",
                    title: "Goals Progress",
                    subtitle: goalProgressText,
                    icon: "target",
                    color: .green
                )
                StatCard(
                    value: "\(pendingApprovals)",
                    title: "Pending Approvals",
                    subtitle: "0 stale tasks",
                    icon: "clock.badge.checkmark",
                    color: .purple
                )
            }

            // Two columns: Recent Activity + Recent Issues
            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("RECENT ACTIVITY")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)

                    ActivityFeedView(activities: Array(store.currentActivities.prefix(10)))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 12) {
                    Text("RECENT ISSUES")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)

                    if store.currentIssues.isEmpty {
                        Text("No issues yet")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    } else {
                        ForEach(store.currentIssues.prefix(8)) { issue in
                            IssueQuickRow(issue: issue)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var goalProgressText: String {
        let inProgress = store.currentGoals.filter { $0.status == .inProgress }.count
        return "\(inProgress) in progress"
    }

    private var pendingApprovals: Int {
        store.currentIssues.filter { $0.status == .blocked }.count
    }
}

struct IssueQuickRow: View {
    @ObservedObject var issue: Issue

    var body: some View {
        HStack(spacing: 8) {
            Text("-")
                .foregroundColor(.secondary)

            Image(systemName: issue.status.iconName)
                .font(.system(size: 12))
                .foregroundColor(issue.status.color)

            Text(issue.title)
                .font(.system(size: 13))
                .lineLimit(1)

            Spacer()

            if let name = issue.assigneeName {
                Text(name)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(.secondary.opacity(0.15)))
            }

            Text(issue.createdAt, style: .relative)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

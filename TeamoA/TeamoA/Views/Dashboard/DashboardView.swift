import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: ProjectStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                if let project = store.currentProject {
                    Text(project.name)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

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
                    // Recent Activity
                    VStack(alignment: .leading, spacing: 12) {
                        Text("RECENT ACTIVITY")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)

                        ActivityFeedView(activities: Array(store.currentActivities.prefix(10)))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Recent Issues
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("RECENT ISSUES")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                            Spacer()
                        }

                        ForEach(store.currentIssues.prefix(8)) { issue in
                            IssueQuickRow(issue: issue)
                        }

                        if store.currentIssues.isEmpty {
                            Text("No issues yet")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(24)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("Dashboard")
    }

    private var goalProgressText: String {
        let inProgress = store.currentGoals.filter { $0.status == .inProgress }.count
        return "\(inProgress) in progress"
    }

    private var pendingApprovals: Int {
        // Issues in blocked state that might need human approval
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

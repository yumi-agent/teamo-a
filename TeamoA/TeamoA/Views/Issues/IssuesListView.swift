import SwiftUI

struct IssuesListView: View {
    @EnvironmentObject var store: ProjectStore
    @State private var showCreateIssue = false
    @State private var selectedIssue: Issue?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("ISSUES")
                    .font(.title3.bold())
                Spacer()
                Button(action: { showCreateIssue = true }) {
                    Label("New Issue", systemImage: "plus")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            Divider()

            if store.currentIssues.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No issues")
                        .font(.title3)
                    Text("Create an issue or let agents report them")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        IssueSectionView(
                            title: "IN PROGRESS",
                            issues: store.currentIssues.filter { $0.status == .inProgress },
                            selectedIssue: $selectedIssue
                        )
                        IssueSectionView(
                            title: "TODO",
                            issues: store.currentIssues.filter { $0.status == .todo },
                            selectedIssue: $selectedIssue
                        )
                        IssueSectionView(
                            title: "BLOCKED",
                            issues: store.currentIssues.filter { $0.status == .blocked },
                            selectedIssue: $selectedIssue
                        )
                        IssueSectionView(
                            title: "DONE",
                            issues: store.currentIssues.filter { $0.status == .done },
                            selectedIssue: $selectedIssue
                        )
                    }
                    .padding(24)
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("Issues")
        .sheet(isPresented: $showCreateIssue) {
            CreateIssueView()
        }
        .sheet(item: $selectedIssue) { issue in
            IssueDetailView(issue: issue)
        }
    }
}

struct IssueSectionView: View {
    let title: String
    let issues: [Issue]
    @Binding var selectedIssue: Issue?

    var body: some View {
        if !issues.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.top, 4)

                ForEach(issues) { issue in
                    IssueRow(issue: issue)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedIssue = issue
                        }
                }
            }
        }
    }
}

struct IssueRow: View {
    @ObservedObject var issue: Issue

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: issue.status.iconName)
                .foregroundColor(issue.status.color)
                .font(.system(size: 14))

            Text(issue.issueTag)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)

            Text(issue.title)
                .font(.system(size: 14))
                .lineLimit(1)

            Spacer()

            if let name = issue.assigneeName {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Text(name.prefix(2).uppercased())
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.blue)
                        )
                    Text(name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if issue.status == .done {
                Text("done")
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(.green.opacity(0.2)))
                    .foregroundColor(.green)
            } else if issue.status == .inProgress {
                Circle().fill(.blue).frame(width: 6, height: 6)
                Text("Live")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }

            Text(issue.createdAt, style: .date)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

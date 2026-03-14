import SwiftUI

struct IssueDetailView: View {
    @ObservedObject var issue: Issue
    @EnvironmentObject var store: ProjectStore
    @Environment(\.dismiss) var dismiss

    var body: some View {
        HStack(spacing: 0) {
            // Main content
            VStack(alignment: .leading, spacing: 16) {
                // Breadcrumb
                HStack(spacing: 4) {
                    Image(systemName: issue.status.iconName)
                        .foregroundColor(issue.status.color)
                    Text(issue.issueTag)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                Text(issue.title)
                    .font(.title2.bold())

                if !issue.description.isEmpty {
                    Text(issue.description)
                        .font(.system(size: 14))
                        .foregroundColor(.primary.opacity(0.9))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(nsColor: .controlBackgroundColor))
                        )
                }

                Divider()

                // Status actions
                HStack(spacing: 8) {
                    ForEach(IssueStatus.allCases, id: \.self) { status in
                        Button(status.displayName) {
                            store.updateIssueStatus(issue, to: status)
                        }
                        .buttonStyle(.bordered)
                        .tint(status == issue.status ? status.color : .secondary)
                    }
                }

                Spacer()
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // Properties panel
            VStack(alignment: .leading, spacing: 16) {
                Text("Properties")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 12) {
                    PropertyRow(label: "Status", value: issue.status.displayName, color: issue.status.color)
                    PropertyRow(label: "Priority", value: issue.priority.displayName, color: issue.priority.color)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Assignee")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let name = issue.assigneeName {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.blue.opacity(0.3))
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Text(name.prefix(2).uppercased())
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.blue)
                                    )
                                Text(name)
                                    .font(.system(size: 13))
                            }
                        } else {
                            Text("Unassigned")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Created")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(issue.createdAt, style: .date)
                            .font(.system(size: 13))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Updated")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(issue.updatedAt, style: .relative)
                            .font(.system(size: 13))
                    }
                }

                Spacer()
            }
            .padding(20)
            .frame(width: 220)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        }
        .frame(width: 720, height: 460)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }
}

struct PropertyRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(value)
                    .font(.system(size: 13))
            }
        }
    }
}

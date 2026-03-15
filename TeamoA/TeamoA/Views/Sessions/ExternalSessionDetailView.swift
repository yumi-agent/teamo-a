import SwiftUI

struct ExternalSessionDetailView: View {
    let sessionId: String
    @EnvironmentObject var sessionScanner: ExternalSessionScanner

    private var session: DiscoveredSession? {
        sessionScanner.sessions.first { $0.id == sessionId }
    }

    var body: some View {
        if let session = session {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    HStack(spacing: 12) {
                        Image(systemName: "terminal")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary)
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(Color.secondary.opacity(0.1)))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.displayName)
                                .font(.title2.bold())
                            Text(session.shortProjectPath)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        SessionStatusBadge(status: session.status)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)

                    // Details
                    VStack(alignment: .leading, spacing: 16) {
                        DetailRow(label: "Session ID", value: session.id)

                        DetailRow(label: "Project Path", value: session.projectPath)

                        if !session.gitBranch.isEmpty {
                            DetailRow(label: "Git Branch", value: session.gitBranch)
                        }

                        if !session.version.isEmpty {
                            DetailRow(label: "Claude Version", value: session.version)
                        }

                        if let pid = session.pid {
                            DetailRow(label: "Process ID", value: "\(pid)")
                        }

                        DetailRow(label: "Last Modified", value: formatDate(session.mtime))

                        DetailRow(label: "File Size", value: formatBytes(session.size))

                        if !session.firstPrompt.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("First Prompt")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                Text(session.firstPrompt)
                                    .font(.system(size: 13))
                                    .padding(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color(nsColor: .controlBackgroundColor))
                                    )
                            }
                        }
                    }
                    .padding(24)

                    Spacer()
                }
            }
            .background(Color(nsColor: .windowBackgroundColor))
            .navigationTitle(session.displayName)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
                Text("Session not found")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text("This session may have been cleaned up or is no longer available.")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.7))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .trailing)
            Text(value)
                .font(.system(size: 13))
                .textSelection(.enabled)
        }
    }
}

struct SessionStatusBadge: View {
    let status: DiscoveredSession.SessionStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
            Text(status.displayName.lowercased())
                .font(.caption2.bold())
                .foregroundColor(status.color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(status.color.opacity(0.12))
        )
    }
}

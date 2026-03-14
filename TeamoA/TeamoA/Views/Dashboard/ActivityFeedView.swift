import SwiftUI

struct ActivityFeedView: View {
    let activities: [ActivityEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(activities) { event in
                ActivityRow(event: event)
                if event.id != activities.last?.id {
                    Divider().padding(.leading, 24)
                }
            }

            if activities.isEmpty {
                Text("No recent activity")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .padding(.vertical, 8)
            }
        }
    }
}

struct ActivityRow: View {
    let event: ActivityEvent

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(event.agentName != nil ? Color.blue.opacity(0.3) : Color.secondary.opacity(0.2))
                .frame(width: 24, height: 24)
                .overlay(
                    Text(event.agentName?.prefix(1).uppercased() ?? "S")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(event.agentName != nil ? .blue : .secondary)
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    if let name = event.agentName {
                        Text(name)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    Text(event.action)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    if !event.detail.isEmpty {
                        Text(event.detail)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
            }

            Spacer()

            Text(event.timeAgo)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
    }
}

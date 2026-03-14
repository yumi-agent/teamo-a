import SwiftUI

struct GoalsListView: View {
    @EnvironmentObject var store: ProjectStore
    @State private var showCreateGoal = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("GOALS")
                    .font(.title3.bold())
                Spacer()
                Button(action: { showCreateGoal = true }) {
                    Label("New Goal", systemImage: "plus")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            Divider()

            if store.currentGoals.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "target")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No goals yet")
                        .font(.title3)
                    Text("Create a goal to track your team's objectives")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        // Group by status
                        GoalSection(title: "In Progress", goals: store.currentGoals.filter { $0.status == .inProgress })
                        GoalSection(title: "Not Started", goals: store.currentGoals.filter { $0.status == .notStarted })
                        GoalSection(title: "Completed", goals: store.currentGoals.filter { $0.status == .completed })
                    }
                    .padding(24)
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("Goals")
        .sheet(isPresented: $showCreateGoal) {
            CreateGoalView()
        }
    }
}

struct GoalSection: View {
    let title: String
    let goals: [Goal]

    var body: some View {
        if !goals.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title.uppercased())
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .padding(.top, 8)

                ForEach(goals) { goal in
                    GoalRow(goal: goal)
                }
            }
        }
    }
}

struct GoalRow: View {
    @ObservedObject var goal: Goal
    @EnvironmentObject var store: ProjectStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: goal.status.iconName)
                    .foregroundColor(goal.status.color)
                    .font(.system(size: 16))

                Text(goal.title)
                    .font(.system(size: 15, weight: .medium))

                Spacer()

                Text("\(Int(goal.progress * 100))%")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(goal.status.color)
            }

            if !goal.description.isEmpty {
                Text(goal.description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(goal.status.color)
                        .frame(width: geo.size.width * goal.progress, height: 6)
                }
            }
            .frame(height: 6)

            // Related issues count
            let relatedIssues = store.issuesForGoal(goal.id)
            let doneCount = relatedIssues.filter { $0.status == .done }.count
            if !relatedIssues.isEmpty {
                Text("\(doneCount)/\(relatedIssues.count) issues completed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
        )
    }
}

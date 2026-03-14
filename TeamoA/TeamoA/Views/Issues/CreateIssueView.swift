import SwiftUI

struct CreateIssueView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: ProjectStore
    @State private var title = ""
    @State private var description = ""
    @State private var priority: IssuePriority = .medium
    @State private var selectedGoalId: UUID?

    var body: some View {
        VStack(spacing: 20) {
            Text("New Issue")
                .font(.title2.bold())

            Form {
                TextField("Issue Title", text: $title)
                    .textFieldStyle(.roundedBorder)

                VStack(alignment: .leading) {
                    Text("Description")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $description)
                        .frame(height: 60)
                        .font(.system(size: 13))
                }

                Picker("Priority", selection: $priority) {
                    ForEach(IssuePriority.allCases, id: \.self) { p in
                        HStack {
                            Circle().fill(p.color).frame(width: 8, height: 8)
                            Text(p.displayName)
                        }
                        .tag(p)
                    }
                }

                Picker("Goal", selection: $selectedGoalId) {
                    Text("None").tag(nil as UUID?)
                    ForEach(store.currentGoals) { goal in
                        Text(goal.title).tag(goal.id as UUID?)
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Create") {
                    store.addIssue(
                        title: title,
                        description: description,
                        priority: priority,
                        goalId: selectedGoalId
                    )
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.isEmpty)
            }
        }
        .padding()
        .frame(width: 450, height: 400)
    }
}

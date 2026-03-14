import SwiftUI

struct CreateGoalView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: ProjectStore
    @State private var title = ""
    @State private var description = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("New Goal")
                .font(.title2.bold())

            Form {
                TextField("Goal Title", text: $title)
                    .textFieldStyle(.roundedBorder)

                VStack(alignment: .leading) {
                    Text("Description")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $description)
                        .frame(height: 80)
                        .font(.system(size: 13))
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Create") {
                    guard let pid = store.currentProjectId else { return }
                    let goal = Goal(projectId: pid, title: title, description: description)
                    store.addGoal(goal)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.isEmpty)
            }
        }
        .padding()
        .frame(width: 420, height: 300)
    }
}

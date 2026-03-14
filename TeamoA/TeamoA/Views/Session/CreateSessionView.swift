import SwiftUI

struct CreateSessionView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var engine: AgentEngine = .claudeCode
    @State private var workingDirectory = NSHomeDirectory()
    @State private var selectedColor: SessionColor = .blue

    var onCreate: (AgentSession) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("New Agent Session")
                .font(.title2.bold())

            Form {
                TextField("Session Name", text: $name)
                    .textFieldStyle(.roundedBorder)

                Picker("Agent Engine", selection: $engine) {
                    ForEach(AgentEngine.allCases) { eng in
                        HStack {
                            Image(systemName: eng.iconName)
                            Text(eng.displayName)
                        }
                        .tag(eng)
                    }
                }
                .pickerStyle(.segmented)

                HStack {
                    Text("Working Directory")
                    Spacer()
                    Text(shortPath(workingDirectory))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Button("Browse...") {
                        chooseDirectory()
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Color")
                    HStack(spacing: 8) {
                        ForEach(SessionColor.allCases) { color in
                            Circle()
                                .fill(color.color)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: selectedColor == color ? 2 : 0)
                                )
                                .shadow(color: selectedColor == color ? color.color.opacity(0.5) : .clear, radius: 4)
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Create") {
                    let session = AgentSession(
                        name: name.isEmpty ? "Untitled Session" : name,
                        engine: engine,
                        workingDirectory: workingDirectory,
                        backgroundColor: selectedColor
                    )
                    onCreate(session)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty)
            }
        }
        .padding()
        .frame(width: 450, height: 380)
    }

    private func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: workingDirectory)

        if panel.runModal() == .OK, let url = panel.url {
            workingDirectory = url.path
        }
    }

    private func shortPath(_ path: String) -> String {
        let home = NSHomeDirectory()
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}

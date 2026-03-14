import SwiftUI

struct SessionDetailView: View {
    @ObservedObject var session: AgentSession
    @EnvironmentObject var sessionStore: SessionStore
    @State private var showStopConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            // Session header bar
            HStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(session.backgroundColor.color)
                    .frame(width: 4, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(session.name)
                        .font(.headline)
                    HStack(spacing: 8) {
                        EngineIcon(engine: session.engine, size: 12)
                        Text(session.engine.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("·")
                            .foregroundColor(.secondary)
                        Text(shortPath(session.workingDirectory))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                StatusBadge(state: session.state)

                // Session controls
                HStack(spacing: 8) {
                    if session.state != .stopped {
                        Button(action: { showStopConfirm = true }) {
                            Image(systemName: "stop.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                        .help("Stop Session")
                    } else {
                        Button(action: restartSession) {
                            Image(systemName: "play.fill")
                                .foregroundColor(.green)
                        }
                        .buttonStyle(.plain)
                        .help("Restart Session")
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)

            Divider()

            // Terminal
            TerminalContainerView(session: session)
        }
        .alert("Stop Session?", isPresented: $showStopConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Stop", role: .destructive) {
                // Terminal controller will handle stopping
                session.state = .stopped
                sessionStore.updateSession(session)
            }
        } message: {
            Text("This will terminate the agent process for '\(session.name)'.")
        }
    }

    private func restartSession() {
        session.state = .stopped // Reset, TerminalContainerView.onAppear will restart
    }

    private func shortPath(_ path: String) -> String {
        let home = NSHomeDirectory()
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}

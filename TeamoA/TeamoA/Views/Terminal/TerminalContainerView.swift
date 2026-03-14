import SwiftUI

struct TerminalContainerView: View {
    @ObservedObject var session: AgentSession
    @EnvironmentObject var sessionStore: SessionStore
    @EnvironmentObject var notificationService: NotificationService

    @StateObject private var controller = TerminalController()

    var body: some View {
        VStack(spacing: 0) {
            // Terminal
            SwiftTermView(
                ptyManager: controller.ptyManager,
                backgroundColor: session.backgroundColor.terminalBackground,
                onResize: { cols, rows in
                    controller.ptyManager.resize(cols: cols, rows: rows)
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Input area
            InputAreaView { text in
                controller.sendInput(text)
                sessionStore.appendTranscript(
                    sessionId: session.id,
                    entry: TranscriptEntry(
                        timestamp: Date(),
                        type: .input,
                        content: text
                    )
                )
            }
        }
        .onAppear {
            controller.session = session
            controller.notificationService = notificationService
            controller.sessionStore = sessionStore
            if session.state == .stopped {
                controller.startSession()
            }
        }
        .onDisappear {
            // Don't terminate - session continues in background
        }
    }
}

class TerminalController: ObservableObject {
    let ptyManager = PTYManager()
    let stateDetector = AgentStateDetector()

    var session: AgentSession?
    var notificationService: NotificationService?
    var sessionStore: SessionStore?

    private var swiftTermCoordinator: SwiftTermView.Coordinator?

    init() {
        ptyManager.delegate = self
        stateDetector.delegate = self
    }

    func startSession() {
        guard let session = session else { return }

        let command: String
        let args: [String]

        if session.engine == .claudeCode {
            command = "claude"
            args = session.engine.defaultArgs
        } else {
            command = session.engine.command
            args = session.engine.defaultArgs
        }

        do {
            try ptyManager.start(
                command: command,
                arguments: args,
                workingDirectory: session.workingDirectory
            )
            session.state = .running
            stateDetector.start()
            sessionStore?.updateSession(session)
        } catch {
            print("Failed to start session: \(error)")
            session.state = .stopped
        }
    }

    func stopSession() {
        ptyManager.terminate()
        stateDetector.stop()
        session?.state = .stopped
        if let session = session {
            sessionStore?.updateSession(session)
        }
    }

    func sendInput(_ text: String) {
        ptyManager.write(text + "\n")
    }

    func setSwiftTermCoordinator(_ coordinator: SwiftTermView.Coordinator) {
        self.swiftTermCoordinator = coordinator
    }
}

extension TerminalController: PTYManagerDelegate {
    func ptyManager(_ manager: PTYManager, didReceiveOutput data: Data) {
        // Feed to terminal view
        swiftTermCoordinator?.feedToTerminal(data)

        // Feed to state detector
        if let text = String(data: data, encoding: .utf8) {
            stateDetector.feedOutput(text)

            // Log to transcript
            if let session = session {
                sessionStore?.appendTranscript(
                    sessionId: session.id,
                    entry: TranscriptEntry(
                        timestamp: Date(),
                        type: .output,
                        content: text
                    )
                )
            }
        }
    }

    func ptyManager(_ manager: PTYManager, didTerminateWithStatus status: Int32) {
        stateDetector.processTerminated()
        session?.state = .stopped
        if let session = session {
            sessionStore?.updateSession(session)
            notificationService?.sendStateChangeNotification(
                sessionId: session.id,
                sessionName: session.name,
                newState: .stopped
            )
        }
    }
}

extension TerminalController: AgentStateDetectorDelegate {
    func stateDetector(_ detector: AgentStateDetector, didDetectState state: SessionState) {
        let previousState = session?.state
        session?.state = state
        session?.lastActivityAt = Date()

        if let session = session {
            sessionStore?.updateSession(session)

            // Only notify for meaningful transitions
            if previousState == .running && (state == .waiting || state == .stopped) {
                notificationService?.sendStateChangeNotification(
                    sessionId: session.id,
                    sessionName: session.name,
                    newState: state
                )
            }
        }
    }
}

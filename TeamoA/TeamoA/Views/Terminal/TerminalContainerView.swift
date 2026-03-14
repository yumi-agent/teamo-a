import SwiftUI

struct TerminalContainerView: View {
    @ObservedObject var agent: Agent
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var notificationService: NotificationService

    @StateObject private var controller = TerminalController()

    var body: some View {
        VStack(spacing: 0) {
            // Terminal
            SwiftTermView(
                ptyManager: controller.ptyManager,
                backgroundColor: NSColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 1.0),
                onResize: { cols, rows in
                    controller.ptyManager.resize(cols: cols, rows: rows)
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Input area
            InputAreaView { text in
                controller.sendInput(text)
            }
        }
        .onAppear {
            controller.agent = agent
            controller.notificationService = notificationService
            controller.store = store
            if agent.state != .running || !controller.ptyManager.isRunning {
                controller.startSession()
            }
        }
    }
}

class TerminalController: ObservableObject {
    let ptyManager = PTYManager()
    let stateDetector = AgentStateDetector()

    var agent: Agent?
    var notificationService: NotificationService?
    var store: ProjectStore?

    private var swiftTermCoordinator: SwiftTermView.Coordinator?

    init() {
        ptyManager.delegate = self
        stateDetector.delegate = self
    }

    func startSession() {
        guard let agent = agent else { return }

        let command = agent.engine.command
        let args = agent.engine.defaultArgs
        let workDir = store?.currentProject?.workingDirectory ?? NSHomeDirectory()

        do {
            try ptyManager.start(
                command: command,
                arguments: args,
                workingDirectory: workDir
            )
            agent.state = .running
            stateDetector.start()
            store?.objectWillChange.send()
        } catch {
            print("Failed to start session: \(error)")
            agent.state = .error
        }
    }

    func stopSession() {
        ptyManager.terminate()
        stateDetector.stop()
        agent?.state = .stopped
        store?.objectWillChange.send()
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
        swiftTermCoordinator?.feedToTerminal(data)

        if let text = String(data: data, encoding: .utf8) {
            stateDetector.feedOutput(text)
        }
    }

    func ptyManager(_ manager: PTYManager, didTerminateWithStatus status: Int32) {
        stateDetector.processTerminated()
        agent?.state = .stopped
        store?.objectWillChange.send()

        if let agent = agent {
            notificationService?.sendNotification(
                sessionId: agent.id,
                sessionName: agent.name,
                title: "[\(agent.name)] Completed",
                body: "Agent session has finished"
            )
        }
    }
}

extension TerminalController: AgentStateDetectorDelegate {
    func stateDetector(_ detector: AgentStateDetector, didDetectState state: SessionState) {
        guard let agent = agent else { return }
        let previousState = agent.state

        // Map SessionState to AgentState
        let newState: AgentState
        switch state {
        case .running: newState = .running
        case .idle: newState = .idle
        case .waiting: newState = .paused
        case .stopped: newState = .stopped
        }

        agent.state = newState
        agent.lastActivityAt = Date()
        store?.objectWillChange.send()

        // Notify on meaningful transitions
        if previousState == .running && (newState == .paused || newState == .stopped) {
            let title = newState == .paused ? "[\(agent.name)] Waiting for Input" : "[\(agent.name)] Completed"
            let body = newState == .paused ? "Agent is waiting for your response" : "Agent session has finished"
            notificationService?.sendNotification(
                sessionId: agent.id,
                sessionName: agent.name,
                title: title,
                body: body
            )
        }
    }
}

import SwiftUI
import SwiftTerm

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
                onTerminalReady: { tv in
                    controller.terminalView = tv
                    // Start session after terminal view is ready
                    // (onAppear already ran by this point since onTerminalReady dispatches async)
                    if !controller.ptyManager.isRunning {
                        controller.startSession()
                    }
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
        }
    }
}

class TerminalController: ObservableObject {
    let ptyManager = PTYManager()
    let stateDetector = AgentStateDetector()

    var agent: Agent?
    var notificationService: NotificationService?
    var store: ProjectStore?
    var terminalView: TerminalView?

    private var engineLaunchedAt: Date?
    private var initialGoalSent = false

    init() {
        ptyManager.delegate = self
        stateDetector.delegate = self
    }

    func startSession() {
        guard let agent = agent else { return }
        let workDir = store?.currentWorkspace?.workingDirectory ?? NSHomeDirectory()

        do {
            // Start a login shell — ensures PATH includes nvm, pyenv, etc.
            try ptyManager.start(
                command: "/bin/zsh",
                arguments: ["--login"],
                workingDirectory: workDir
            )
            agent.state = .running
            stateDetector.start()
            store?.objectWillChange.send()

            // After shell initializes, send the agent engine command
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                guard let self = self, let agent = self.agent else { return }
                let cmd = agent.engine.launchCommand
                self.ptyManager.write(cmd + "\n")
                self.engineLaunchedAt = Date()

                // Auto-accept workspace trust check after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                    self?.ptyManager.write("\r")
                }
            }
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
        ptyManager.write(text + "\r")
    }

    func trySendInitialGoal() {
        guard !initialGoalSent else { return }
        guard let agent = agent, let goal = agent.goalDescription, !goal.isEmpty else { return }
        guard let launched = engineLaunchedAt, Date().timeIntervalSince(launched) > 4.0 else { return }
        initialGoalSent = true
        ptyManager.write(goal + "\r")
    }
}

extension TerminalController: PTYManagerDelegate {
    func ptyManager(_ manager: PTYManager, didReceiveOutput data: Data) {
        // Feed output directly to TerminalView
        let bytes = Array(data)
        terminalView?.feed(byteArray: ArraySlice(bytes))

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

        // Auto-send initial goal when agent enters waiting state
        if newState == .paused {
            trySendInitialGoal()
        }

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

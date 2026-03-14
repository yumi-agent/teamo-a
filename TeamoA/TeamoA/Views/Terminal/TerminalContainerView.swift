import SwiftUI
import SwiftTerm

struct TerminalContainerView: View {
    @ObservedObject var agent: Agent
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var notificationService: NotificationService
    @EnvironmentObject var sessionManager: TerminalSessionManager

    var body: some View {
        VStack(spacing: 0) {
            // Terminal — uses persistent session from manager
            PersistentTerminalView(
                session: sessionManager.session(
                    for: agent, store: store,
                    notificationService: notificationService
                )
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Input area
            InputAreaView { text in
                sessionManager.session(
                    for: agent, store: store,
                    notificationService: notificationService
                ).controller.sendInput(text)
            }
        }
        .onAppear {
            let session = sessionManager.session(
                for: agent, store: store,
                notificationService: notificationService
            )
            if !session.isStarted {
                session.isStarted = true
                session.controller.startSession()
            }
        }
    }
}

// MARK: - PersistentTerminalView

/// NSViewRepresentable that reuses a cached TerminalView from the session.
/// The TerminalView instance survives navigation — only the container NSView
/// is created/destroyed by SwiftUI.
struct PersistentTerminalView: NSViewRepresentable {
    let session: TerminalSession

    func makeNSView(context: Context) -> NSView {
        let container = NSView()
        embedTerminalView(in: container)
        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // Re-embed if the terminal view was detached (e.g. after navigation)
        let tv = getOrCreateTerminalView()
        if tv.superview !== nsView {
            embedTerminalView(in: nsView)
        }
    }

    private func embedTerminalView(in container: NSView) {
        let tv = getOrCreateTerminalView()
        tv.removeFromSuperview()
        tv.autoresizingMask = [.width, .height]
        container.addSubview(tv)

        // Force full redraw by triggering a resize cycle after layout
        DispatchQueue.main.async {
            // Set frame to container bounds (may be zero initially)
            if container.bounds.width > 0 && container.bounds.height > 0 {
                // Resize trick: change frame by 1px then back to force SwiftTerm's
                // processSizeChange() which does a full terminal layout + redraw
                var frame = container.bounds
                frame.size.width -= 1
                tv.frame = frame
                frame.size.width += 1
                tv.frame = frame
            }
            let terminal = tv.getTerminal()
            terminal.refresh(startRow: 0, endRow: max(0, terminal.rows - 1))
            tv.needsDisplay = true
        }
    }

    private func getOrCreateTerminalView() -> TerminalView {
        if let cached = session.cachedTerminalView {
            return cached
        }

        let tv = TerminalView(frame: .zero)
        tv.nativeBackgroundColor = NSColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 1.0)
        tv.nativeForegroundColor = .white
        tv.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        tv.terminalDelegate = session.controller

        session.cachedTerminalView = tv
        session.controller.terminalView = tv
        return tv
    }
}

// MARK: - TerminalController

class TerminalController: NSObject, ObservableObject {
    let ptyManager = PTYManager()
    let stateDetector = AgentStateDetector()

    var agent: Agent?
    var notificationService: NotificationService?
    var store: ProjectStore?
    var terminalView: TerminalView?

    private var engineLaunchedAt: Date?
    private var initialGoalSent = false

    override init() {
        super.init()
        ptyManager.delegate = self
        stateDetector.delegate = self
    }

    func startSession() {
        guard let agent = agent else { return }
        let workDir = store?.currentWorkspace?.workingDirectory ?? NSHomeDirectory()

        do {
            try ptyManager.start(
                command: "/bin/zsh",
                arguments: ["--login"],
                workingDirectory: workDir
            )
            agent.state = .running
            stateDetector.start()
            store?.objectWillChange.send()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                guard let self = self, let agent = self.agent else { return }
                let cmd = agent.engine.launchCommand
                self.ptyManager.write(cmd + "\n")
                self.engineLaunchedAt = Date()

                // Auto-accept workspace trust check
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                    self?.ptyManager.write("\r")
                }

                // Timer-based fallback: send initial goal
                DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) { [weak self] in
                    self?.trySendInitialGoal()
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

// MARK: - TerminalViewDelegate

extension TerminalController: TerminalViewDelegate {
    func send(source: TerminalView, data: ArraySlice<UInt8>) {
        ptyManager.write(Data(data))
    }

    func scrolled(source: TerminalView, position: Double) {}

    func setTerminalTitle(source: TerminalView, title: String) {}

    func sizeChanged(source: TerminalView, newCols: Int, newRows: Int) {
        ptyManager.resize(cols: newCols, rows: newRows)
    }

    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}

    func requestOpenLink(source: TerminalView, link: String, params: [String: String]) {
        if let url = URL(string: link) {
            NSWorkspace.shared.open(url)
        }
    }

    func rangeChanged(source: TerminalView, startY: Int, endY: Int) {}

    func clipboardCopy(source: TerminalView, content: Data) {
        if let str = String(data: content, encoding: .utf8) {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(str, forType: .string)
        }
    }

    func bell(source: TerminalView) {
        NSSound.beep()
    }

    func iTermContent(source: TerminalView, content: ArraySlice<UInt8>) {}
}

// MARK: - PTYManagerDelegate

extension TerminalController: PTYManagerDelegate {
    func ptyManager(_ manager: PTYManager, didReceiveOutput data: Data) {
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

// MARK: - AgentStateDetectorDelegate

extension TerminalController: AgentStateDetectorDelegate {
    func stateDetector(_ detector: AgentStateDetector, didDetectState state: SessionState) {
        guard let agent = agent else { return }
        let previousState = agent.state

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

        if newState == .paused {
            trySendInitialGoal()
        }

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

import SwiftUI
import SwiftTerm

struct TerminalContainerView: View {
    @ObservedObject var agent: Agent
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var notificationService: NotificationService
    @EnvironmentObject var sessionManager: TerminalSessionManager
    @State private var showSearch = false
    @State private var searchText = ""
    @State private var searchMatches: [TerminalSearchMatch] = []
    @State private var currentMatchIndex = 0

    private var session: TerminalSession {
        sessionManager.session(for: agent, store: store, notificationService: notificationService)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            if showSearch {
                terminalSearchBar
            }

            // Terminal — uses persistent session from manager
            PersistentTerminalView(session: session)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Input area
            HStack(spacing: 0) {
                InputAreaView { text in
                    session.controller.sendInput(text)
                }
                .frame(maxWidth: .infinity)

                Button(action: { showSearch.toggle() }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundColor(showSearch ? .blue : .secondary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 12)
                .help("Search terminal output")
            }
        }
        .onAppear {
            if !session.isStarted {
                session.isStarted = true
                // Delay start to ensure TerminalView has completed layout
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [session] in
                    session.controller.startSession()
                }
            }
        }
    }

    private var terminalSearchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 12))

            TextField("Search terminal output...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .onSubmit { performSearch() }
                .onChange(of: searchText) { _ in
                    if searchText.isEmpty {
                        searchMatches = []
                        currentMatchIndex = 0
                    }
                }

            if !searchMatches.isEmpty {
                Text("\(currentMatchIndex + 1)/\(searchMatches.count)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)

                Button(action: navigatePrevious) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.plain)
                .disabled(searchMatches.count <= 1)

                Button(action: navigateNext) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.plain)
                .disabled(searchMatches.count <= 1)
            } else if !searchText.isEmpty {
                Text("No matches")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Button(action: {
                showSearch = false
                searchText = ""
                searchMatches = []
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func performSearch() {
        guard !searchText.isEmpty else { return }
        guard let tv = session.cachedTerminalView else { return }

        let terminal = tv.getTerminal()
        let keyword = searchText.lowercased()
        var matches: [TerminalSearchMatch] = []

        // Iterate through scroll-invariant lines until we get nil
        var row = 0
        while let line = terminal.getScrollInvariantLine(row: row) {
            let text = line.translateToString(trimRight: true)
            let lowerText = text.lowercased()
            var searchStart = lowerText.startIndex
            while let range = lowerText.range(of: keyword, range: searchStart..<lowerText.endIndex) {
                let col = lowerText.distance(from: lowerText.startIndex, to: range.lowerBound)
                matches.append(TerminalSearchMatch(bufferRow: row, col: col))
                searchStart = range.upperBound
            }
            row += 1
            if row > 50000 { break } // safety limit
        }

        searchMatches = matches
        if !matches.isEmpty {
            currentMatchIndex = max(0, matches.count - 1)
            scrollToCurrentMatch(tv: tv)
        }
    }

    private func navigateNext() {
        guard !searchMatches.isEmpty else { return }
        currentMatchIndex = (currentMatchIndex + 1) % searchMatches.count
        if let tv = session.cachedTerminalView {
            scrollToCurrentMatch(tv: tv)
        }
    }

    private func navigatePrevious() {
        guard !searchMatches.isEmpty else { return }
        currentMatchIndex = (currentMatchIndex - 1 + searchMatches.count) % searchMatches.count
        if let tv = session.cachedTerminalView {
            scrollToCurrentMatch(tv: tv)
        }
    }

    private func scrollToCurrentMatch(tv: TerminalView) {
        let match = searchMatches[currentMatchIndex]
        let terminal = tv.getTerminal()

        // Count total lines by iterating (getScrollInvariantLine returns nil past end)
        var totalLines = 0
        while terminal.getScrollInvariantLine(row: totalLines) != nil {
            totalLines += 1
            if totalLines > 50000 { break }
        }
        let maxScroll = totalLines - terminal.rows
        guard maxScroll > 0 else { return }

        let targetRow = max(0, min(match.bufferRow - terminal.rows / 2, maxScroll))
        let position = Double(targetRow) / Double(maxScroll)
        tv.scroll(toPosition: position)
    }
}

struct TerminalSearchMatch {
    let bufferRow: Int
    let col: Int
}

// MARK: - PersistentTerminalView

/// NSViewRepresentable that reuses a cached TerminalView from the session.
/// The TerminalView instance survives navigation — only the container NSView
/// is created/destroyed by SwiftUI.
struct PersistentTerminalView: NSViewRepresentable {
    let session: TerminalSession

    func makeNSView(context: Context) -> NSView {
        let container = ClippingView()
        embedTerminalView(in: container)
        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        let tv = getOrCreateTerminalView()
        if tv.superview !== nsView {
            embedTerminalView(in: nsView)
        }
    }

    private func embedTerminalView(in container: NSView) {
        let tv = getOrCreateTerminalView()

        for sub in container.subviews where sub !== tv {
            sub.removeFromSuperview()
        }
        tv.removeFromSuperview()

        tv.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(tv)
        NSLayoutConstraint.activate([
            tv.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            tv.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            tv.topAnchor.constraint(equalTo: container.topAnchor),
            tv.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        for delay in [0.1, 0.3, 0.6, 1.2] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                container.layoutSubtreeIfNeeded()
                let terminal = tv.getTerminal()
                if terminal.rows > 0 {
                    terminal.refresh(startRow: 0, endRow: terminal.rows - 1)
                    tv.needsDisplay = true
                }
            }
        }
    }

    private func getOrCreateTerminalView() -> TerminalView {
        if let cached = session.cachedTerminalView {
            return cached
        }

        // Use small initial frame — Auto Layout will resize to fit container.
        // Must NOT be .zero (SwiftTerm needs >0 rows/cols for its buffer).
        let tv = TerminalView(frame: NSRect(x: 0, y: 0, width: 100, height: 50))
        tv.nativeBackgroundColor = NSColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 1.0)
        tv.nativeForegroundColor = .white
        tv.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        tv.terminalDelegate = session.controller

        // Hide the built-in NSScroller (legacy style white scrollbar)
        hideScroller(in: tv)

        session.cachedTerminalView = tv
        session.controller.terminalView = tv
        return tv
    }

    /// Hides SwiftTerm's built-in NSScroller to prevent white rectangle artifacts
    private func hideScroller(in view: NSView) {
        for subview in view.subviews {
            if let scroller = subview as? NSScroller {
                scroller.isHidden = true
            }
        }
    }
}

/// NSView that clips its children — prevents terminal content from overflowing.
private class ClippingView: NSView {
    override var wantsDefaultClipping: Bool { true }
    override func layout() {
        super.layout()
        // CALayer clipsToBounds equivalent for NSView
        wantsLayer = true
        layer?.masksToBounds = true
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

    /// Accumulated terminal output lines for search
    var outputLines: [String] = []
    private var currentLineBuffer = ""

    private var engineLaunchedAt: Date?
    private var initialGoalSent = false
    private var sessionIdCaptured = false

    override init() {
        super.init()
        ptyManager.delegate = self
        stateDetector.delegate = self
    }

    func startSession() {
        guard let agent = agent else { return }
        let workDir = agent.workingDirectory

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

    /// Try to capture Claude session ID from output and persist it on the agent.
    /// Also auto-associate with most recent JSONL if not yet captured.
    private func captureSessionId(from text: String) {
        guard !sessionIdCaptured, let agent = agent else { return }

        // Try regex extraction first
        if let sid = ClaudeSessionReader.extractSessionId(from: text) {
            agent.claudeSessionId = sid
            sessionIdCaptured = true
            store?.objectWillChange.send()
            return
        }

        // Fallback: after engine has been running 5s, grab most recent JSONL
        if let launched = engineLaunchedAt,
           Date().timeIntervalSince(launched) > 5.0,
           agent.claudeSessionId == nil {
            if let recent = ClaudeSessionReader.mostRecentSession(forDirectory: agent.workingDirectory) {
                agent.claudeSessionId = recent.id
                sessionIdCaptured = true
                store?.objectWillChange.send()
                ClaudeSessionReader.invalidateCache(forDirectory: agent.workingDirectory)
            }
        }
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
        // Force refresh after resize to display buffered content
        let terminal = source.getTerminal()
        if newRows > 0 {
            terminal.refresh(startRow: 0, endRow: newRows - 1)
            source.needsDisplay = true
        }
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
            appendToOutputBuffer(text)
            captureSessionId(from: text)
        }
    }

    private func appendToOutputBuffer(_ text: String) {
        currentLineBuffer += text
        while let range = currentLineBuffer.range(of: "\n") {
            let line = String(currentLineBuffer[currentLineBuffer.startIndex..<range.lowerBound])
            // Strip ANSI escape sequences for cleaner search
            let cleaned = line.replacingOccurrences(
                of: "\u{1B}\\[[0-9;]*[a-zA-Z]",
                with: "",
                options: .regularExpression
            )
            outputLines.append(cleaned)
            currentLineBuffer = String(currentLineBuffer[range.upperBound...])
        }
        // Cap at 10000 lines
        if outputLines.count > 10000 {
            outputLines.removeFirst(outputLines.count - 10000)
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

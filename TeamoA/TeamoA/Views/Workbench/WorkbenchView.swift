import SwiftUI
import SwiftTerm

struct WorkbenchView: View {
    @EnvironmentObject var store: ProjectStore
    @EnvironmentObject var notificationService: NotificationService
    @EnvironmentObject var sessionManager: TerminalSessionManager

    @AppStorage("workbench_columns") private var columnsPerRow: Int = 2
    @AppStorage("workbench_heightPercent") private var heightPercent: Int = 50

    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Workbench")
                    .font(.title2.bold())
                Spacer()

                let agents = store.currentAgents
                let hasRunning = agents.contains { $0.state == .running }
                let hasStopped = agents.contains { $0.state == .stopped || $0.state == .idle }

                if !agents.isEmpty {
                    if hasStopped {
                        Button(action: startAllAgents) {
                            Label("Start All", systemImage: "play.fill")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    if hasRunning {
                        Button(action: stopAllAgents) {
                            Label("Stop All", systemImage: "stop.fill")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.red)
                    }
                }

                Button(action: { showSettings.toggle() }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showSettings, arrowEdge: .bottom) {
                    WorkbenchSettingsView(
                        columnsPerRow: $columnsPerRow,
                        heightPercent: $heightPercent
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)

            Divider()

            // Content
            let agents = store.currentAgents
            if agents.isEmpty {
                emptyState
            } else {
                GeometryReader { geo in
                    let availableHeight = geo.size.height
                    let terminalHeight = terminalHeight(for: availableHeight)

                    ScrollView {
                        let effectiveColumns = min(columnsPerRow, agents.count)
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: effectiveColumns),
                            spacing: 8
                        ) {
                            ForEach(agents) { agent in
                                WorkbenchTerminalCell(
                                    agent: agent,
                                    session: sessionManager.session(
                                        for: agent,
                                        store: store,
                                        notificationService: notificationService
                                    ),
                                    height: terminalHeight
                                )
                            }
                        }
                        .padding(8)

                        // Bottom hint space — always present so user knows they can scroll
                        Color.clear.frame(height: 40)
                    }
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func terminalHeight(for availableHeight: CGFloat) -> CGFloat {
        // Available height minus padding (top 8 + spacing + bottom hint 40)
        let usableHeight = availableHeight - 56
        let rawHeight: CGFloat
        switch heightPercent {
        case 25:
            rawHeight = usableHeight * 0.25
        case 75:
            rawHeight = usableHeight * 0.75
        case 100:
            // Nearly full height but leave bottom hint for scrolling
            rawHeight = usableHeight * 0.95
        default: // 50
            // At 50%, two rows of terminals nearly fill the screen
            rawHeight = (usableHeight - 8) / 2  // subtract inter-row spacing
        }
        return max(rawHeight, 120)
    }

    private func startAllAgents() {
        for agent in store.currentAgents where agent.state == .stopped || agent.state == .idle {
            let session = sessionManager.session(for: agent, store: store, notificationService: notificationService)
            if !session.isStarted {
                session.isStarted = true
                session.controller.startSession()
            }
        }
    }

    private func stopAllAgents() {
        for agent in store.currentAgents where agent.state == .running {
            let session = sessionManager.session(for: agent, store: store, notificationService: notificationService)
            session.controller.stopSession()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "rectangle.split.2x2.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.4))
            Text("No Agents Yet")
                .font(.title3.bold())
                .foregroundColor(.secondary)
            Text("Create agents from the sidebar to see them here")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Workbench Terminal Cell

struct WorkbenchTerminalCell: View {
    @ObservedObject var agent: Agent
    let session: TerminalSession
    let height: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack(spacing: 6) {
                Circle()
                    .fill(agent.state.color)
                    .frame(width: 8, height: 8)
                Text(agent.name)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                Text("·")
                    .foregroundColor(.secondary)
                Text(agent.engine.displayName)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
                Text(agent.state.displayName.lowercased())
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(agent.state.color)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(nsColor: .controlBackgroundColor))

            // Terminal
            WorkbenchTerminalRepresentable(session: session)
                .frame(maxWidth: .infinity)
                .frame(height: height - 30) // subtract title bar height
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(agent.state == .running ? Color.green.opacity(0.4) : Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            if !session.isStarted {
                session.isStarted = true
                session.controller.startSession()
            }
        }
    }
}

// MARK: - WorkbenchTerminalRepresentable

/// Lightweight NSViewRepresentable that embeds the session's cached TerminalView.
/// Similar to PersistentTerminalView but optimized for the multi-panel workbench.
struct WorkbenchTerminalRepresentable: NSViewRepresentable {
    let session: TerminalSession

    func makeNSView(context: Context) -> NSView {
        let container = NSView()
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
        tv.removeFromSuperview()
        tv.autoresizingMask = [.width, .height]
        container.addSubview(tv)

        DispatchQueue.main.async {
            if container.bounds.width > 0 && container.bounds.height > 0 {
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
        tv.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        tv.terminalDelegate = session.controller

        session.cachedTerminalView = tv
        session.controller.terminalView = tv
        return tv
    }
}

// MARK: - Workbench Settings

struct WorkbenchSettingsView: View {
    @Binding var columnsPerRow: Int
    @Binding var heightPercent: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workbench Settings")
                .font(.headline)

            // Columns per row
            VStack(alignment: .leading, spacing: 6) {
                Text("Columns per row")
                    .font(.system(size: 13, weight: .medium))
                Picker("", selection: $columnsPerRow) {
                    Text("1").tag(1)
                    Text("2").tag(2)
                    Text("3").tag(3)
                    Text("4").tag(4)
                }
                .pickerStyle(.segmented)
            }

            // Terminal height
            VStack(alignment: .leading, spacing: 6) {
                Text("Terminal height")
                    .font(.system(size: 13, weight: .medium))
                Picker("", selection: $heightPercent) {
                    Text("25%").tag(25)
                    Text("50%").tag(50)
                    Text("75%").tag(75)
                    Text("100%").tag(100)
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(16)
        .frame(width: 260)
    }
}

import Foundation

protocol AgentStateDetectorDelegate: AnyObject {
    func stateDetector(_ detector: AgentStateDetector, didDetectState state: SessionState)
}

class AgentStateDetector {
    weak var delegate: AgentStateDetectorDelegate?

    private var idleTimer: Timer?
    private var lastOutputTime: Date = Date()
    private var currentState: SessionState = .stopped
    private let idleThreshold: TimeInterval = 3.0

    // Patterns that indicate the agent is waiting for input
    private let waitingPatterns: [NSRegularExpression] = {
        let patterns = [
            "❯\\s*$",                    // Claude Code prompt
            ">\\s*$",                     // Generic prompt
            "\\$\\s*$",                   // Shell prompt
            "waiting for input",          // Explicit waiting
            "Enter your (message|response|input)",
            "What would you like",
            "How can I help",
        ]
        return patterns.compactMap { try? NSRegularExpression(pattern: $0, options: [.caseInsensitive]) }
    }()

    func start() {
        updateState(.running)
        startIdleTimer()
    }

    func stop() {
        idleTimer?.invalidate()
        idleTimer = nil
        updateState(.stopped)
    }

    func processTerminated() {
        idleTimer?.invalidate()
        idleTimer = nil
        updateState(.stopped)
    }

    func feedOutput(_ text: String) {
        lastOutputTime = Date()

        // Check for waiting patterns in the last few lines
        let lines = text.components(separatedBy: "\n")
        let recentText = lines.suffix(3).joined(separator: "\n")

        for pattern in waitingPatterns {
            let range = NSRange(recentText.startIndex..., in: recentText)
            if pattern.firstMatch(in: recentText, options: [], range: range) != nil {
                updateState(.waiting)
                return
            }
        }

        // Active output means running
        updateState(.running)
        restartIdleTimer()
    }

    func manualOverride(state: SessionState) {
        updateState(state)
    }

    // MARK: - Private

    private func updateState(_ newState: SessionState) {
        guard newState != currentState else { return }
        currentState = newState
        delegate?.stateDetector(self, didDetectState: newState)
    }

    private func startIdleTimer() {
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkIdle()
        }
    }

    private func restartIdleTimer() {
        lastOutputTime = Date()
    }

    private func checkIdle() {
        guard currentState == .running else { return }
        let elapsed = Date().timeIntervalSince(lastOutputTime)
        if elapsed > idleThreshold {
            updateState(.idle)
        }
    }
}

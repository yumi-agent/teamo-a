import Foundation

// Detection-layer state enum (internal to the detector subsystem)
enum SessionState: String {
    case running
    case idle
    case waiting
    case stopped
}

protocol AgentStateDetectorDelegate: AnyObject {
    func stateDetector(_ detector: AgentStateDetector, didDetectState state: SessionState)
}

class AgentStateDetector {
    weak var delegate: AgentStateDetectorDelegate?

    private var idleTimer: Timer?
    private var lastOutputTime: Date = Date()
    private var currentState: SessionState = .stopped
    private let idleThreshold: TimeInterval = 3.0

    private let waitingPatterns: [NSRegularExpression] = {
        let patterns = [
            "❯\\s*$",
            ">\\s*$",
            "\\$\\s*$",
            "waiting for input",
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

        // Strip ANSI escape sequences before pattern matching
        let stripped = stripAnsiEscapes(text)
        let lines = stripped.components(separatedBy: "\n")
        let recentText = lines.suffix(3).joined(separator: "\n")

        for pattern in waitingPatterns {
            let range = NSRange(recentText.startIndex..., in: recentText)
            if pattern.firstMatch(in: recentText, options: [], range: range) != nil {
                updateState(.waiting)
                return
            }
        }

        updateState(.running)
        restartIdleTimer()
    }

    private func stripAnsiEscapes(_ text: String) -> String {
        // Remove ANSI escape sequences: CSI (ESC[), OSC (ESC]), etc.
        let esc = "\u{1b}"
        let bel = "\u{07}"
        let pattern = "\(esc)\\[[0-9;]*[a-zA-Z]|\(esc)\\][^\(bel)]*\(bel)|\(esc)\\([A-Z]|\(esc)[=>]"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return text }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
    }

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
        if Date().timeIntervalSince(lastOutputTime) > idleThreshold {
            updateState(.idle)
        }
    }
}

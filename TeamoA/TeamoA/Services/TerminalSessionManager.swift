import Foundation
import SwiftTerm

/// Holds a single agent's terminal session — PTY + cached TerminalView.
/// Lifetime matches the agent, NOT the SwiftUI view.
class TerminalSession {
    let agentId: UUID
    let controller: TerminalController
    var cachedTerminalView: TerminalView?
    var isStarted = false

    init(agentId: UUID, controller: TerminalController) {
        self.agentId = agentId
        self.controller = controller
    }
}

/// Central manager for all terminal sessions. Lives at the app level
/// (injected via @EnvironmentObject) so sessions survive navigation.
class TerminalSessionManager: ObservableObject {
    private var sessions: [UUID: TerminalSession] = [:]

    /// Get or create a persistent session for the given agent.
    /// Idempotent — safe to call from SwiftUI body.
    func session(
        for agent: Agent,
        store: ProjectStore,
        notificationService: NotificationService
    ) -> TerminalSession {
        if let existing = sessions[agent.id] {
            return existing
        }

        let controller = TerminalController()
        controller.agent = agent
        controller.store = store
        controller.notificationService = notificationService

        let session = TerminalSession(agentId: agent.id, controller: controller)
        sessions[agent.id] = session
        return session
    }

    /// Restart a session — destroy old PTY/view, create fresh session, auto-start.
    /// Returns the new session. Safe to call even if no session exists yet.
    func restartSession(
        for agent: Agent,
        store: ProjectStore,
        notificationService: NotificationService
    ) -> TerminalSession {
        // Tear down existing session completely
        if let old = sessions.removeValue(forKey: agent.id) {
            old.controller.stopSession()
            old.cachedTerminalView?.removeFromSuperview()
            old.cachedTerminalView = nil
        }

        // Create fresh session
        let newSession = session(for: agent, store: store, notificationService: notificationService)
        newSession.isStarted = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [newSession] in
            newSession.controller.startSession()
        }
        objectWillChange.send()
        return newSession
    }

    /// Destroy a session (when agent is deleted).
    func destroySession(for agentId: UUID) {
        if let session = sessions.removeValue(forKey: agentId) {
            session.controller.stopSession()
            session.cachedTerminalView?.removeFromSuperview()
            session.cachedTerminalView = nil
        }
    }

    /// Destroy all sessions (app termination).
    func destroyAllSessions() {
        for (_, session) in sessions {
            session.controller.stopSession()
        }
        sessions.removeAll()
    }
}

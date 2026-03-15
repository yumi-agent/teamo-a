import SwiftUI

@main
struct TeamoAApp: App {
    @StateObject private var store = ProjectStore()
    @StateObject private var notificationService = NotificationService()
    @StateObject private var sessionManager = TerminalSessionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(notificationService)
                .environmentObject(sessionManager)
                .frame(minWidth: 960, minHeight: 640)
                .onAppear {
                    notificationService.requestPermission()
                    // Navigate to workbench if requested (works with or without --auto-setup)
                    if CommandLine.arguments.contains("--workbench") && store.hasWorkspace && !CommandLine.arguments.contains("--auto-setup") {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            NotificationCenter.default.post(name: .navigateToWorkbench, object: nil)
                        }
                    }
                    // Auto-setup for testing: --auto-setup creates workspace + agents
                    // --agents N controls how many agents to create (default 1)
                    if CommandLine.arguments.contains("--auto-setup") && !store.hasWorkspace {
                        store.createWorkspace(name: "TestWS", type: .personal)

                        var agentCount = 1
                        if let idx = CommandLine.arguments.firstIndex(of: "--agents"),
                           idx + 1 < CommandLine.arguments.count,
                           let n = Int(CommandLine.arguments[idx + 1]) {
                            agentCount = max(0, n)
                        }

                        let agentNames = ["Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta"]
                        let engines: [AgentEngine] = [.claudeCode, .codex, .claudeCode, .codex, .claudeCode, .codex]

                        let navigateToWorkbench = CommandLine.arguments.contains("--workbench")
                        let testNavPersistence = CommandLine.arguments.contains("--test-nav-persistence")

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            for i in 0..<agentCount {
                                let name = i < agentNames.count ? agentNames[i] : "Agent\(i+1)"
                                store.createAgent(
                                    name: name,
                                    role: i == 0 ? "Tester" : "",
                                    engine: i < engines.count ? engines[i] : .claudeCode,
                                    goalDescription: i == 0 ? "say hello world and nothing else" : nil
                                )
                            }
                            // Navigate to workbench after agents are created
                            if navigateToWorkbench || testNavPersistence {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    NotificationCenter.default.post(name: .navigateToWorkbench, object: nil)
                                }
                            }
                            // Navigation persistence test: Workbench → Agent Detail → Workbench
                            if testNavPersistence, let firstAgent = store.currentAgents.first {
                                // After 5s on Workbench, navigate to first agent
                                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                    NotificationCenter.default.post(
                                        name: .navigateToAgent,
                                        object: nil,
                                        userInfo: ["agentId": firstAgent.id]
                                    )
                                }
                                // After 10s, navigate back to Workbench
                                DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                                    NotificationCenter.default.post(name: .navigateToWorkbench, object: nil)
                                }
                            }
                        }
                    }
                }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1280, height: 800)
    }
}

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
                    // Auto-setup for testing: --auto-setup creates workspace + agent
                    if CommandLine.arguments.contains("--auto-setup") && !store.hasWorkspace {
                        store.createWorkspace(name: "TestWS", type: .personal)
                        // Delay agent creation so MainView has time to mount
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            store.createAgent(
                                name: "TestBot",
                                role: "Tester",
                                engine: .claudeCode,
                                goalDescription: "say hello world and nothing else"
                            )
                        }
                    }
                }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1280, height: 800)
    }
}

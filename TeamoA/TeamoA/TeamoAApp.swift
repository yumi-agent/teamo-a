import SwiftUI

@main
struct TeamoAApp: App {
    @StateObject private var sessionStore = SessionStore()
    @StateObject private var notificationService = NotificationService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionStore)
                .environmentObject(notificationService)
                .frame(minWidth: 900, minHeight: 600)
                .onAppear {
                    notificationService.requestPermission()
                }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1200, height: 800)
    }
}

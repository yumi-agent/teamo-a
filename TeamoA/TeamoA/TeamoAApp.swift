import SwiftUI

@main
struct TeamoAApp: App {
    @StateObject private var store = ProjectStore()
    @StateObject private var notificationService = NotificationService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(notificationService)
                .frame(minWidth: 960, minHeight: 640)
                .onAppear {
                    notificationService.requestPermission()
                }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1280, height: 800)
    }
}

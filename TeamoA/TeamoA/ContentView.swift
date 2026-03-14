import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @State private var selectedSessionId: UUID?
    @State private var showCreateSheet = false

    var body: some View {
        NavigationSplitView {
            SidebarView(
                selectedSessionId: $selectedSessionId,
                showCreateSheet: $showCreateSheet
            )
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } detail: {
            if let id = selectedSessionId,
               let session = sessionStore.session(byId: id) {
                SessionDetailView(session: session)
            } else {
                DashboardView(selectedSessionId: $selectedSessionId)
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateSessionView { newSession in
                sessionStore.addSession(newSession)
                selectedSessionId = newSession.id
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToSession)) { notification in
            if let id = notification.userInfo?["sessionId"] as? UUID {
                selectedSessionId = id
            }
        }
    }
}

extension Notification.Name {
    static let navigateToSession = Notification.Name("navigateToSession")
}

import SwiftUI

enum NavigationItem: Hashable {
    case dashboard
    case goals
    case issues
    case agent(UUID)
}

struct ContentView: View {
    @EnvironmentObject var store: ProjectStore
    @State private var selectedItem: NavigationItem? = .dashboard

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedItem: $selectedItem)
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } detail: {
            detailView
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToAgent)) { notification in
            if let id = notification.userInfo?["agentId"] as? UUID {
                selectedItem = .agent(id)
            }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedItem {
        case .dashboard, .none:
            DashboardView()
        case .goals:
            GoalsListView()
        case .issues:
            IssuesListView()
        case .agent(let id):
            if let agent = store.agent(byId: id) {
                AgentDetailView(agent: agent)
            } else {
                Text("Agent not found")
                    .foregroundColor(.secondary)
            }
        }
    }
}

extension Notification.Name {
    static let navigateToAgent = Notification.Name("navigateToAgent")
}

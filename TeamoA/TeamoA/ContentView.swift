import SwiftUI

enum NavigationItem: Hashable {
    case dashboard
    case workbench
    case goals
    case issues
    case settings
    case agent(UUID)
    case externalSession(String) // session id
}

struct ContentView: View {
    @EnvironmentObject var store: ProjectStore

    var body: some View {
        if store.hasWorkspace {
            MainView()
        } else {
            WelcomeView()
        }
    }
}

// MARK: - Main App View

struct MainView: View {
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
        .onReceive(NotificationCenter.default.publisher(for: .navigateToWorkbench)) { _ in
            selectedItem = .workbench
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedItem {
        case .dashboard, .none:
            DashboardView()
        case .workbench:
            WorkbenchView()
        case .goals:
            GoalsListView()
        case .issues:
            IssuesListView()
        case .settings:
            SettingsDetailView()
        case .agent(let id):
            if let agent = store.agent(byId: id) {
                AgentDetailView(agent: agent)
            } else {
                Text("Agent not found")
                    .foregroundColor(.secondary)
            }
        case .externalSession(let sessionId):
            ExternalSessionDetailView(sessionId: sessionId)
        }
    }
}

// MARK: - Welcome / Onboarding

struct WelcomeView: View {
    @EnvironmentObject var store: ProjectStore
    @State private var step = 0
    @State private var selectedType: WorkspaceType = .personal
    @State private var workspaceName = ""

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            if step == 0 {
                typeSelectionView
            } else {
                nameInputView
            }

            Spacer()

            // Footer
            HStack {
                Text("Teamo A")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("v0.2.0")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var typeSelectionView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                Text("Welcome to Teamo A")
                    .font(.largeTitle.bold())
                Text("The Agent IDE for orchestrating AI teams")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            Text("How will you use Teamo A?")
                .font(.headline)
                .padding(.top, 8)

            HStack(spacing: 20) {
                WorkspaceTypeCard(
                    type: .personal,
                    isSelected: selectedType == .personal,
                    onSelect: { selectedType = .personal }
                )
                WorkspaceTypeCard(
                    type: .team,
                    isSelected: selectedType == .team,
                    onSelect: { selectedType = .team }
                )
            }

            Button(action: { step = 1 }) {
                Text("Continue")
                    .font(.headline)
                    .frame(width: 200)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(40)
    }

    private var nameInputView: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Image(systemName: selectedType.iconName)
                    .font(.system(size: 36))
                    .foregroundColor(.blue)
                Text("Name your workspace")
                    .font(.title.bold())
                Text(selectedType == .personal
                     ? "This is your personal agent workspace"
                     : "Your team will collaborate here")
                    .foregroundColor(.secondary)
            }

            TextField("Workspace name", text: $workspaceName)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 16))
                .frame(width: 320)
                .onSubmit { createAndProceed() }

            HStack(spacing: 16) {
                Button("Back") { step = 0 }
                    .buttonStyle(.bordered)

                Button(action: createAndProceed) {
                    Text("Get Started")
                        .font(.headline)
                        .frame(width: 160)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(workspaceName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(40)
    }

    private func createAndProceed() {
        let name = workspaceName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        store.createWorkspace(name: name, type: selectedType)
    }
}

struct WorkspaceTypeCard: View {
    let type: WorkspaceType
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                Image(systemName: type.iconName)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .white : .blue)

                Text(type.displayName)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)

                Text(type.description)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
            .frame(width: 200, height: 160)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.secondary.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

extension Notification.Name {
    static let navigateToAgent = Notification.Name("navigateToAgent")
    static let navigateToWorkbench = Notification.Name("navigateToWorkbench")
}

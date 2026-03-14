import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var store: ProjectStore
    @Binding var selectedItem: NavigationItem?
    @State private var showCreateIssue = false

    var body: some View {
        VStack(spacing: 0) {
            // Project Picker
            projectPicker
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            Divider()

            List(selection: $selectedItem) {
                // Dashboard
                NavigationLink(value: NavigationItem.dashboard) {
                    HStack {
                        Label("Dashboard", systemImage: "square.grid.2x2")
                        Spacer()
                        if store.runningAgentsCount > 0 {
                            HStack(spacing: 4) {
                                Circle().fill(.blue).frame(width: 6, height: 6)
                                Text("\(store.runningAgentsCount) live")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }

                Section("WORK") {
                    NavigationLink(value: NavigationItem.issues) {
                        Label {
                            HStack {
                                Text("Issues")
                                Spacer()
                                if store.openIssuesCount > 0 {
                                    Text("\(store.openIssuesCount)")
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(.secondary.opacity(0.2)))
                                }
                            }
                        } icon: {
                            Image(systemName: "circle.dotted")
                        }
                    }

                    NavigationLink(value: NavigationItem.goals) {
                        Label {
                            HStack {
                                Text("Goals")
                                Spacer()
                                Text("\(store.goalsCompletedCount)/\(store.goalsTotalCount)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        } icon: {
                            Image(systemName: "target")
                        }
                    }
                }

                Section("AGENTS") {
                    ForEach(store.currentAgents) { agent in
                        NavigationLink(value: NavigationItem.agent(agent.id)) {
                            AgentSidebarRow(agent: agent)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
        }
        .toolbar {
            ToolbarItem {
                Button(action: { showCreateIssue = true }) {
                    Image(systemName: "plus")
                }
                .help("New Issue")
            }
        }
        .sheet(isPresented: $showCreateIssue) {
            CreateIssueView()
        }
    }

    private var projectPicker: some View {
        Menu {
            ForEach(store.projects) { project in
                Button(action: { store.switchProject(project.id) }) {
                    HStack {
                        Circle().fill(project.color.color).frame(width: 8, height: 8)
                        Text(project.name)
                        if project.id == store.currentProjectId {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                if let project = store.currentProject {
                    Circle().fill(project.color.color).frame(width: 10, height: 10)
                    Text(project.name)
                        .font(.headline)
                } else {
                    Text("Select Project")
                        .font(.headline)
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .menuStyle(.borderlessButton)
    }
}

struct AgentSidebarRow: View {
    @ObservedObject var agent: Agent

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: agent.iconName)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 20)

            Text(agent.name)
                .lineLimit(1)

            Spacer()

            if agent.state == .running {
                HStack(spacing: 4) {
                    Circle().fill(.green).frame(width: 6, height: 6)
                    Text("live")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            } else {
                Circle()
                    .fill(agent.state.color)
                    .frame(width: 8, height: 8)
            }
        }
    }
}

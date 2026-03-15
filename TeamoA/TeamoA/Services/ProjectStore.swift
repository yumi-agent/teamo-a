import Foundation
import SwiftUI

class ProjectStore: ObservableObject {
    @Published var workspaces: [Workspace] = []
    @Published var currentWorkspaceId: UUID?
    @Published var goals: [Goal] = []
    @Published var issues: [Issue] = []
    @Published var agents: [Agent] = []
    @Published var activities: [ActivityEvent] = []

    private var nextIssueNumber = 1

    var hasWorkspace: Bool {
        !workspaces.isEmpty
    }

    // MARK: - Current Workspace

    var currentWorkspace: Workspace? {
        workspaces.first { $0.id == currentWorkspaceId }
    }

    var currentGoals: [Goal] {
        guard let wid = currentWorkspaceId else { return [] }
        return goals.filter { $0.projectId == wid }
    }

    var currentIssues: [Issue] {
        guard let wid = currentWorkspaceId else { return [] }
        return issues.filter { $0.projectId == wid }
    }

    var currentAgents: [Agent] {
        guard let wid = currentWorkspaceId else { return [] }
        return agents.filter { $0.projectId == wid }
    }

    var currentActivities: [ActivityEvent] {
        guard let wid = currentWorkspaceId else { return [] }
        return activities.filter { $0.projectId == wid }
            .sorted { $0.timestamp > $1.timestamp }
    }

    // MARK: - Stats

    var runningAgentsCount: Int {
        currentAgents.filter { $0.state == .running }.count
    }

    var pausedAgentsCount: Int {
        currentAgents.filter { $0.state == .paused }.count
    }

    var openIssuesCount: Int {
        currentIssues.filter { $0.status != .done }.count
    }

    var blockedIssuesCount: Int {
        currentIssues.filter { $0.status == .blocked }.count
    }

    var goalsCompletedCount: Int {
        currentGoals.filter { $0.status == .completed }.count
    }

    var goalsTotalCount: Int {
        currentGoals.count
    }

    // MARK: - Workspace

    func createWorkspace(name: String, type: WorkspaceType) {
        let ws = Workspace(
            name: name,
            workspaceType: type,
            workingDirectory: NSHomeDirectory()
        )
        workspaces.append(ws)
        currentWorkspaceId = ws.id
    }

    func switchWorkspace(_ id: UUID) {
        currentWorkspaceId = id
    }

    // MARK: - Agent

    func createAgent(name: String, role: String, engine: AgentEngine, goalDescription: String?, workingDirectory: String = NSHomeDirectory()) {
        guard let wid = currentWorkspaceId else { return }

        let goalDesc = goalDescription?.trimmingCharacters(in: .whitespaces)
        let agent = Agent(
            projectId: wid,
            name: name,
            role: role,
            engine: engine,
            iconName: iconForRole(role),
            goalDescription: (goalDesc?.isEmpty == false) ? goalDesc : nil,
            workingDirectory: workingDirectory
        )
        agents.append(agent)
        addActivity(agentName: name, action: "joined the workspace")

        // Create a linked goal if provided
        if let desc = goalDesc, !desc.isEmpty {
            let goal = Goal(
                projectId: wid,
                title: desc,
                description: "Goal assigned to \(name)"
            )
            goals.append(goal)
            addActivity(action: "created goal", detail: desc)
        }

        // Navigate to agent terminal
        NotificationCenter.default.post(
            name: .navigateToAgent,
            object: nil,
            userInfo: ["agentId": agent.id]
        )
    }

    private func iconForRole(_ role: String) -> String {
        let lower = role.lowercased()
        if lower.contains("architect") { return "building.columns" }
        if lower.contains("frontend") || lower.contains("ui") { return "paintbrush" }
        if lower.contains("backend") || lower.contains("server") { return "server.rack" }
        if lower.contains("qa") || lower.contains("test") { return "checkmark.shield" }
        if lower.contains("devops") || lower.contains("infra") { return "gearshape.2" }
        if lower.contains("data") { return "chart.bar" }
        return "person.crop.circle"
    }

    // MARK: - Goals

    func addGoal(_ goal: Goal) {
        goals.append(goal)
        addActivity(action: "created goal", detail: goal.title)
    }

    // MARK: - Issues

    func addIssue(title: String, description: String = "", priority: IssuePriority = .medium, goalId: UUID? = nil) {
        guard let wid = currentWorkspaceId else { return }
        let issue = Issue(
            projectId: wid,
            goalId: goalId,
            issueNumber: nextIssueNumber,
            title: title,
            description: description,
            priority: priority
        )
        nextIssueNumber += 1
        issues.append(issue)
        addActivity(action: "created issue", detail: issue.issueTag + " " + title)
    }

    func updateIssueStatus(_ issue: Issue, to status: IssueStatus) {
        issue.status = status
        issue.updatedAt = Date()
        addActivity(action: "changed status to \(status.displayName.lowercased())", detail: issue.issueTag, issueTag: issue.issueTag)
        objectWillChange.send()
    }

    func assignIssue(_ issue: Issue, to agent: Agent) {
        issue.assigneeId = agent.id
        issue.assigneeName = agent.name
        issue.updatedAt = Date()
        addActivity(agentName: agent.name, action: "was assigned", detail: issue.issueTag, issueTag: issue.issueTag)
        objectWillChange.send()
    }

    func updateAgentState(_ agent: Agent, to state: AgentState) {
        agent.state = state
        agent.lastActivityAt = Date()
        addActivity(agentName: agent.name, action: "state changed to \(state.displayName.lowercased())")
        objectWillChange.send()
    }

    func agent(byId id: UUID) -> Agent? {
        agents.first { $0.id == id }
    }

    func issuesForAgent(_ agentId: UUID) -> [Issue] {
        currentIssues.filter { $0.assigneeId == agentId }
    }

    func issuesForGoal(_ goalId: UUID) -> [Issue] {
        currentIssues.filter { $0.goalId == goalId }
    }

    // MARK: - Activity

    func addActivity(agentName: String? = nil, action: String, detail: String = "", issueTag: String? = nil) {
        guard let wid = currentWorkspaceId else { return }
        let event = ActivityEvent(
            projectId: wid,
            agentName: agentName,
            action: action,
            detail: detail,
            issueTag: issueTag
        )
        activities.append(event)
        objectWillChange.send()
    }
}

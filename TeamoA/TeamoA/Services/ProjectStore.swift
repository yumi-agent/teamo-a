import Foundation
import SwiftUI

class ProjectStore: ObservableObject {
    @Published var projects: [Project] = []
    @Published var currentProjectId: UUID?
    @Published var goals: [Goal] = []
    @Published var issues: [Issue] = []
    @Published var agents: [Agent] = []
    @Published var activities: [ActivityEvent] = []

    private var nextIssueNumber = 1

    init() {
        loadOrCreateSampleData()
    }

    // MARK: - Current Project

    var currentProject: Project? {
        projects.first { $0.id == currentProjectId }
    }

    var currentGoals: [Goal] {
        guard let pid = currentProjectId else { return [] }
        return goals.filter { $0.projectId == pid }
    }

    var currentIssues: [Issue] {
        guard let pid = currentProjectId else { return [] }
        return issues.filter { $0.projectId == pid }
    }

    var currentAgents: [Agent] {
        guard let pid = currentProjectId else { return [] }
        return agents.filter { $0.projectId == pid }
    }

    var currentActivities: [ActivityEvent] {
        guard let pid = currentProjectId else { return [] }
        return activities.filter { $0.projectId == pid }
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

    // MARK: - CRUD

    func addProject(_ project: Project) {
        projects.append(project)
        if currentProjectId == nil {
            currentProjectId = project.id
        }
    }

    func switchProject(_ id: UUID) {
        currentProjectId = id
    }

    func addGoal(_ goal: Goal) {
        goals.append(goal)
        addActivity(action: "created goal", detail: goal.title)
    }

    func addIssue(title: String, description: String = "", priority: IssuePriority = .medium, goalId: UUID? = nil) {
        guard let pid = currentProjectId else { return }
        let issue = Issue(
            projectId: pid,
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

    func addAgent(_ agent: Agent) {
        agents.append(agent)
        addActivity(action: "added agent", detail: agent.name)
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
        guard let pid = currentProjectId else { return }
        let event = ActivityEvent(
            projectId: pid,
            agentName: agentName,
            action: action,
            detail: detail,
            issueTag: issueTag
        )
        activities.append(event)
        objectWillChange.send()
    }

    // MARK: - Sample Data

    private func loadOrCreateSampleData() {
        let projectId = UUID()

        let project = Project(
            id: projectId,
            name: "Teamo A",
            color: .blue,
            workingDirectory: NSHomeDirectory() + "/teamo-a"
        )
        projects.append(project)
        currentProjectId = projectId

        // Goals
        let goalMVP = Goal(id: UUID(), projectId: projectId, title: "Launch MVP",
                           description: "Ship the first working version of Teamo A with core agent management features",
                           status: .inProgress, progress: 0.65,
                           createdAt: Date().addingTimeInterval(-86400 * 5))
        let goalTerminal = Goal(id: UUID(), projectId: projectId, title: "Terminal Integration",
                                description: "Integrate SwiftTerm for full PTY-based terminal emulation",
                                status: .completed, progress: 1.0,
                                createdAt: Date().addingTimeInterval(-86400 * 7))
        let goalCI = Goal(id: UUID(), projectId: projectId, title: "CI/CD Pipeline",
                          description: "Set up automated testing and deployment pipeline",
                          status: .notStarted, progress: 0,
                          createdAt: Date().addingTimeInterval(-86400 * 2))
        let goalMultiAgent = Goal(id: UUID(), projectId: projectId, title: "Multi-Agent Orchestration",
                                  description: "Enable agents to collaborate, delegate issues, and review each other's work",
                                  status: .inProgress, progress: 0.3,
                                  createdAt: Date().addingTimeInterval(-86400 * 3))
        goals = [goalMVP, goalTerminal, goalCI, goalMultiAgent]

        // Agents
        let agentArchitect = Agent(id: UUID(), projectId: projectId, name: "Architect",
                                   role: "System Architect", engine: .claudeCode,
                                   iconName: "building.columns", state: .idle,
                                   createdAt: Date().addingTimeInterval(-86400 * 5))
        let agentFrontend = Agent(id: UUID(), projectId: projectId, name: "FrontendDev",
                                  role: "SwiftUI Engineer", engine: .claudeCode,
                                  iconName: "paintbrush", state: .running,
                                  createdAt: Date().addingTimeInterval(-86400 * 4))
        let agentBackend = Agent(id: UUID(), projectId: projectId, name: "BackendDev",
                                 role: "Backend Engineer", engine: .codex,
                                 iconName: "server.rack", state: .idle,
                                 createdAt: Date().addingTimeInterval(-86400 * 4))
        let agentQA = Agent(id: UUID(), projectId: projectId, name: "QA",
                            role: "Quality Assurance", engine: .claudeCode,
                            iconName: "checkmark.shield", state: .paused,
                            createdAt: Date().addingTimeInterval(-86400 * 3))
        agents = [agentArchitect, agentFrontend, agentBackend, agentQA]

        // Issues
        nextIssueNumber = 1
        let issues: [(String, String, IssueStatus, IssuePriority, UUID?, UUID?)] = [
            ("Implement Dashboard stats cards", "Add stat cards showing agents enabled, tasks in progress, and pending approvals", .done, .high, agentFrontend.id, goalMVP.id),
            ("Fix PTY FD leak on rapid session restart", "When rapidly starting/stopping sessions, file descriptors are not properly closed", .inProgress, .critical, agentBackend.id, goalTerminal.id),
            ("Design multi-agent communication protocol", "Define how agents delegate issues and respond to each other", .inProgress, .high, agentArchitect.id, goalMultiAgent.id),
            ("Add Goal progress tracking UI", "Show progress bars and completion percentage for each goal", .todo, .medium, nil, goalMVP.id),
            ("Set up GitHub Actions workflow", "Create CI pipeline for automated builds and tests", .todo, .medium, nil, goalCI.id),
            ("Agent state detection false positives", "Idle detection triggers too early on slow networks", .blocked, .high, agentFrontend.id, goalMVP.id),
            ("Implement issue assignment flow", "Allow agents to pick up issues and mark them in progress", .done, .high, agentArchitect.id, goalMultiAgent.id),
            ("Add notification click-to-navigate", "Clicking a notification should jump to the relevant agent terminal", .done, .medium, agentFrontend.id, goalMVP.id),
        ]

        for (i, item) in issues.enumerated() {
            let issue = Issue(
                projectId: projectId,
                goalId: item.5,
                issueNumber: i + 1,
                title: item.0,
                description: item.1,
                status: item.2,
                priority: item.3,
                assigneeId: item.4,
                assigneeName: item.4 != nil ? self.agents.first(where: { $0.id == item.4 })?.name : nil,
                createdAt: Date().addingTimeInterval(-86400 * Double(8 - i))
            )
            self.issues.append(issue)
        }
        nextIssueNumber = issues.count + 1

        // Activities
        let activityData: [(String?, String, String, Double, String?)] = [
            ("FrontendDev", "commented on", "TA-6", 180, "TA-6"),
            ("FrontendDev", "changed status from in progress to done on", "TA-8", 360, "TA-8"),
            ("Architect", "was assigned", "TA-3", 600, "TA-3"),
            ("BackendDev", "started working on", "TA-2", 900, "TA-2"),
            (nil, "created issue", "TA-5 Set up GitHub Actions workflow", 1800, "TA-5"),
            ("QA", "reported", "TA-6 Agent state detection false positives", 2400, "TA-6"),
            ("Architect", "completed", "TA-7", 3600, "TA-7"),
            ("FrontendDev", "started", "TA-1", 7200, "TA-1"),
            (nil, "created goal", "Multi-Agent Orchestration", 10800, nil),
            ("FrontendDev", "invoked", "", 14400, nil),
        ]

        for item in activityData {
            let event = ActivityEvent(
                projectId: projectId,
                agentName: item.0,
                action: item.1,
                detail: item.2,
                timestamp: Date().addingTimeInterval(-item.3),
                issueTag: item.4
            )
            activities.append(event)
        }

        // Second project
        let project2Id = UUID()
        let project2 = Project(
            id: project2Id,
            name: "ClawSchool",
            color: .green,
            workingDirectory: NSHomeDirectory() + "/clawschool"
        )
        projects.append(project2)
    }
}

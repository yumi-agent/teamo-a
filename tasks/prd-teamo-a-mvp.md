# PRD: Teamo A — Agent IDE for macOS (MVP)

## Introduction

Teamo A 是全球首个以 Agent Session 为核心抽象的 macOS 原生桌面 IDE。用户可以同时管理多个 AI 编码代理（Claude Code / Codex），在 Dashboard 总览全局状态，通过 Workbench 多终端视图同屏操作，利用 Goals 和 Issues 系统进行项目管理，并在 agent 状态变化时收到实时通知。

**竞品空白**：Cursor 以代码文件为中心，Warp 以终端为中心——没有人以 "Agent Session" 作为 IDE 的核心抽象。

## Goals

- 用户可以创建、管理、监控多个 AI agent 的终端会话
- 提供 Dashboard 总览所有 agent 状态
- Workbench 多终端同屏视图，可配置布局
- Goals/Issues 系统追踪项目进展
- 状态自动检测 + macOS 通知
- **数据持久化**：关闭 app 重启后数据不丢失
- **Agent 生命周期管理**：启动、暂停、重启、删除

## User Stories

### US-001: Workspace Onboarding
**Description:** As a new user, I want to create a workspace so I have a place to manage my agents.

**Acceptance Criteria:**
- [x] Welcome 页面让用户选择 Personal/Team 类型
- [x] 输入 workspace 名称后进入主界面
- [x] 编译通过

### US-002: 侧边栏导航结构
**Description:** As a user, I want a clean sidebar to navigate between Dashboard, Workbench, Issues, Goals, and individual agents.

**Acceptance Criteria:**
- [x] Dashboard / Workbench / Issues / Goals 为顶级平级项
- [x] AGENTS 分组下列出所有 agent
- [x] 无多余的 "WORK" 分组
- [x] 编译通过

### US-003: Agent 创建页面
**Description:** As a user, I want to create an agent with engine selection, optional role, multi-line goal, and working directory.

**Acceptance Criteria:**
- [x] Engine 只有 Claude Code 和 Codex 两个选项
- [x] Role 标记为可选
- [x] Goal 为多行 TextEditor
- [x] Working directory 选择器，默认 ~/
- [x] 创建后自动导航到 Agent Detail 页
- [x] 编译通过

### US-004: PTY 终端集成
**Description:** As a user, I want each agent to have a real terminal that launches the corresponding AI engine.

**Acceptance Criteria:**
- [x] openpty() + posix_spawn 启动 /bin/zsh --login
- [x] 自动执行引擎启动命令 (claude / codex)
- [x] 终端支持完整 VT100/Xterm/ANSI
- [x] 支持 resize
- [x] 编译通过

### US-005: 终端 Session 持久化（跨导航）
**Description:** As a user, I want terminal content preserved when I navigate away and back.

**Acceptance Criteria:**
- [x] TerminalSessionManager 在 App 级持有 TerminalView 缓存
- [x] 从 Agent Detail 切走再切回，终端内容不丢失
- [x] Workbench 和 Agent Detail 共享同一 TerminalView
- [x] 编译通过

### US-006: Agent 状态自动检测
**Description:** As a user, I want to see the current state of each agent (running/idle/waiting/stopped) automatically.

**Acceptance Criteria:**
- [x] ANSI 转义清洗后正则匹配等待模式
- [x] 3 秒静默 → idle
- [x] 进程退出 → stopped
- [x] decoration 行不触发误判
- [x] 编译通过

### US-007: macOS 通知
**Description:** As a user, I want to receive notifications when an agent changes state.

**Acceptance Criteria:**
- [x] Running → Waiting 触发 "等待输入" 通知
- [x] 进程终止触发 "完成" 通知
- [x] 点击通知跳转到对应 agent
- [x] 编译通过

### US-008: Dashboard 总览
**Description:** As a user, I want a dashboard showing key metrics and recent activity.

**Acceptance Criteria:**
- [x] 4 个 StatCard: Agents Enabled, Open Issues, Goals Progress, Pending Approvals
- [x] Recent Activity 流
- [x] Recent Issues 列表
- [x] 编译通过

### US-009: Workbench 多终端视图
**Description:** As a user, I want to see all agent terminals simultaneously in a configurable grid.

**Acceptance Criteria:**
- [x] LazyVGrid 支持 1-4 列配置
- [x] 终端高度 25%/50%/75%/100% 可选
- [x] 0 个 agent 显示空状态
- [x] 单个 agent 占满全宽
- [x] Settings 齿轮图标弹出配置 popover
- [x] 编译通过
- [x] 全部 13 个 E2E 测试用例通过

### US-010: Goals 管理
**Description:** As a user, I want to create and track goals with status and progress.

**Acceptance Criteria:**
- [x] 3 状态分组 (Not Started / In Progress / Completed)
- [x] 进度条显示
- [x] 关联 issues 数量
- [x] 创建 Goal 弹窗
- [x] 编译通过

### US-011: Issues 管理
**Description:** As a user, I want to create and manage issues with priorities and status tracking.

**Acceptance Criteria:**
- [x] 4 状态看板 (TODO / IN PROGRESS / BLOCKED / DONE)
- [x] 优先级颜色区分
- [x] Issue 详情 Sheet
- [x] 状态变更按钮
- [x] 创建 Issue 弹窗，支持 Goal 关联
- [x] 编译通过

### US-012: 自动发送初始 Goal
**Description:** As a user, I want the agent to automatically receive its initial goal when it's ready.

**Acceptance Criteria:**
- [x] state 变为 waiting 时自动发送 goal
- [x] 8 秒 timer fallback 保底
- [x] 编译通过

### US-013: E2E 测试基础设施
**Description:** As a developer, I need CLI flags for automated E2E testing.

**Acceptance Criteria:**
- [x] --auto-setup 创建 workspace + agents
- [x] --agents N 控制 agent 数量
- [x] --workbench 自动导航到 Workbench
- [x] --test-nav-persistence 测试导航持久化
- [x] 编译通过

---

以下为待实现的用户故事：

### US-014: 数据持久化 — Workspace 和 Agent
**Description:** As a user, I want my workspace and agents to persist across app restarts.

**Acceptance Criteria:**
- [ ] Workspace 数据保存到 ~/Library/Application Support/TeamoA/workspaces.json
- [ ] Agent 数据保存到 ~/Library/Application Support/TeamoA/agents.json
- [ ] App 启动时自动加载已保存数据
- [ ] 创建/修改/删除操作实时落盘
- [ ] 编译通过
- [ ] E2E: 创建 workspace + agent，退出 app，重新启动，数据还在

### US-015: 数据持久化 — Goals 和 Issues
**Description:** As a user, I want my goals and issues to persist across app restarts.

**Acceptance Criteria:**
- [ ] Goals 保存到 ~/Library/Application Support/TeamoA/goals.json
- [ ] Issues 保存到 ~/Library/Application Support/TeamoA/issues.json
- [ ] 关联关系（issue → goal, issue → agent）正确恢复
- [ ] 编译通过

### US-016: Agent 生命周期 — 重启和删除
**Description:** As a user, I want to restart a stopped agent or delete an agent entirely.

**Acceptance Criteria:**
- [ ] Agent Detail 页面有 "Restart" 按钮（仅 stopped 状态可见）
- [ ] Restart 关闭旧 PTY，创建新 session，重新启动引擎
- [ ] 侧边栏 agent 行右键菜单有 "Delete" 选项
- [ ] 删除前弹出确认对话框
- [ ] 删除后终止 PTY 进程，清理 session，从列表移除
- [ ] 编译通过
- [ ] E2E: 创建 agent → 停止 → 重启 → 验证终端工作

### US-017: Settings 视图
**Description:** As a user, I want a settings/preferences page for app-level configuration.

**Acceptance Criteria:**
- [ ] 侧边栏底部或菜单栏有 Settings 入口
- [ ] 设置项：默认引擎、默认工作目录、通知开关
- [ ] 设置保存到 UserDefaults
- [ ] 编译通过

### US-018: 终端输出搜索
**Description:** As a user, I want to search within a terminal's output to find specific text.

**Acceptance Criteria:**
- [ ] Agent Detail 页面有搜索图标，点击展开搜索栏
- [ ] 输入关键词高亮匹配行
- [ ] 支持上/下导航匹配结果
- [ ] 编译通过

### US-019: Agent 批量操作
**Description:** As a user, I want to start/stop all agents at once from the Workbench.

**Acceptance Criteria:**
- [ ] Workbench header 增加 "Start All" / "Stop All" 按钮
- [ ] Start All 启动所有 stopped 状态的 agent
- [ ] Stop All 终止所有 running 状态的 agent
- [ ] 按钮根据当前状态动态显示/隐藏
- [ ] 编译通过

### US-020: 活动日志持久化
**Description:** As a user, I want to see activity history across app sessions.

**Acceptance Criteria:**
- [ ] ActivityEvent 保存到 ~/Library/Application Support/TeamoA/activities.jsonl（追加写入）
- [ ] 限制最多保留最近 1000 条
- [ ] App 启动时加载
- [ ] 编译通过

## Functional Requirements

- FR-1: 所有数据（workspace、agents、goals、issues、activities）持久化到 JSON 文件
- FR-2: Agent 支持完整生命周期：创建 → 运行 → 暂停 → 重启 → 删除
- FR-3: Workbench 支持批量操作（全部启动/停止）
- FR-4: 终端输出支持文本搜索
- FR-5: Settings 页面管理 app 级配置

## Non-Goals

- 不做 session 历史回放（transcript 查看）—— 留给后续版本
- 不做多 workspace 切换 UI —— MVP 只支持单 workspace
- 不做 Bark 推送 —— 留给后续版本
- 不做终端背景色自定义 —— 留给后续版本
- 不做 XCTest 单元测试 —— 用 E2E 截图验证代替

## Technical Considerations

- 持久化使用 JSON 文件，不用 SQLite（MVP 阶段足够）
- 存储路径：`~/Library/Application Support/TeamoA/`
- Agent 的 PTY FD 上限 20，超限拒绝创建
- 删除 agent 必须先 SIGTERM → 3s → SIGKILL PTY 进程
- 所有 @AppStorage key 的 bundle ID 是 `com.teamolab.teamoa`

## Success Metrics

- 用户可以关闭 app 再打开，所有 workspace/agent/goal/issue 数据完整保留
- 4 个 agent 同屏运行 30 分钟无崩溃、无 FD 泄漏
- 创建到运行一个 agent 不超过 3 步操作

## Open Questions

- 是否需要终端会话内容（transcript）持久化？当前 MVP 不做
- 是否需要 agent 模板（预设配置快速创建）？待用户反馈

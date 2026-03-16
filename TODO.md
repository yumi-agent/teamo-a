# Teamo A — TODO（按用户路径 + 验收标准）

## P0：主链路可用

- [x] **编译通过** — `xcodebuild Debug` → BUILD SUCCEEDED
- [x] **New Agent 表单可输入** — TextField 能获取焦点、输入文字
- [x] **New Agent 消费 Settings 默认值** — Settings 设的 engine/目录反映到 New Agent 表单
- [x] **New Agent → 自动跳转 Agent Detail** — 创建后 sheet dismiss，自动导航到 agent 详情
- [ ] **终端可见/可输入/有输出** — Agent Detail 终端区域 3s 内有 shell 输出；底部输入框发送 `echo hello` 后终端显示 hello
- [x] **Workbench Start All / Stop All** — 按钮状态与 agent 实际状态同步；Start All 全绿，Stop All 全灰

## P1：核心体验完善

- [ ] **Session 持久化（对标 opcode）** — workspace 选中后 session 列表快速加载；点 session 立刻显示历史；重启 app 后记忆仍在
- [ ] **Pause / Restart / Delete 真实语义** — Pause 发送 SIGTSTP；Restart 销毁旧 session 重新启动 PTY；Delete 终止进程并清理数据
- [ ] **Onboarding 闭环** — Welcome → 选类型 → 命名 → 创建 workspace → 进入 Dashboard，全链路无白屏
- [ ] **Issue Detail 闭环** — 点 Issue 弹出详情面板，可编辑状态/优先级/指派
- [ ] **Assign Issue 闭环** — Agent Detail 点 Assign Issue → 选择 Issue → 确认分配 → Issue 列表更新 assignee
- [ ] **New Goal 闭环** — Goals 页面创建目标 → 关联 Issues → 进度自动计算
- [ ] **New Issue 闭环** — Issues 页面创建 Issue → 选优先级/指派 → 出现在看板
- [ ] **数据联动一致** — Dashboard 统计数、Goals 进度、Issues 看板、Agent 分配数四处同步

## P2：体验打磨

- [ ] **外部 Claude Sessions** — 不只显示元数据，嵌入终端历史预览或消息摘要
- [ ] **终端搜索统一** — 收口为一套搜索逻辑（AgentDetail + TerminalContainer 合并）
- [ ] **通知跳转** — 点通知 → app 激活 → 自动跳转到对应 agent 终端
- [ ] **修复后自动构建启动** — 每次代码修改后自动 xcodebuild + open app

## 已完成历史

<details>
<summary>Phase 0-2 历史（折叠）</summary>

- [x] Xcode 项目结构 + SPM SwiftTerm 依赖
- [x] Project/Goal/Issue/Agent/ActivityEvent 模型
- [x] ProjectStore 统一数据层
- [x] 侧边栏 + Dashboard + Goals + Issues + Agent 详情页
- [x] UI 自动化测试验证（Dashboard/Issues/Goals/Agent/Terminal/创建/切换）
- [x] PTY 终端集成（posix_spawn + SwiftTerm）
- [x] 本地 Claude session 发现（两阶段扫描）
- [x] 终端输出搜索
- [x] Settings 页面（默认引擎/目录/通知/Workbench 布局）
- [x] Agent 批量操作（Start All / Stop All）
- [x] Session scanner 性能优化（跳过 lsof 瓶颈）
- [x] ClaudeSessionReader 服务（读取 ~/.claude/projects/ JSONL）
</details>

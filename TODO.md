# Teamo A - TODO

## Phase 0: 项目骨架
- [x] Xcode 项目结构
- [x] SPM SwiftTerm 依赖
- [x] xcodeproj 生成（手工 pbxproj）
- [x] xcodebuild 编译通过（macOS 13.3 / Xcode 14.3.1）
- [x] Git + GitHub: https://github.com/yumi-agent/teamo-a

## Phase 1: 产品架构重构（参考 Paperclip）
- [x] **Project 模型** — 顶层实体，项目切换器
- [x] **Goal 模型** — 目标追踪，进度条，关联 Issues
- [x] **Issue 模型** — 看板分组（TODO/In Progress/Blocked/Done），优先级，分配
- [x] **Agent 模型** — 命名角色，状态管理，Issue 分配
- [x] **ActivityEvent 模型** — 活动流
- [x] **ProjectStore** — 统一数据层，样例数据
- [x] **侧边栏重构** — 项目选择 > Dashboard > Issues > Goals > Agents
- [x] **Dashboard 重构** — 统计卡片 + 活动流 + 最近 Issues
- [x] **Goals 页面** — 分组列表 + 进度条 + 创建弹窗
- [x] **Issues 页面** — 看板分组 + Issue 详情 + 创建弹窗
- [x] **Agent 详情页** — 头部信息 + 统计 + 分配的 Issues + Invoke 终端

## Phase 2: UI 自动化测试验证
- [x] Dashboard 页面 — 统计卡片显示正确（4 Agents, 5 Issues, 1/4 Goals, 1 Approval）
- [x] Issues 页面 — 4 个状态分组正确显示，9 个 Issue
- [x] Goals 页面 — 4 个目标按状态分组，进度条和百分比正确
- [x] Agent 详情页 — FrontendDev 显示 Latest Run + 统计 + Assigned Issues
- [x] 终端 Invoke — 点击 Invoke 后终端区域出现，按钮变为 Hide Terminal
- [x] 创建 Issue — 弹窗正常，输入标题后 Create 按钮可用，提交后出现在 TODO 分组
- [x] 项目切换 — 下拉菜单显示 Teamo A 和 ClawSchool，checkmark 标记当前

## 待完成
- [ ] Issue 详情弹窗 — 点击 Issue 行打开详情面板（已实现，待 UI 验证）
- [ ] Assign Issue Sheet — Agent 详情页的 Assign Issue 按钮
- [ ] Goal 创建弹窗 — New Goal 按钮功能
- [ ] 项目切换后数据联动 — 切到 ClawSchool 后 Dashboard/Issues/Goals/Agents 清空
- [ ] 持久化 — 当前仅内存样例数据，需 JSON 持久化
- [ ] PTY 终端集成 — 实际启动 claude/codex 进程
- [ ] XCTest 单元测试
- [ ] XCUITest UI 测试

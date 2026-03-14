# Teamo A - TODO

## Phase 0: 项目骨架
- [x] 创建 Xcode 项目目录结构
- [x] SPM 添加 SwiftTerm 依赖
- [x] 搭建完整目录结构（19 个 Swift 源文件）
- [x] 配置 Info.plist（非沙盒 + 通知描述）
- [x] Hardened Runtime + ad-hoc 签名
- [x] 生成 xcodeproj（手工 pbxproj）
- [x] xcodebuild 编译通过（macOS 13.3 / Xcode 14.3.1 / Swift 5.8.1）
- [x] SwiftTerm API 兼容性修复（ArraySlice<UInt8> + delegate 方法）
- [x] Git 初始化 + GitHub 仓库：https://github.com/yumi-agent/teamo-a

## Phase 1: PTY + SwiftTerm 集成
- [x] PTYManager.swift — openpty + Process + DispatchSource
- [x] SwiftTermView.swift — NSViewRepresentable + Coordinator + TerminalViewDelegate
- [x] TerminalContainerView.swift — TerminalController 连接 PTY 和 SwiftTerm
- [ ] 手动验证：启动 App → 创建 session → 输入 `echo hello` → 看到输出

## Phase 2: Session 管理 + Dashboard
- [x] AgentSession 数据模型（ObservableObject + Codable）
- [x] SessionStore（JSON 持久化 + JSONL transcript）
- [x] Dashboard UI（Grid + 搜索 + 统计栏）
- [x] SessionCard 卡片组件
- [x] CreateSessionView（引擎选择 + 目录选择 + 颜色）
- [x] SidebarView（活跃/停止分组）
- [ ] 手动验证：创建多个 session → Dashboard 正确显示

## Phase 3: 状态检测 + 通知
- [x] AgentStateDetector（正则匹配 + 空闲定时器 + 多信号融合）
- [x] NotificationService（UNUserNotificationCenter + 点击跳转）
- [ ] 手动验证：session 完成时收到通知 → 点击跳转

## Phase 4: 增强终端 + 打磨
- [x] InputAreaView（底部输入框 + 文件拖放）
- [x] StatusBadge（脉冲动画）
- [x] EngineIcon
- [ ] Session 历史查看（已停止 session 从 JSONL 加载 transcript）
- [ ] Dashboard 空状态引导

## 测试
- [ ] XCTest 单元测试（PTYManager / AgentStateDetector / SessionStore）
- [ ] XCUITest UI 测试
- [ ] Playwright E2E

# Issues

| # | 日期 | 问题描述 | 状态 | 解决方案 | Skill |
|---|------|---------|------|---------|-------|
| 1 | 2025-03-15 | E2E 测试中 `defaults write` 使用了错误的 bundle ID (`com.TeamoA.TeamoA`)，实际应为 `com.teamolab.teamoa`，导致 @AppStorage 设置无法生效，T06-T11 截图全部是默认 2 列 50% 布局 | closed | 用 PlistBuddy 从 Info.plist 读取正确的 CFBundleIdentifier，在测试脚本中使用正确的 bundle ID | - |
| 2 | 2025-03-15 | E2E 测试 `defaults write` 必须在 app 启动前设置，否则 @AppStorage 在 view init 时已读取默认值，后续外部修改不会触发更新 | closed | 在 cleanup() 后、open app 前设置 defaults，确保 @AppStorage 启动时就读到正确值 | - |
| 3 | 2026-03-16 | New Agent 对话框 TextField 无法输入 — macOS SwiftUI Form+.formStyle(.grouped) 在 .sheet() 中吞掉焦点 | closed | 用 VStack 替代 Form | - |
| 4 | 2026-03-16 | Agent 终端创建后黑屏 — TerminalView(frame:.zero) 导致 0x0 缓冲区，刷新仅一次 50ms 太早 | closed | 非零初始 frame + 多次递增重试刷新 + sizeChanged 强制刷新 + 延迟启动 session | - |
| 5 | 2026-03-16 | Workbench ↔ Agent 切换白屏 — 修改 PersistentTerminalView 时遗漏 WorkbenchTerminalRepresentable 同样代码，且 detail view 无背景色兜底 | closed | 同步修复 Workbench 的终端初始化 + detail view 加背景色 | pre-delivery-check |

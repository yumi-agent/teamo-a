# Issues

| # | 日期 | 问题描述 | 状态 | 解决方案 | Skill |
|---|------|---------|------|---------|-------|
| 1 | 2025-03-15 | E2E 测试中 `defaults write` 使用了错误的 bundle ID (`com.TeamoA.TeamoA`)，实际应为 `com.teamolab.teamoa`，导致 @AppStorage 设置无法生效，T06-T11 截图全部是默认 2 列 50% 布局 | closed | 用 PlistBuddy 从 Info.plist 读取正确的 CFBundleIdentifier，在测试脚本中使用正确的 bundle ID | - |
| 2 | 2025-03-15 | E2E 测试 `defaults write` 必须在 app 启动前设置，否则 @AppStorage 在 view init 时已读取默认值，后续外部修改不会触发更新 | closed | 在 cleanup() 后、open app 前设置 defaults，确保 @AppStorage 启动时就读到正确值 | - |

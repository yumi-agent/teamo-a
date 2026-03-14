# Teamo A — 需求收集与澄清

> Phase 1 | 创建时间: 2026-03-15 | 状态: 待确认

## 用户原始描述

将「管理的单位从传统 IDE 的文件，变成管理 Agent Session」抽象成一个 Mac App 产品。

- 产品名：**Teamo A**，定位「全球首个 Agent IDE」
- 创建新 agent session 时起名字（类比给新文件起文件名）
- 一个项目下可有多个并行 agent session
- 每个 session 有独立通知系统
- 每个 session 可选 agent 引擎（MVP: Claude Code、Codex）
- MVP 先支持 macOS

## Agent 理解

### 产品是什么（一句话）

**Teamo A 是一个 macOS 原生桌面应用，以 Agent Session 为核心管理单位，内嵌增强终端，提供 Dashboard 总览和多端通知，让用户像管理文件一样管理多个 AI Agent 的工作。**

### 解决谁的什么问题

| 用户 | 痛点 |
|------|------|
| 使用 Claude Code / Codex 的开发者 | 多个 agent 同时工作时，散落在不同终端窗口，无法一眼掌握全局状态 |
| 使用 Claude Code / Codex 的开发者 | 终端窗口之间切换混乱，通知无法精准定位到具体 session |
| 想用 AI agent 但不熟悉命令行的人 | 原始 CLI 体验门槛高，不知道怎么跟 agent 交互 |
| 多 agent 并行工作的团队/个人 | 缺乏统一的 Dashboard 查看所有 agent 的工作状态 |

### 核心功能（MVP）

| # | 功能 | 优先级 | 描述 |
|---|------|--------|------|
| 1 | **Dashboard 主页** | P0 | 展示所有 agent session 的状态（running/idle/waiting/stopped），提供可视化导航入口 |
| 2 | **创建 Session** | P0 | 起名字 + 选择 agent 引擎（Claude Code / Codex）+ 选择工作目录 |
| 3 | **内嵌增强终端** | P0 | 每个 session 内嵌完整终端，支持：醒目输入框、文件上传、鼠标控制、历史提问独立样式、背景色区分 |
| 4 | **Session 状态监控** | P0 | 实时检测 agent 状态：Running（工作中）/ Idle（空闲）/ Waiting（等待输入）/ Stopped（已结束） |
| 5 | **通知系统** | P0 | 每个 session 独立通知，Mac 原生通知 + 提示音，点击跳转到对应 session |
| 6 | **Session 历史记录** | P1 | 查看已结束的 session 历史，可回溯 |
| 7 | **Session 背景色/视觉区分** | P1 | 不同 session 用不同背景色，在 Dashboard 和终端内都有视觉区分 |

### 后续迭代（非 MVP）

- Bark 推送到 iPhone + Apple Watch
- 团队协作（多人查看同一组 session）
- 更多 agent 引擎支持（Gemini CLI、Aider 等）
- 对外发布 App Store + Landing Page
- Session 间通信（一个 agent 的产出作为另一个的输入）

## 澄清 Q&A

| 问题 | 回答 |
|------|------|
| 目标用户群体 | 面向所有人，但 MVP 推广优先打开发者/Geek 群体（类似 OpenClaw 的爆火逻辑） |
| 参考产品 | 概念接近 [Paperclip](https://github.com/paperclipai/paperclip)（零人公司编排），但从第一性原理出发做 Agent IDE |
| 技术栈 | SwiftUI 原生 macOS App |
| MVP 范围 | Dashboard + 创建 Session + 内嵌终端 + 状态监控 + 通知 + 历史记录 |
| 商业化 | MVP 先自用 → 团队内部 → 对外发布 App Store |
| 时间限制 | 立刻开始 |
| 端到端测试 | 需要用 Playwright 控制 Mac 做 E2E 测试 |

## 技术约束

- macOS 13 Ventura+（用户当前系统为 macOS 13）
- SwiftUI + AppKit（需要 Terminal 嵌入）
- Agent 引擎通过子进程调用 CLI（`claude`、`codex`）
- 通知使用 UNUserNotificationCenter（已验证可行，需 ad-hoc 签名）

## 关键结论

1. **核心创新**：以 Agent Session 替代文件作为 IDE 的管理单位，这是一个范式转变
2. **MVP 闭环**：Dashboard 概览 → 创建 Session → 内嵌终端交互 → 状态监控 → 通知提醒
3. **增强终端**：不是简单套壳终端，而是让非技术用户也能轻松使用的增强交互体验
4. **多引擎架构**：抽象 agent 引擎接口，MVP 支持 Claude Code + Codex，后续可扩展

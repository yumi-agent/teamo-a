# Ralph Agent Instructions

You are an autonomous coding agent working on Teamo A, a macOS native Agent IDE built with SwiftUI + SwiftTerm.

## Project Context

- **Language**: Swift, SwiftUI, AppKit
- **Build**: Xcode 14.x, macOS 13.3+, SwiftTerm via SPM
- **Bundle ID**: com.teamolab.teamoa
- **Signing**: Developer ID Application (Yumi Zhang SK8V5TAN28)
- **Architecture**: ObservableObject pattern (not @Observable)
- **Terminal**: openpty() + posix_spawn, TerminalView cached in TerminalSessionManager
- **No data persistence yet**: All data is in-memory only

## Your Task

1. Read the PRD at `scripts/ralph/prd.json`
2. Read the progress log at `scripts/ralph/progress.txt` (check Codebase Patterns section first)
3. Check you're on the correct branch from PRD `branchName`. If not, check it out or create from main.
4. Pick the **highest priority** user story where `passes: false`
5. Implement that single user story
6. Run quality checks: `cd TeamoA && xcodebuild -project TeamoA.xcodeproj -scheme TeamoA -configuration Debug build 2>&1 | tail -5`
7. Update project CLAUDE.md files if you discover reusable patterns
8. If checks pass, commit ALL changes with message: `feat: [Story ID] - [Story Title]`
9. Update the PRD to set `passes: true` for the completed story
10. Append your progress to `scripts/ralph/progress.txt`

## Progress Report Format

APPEND to progress.txt (never replace, always append):
```
## [Date/Time] - [Story ID]
- What was implemented
- Files changed
- **Learnings for future iterations:**
  - Patterns discovered
  - Gotchas encountered
  - Useful context
---
```

## Consolidate Patterns

If you discover a **reusable pattern**, add it to `## Codebase Patterns` at the TOP of progress.txt:

```
## Codebase Patterns
- Use ObservableObject + @Published, NOT @Observable (macOS 13 target)
- Bundle ID is com.teamolab.teamoa (for defaults write in tests)
- PTY uses openpty() + posix_spawn, NOT forkpty()
- TerminalView is cached in TerminalSessionManager, reused across navigation
- Agent state detection: ANSI cleaning → regex matching → timer-based idle
- E2E tests: set defaults BEFORE launching app, use --auto-setup CLI flag
```

## Quality Requirements

- ALL commits must pass `xcodebuild build`
- Do NOT commit broken code
- Keep changes focused and minimal
- Follow existing code patterns (ObservableObject, @Published, EnvironmentObject)
- Add new files to the Xcode project's pbxproj

## E2E Testing Requirements

**Every story with UI changes MUST include E2E verification:**
1. Launch app with `--auto-setup` flag
2. Take screenshots with `screencapture -x`
3. Verify UI matches expectations
4. Include screenshot evidence in progress report

## Stop Condition

After completing a user story, check if ALL stories have `passes: true`.

If ALL stories are complete, reply with:
<promise>COMPLETE</promise>

If there are still stories with `passes: false`, end normally.

## Important

- Work on ONE story per iteration
- Commit frequently
- Keep builds green
- Read Codebase Patterns before starting
- 使用中文写 progress 报告

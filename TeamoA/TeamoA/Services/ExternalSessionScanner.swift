import Foundation
import SwiftUI

/// Represents a Claude Code session discovered on the local machine.
struct DiscoveredSession: Identifiable {
    let id: String // session UUID from jsonl filename
    let projectDir: String
    let projectPath: String
    var firstPrompt: String
    var status: SessionStatus
    var pid: Int?
    var mtime: Date
    var size: Int64
    var gitBranch: String
    var version: String

    enum SessionStatus: String {
        case live, paused, stopped

        var displayName: String { rawValue.capitalized }

        var color: SwiftUI.Color {
            switch self {
            case .live: return .green
            case .paused: return .yellow
            case .stopped: return .gray
            }
        }
    }

    /// Short display name derived from project path
    var displayName: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        var path = projectPath
        if path.hasPrefix(home) {
            path = "~" + path.dropFirst(home.count)
        }
        // Use last path component as name
        return (path as NSString).lastPathComponent
    }

    var shortProjectPath: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if projectPath.hasPrefix(home) {
            return "~" + projectPath.dropFirst(home.count)
        }
        return projectPath
    }

    var shortPrompt: String {
        if firstPrompt.count > 80 {
            return String(firstPrompt.prefix(80)) + "..."
        }
        return firstPrompt
    }
}

/// Scans the local machine for Claude Code sessions by examining
/// ~/.claude/projects/ JSONL files and running processes.
class ExternalSessionScanner: ObservableObject {
    @Published var sessions: [DiscoveredSession] = []
    private var timer: Timer?

    /// Known internal PIDs (Teamo A's own agents) to exclude from results
    var internalPids: Set<Int> = []

    func startMonitoring(interval: TimeInterval = 10) {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    func refresh() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            let processes = self.getRunningClaudeProcesses()
            var discovered = self.scanAllSessions()
            discovered = self.classifySessions(discovered, processes: processes)

            // Sort: live first, then paused, then stopped (by mtime desc)
            let order: [DiscoveredSession.SessionStatus: Int] = [.live: 0, .paused: 1, .stopped: 2]
            discovered.sort {
                let o1 = order[$0.status] ?? 3
                let o2 = order[$1.status] ?? 3
                if o1 != o2 { return o1 < o2 }
                return $0.mtime > $1.mtime
            }

            // Only keep live/paused + recent stopped (last 2h), max 20 sessions
            let cutoff = Date().addingTimeInterval(-7200)
            discovered = discovered.filter { session in
                session.status == .live || session.status == .paused || session.mtime > cutoff
            }
            if discovered.count > 20 {
                discovered = Array(discovered.prefix(20))
            }

            DispatchQueue.main.async {
                self.sessions = discovered
            }
        }
    }

    // MARK: - Process Discovery

    private struct ClaudeProcess {
        let pid: Int
        let ppid: Int
        let tty: String
        let etime: String
        var cwd: String?
    }

    private func getRunningClaudeProcesses() -> [ClaudeProcess] {
        guard let output = runCommand("/bin/ps", arguments: ["-eo", "pid,ppid,tty,etime,command"]) else {
            return []
        }

        var processes: [ClaudeProcess] = []
        let lines = output.split(separator: "\n")

        for line in lines.dropFirst() { // skip header
            let str = String(line)
            guard str.contains("claude") else { continue }
            // Match both `claude` and `claude --dangerously-skip-permissions`
            guard str.contains("--dangerously-skip-permissions") || str.contains("node") && str.contains("claude") else { continue }

            let parts = str.trimmingCharacters(in: .whitespaces).split(separator: " ", maxSplits: 4)
            guard parts.count >= 4, let pid = Int(parts[0]), let ppid = Int(parts[1]) else { continue }

            // Skip Teamo A's own agent PIDs
            if internalPids.contains(pid) { continue }

            let tty = String(parts[2])
            let etime = String(parts[3])

            var proc = ClaudeProcess(pid: pid, ppid: ppid, tty: tty, etime: etime)
            proc.cwd = getProcessCwd(pid: pid)
            processes.append(proc)
        }

        return processes
    }

    private func getProcessCwd(pid: Int) -> String? {
        guard let output = runCommand("/usr/sbin/lsof", arguments: ["-p", String(pid)]) else {
            return nil
        }
        for line in output.split(separator: "\n") {
            if line.contains("cwd") {
                let parts = String(line).split(separator: " ")
                if let last = parts.last {
                    return String(last)
                }
            }
        }
        return nil
    }

    // MARK: - Session File Scanning

    private func scanAllSessions() -> [DiscoveredSession] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let projectsDir = home.appendingPathComponent(".claude/projects")

        guard FileManager.default.fileExists(atPath: projectsDir.path) else {
            return []
        }

        var sessions: [DiscoveredSession] = []
        let fm = FileManager.default

        guard let projDirs = try? fm.contentsOfDirectory(atPath: projectsDir.path) else {
            return []
        }

        for projDirName in projDirs {
            let projPath = projectsDir.appendingPathComponent(projDirName)
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: projPath.path, isDirectory: &isDir), isDir.boolValue else {
                continue
            }

            // Decode project path from directory name
            var projectPath = projDirName.replacingOccurrences(of: "-", with: "/")
            if !projectPath.hasPrefix("/") {
                projectPath = "/" + projectPath
            }

            // Find JSONL files
            guard let files = try? fm.contentsOfDirectory(atPath: projPath.path) else { continue }
            for file in files where file.hasSuffix(".jsonl") {
                let filePath = projPath.appendingPathComponent(file)
                guard let attrs = try? fm.attributesOfItem(atPath: filePath.path) else { continue }

                let sessionId = (file as NSString).deletingPathExtension
                let mtime = (attrs[.modificationDate] as? Date) ?? Date.distantPast
                let size = (attrs[.size] as? Int64) ?? 0

                // Parse JSONL for metadata
                let metadata = parseSessionMetadata(path: filePath.path)

                let session = DiscoveredSession(
                    id: sessionId,
                    projectDir: projDirName,
                    projectPath: metadata.cwd.isEmpty ? projectPath : metadata.cwd,
                    firstPrompt: metadata.firstPrompt,
                    status: .stopped,
                    pid: nil,
                    mtime: mtime,
                    size: size,
                    gitBranch: metadata.gitBranch,
                    version: metadata.version
                )
                sessions.append(session)
            }
        }

        return sessions
    }

    private struct SessionMetadata {
        var cwd = ""
        var gitBranch = ""
        var version = ""
        var firstPrompt = ""
    }

    private func parseSessionMetadata(path: String) -> SessionMetadata {
        var meta = SessionMetadata()

        guard let handle = FileHandle(forReadingAtPath: path) else { return meta }
        defer { handle.closeFile() }

        // Read only first 50KB to avoid slow parsing of large files
        let data = handle.readData(ofLength: 50_000)
        guard let text = String(data: data, encoding: .utf8) else { return meta }

        for line in text.split(separator: "\n") {
            guard let jsonData = line.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                continue
            }

            if meta.cwd.isEmpty, let cwd = obj["cwd"] as? String {
                meta.cwd = cwd
            }
            if meta.gitBranch.isEmpty, let branch = obj["gitBranch"] as? String {
                meta.gitBranch = branch
            }
            if meta.version.isEmpty, let ver = obj["version"] as? String {
                meta.version = ver
            }

            // Find first user message
            if meta.firstPrompt.isEmpty,
               let type = obj["type"] as? String, type == "user",
               let message = obj["message"] as? [String: Any],
               let content = message["content"] {

                if let text = content as? String {
                    if !text.hasPrefix("[Request") && !text.hasPrefix("<command") && !text.hasPrefix("<local-command") {
                        meta.firstPrompt = String(text.prefix(150)).replacingOccurrences(of: "\n", with: " ")
                        break
                    }
                } else if let arr = content as? [[String: Any]], let first = arr.first, let text = first["text"] as? String {
                    if !text.hasPrefix("[Request") && !text.hasPrefix("<command") && !text.hasPrefix("<local-command") {
                        meta.firstPrompt = String(text.prefix(150)).replacingOccurrences(of: "\n", with: " ")
                        break
                    }
                }
            }
        }

        return meta
    }

    // MARK: - Classification

    private func classifySessions(_ sessions: [DiscoveredSession], processes: [ClaudeProcess]) -> [DiscoveredSession] {
        var result = sessions

        // Build map: project_key -> running processes
        var runningProjects: [String: [ClaudeProcess]] = [:]
        for proc in processes {
            if let cwd = proc.cwd {
                let key = cwd.replacingOccurrences(of: "/", with: "-")
                runningProjects[key, default: []].append(proc)
            }
        }

        let now = Date()

        for i in result.indices {
            let projKey = result[i].projectDir
            let matchingProcs = runningProjects[projKey] ?? []

            if !matchingProcs.isEmpty {
                let age = now.timeIntervalSince(result[i].mtime) / 60
                if age < 2 {
                    result[i].status = .live
                    result[i].pid = matchingProcs.first?.pid
                } else {
                    result[i].status = .stopped
                }
            } else {
                let ageHours = now.timeIntervalSince(result[i].mtime) / 3600
                if ageHours < 1 {
                    result[i].status = .paused
                } else {
                    result[i].status = .stopped
                }
            }
        }

        // Second pass: for projects with running processes, mark most recent session as live
        for (key, procs) in runningProjects {
            let projSessions = result.indices.filter { result[$0].projectDir == key }
            if let mostRecentIdx = projSessions.max(by: { result[$0].mtime < result[$1].mtime }) {
                if result[mostRecentIdx].status != .live {
                    result[mostRecentIdx].status = .live
                    result[mostRecentIdx].pid = procs.first?.pid
                }
            }
        }

        return result
    }

    // MARK: - Helpers

    private func runCommand(_ command: String, arguments: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
}

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

            // Phase 1: Quick file scan — publish immediately based on file age
            var discovered = self.scanAllSessions()
            discovered = self.classifyByFileAge(discovered)
            let sorted = self.sortAndFilter(discovered)
            DispatchQueue.main.async {
                self.sessions = sorted
            }

            // Phase 2: Process matching — update live/paused status
            let runningPids = self.getRunningClaudePids()
            if !runningPids.isEmpty {
                discovered = self.classifyWithProcesses(discovered, pids: runningPids)
                let updated = self.sortAndFilter(discovered)
                DispatchQueue.main.async {
                    self.sessions = updated
                }
            }
        }
    }

    // MARK: - Process Discovery

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

            // Find JSONL files — only scan recent ones (last 3h) for performance
            let recentCutoff = Date().addingTimeInterval(-10800)
            guard let files = try? fm.contentsOfDirectory(atPath: projPath.path) else { continue }
            for file in files where file.hasSuffix(".jsonl") {
                let filePath = projPath.appendingPathComponent(file)
                guard let attrs = try? fm.attributesOfItem(atPath: filePath.path) else { continue }

                let mtime = (attrs[.modificationDate] as? Date) ?? Date.distantPast
                // Skip old files early to avoid parsing metadata
                guard mtime > recentCutoff else { continue }

                let sessionId = (file as NSString).deletingPathExtension
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

    /// Quick classification based on file modification time only (no process lookups)
    private func classifyByFileAge(_ sessions: [DiscoveredSession]) -> [DiscoveredSession] {
        var result = sessions
        let now = Date()
        for i in result.indices {
            let ageMinutes = now.timeIntervalSince(result[i].mtime) / 60
            if ageMinutes < 5 {
                result[i].status = .live  // Recently active — likely live
            } else if ageMinutes < 60 {
                result[i].status = .paused
            } else {
                result[i].status = .stopped
            }
        }
        return result
    }

    /// Get just the PIDs of running claude processes (fast — no lsof)
    private func getRunningClaudePids() -> Set<Int> {
        guard let output = runCommand("/bin/ps", arguments: ["-eo", "pid,command"]) else {
            return []
        }
        var pids = Set<Int>()
        for line in output.split(separator: "\n").dropFirst() {
            let str = String(line)
            guard str.contains("claude") && str.contains("--dangerously-skip-permissions") else { continue }
            let trimmed = str.trimmingCharacters(in: .whitespaces)
            if let spaceIdx = trimmed.firstIndex(of: " "),
               let pid = Int(trimmed[trimmed.startIndex..<spaceIdx]) {
                if !internalPids.contains(pid) {
                    pids.insert(pid)
                }
            }
        }
        return pids
    }

    /// Refine classification using process info (uses lsof sparingly)
    private func classifyWithProcesses(_ sessions: [DiscoveredSession], pids: Set<Int>) -> [DiscoveredSession] {
        var result = sessions

        // Sample up to 10 PIDs to avoid slow lsof calls
        let sampledPids = Array(pids.prefix(10))
        var runningProjectDirs = Set<String>()

        for pid in sampledPids {
            if let cwd = getProcessCwd(pid: pid) {
                let key = cwd.replacingOccurrences(of: "/", with: "-")
                runningProjectDirs.insert(key)
            }
        }

        // Mark sessions in running project dirs as live
        for i in result.indices {
            if runningProjectDirs.contains(result[i].projectDir) {
                result[i].status = .live
            }
        }

        return result
    }

    /// Sort by status priority, filter to recent, cap at max count
    private func sortAndFilter(_ sessions: [DiscoveredSession]) -> [DiscoveredSession] {
        var result = sessions

        let order: [DiscoveredSession.SessionStatus: Int] = [.live: 0, .paused: 1, .stopped: 2]
        result.sort {
            let o1 = order[$0.status] ?? 3
            let o2 = order[$1.status] ?? 3
            if o1 != o2 { return o1 < o2 }
            return $0.mtime > $1.mtime
        }

        // Keep live/paused + recent stopped (last 2h), max 20
        let cutoff = Date().addingTimeInterval(-7200)
        result = result.filter { session in
            session.status == .live || session.status == .paused || session.mtime > cutoff
        }
        if result.count > 20 {
            result = Array(result.prefix(20))
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

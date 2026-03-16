import Foundation

/// Reads Claude Code's native session files from ~/.claude/projects/
/// Inspired by opcode's approach: directly read Claude's JSONL files for
/// session discovery, history, and persistence — no custom storage needed.
class ClaudeSessionReader {

    // MARK: - Data Types

    struct SessionMessage {
        let role: String        // "user", "assistant", "system"
        let content: String
        let timestamp: Date?
        let type: String?       // message type/subtype from JSONL
    }

    struct SessionSummary: Identifiable {
        let id: String          // session UUID (JSONL filename without extension)
        let projectPath: String
        let firstMessage: String?
        let createdAt: Date
        let modifiedAt: Date
        let fileSize: Int64
    }

    // MARK: - Cache

    private static var summaryCache: [String: [SessionSummary]] = [:]
    private static var historyCacheKeys: [String: Date] = [:] // sessionId -> last loaded mtime

    // MARK: - Public API

    /// List all sessions for a given working directory.
    /// Uses Claude Code's path encoding: /Users/foo/bar → -Users-foo-bar
    static func sessions(forDirectory dir: String) -> [SessionSummary] {
        let projectDir = resolveProjectDir(for: dir)
        guard let projectDir = projectDir else { return [] }

        // Check cache
        if let cached = summaryCache[projectDir] {
            return cached
        }

        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: projectDir) else {
            return []
        }

        let results = files
            .filter { $0.hasSuffix(".jsonl") }
            .compactMap { file -> SessionSummary? in
                let sessionId = String(file.dropLast(6)) // strip .jsonl
                let path = projectDir + "/" + file

                guard let attrs = try? fm.attributesOfItem(atPath: path) else {
                    return nil
                }

                let createdAt = attrs[.creationDate] as? Date ?? Date()
                let modifiedAt = attrs[.modificationDate] as? Date ?? Date()
                let fileSize = attrs[.size] as? Int64 ?? 0

                let firstMessage = extractFirstUserMessage(from: path)

                return SessionSummary(
                    id: sessionId,
                    projectPath: dir,
                    firstMessage: firstMessage,
                    createdAt: createdAt,
                    modifiedAt: modifiedAt,
                    fileSize: fileSize
                )
            }
            .sorted { $0.modifiedAt > $1.modifiedAt }

        summaryCache[projectDir] = results
        return results
    }

    /// Load full message history from a session's JSONL file.
    /// Returns parsed messages in chronological order.
    static func loadHistory(workingDirectory dir: String, sessionId: String) -> [SessionMessage] {
        guard let projectDir = resolveProjectDir(for: dir) else { return [] }
        let path = "\(projectDir)/\(sessionId).jsonl"

        guard FileManager.default.fileExists(atPath: path) else { return [] }
        guard let data = FileManager.default.contents(atPath: path) else { return [] }
        guard let content = String(data: data, encoding: .utf8) else { return [] }

        var messages: [SessionMessage] = []
        for line in content.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            guard let lineData = trimmed.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any]
            else { continue }

            // Extract role and content from Claude's JSONL format
            if let message = parseMessage(from: json) {
                messages.append(message)
            }
        }

        return messages
    }

    /// Find the most recent session for a working directory.
    /// Useful for mapping an agent to its last Claude session.
    static func mostRecentSession(forDirectory dir: String) -> SessionSummary? {
        return sessions(forDirectory: dir).first
    }

    /// Detect the Claude session ID from terminal output.
    /// Claude Code prints session info during startup that includes the session ID.
    static func extractSessionId(from output: String) -> String? {
        // Claude's JSONL session files are named with UUIDs
        // The session ID appears in the init message or can be derived from the JSONL path
        // Pattern: session_id appears in Claude Code's startup output
        let patterns = [
            "session_id[\":\\s]+([a-f0-9-]{36})",
            "Session: ([a-f0-9-]{36})",
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)),
               let range = Range(match.range(at: 1), in: output) {
                return String(output[range])
            }
        }
        return nil
    }

    /// Invalidate cache for a directory (call after session changes)
    static func invalidateCache(forDirectory dir: String) {
        if let projectDir = resolveProjectDir(for: dir) {
            summaryCache.removeValue(forKey: projectDir)
        }
    }

    static func invalidateAllCaches() {
        summaryCache.removeAll()
        historyCacheKeys.removeAll()
    }

    // MARK: - Private Helpers

    /// Resolve a working directory to its Claude projects path.
    /// Claude encodes /Users/foo/bar as -Users-foo-bar in ~/.claude/projects/
    private static func resolveProjectDir(for dir: String) -> String? {
        let claudeProjectsDir = NSHomeDirectory() + "/.claude/projects"

        // Method 1: direct path encoding (like opcode)
        let encoded = dir
            .replacingOccurrences(of: "/", with: "-")
        let trimmed = encoded.hasPrefix("-") ? String(encoded.dropFirst()) : encoded
        let directPath = claudeProjectsDir + "/" + trimmed

        if FileManager.default.fileExists(atPath: directPath) {
            return directPath
        }

        // Method 2: scan all project dirs and match by reading session cwd
        guard let dirs = try? FileManager.default.contentsOfDirectory(atPath: claudeProjectsDir) else {
            return nil
        }

        for projDir in dirs {
            let fullPath = claudeProjectsDir + "/" + projDir
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDir),
                  isDir.boolValue else { continue }

            // Check if any JSONL file in this dir has cwd matching our directory
            if let files = try? FileManager.default.contentsOfDirectory(atPath: fullPath),
               let jsonlFile = files.first(where: { $0.hasSuffix(".jsonl") }) {
                let filePath = fullPath + "/" + jsonlFile
                if let cwd = extractCwd(from: filePath), cwd == dir {
                    return fullPath
                }
            }
        }

        return nil
    }

    /// Extract the cwd field from the first few lines of a JSONL file
    private static func extractCwd(from path: String) -> String? {
        guard let fh = FileHandle(forReadingAtPath: path) else { return nil }
        defer { fh.closeFile() }

        // Read first 50KB (like opcode, enough for metadata)
        let data = fh.readData(ofLength: 50 * 1024)
        guard let content = String(data: data, encoding: .utf8) else { return nil }

        for line in content.components(separatedBy: "\n").prefix(20) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty,
                  let lineData = trimmed.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any]
            else { continue }

            if let cwd = json["cwd"] as? String {
                return cwd
            }
        }
        return nil
    }

    /// Extract the first user message from a JSONL file (for session preview)
    private static func extractFirstUserMessage(from path: String) -> String? {
        guard let fh = FileHandle(forReadingAtPath: path) else { return nil }
        defer { fh.closeFile() }

        // Read first 50KB
        let data = fh.readData(ofLength: 50 * 1024)
        guard let content = String(data: data, encoding: .utf8) else { return nil }

        for line in content.components(separatedBy: "\n").prefix(50) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty,
                  let lineData = trimmed.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any]
            else { continue }

            // Look for user messages (skip system messages)
            let role = json["role"] as? String
            let type = json["type"] as? String

            // Claude JSONL format: {"type":"human","message":{"role":"user","content":[...]}}
            if role == "user" || type == "human" {
                return extractContent(from: json)
            }

            // Also check nested message structure
            if let message = json["message"] as? [String: Any],
               let msgRole = message["role"] as? String,
               msgRole == "user" {
                return extractContent(from: message)
            }
        }
        return nil
    }

    /// Extract readable content from a message JSON object
    private static func extractContent(from json: [String: Any]) -> String? {
        // Simple string content
        if let content = json["content"] as? String, !content.isEmpty {
            return String(content.prefix(200))
        }

        // Array content (Claude format: [{"type":"text","text":"..."}])
        if let contentArray = json["content"] as? [[String: Any]] {
            for item in contentArray {
                if let text = item["text"] as? String, !text.isEmpty {
                    return String(text.prefix(200))
                }
            }
        }

        // Nested message
        if let message = json["message"] as? [String: Any] {
            return extractContent(from: message)
        }

        return nil
    }

    /// Parse a single JSONL line into a SessionMessage
    private static func parseMessage(from json: [String: Any]) -> SessionMessage? {
        let type = json["type"] as? String

        // Get role from various possible locations
        var role: String?
        var content: String?

        if let r = json["role"] as? String {
            role = r
        } else if type == "human" {
            role = "user"
        } else if type == "assistant" {
            role = "assistant"
        } else if type == "system" {
            role = "system"
        }

        // Extract content
        if let message = json["message"] as? [String: Any] {
            if role == nil, let r = message["role"] as? String {
                role = r
            }
            content = extractContent(from: message)
        } else {
            content = extractContent(from: json)
        }

        guard let finalRole = role, let finalContent = content else {
            return nil
        }

        // Parse timestamp if available
        var timestamp: Date?
        if let ts = json["timestamp"] as? String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            timestamp = formatter.date(from: ts)
        }

        return SessionMessage(
            role: finalRole,
            content: finalContent,
            timestamp: timestamp,
            type: type
        )
    }
}

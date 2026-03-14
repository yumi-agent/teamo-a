import Foundation
import SwiftUI

class SessionStore: ObservableObject {
    @Published var sessions: [AgentSession] = []

    private let sessionsURL: URL
    private let transcriptsDir: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!.appendingPathComponent("TeamoA")

        sessionsURL = appSupport.appendingPathComponent("sessions.json")
        transcriptsDir = appSupport.appendingPathComponent("transcripts")

        // Create directories
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: transcriptsDir, withIntermediateDirectories: true)

        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        decoder.dateDecodingStrategy = .iso8601

        loadSessions()
    }

    func session(byId id: UUID) -> AgentSession? {
        sessions.first { $0.id == id }
    }

    func addSession(_ session: AgentSession) {
        sessions.append(session)
        saveSessions()
    }

    func removeSession(_ session: AgentSession) {
        sessions.removeAll { $0.id == session.id }
        // Remove transcript file
        let transcriptURL = transcriptsDir.appendingPathComponent("\(session.id.uuidString).jsonl")
        try? FileManager.default.removeItem(at: transcriptURL)
        saveSessions()
    }

    func updateSession(_ session: AgentSession) {
        saveSessions()
    }

    func appendTranscript(sessionId: UUID, entry: TranscriptEntry) {
        let url = transcriptsDir.appendingPathComponent("\(sessionId.uuidString).jsonl")
        if let data = try? encoder.encode(entry),
           let line = String(data: data, encoding: .utf8) {
            let lineData = (line + "\n").data(using: .utf8)!
            if FileManager.default.fileExists(atPath: url.path) {
                if let handle = try? FileHandle(forWritingTo: url) {
                    handle.seekToEndOfFile()
                    handle.write(lineData)
                    handle.closeFile()
                }
            } else {
                try? lineData.write(to: url)
            }
        }
    }

    func loadTranscript(sessionId: UUID) -> [TranscriptEntry] {
        let url = transcriptsDir.appendingPathComponent("\(sessionId.uuidString).jsonl")
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return [] }

        return content.components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .compactMap { line in
                guard let data = line.data(using: .utf8) else { return nil }
                return try? decoder.decode(TranscriptEntry.self, from: data)
            }
    }

    var runningSessions: [AgentSession] {
        sessions.filter { $0.state == .running }
    }

    var waitingSessions: [AgentSession] {
        sessions.filter { $0.state == .waiting }
    }

    var stoppedSessions: [AgentSession] {
        sessions.filter { $0.state == .stopped }
    }

    // MARK: - Private

    private func loadSessions() {
        guard FileManager.default.fileExists(atPath: sessionsURL.path) else { return }
        guard let data = try? Data(contentsOf: sessionsURL) else { return }
        sessions = (try? decoder.decode([AgentSession].self, from: data)) ?? []
    }

    private func saveSessions() {
        guard let data = try? encoder.encode(sessions) else { return }
        try? data.write(to: sessionsURL, options: .atomic)
    }
}

struct TranscriptEntry: Codable {
    let timestamp: Date
    let type: TranscriptEntryType
    let content: String
}

enum TranscriptEntryType: String, Codable {
    case output
    case input
    case stateChange
    case error
}

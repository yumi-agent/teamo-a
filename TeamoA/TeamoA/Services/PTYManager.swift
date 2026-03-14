import Foundation

protocol PTYManagerDelegate: AnyObject {
    func ptyManager(_ manager: PTYManager, didReceiveOutput data: Data)
    func ptyManager(_ manager: PTYManager, didTerminateWithStatus status: Int32)
}

class PTYManager {
    weak var delegate: PTYManagerDelegate?

    private var masterFD: Int32 = -1
    private var slaveFD: Int32 = -1
    private var childPID: pid_t = 0
    private var readSource: DispatchSourceRead?
    private var waitSource: DispatchSourceProcess?

    private static var activeFDCount = 0
    private static let maxFDs = 20
    private static let fdLock = NSLock()

    var isRunning: Bool {
        guard childPID > 0 else { return false }
        // Check if process is still alive
        return kill(childPID, 0) == 0
    }

    deinit {
        terminate()
    }

    func start(
        command: String,
        arguments: [String] = [],
        workingDirectory: String,
        environment: [String: String]? = nil,
        cols: Int = 80,
        rows: Int = 24
    ) throws {
        guard PTYManager.acquireFD() else {
            throw PTYError.tooManyOpenFDs
        }

        var master: Int32 = 0
        var slave: Int32 = 0

        guard openpty(&master, &slave, nil, nil, nil) == 0 else {
            PTYManager.releaseFD()
            throw PTYError.openptyFailed(errno: errno)
        }

        masterFD = master
        slaveFD = slave

        // Set initial window size
        setWindowSize(cols: cols, rows: rows)

        // Resolve command path
        let resolvedCommand = resolveCommand(command)

        // Build environment
        var env = ProcessInfo.processInfo.environment
        env["TERM"] = "xterm-256color"
        env["COLORTERM"] = "truecolor"
        // Remove nesting detection markers so claude/codex can start fresh
        env.removeValue(forKey: "CLAUDECODE")
        env.removeValue(forKey: "CLAUDE_CODE_ENTRYPOINT")
        // Prevent Apple Terminal session restore hooks (avoids TCC prompts and "Restored session:" noise)
        env.removeValue(forKey: "TERM_PROGRAM")
        env.removeValue(forKey: "TERM_SESSION_ID")
        if let extra = environment {
            env.merge(extra) { _, new in new }
        }

        // Set up posix_spawn file actions: slave FD → stdin/stdout/stderr
        var fileActions = posix_spawn_file_actions_t?.none
        posix_spawn_file_actions_init(&fileActions)
        posix_spawn_file_actions_adddup2(&fileActions, slave, STDIN_FILENO)
        posix_spawn_file_actions_adddup2(&fileActions, slave, STDOUT_FILENO)
        posix_spawn_file_actions_adddup2(&fileActions, slave, STDERR_FILENO)
        posix_spawn_file_actions_addclose(&fileActions, slave)
        posix_spawn_file_actions_addclose(&fileActions, master)
        posix_spawn_file_actions_addchdir_np(&fileActions, workingDirectory)

        // Set up spawn attributes
        var spawnAttr = posix_spawnattr_t?.none
        posix_spawnattr_init(&spawnAttr)
        // Start a new session (setsid) so the child gets the PTY as controlling terminal
        var flags: Int16 = Int16(POSIX_SPAWN_SETSID)
        posix_spawnattr_setflags(&spawnAttr, flags)

        // Build argv: [command, ...arguments, nil]
        let allArgs = [resolvedCommand] + arguments
        let cArgs = allArgs.map { strdup($0)! } + [nil]
        defer { cArgs.forEach { if let p = $0 { free(p) } } }

        // Build envp
        let envStrings = env.map { "\($0.key)=\($0.value)" }
        let cEnv = envStrings.map { strdup($0)! } + [nil]
        defer { cEnv.forEach { if let p = $0 { free(p) } } }

        var pid: pid_t = 0
        let spawnResult = posix_spawn(&pid, resolvedCommand, &fileActions, &spawnAttr, cArgs, cEnv)

        posix_spawn_file_actions_destroy(&fileActions)
        posix_spawnattr_destroy(&spawnAttr)

        guard spawnResult == 0 else {
            cleanup()
            throw PTYError.spawnFailed(errno: spawnResult)
        }

        childPID = pid

        // Close slave FD in parent process (child has it)
        close(slaveFD)
        slaveFD = -1

        // Start reading from master FD
        let source = DispatchSource.makeReadSource(fileDescriptor: masterFD, queue: .global(qos: .userInteractive))
        source.setEventHandler { [weak self] in
            guard let self = self else { return }
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 8192)
            defer { buffer.deallocate() }

            let bytesRead = read(self.masterFD, buffer, 8192)
            if bytesRead > 0 {
                let data = Data(bytes: buffer, count: bytesRead)
                DispatchQueue.main.async {
                    self.delegate?.ptyManager(self, didReceiveOutput: data)
                }
            }
        }
        source.setCancelHandler { [weak self] in
            self?.cleanup()
        }
        source.resume()
        readSource = source

        // Monitor child process exit
        let procSource = DispatchSource.makeProcessSource(identifier: pid, eventMask: .exit, queue: .main)
        procSource.setEventHandler { [weak self] in
            guard let self = self else { return }
            var status: Int32 = 0
            waitpid(self.childPID, &status, WNOHANG)
            let exited = (status & 0x7f) == 0
            let exitStatus: Int32 = exited ? ((status >> 8) & 0xff) : -1
            self.delegate?.ptyManager(self, didTerminateWithStatus: exitStatus)
            self.waitSource?.cancel()
            self.waitSource = nil
        }
        procSource.resume()
        waitSource = procSource
    }

    func write(_ data: Data) {
        guard masterFD >= 0 else { return }
        data.withUnsafeBytes { rawBuffer in
            guard let ptr = rawBuffer.baseAddress else { return }
            _ = Foundation.write(masterFD, ptr, rawBuffer.count)
        }
    }

    func write(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        write(data)
    }

    func resize(cols: Int, rows: Int) {
        setWindowSize(cols: cols, rows: rows)
    }

    func terminate() {
        readSource?.cancel()
        readSource = nil
        waitSource?.cancel()
        waitSource = nil

        if childPID > 0 && kill(childPID, 0) == 0 {
            kill(childPID, SIGTERM)
            // Give it a moment then force kill
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) { [weak self] in
                guard let self = self else { return }
                if self.childPID > 0 && kill(self.childPID, 0) == 0 {
                    kill(self.childPID, SIGKILL)
                }
                var status: Int32 = 0
                waitpid(self.childPID, &status, WNOHANG)
                self.cleanup()
            }
        } else {
            cleanup()
        }
    }

    // MARK: - Private

    private func setWindowSize(cols: Int, rows: Int) {
        guard masterFD >= 0, cols > 0, rows > 0 else { return }
        var size = winsize(
            ws_row: UInt16(clamping: rows),
            ws_col: UInt16(clamping: cols),
            ws_xpixel: 0,
            ws_ypixel: 0
        )
        _ = ioctl(masterFD, TIOCSWINSZ, &size)
    }

    private func cleanup() {
        if masterFD >= 0 {
            close(masterFD)
            masterFD = -1
            PTYManager.releaseFD()
        }
        if slaveFD >= 0 {
            close(slaveFD)
            slaveFD = -1
        }
        childPID = 0
    }

    private func resolveCommand(_ command: String) -> String {
        if command.hasPrefix("/") {
            return command
        }

        let searchPaths = [
            "/usr/local/bin",
            "/usr/bin",
            "/bin",
            "/opt/homebrew/bin",
            "\(NSHomeDirectory())/.local/bin",
            "\(NSHomeDirectory())/Library/pnpm",
            "\(NSHomeDirectory())/.cargo/bin",
        ]

        if let pathEnv = ProcessInfo.processInfo.environment["PATH"] {
            let allPaths = searchPaths + pathEnv.split(separator: ":").map(String.init)
            for dir in allPaths {
                let fullPath = "\(dir)/\(command)"
                if FileManager.default.isExecutableFile(atPath: fullPath) {
                    return fullPath
                }
            }
        }

        return "/usr/bin/env"
    }

    private static func acquireFD() -> Bool {
        fdLock.lock()
        defer { fdLock.unlock() }
        guard activeFDCount < maxFDs else { return false }
        activeFDCount += 1
        return true
    }

    private static func releaseFD() {
        fdLock.lock()
        defer { fdLock.unlock() }
        activeFDCount = max(0, activeFDCount - 1)
    }
}

enum PTYError: LocalizedError {
    case openptyFailed(errno: Int32)
    case spawnFailed(errno: Int32)
    case tooManyOpenFDs

    var errorDescription: String? {
        switch self {
        case .openptyFailed(let errno):
            return "Failed to open PTY: \(String(cString: strerror(errno)))"
        case .spawnFailed(let errno):
            return "Failed to spawn process: \(String(cString: strerror(errno)))"
        case .tooManyOpenFDs:
            return "Too many open PTY sessions (max 20)"
        }
    }
}

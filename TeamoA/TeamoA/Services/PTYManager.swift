import Foundation

protocol PTYManagerDelegate: AnyObject {
    func ptyManager(_ manager: PTYManager, didReceiveOutput data: Data)
    func ptyManager(_ manager: PTYManager, didTerminateWithStatus status: Int32)
}

class PTYManager {
    weak var delegate: PTYManagerDelegate?

    private var masterFD: Int32 = -1
    private var slaveFD: Int32 = -1
    private var process: Process?
    private var readSource: DispatchSourceRead?

    private static var activeFDCount = 0
    private static let maxFDs = 20
    private static let fdLock = NSLock()

    var isRunning: Bool {
        process?.isRunning ?? false
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

        // Set up the process
        let proc = Process()

        // Find the command in PATH
        let resolvedCommand = resolveCommand(command)
        proc.executableURL = URL(fileURLWithPath: resolvedCommand)
        proc.arguments = arguments
        proc.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)

        // Set up environment
        var env = ProcessInfo.processInfo.environment
        env["TERM"] = "xterm-256color"
        env["COLORTERM"] = "truecolor"
        // Remove nesting detection markers so claude/codex can start fresh
        env.removeValue(forKey: "CLAUDECODE")
        env.removeValue(forKey: "CLAUDE_CODE_ENTRYPOINT")
        if let extra = environment {
            env.merge(extra) { _, new in new }
        }
        proc.environment = env

        // Bind slave FD as stdin/stdout/stderr
        proc.standardInput = FileHandle(fileDescriptor: slaveFD, closeOnDealloc: false)
        proc.standardOutput = FileHandle(fileDescriptor: slaveFD, closeOnDealloc: false)
        proc.standardError = FileHandle(fileDescriptor: slaveFD, closeOnDealloc: false)

        proc.terminationHandler = { [weak self] process in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.delegate?.ptyManager(self, didTerminateWithStatus: process.terminationStatus)
            }
            self.cleanup()
        }

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

        try proc.run()
        process = proc

        // Close slave FD in parent process (child has it)
        close(slaveFD)
        slaveFD = -1
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

        if let proc = process, proc.isRunning {
            proc.terminate()
            // Give it a moment then force kill
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) { [weak self] in
                if proc.isRunning {
                    kill(proc.processIdentifier, SIGKILL)
                }
                self?.cleanup()
            }
        } else {
            cleanup()
        }
    }

    // MARK: - Private

    private func setWindowSize(cols: Int, rows: Int) {
        guard masterFD >= 0 else { return }
        var size = winsize(
            ws_row: UInt16(rows),
            ws_col: UInt16(cols),
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
        process = nil
    }

    private func resolveCommand(_ command: String) -> String {
        // If it's already an absolute path, return it
        if command.hasPrefix("/") {
            return command
        }

        // Search in common paths
        let searchPaths = [
            "/usr/local/bin",
            "/usr/bin",
            "/bin",
            "/opt/homebrew/bin",
            "\(NSHomeDirectory())/.local/bin",
            "\(NSHomeDirectory())/Library/pnpm",
            "\(NSHomeDirectory())/.cargo/bin",
        ]

        // Also check PATH
        if let pathEnv = ProcessInfo.processInfo.environment["PATH"] {
            let allPaths = searchPaths + pathEnv.split(separator: ":").map(String.init)
            for dir in allPaths {
                let fullPath = "\(dir)/\(command)"
                if FileManager.default.isExecutableFile(atPath: fullPath) {
                    return fullPath
                }
            }
        }

        // Fallback: use /usr/bin/env to resolve
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
    case tooManyOpenFDs

    var errorDescription: String? {
        switch self {
        case .openptyFailed(let errno):
            return "Failed to open PTY: \(String(cString: strerror(errno)))"
        case .tooManyOpenFDs:
            return "Too many open PTY sessions (max 20)"
        }
    }
}

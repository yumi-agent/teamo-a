import SwiftUI
import SwiftTerm

struct SwiftTermView: NSViewRepresentable {
    let ptyManager: PTYManager
    let backgroundColor: NSColor
    var onResize: ((Int, Int) -> Void)?

    func makeNSView(context: Context) -> TerminalView {
        let tv = TerminalView(frame: .zero)
        tv.terminalDelegate = context.coordinator
        tv.nativeBackgroundColor = backgroundColor
        tv.nativeForegroundColor = .white

        // Configure terminal appearance
        let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        tv.font = font

        context.coordinator.terminalView = tv
        context.coordinator.ptyManager = ptyManager

        return tv
    }

    func updateNSView(_ nsView: TerminalView, context: Context) {
        nsView.nativeBackgroundColor = backgroundColor
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onResize: onResize)
    }

    class Coordinator: NSObject, TerminalViewDelegate {
        var terminalView: TerminalView?
        var ptyManager: PTYManager?
        var onResize: ((Int, Int) -> Void)?

        init(onResize: ((Int, Int) -> Void)?) {
            self.onResize = onResize
        }

        // Feed data from PTY to terminal
        func feedToTerminal(_ data: Data) {
            let bytes = ArraySlice([UInt8](data))
            terminalView?.feed(byteArray: bytes)
        }

        // MARK: - TerminalViewDelegate

        func send(source: TerminalView, data: ArraySlice<UInt8>) {
            let d = Data(data)
            ptyManager?.write(d)
        }

        func scrolled(source: TerminalView, position: Double) {
            // No-op
        }

        func setTerminalTitle(source: TerminalView, title: String) {
            // Could update window title
        }

        func sizeChanged(source: TerminalView, newCols: Int, newRows: Int) {
            ptyManager?.resize(cols: newCols, rows: newRows)
            onResize?(newCols, newRows)
        }

        func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
            // Could update session cwd
        }

        func requestOpenLink(source: TerminalView, link: String, params: [String: String]) {
            if let url = URL(string: link) {
                NSWorkspace.shared.open(url)
            }
        }

        func rangeChanged(source: TerminalView, startY: Int, endY: Int) {
            // No-op
        }

        func clipboardCopy(source: TerminalView, content: Data) {
            if let str = String(data: content, encoding: .utf8) {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(str, forType: .string)
            }
        }

        func bell(source: TerminalView) {
            NSSound.beep()
        }

        func iTermContent(source: TerminalView, content: ArraySlice<UInt8>) {
            // No-op
        }
    }
}

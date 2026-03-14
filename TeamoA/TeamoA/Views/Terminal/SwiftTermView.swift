import SwiftUI
import SwiftTerm

struct SwiftTermView: NSViewRepresentable {
    let ptyManager: PTYManager
    let backgroundColor: NSColor
    var onTerminalReady: ((TerminalView) -> Void)?

    func makeNSView(context: Context) -> TerminalView {
        let tv = TerminalView(frame: .zero)
        tv.terminalDelegate = context.coordinator
        tv.nativeBackgroundColor = backgroundColor
        tv.nativeForegroundColor = .white

        let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        tv.font = font

        context.coordinator.ptyManager = ptyManager

        // Notify controller that terminal view is ready
        DispatchQueue.main.async {
            onTerminalReady?(tv)
        }

        return tv
    }

    func updateNSView(_ nsView: TerminalView, context: Context) {
        nsView.nativeBackgroundColor = backgroundColor
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, TerminalViewDelegate {
        var ptyManager: PTYManager?

        func send(source: TerminalView, data: ArraySlice<UInt8>) {
            ptyManager?.write(Data(data))
        }

        func scrolled(source: TerminalView, position: Double) {}

        func setTerminalTitle(source: TerminalView, title: String) {}

        func sizeChanged(source: TerminalView, newCols: Int, newRows: Int) {
            ptyManager?.resize(cols: newCols, rows: newRows)
        }

        func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}

        func requestOpenLink(source: TerminalView, link: String, params: [String: String]) {
            if let url = URL(string: link) {
                NSWorkspace.shared.open(url)
            }
        }

        func rangeChanged(source: TerminalView, startY: Int, endY: Int) {}

        func clipboardCopy(source: TerminalView, content: Data) {
            if let str = String(data: content, encoding: .utf8) {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(str, forType: .string)
            }
        }

        func bell(source: TerminalView) {
            NSSound.beep()
        }

        func iTermContent(source: TerminalView, content: ArraySlice<UInt8>) {}
    }
}

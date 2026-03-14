import SwiftUI
import UniformTypeIdentifiers

struct InputAreaView: View {
    @State private var inputText = ""
    @State private var isDragging = false
    var onSubmit: (String) -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.accentColor)

            TextField("Send a message...", text: $inputText)
                .textFieldStyle(.plain)
                .font(.system(size: 14, design: .monospaced))
                .onSubmit {
                    submitText()
                }

            Button(action: submitText) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(inputText.isEmpty ? .gray : .accentColor)
            }
            .buttonStyle(.plain)
            .disabled(inputText.isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isDragging ? Color.accentColor.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isDragging ? Color.accentColor : Color.clear, lineWidth: 2)
                )
        )
        .padding(8)
        .onDrop(of: [UTType.fileURL], isTargeted: $isDragging) { providers in
            handleDrop(providers)
            return true
        }
    }

    private func submitText() {
        guard !inputText.isEmpty else { return }
        onSubmit(inputText)
        inputText = ""
    }

    private func handleDrop(_ providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    DispatchQueue.main.async {
                        if inputText.isEmpty {
                            inputText = url.path
                        } else {
                            inputText += " " + url.path
                        }
                    }
                }
            }
        }
    }
}

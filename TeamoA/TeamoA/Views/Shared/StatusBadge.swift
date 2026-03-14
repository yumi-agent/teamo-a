import SwiftUI

struct StatusBadge: View {
    let state: SessionState

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(state.color)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .fill(state.color.opacity(0.3))
                        .frame(width: 14, height: 14)
                        .opacity(state == .running ? 1 : 0)
                        .animation(
                            state == .running
                                ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
                                : .default,
                            value: state
                        )
                )

            Text(state.displayName)
                .font(.caption2.bold())
                .foregroundColor(state.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(state.color.opacity(0.15))
        )
    }
}

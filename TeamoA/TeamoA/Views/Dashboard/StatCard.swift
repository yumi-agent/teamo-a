import SwiftUI

struct StatCard: View {
    let value: String
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color.opacity(0.7))
            }

            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
        )
    }
}

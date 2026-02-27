import SwiftUI

struct BackNavigationButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                Text("戻る")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(TinyTokens.ColorToken.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

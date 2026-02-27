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
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(minWidth: 68, minHeight: 34, alignment: .leading)
            .contentShape(Rectangle())
            .background(TinyTokens.ColorToken.bgCell)
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(TinyTokens.ColorToken.borderDefault, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
    }
}

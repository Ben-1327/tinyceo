import SwiftUI

struct CategoryBadgeView: View {
    let category: String

    var body: some View {
        Text(displayName)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(TinyTokens.ColorToken.categoryBadge(category))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var displayName: String {
        switch category {
        case "CRISIS":
            return "⚠ CRISIS"
        case "AI":
            return "🤖 AI"
        default:
            return category
        }
    }
}

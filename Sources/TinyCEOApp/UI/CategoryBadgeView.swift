import SwiftUI

struct CategoryBadgeView: View {
    let category: String

    var body: some View {
        let spec = EventVisualCatalog.spec(for: category)

        return HStack(spacing: 4) {
            TinyAsset.icon(assetName: spec.iconAssetName, sfSymbol: spec.fallbackSymbol)
                .font(.system(size: 10, weight: .semibold))
            Text(spec.label)
                .font(.system(size: 10, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(TinyTokens.ColorToken.categoryBadge(category))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

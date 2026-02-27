import SwiftUI

struct InboxListView: View {
    @ObservedObject var store: GameRuntimeStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if store.viewState.showInboxFullBanner {
                inboxFullBanner
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }

            if store.inboxCards.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "tray")
                        .font(.system(size: 24))
                        .foregroundStyle(TinyTokens.ColorToken.textSecondary)
                    Text("受信箱は空です")
                        .font(.system(size: 13))
                        .foregroundStyle(TinyTokens.ColorToken.textSecondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(store.inboxCards) { card in
                            Button {
                                store.openCardDetail(cardID: card.cardID)
                            } label: {
                                InboxCardRow(card: card)
                            }
                            .buttonStyle(.plain)
                        }

                        Text("次のカードまで: 約\(store.viewState.minutesUntilNextCard)分")
                            .font(.system(size: 12))
                            .monospacedDigit()
                            .foregroundStyle(TinyTokens.ColorToken.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .scrollIndicators(.never)
            }
        }
        .background(TinyTokens.ColorToken.bgPopover)
    }

    private var header: some View {
        HStack(spacing: 8) {
            BackNavigationButton {
                store.openHome()
            }

            Text("受信箱")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(TinyTokens.ColorToken.textPrimary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var inboxFullBanner: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.octagon.fill")
                    .font(.system(size: 12))
                Text("受信箱が満杯です")
                    .font(.system(size: 11, weight: .semibold))
            }
            Text("未処理ペナルティ: 健康 -3 / 技術負債 +2 / 評判 -1")
                .font(.system(size: 11))
        }
        .foregroundStyle(TinyTokens.ColorToken.statusDanger)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TinyTokens.ColorToken.bgDanger)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(TinyTokens.ColorToken.borderDanger, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct InboxCardRow: View {
    let card: InboxDisplayCard

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            TinyAsset.icon(
                assetName: EventVisualCatalog.spec(for: card.category).iconAssetName,
                sfSymbol: EventVisualCatalog.spec(for: card.category).fallbackSymbol
            )
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(TinyTokens.ColorToken.categoryBadge(card.category))
            .frame(width: 20, height: 20)
            .padding(.top, 1)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    CategoryBadgeView(category: card.category)
                    if card.isCrisis {
                        Text("緊急")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(TinyTokens.ColorToken.statusDanger)
                            .clipShape(Capsule())
                    }
                    Spacer()
                }

                Text(card.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(TinyTokens.ColorToken.textPrimary)
                    .lineLimit(2)

                Text("\(card.optionCount)択")
                    .font(.system(size: 11))
                    .foregroundStyle(TinyTokens.ColorToken.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(TinyTokens.ColorToken.bgCell)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(TinyTokens.ColorToken.borderDefault, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

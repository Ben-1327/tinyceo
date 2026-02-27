import SwiftUI
import TinyCEOCore

struct CardDetailView: View {
    @ObservedObject var store: GameRuntimeStore
    let card: CardDefinition

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        TinyAsset.icon(
                            assetName: EventVisualCatalog.spec(for: card.category).iconAssetName,
                            sfSymbol: EventVisualCatalog.spec(for: card.category).fallbackSymbol
                        )
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(TinyTokens.ColorToken.categoryBadge(card.category))
                        .frame(width: 20, height: 20)

                        CategoryBadgeView(category: card.category)
                    }
                    Text(card.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(TinyTokens.ColorToken.textPrimary)

                    Text(flavorText)
                        .font(.system(size: 13))
                        .foregroundStyle(TinyTokens.ColorToken.textSecondary)

                    Divider()

                    VStack(spacing: 8) {
                        ForEach(Array(card.options.enumerated()), id: \.offset) { index, option in
                            Button {
                                store.resolveCard(cardID: card.id, optionIndex: index)
                            } label: {
                                ChoiceButtonView(
                                    showTexture: store.showChoiceTexture,
                                    label: choiceLabel(index: index),
                                    title: option.label,
                                    effects: effectRows(for: option)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .scrollIndicators(.never)
        }
        .background(TinyTokens.ColorToken.bgPopover)
    }

    private var header: some View {
        HStack(spacing: 8) {
            BackNavigationButton {
                store.backFromCardDetail()
            }

            Text("カード詳細")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(TinyTokens.ColorToken.textPrimary)
            Spacer()
            Text("\(store.viewState.day)日目")
                .font(.system(size: 12))
                .foregroundStyle(TinyTokens.ColorToken.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var flavorText: String {
        switch card.category {
        case "SALES":
            return "収益と評判のバランスを見ながら、短期と中期の意思決定を行います。"
        case "HIRING":
            return "採用の判断は固定費と実行速度に直結します。"
        case "FINANCE":
            return "資金繰りと将来の打ち手を同時に考える必要があります。"
        case "CRISIS":
            return "緊急対応です。処理が遅れるほど不利になります。"
        case "AI":
            return "AI投資は効率改善と負債リスクの両面を持ちます。"
        default:
            return "この選択は会社の状態に直接影響します。"
        }
    }

    private func choiceLabel(index: Int) -> String {
        switch index {
        case 0:
            return "A"
        case 1:
            return "B"
        default:
            return "C"
        }
    }

    private func effectRows(for option: CardOption) -> [EffectRow] {
        let rows = option.effects.compactMap { effect -> EffectRow? in
            switch effect.op {
            case "ADD_CASH":
                let amount = effect.value?.intValue ?? 0
                return EffectRow(
                    text: "資金 \(currency(amount))",
                    tone: amount >= 0 ? .positive : .negative
                )
            case "ADD_MRR":
                let amount = effect.value?.intValue ?? 0
                return EffectRow(
                    text: "月次売上 \(currency(amount))",
                    tone: amount >= 0 ? .positive : .negative
                )
            case "ADD_REPUTATION":
                let amount = effect.value?.doubleValue ?? 0
                return EffectRow(
                    text: "評判 \(signedNumber(amount))",
                    tone: amount >= 0 ? .positive : .negative
                )
            case "ADD_TEAM_HEALTH":
                let amount = effect.value?.doubleValue ?? 0
                return EffectRow(
                    text: "健康 \(signedNumber(amount))",
                    tone: amount >= 0 ? .positive : .negative
                )
            case "ADD_TECH_DEBT":
                let amount = effect.value?.doubleValue ?? 0
                return EffectRow(
                    text: "技術負債 \(signedNumber(amount))",
                    tone: amount > 0 ? .negative : .positive
                )
            case "ADD_DEBT":
                let amount = effect.value?.intValue ?? 0
                return EffectRow(
                    text: "借入 \(currency(amount))",
                    tone: amount > 0 ? .negative : .positive
                )
            case "SET_STRATEGY":
                let strategy = effect.value?.stringValue ?? "BALANCED"
                return EffectRow(text: "方針 \(strategyLabel(strategy))", tone: .neutral)
            case "ADD_LEADS":
                let amount = effect.value?.intValue ?? 0
                return EffectRow(
                    text: "見込み客 \(signedInteger(amount))",
                    tone: amount >= 0 ? .positive : .negative
                )
            case "ADD_AI_XP":
                let amount = effect.value?.intValue ?? 0
                return EffectRow(
                    text: "AI経験値 \(signedInteger(amount))",
                    tone: amount >= 0 ? .positive : .negative
                )
            default:
                return nil
            }
        }

        return Array(rows.prefix(3))
    }

    private func currency(_ value: Int) -> String {
        let rendered = Self.currencyFormatter.string(from: NSNumber(value: value)) ?? "¥\(value)"
        return value >= 0 ? "+\(rendered)" : rendered
    }

    private func signedNumber(_ value: Double) -> String {
        let rounded = String(format: "%.1f", value)
        return value >= 0 ? "+\(rounded)" : rounded
    }

    private func signedInteger(_ value: Int) -> String {
        value >= 0 ? "+\(value)" : "\(value)"
    }

    private func strategyLabel(_ raw: String) -> String {
        switch raw {
        case "CONTRACT_HEAVY":
            return "受託重視"
        case "PRODUCT_HEAVY":
            return "プロダクト重視"
        case "BALANCED":
            return "バランス"
        default:
            return raw
        }
    }
}

private struct EffectRow: Equatable {
    let text: String
    let tone: EffectTone
}

private enum EffectTone {
    case positive
    case negative
    case neutral
}

private struct ChoiceButtonView: View {
    let showTexture: Bool
    let label: String
    let title: String
    let effects: [EffectRow]

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(TinyTokens.ColorToken.bgCell)

            if showTexture, let texture = TinyAsset.choiceTexture() {
                texture
                    .resizable()
                    .scaledToFill()
                    .opacity(0.1)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 8) {
                    Text(label)
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundStyle(TinyTokens.ColorToken.textPrimary)
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(TinyTokens.ColorToken.textPrimary)
                        .multilineTextAlignment(.leading)
                }

                if effects.isEmpty {
                    Text("変化なし")
                        .font(.system(size: 11))
                        .foregroundStyle(TinyTokens.ColorToken.textSecondary)
                } else {
                    ForEach(Array(effects.enumerated()), id: \.offset) { _, effect in
                        Text(effect.text)
                            .font(.system(size: 11))
                            .foregroundStyle(color(for: effect.tone))
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .frame(minHeight: 56)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(TinyTokens.ColorToken.borderDefault, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func color(for tone: EffectTone) -> Color {
        switch tone {
        case .positive:
            return TinyTokens.ColorToken.effectPositive
        case .negative:
            return TinyTokens.ColorToken.effectNegative
        case .neutral:
            return TinyTokens.ColorToken.textSecondary
        }
    }
}

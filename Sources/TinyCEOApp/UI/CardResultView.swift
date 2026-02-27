import SwiftUI

struct CardResultView: View {
    @ObservedObject var store: GameRuntimeStore

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
            HStack(spacing: 8) {
                Button {
                    store.openHome()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                Text("完了")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(TinyTokens.ColorToken.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if let result = store.lastResolution {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                            Text("「\(result.selectedOptionLabel)」を選択しました")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(TinyTokens.ColorToken.textPrimary)

                        Divider()

                        if result.metricDeltas.isEmpty {
                            Text("変化なし")
                                .font(.system(size: 13))
                                .foregroundStyle(TinyTokens.ColorToken.textSecondary)
                        } else {
                            ForEach(result.metricDeltas) { delta in
                                HStack(spacing: 8) {
                                    Image(systemName: delta.sfSymbol)
                                        .font(.system(size: 13))
                                        .frame(width: 18)
                                    Text(delta.label)
                                        .font(.system(size: 13))
                                    Spacer()
                                    Text(format(delta: delta))
                                        .font(.system(size: 13, weight: .semibold))
                                        .monospacedDigit()
                                }
                                .foregroundStyle(store.isBeneficial(delta) ? TinyTokens.ColorToken.effectPositive : TinyTokens.ColorToken.effectNegative)
                            }
                        }

                        Divider()

                        Text("次のカード到着まで: 約\(result.minutesUntilNextCard)分")
                            .font(.system(size: 12))
                            .foregroundStyle(TinyTokens.ColorToken.textSecondary)
                            .monospacedDigit()

                        Button("ホームに戻る") {
                            store.closeResultToHome()
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .scrollIndicators(.never)
            } else {
                VStack {
                    Spacer()
                    Text("結果データがありません")
                        .font(.system(size: 13))
                        .foregroundStyle(TinyTokens.ColorToken.textSecondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(TinyTokens.ColorToken.bgPopover)
    }

    private func format(delta: MetricDelta) -> String {
        switch delta.format {
        case .integer:
            let value = Int(delta.delta.rounded())
            return value >= 0 ? "+\(value)" : "\(value)"
        case .oneDecimal:
            let value = String(format: "%.1f", delta.delta)
            return delta.delta >= 0 ? "+\(value)" : value
        case .currency:
            let value = Int(delta.delta.rounded())
            let rendered = Self.currencyFormatter.string(from: NSNumber(value: value)) ?? "¥\(value)"
            return value >= 0 ? "+\(rendered)" : rendered
        }
    }
}

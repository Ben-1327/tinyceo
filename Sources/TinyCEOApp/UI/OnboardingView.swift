import SwiftUI

struct OnboardingView: View {
    @ObservedObject var store: GameRuntimeStore

    private let privacyText1 = """
「あなたの作業内容は記録しません。
 アプリ種別の滞在時間をカテゴリに集計するだけです。」
"""

    private let privacyText2 = """
「このデータはローカルに保存され、外部に送信されません。」
"""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(spacing: 8) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(TinyTokens.ColorToken.textPrimary)
                    Text("TinyCEO へようこそ")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(TinyTokens.ColorToken.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

                Divider()

                Text("作業連携について")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(TinyTokens.ColorToken.textPrimary)

                Text("アプリの種別（DEV / COMMS / BREAK など）を10分ごとにカテゴリとして集計します。")
                    .font(.system(size: 13))
                    .foregroundStyle(TinyTokens.ColorToken.textPrimary)

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                    Text(privacyText1)
                        .font(.system(size: 13))
                }
                .foregroundStyle(TinyTokens.ColorToken.textPrimary)

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "internaldrive.fill")
                        .font(.system(size: 14))
                    Text(privacyText2)
                        .font(.system(size: 13))
                }
                .foregroundStyle(TinyTokens.ColorToken.textPrimary)

                Divider()

                Button("作業連携をONにして始める（推奨）") {
                    store.completeOnboarding(workIntegrationEnabled: true)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)

                Button("作業連携をOFFで始める") {
                    store.completeOnboarding(workIntegrationEnabled: false)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundStyle(TinyTokens.ColorToken.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .scrollIndicators(.never)
        .background(TinyTokens.ColorToken.bgPopover)
    }
}

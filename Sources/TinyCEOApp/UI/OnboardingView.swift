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

                profileSection

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

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("プロフィール設定")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(TinyTokens.ColorToken.textPrimary)

            VStack(alignment: .leading, spacing: 4) {
                Text("あなたの名前")
                    .font(.system(size: 12))
                    .foregroundStyle(TinyTokens.ColorToken.textSecondary)
                TextField("例: 岡田 太一", text: $store.playerName)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("会社名")
                    .font(.system(size: 12))
                    .foregroundStyle(TinyTokens.ColorToken.textSecondary)
                TextField("例: TinyCEO Studio", text: $store.companyName)
                    .textFieldStyle(.roundedBorder)
            }

            Text("アバター")
                .font(.system(size: 12))
                .foregroundStyle(TinyTokens.ColorToken.textSecondary)

            HStack(spacing: 8) {
                ForEach(store.avatarOptions) { option in
                    Button {
                        store.selectedAvatarID = option.id
                    } label: {
                        VStack(spacing: 4) {
                            if let sprite = TinyAsset.characterSprite(named: option.assetName) {
                                sprite
                                    .resizable()
                                    .interpolation(.none)
                                    .scaledToFit()
                                    .frame(width: 22, height: 30)
                            }
                            Text(option.label)
                                .font(.system(size: 10, weight: .medium))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(store.selectedAvatarID == option.id ? TinyTokens.ColorToken.bgWarning : TinyTokens.ColorToken.bgCell)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(store.selectedAvatarID == option.id ? TinyTokens.ColorToken.borderWarning : TinyTokens.ColorToken.borderDefault, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(TinyTokens.ColorToken.textPrimary)
                }
            }
        }
        .padding(12)
        .background(TinyTokens.ColorToken.bgCell)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(TinyTokens.ColorToken.borderDefault, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

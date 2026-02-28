import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: GameRuntimeStore
    @State private var showResetConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    sectionTitle("プロフィール")
                    TextField("あなたの名前", text: $store.playerName)
                        .textFieldStyle(.roundedBorder)
                    TextField("会社名", text: $store.companyName)
                        .textFieldStyle(.roundedBorder)

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
                                            .frame(width: 20, height: 28)
                                    }
                                    Text(option.label)
                                        .font(.system(size: 10, weight: .medium))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 7)
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

                    sectionTitle("作業連携")
                    Toggle(
                        "作業連携",
                        isOn: Binding(
                            get: { store.snapshot?.isWorkIntegrationEnabled ?? true },
                            set: { store.setWorkIntegrationEnabled($0) }
                        )
                    )
                    activityDiagnosticsPanel

                    sectionTitle("通知")
                    Toggle("カード到着", isOn: $store.cardNotificationsEnabled)
                    Toggle("重大Crisis", isOn: $store.crisisNotificationsEnabled)

                    sectionTitle("プライバシー")
                    Button("収集データを確認する ↗") {
                        openAppDataDirectory()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(TinyTokens.ColorToken.textPrimary)

                    if let appDataDirectory = store.appDataDirectoryURL {
                        Text(appDataDirectory.path)
                            .font(.system(size: 11))
                            .foregroundStyle(TinyTokens.ColorToken.textSecondary)
                            .textSelection(.enabled)
                    }

                    sectionTitle("表示")
                    Toggle("選択肢テクスチャ（既定OFF）", isOn: $store.showChoiceTexture)
                    Toggle("オフィス装飾を表示", isOn: $store.showOfficeDecorations)

                    Divider()

                    Button("アプリケーションを終了") {
                        NSApp.terminate(nil)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(TinyTokens.ColorToken.textPrimary)

                    Button("データをリセット（最初からやり直す）") {
                        showResetConfirmation = true
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(TinyTokens.ColorToken.statusDanger)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .scrollIndicators(.never)
        }
        .background(TinyTokens.ColorToken.bgPopover)
        .confirmationDialog("データをリセットしますか？", isPresented: $showResetConfirmation, titleVisibility: .visible) {
            Button("リセット", role: .destructive) {
                store.resetGame()
            }
            Button("キャンセル", role: .cancel) {}
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            BackNavigationButton {
                store.backFromSettings()
            }

            Text("設定")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(TinyTokens.ColorToken.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(TinyTokens.ColorToken.textSecondary)
            .textCase(.uppercase)
    }

    private var activityDiagnosticsPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("現在のアプリ: \(store.activityObservation.appName)")
            Text("Bundle ID: \(store.activityObservation.bundleID)")
            Text("URLドメイン: \(store.activityObservation.domain ?? "-")")
            Text("判定カテゴリ: \(store.activityObservation.category)")
            Text("状態: \(statusText(store.activityObservation))")
            if let sampledAt = store.activityObservation.sampledAt {
                Text("最終取得: \(sampledAt.formatted(date: .omitted, time: .standard))")
            }
            Text("反映先: プロジェクト進捗・AI経験値・健康回復")
                .foregroundStyle(TinyTokens.ColorToken.textSecondary)
        }
        .font(.system(size: 11))
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TinyTokens.ColorToken.bgCell)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(TinyTokens.ColorToken.borderDefault, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func statusText(_ observation: ActivityObservation) -> String {
        switch observation.status {
        case .waiting:
            return "取得待ち"
        case .disabled:
            return "作業連携OFF"
        case .sampled:
            if observation.isIdle {
                return "アイドル判定"
            }
            return "取得中"
        }
    }

    private func openAppDataDirectory() {
        guard let url = store.appDataDirectoryURL else {
            return
        }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}

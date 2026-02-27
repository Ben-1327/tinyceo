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
                    sectionTitle("作業連携")
                    Toggle(
                        "作業連携",
                        isOn: Binding(
                            get: { store.snapshot?.isWorkIntegrationEnabled ?? true },
                            set: { store.setWorkIntegrationEnabled($0) }
                        )
                    )

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
                    Toggle("Choice Texture（既定OFF）", isOn: $store.showChoiceTexture)
                    Toggle("Office 装飾を表示", isOn: $store.showOfficeDecorations)

                    Divider()

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
            Button {
                store.backFromSettings()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
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

    private func openAppDataDirectory() {
        guard let url = store.appDataDirectoryURL else {
            return
        }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}

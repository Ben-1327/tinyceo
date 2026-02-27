import SwiftUI

struct PopoverRootView: View {
    @ObservedObject var store: GameRuntimeStore

    var body: some View {
        Group {
            switch store.currentScreen {
            case .onboarding:
                OnboardingView(store: store)
            case .home:
                HomePopoverView(store: store)
            case .inbox:
                InboxListView(store: store)
            case .cardDetail(let cardID):
                if let card = store.cardDefinition(for: cardID) {
                    CardDetailView(store: store, card: card)
                } else {
                    HomePopoverView(store: store)
                }
            case .cardResult:
                CardResultView(store: store)
            case .settings:
                SettingsView(store: store)
            }
        }
        .frame(minWidth: TinyTokens.Size.popoverMinWidth)
        .frame(width: TinyTokens.Size.popoverWidth)
        .background(TinyTokens.ColorToken.bgPopover)
    }
}

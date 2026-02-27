import AppKit
import Combine
import SwiftUI
import TinyCEOCore

@MainActor
final class MenuBarAppDelegate: NSObject, NSApplicationDelegate {
    private let store = GameRuntimeStore()
    private let popover = NSPopover()

    private var statusItem: NSStatusItem?
    private var cancellables: Set<AnyCancellable> = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configurePopover()
        configureStatusItem()
        bindStore()
        store.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        store.stop()
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: TinyTokens.Size.popoverWidth, height: 420)
        popover.contentViewController = NSHostingController(
            rootView: HomePopoverView(store: store)
                .frame(minWidth: TinyTokens.Size.popoverMinWidth)
                .frame(width: TinyTokens.Size.popoverWidth)
        )
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem = item
        guard let button = item.button else { return }

        button.target = self
        button.action = #selector(togglePopover(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        updateStatusIcon(for: store.viewState)
    }

    private func bindStore() {
        store.$viewState
            .sink { [weak self] viewState in
                self?.updateStatusIcon(for: viewState)
            }
            .store(in: &cancellables)

        store.$runtimeError
            .sink { [weak self] error in
                guard let button = self?.statusItem?.button else { return }
                if let error {
                    button.toolTip = "TinyCEO: \(error)"
                } else {
                    button.toolTip = "TinyCEO"
                }
            }
            .store(in: &cancellables)
    }

    private func updateStatusIcon(for viewState: GameViewState) {
        guard let button = statusItem?.button else { return }
        let symbolName = statusSymbolName(for: viewState)
        guard let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "TinyCEO") else {
            return
        }
        image.isTemplate = true
        button.image = image
    }

    private func statusSymbolName(for viewState: GameViewState) -> String {
        if viewState.showInboxFullBanner {
            return "tray.full.fill"
        }
        if viewState.inboxCount > 0 {
            return "tray.fill"
        }
        switch viewState.riskLevel {
        case .normal:
            return "building.2.fill"
        case .warn:
            return "exclamationmark.circle.fill"
        case .danger:
            return "exclamationmark.triangle.fill"
        }
    }

    @objc
    private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem?.button else { return }

        if popover.isShown {
            popover.performClose(sender)
            return
        }

        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }
}

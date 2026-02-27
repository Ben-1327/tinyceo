import AppKit
import Combine
import QuartzCore
import SwiftUI
import TinyCEOCore

@MainActor
final class MenuBarAppDelegate: NSObject, NSApplicationDelegate {
    private let store = GameRuntimeStore()
    private let popover = NSPopover()

    private var statusItem: NSStatusItem?
    private var statusDotView: NSView?
    private var cancellables: Set<AnyCancellable> = []
    private let pulseAnimationKey = "tinyceo.statusDotPulse"

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
            rootView: PopoverRootView(store: store)
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
        configureStatusDot(on: button)
        updateStatusPresentation(for: store.viewState)
    }

    private func bindStore() {
        store.$viewState
            .sink { [weak self] viewState in
                self?.updateStatusPresentation(for: viewState)
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

        store.$requiresStickyPopover
            .sink { [weak self] requiresSticky in
                self?.popover.behavior = requiresSticky ? .semitransient : .transient
            }
            .store(in: &cancellables)
    }

    private func updateStatusPresentation(for viewState: GameViewState) {
        updateStatusIcon()
        updateStatusDot(for: viewState)
    }

    private func updateStatusIcon() {
        guard let button = statusItem?.button else { return }
        guard let image = NSImage(systemSymbolName: "building.2.fill", accessibilityDescription: "TinyCEO") else {
            return
        }
        image.isTemplate = true
        button.image = image
    }

    private func configureStatusDot(on button: NSStatusBarButton) {
        let dot = NSView(frame: .zero)
        dot.wantsLayer = true
        dot.isHidden = true
        button.addSubview(dot)
        statusDotView = dot
        positionStatusDot(in: button)
    }

    private func positionStatusDot(in button: NSStatusBarButton) {
        guard let dot = statusDotView else { return }
        let size: CGFloat = 8
        dot.frame = NSRect(
            x: button.bounds.width - size - 2,
            y: button.bounds.height - size - 2,
            width: size,
            height: size
        )
        dot.layer?.cornerRadius = size / 2
        dot.layer?.masksToBounds = true
    }

    private func updateStatusDot(for viewState: GameViewState) {
        guard let button = statusItem?.button, let dot = statusDotView else { return }
        positionStatusDot(in: button)

        let appearance: (color: NSColor?, pulse: Bool)
        if viewState.riskLevel == .danger {
            appearance = (NSColor.systemRed, true)
        } else if viewState.showInboxFullBanner {
            appearance = (NSColor.systemRed, false)
        } else if viewState.inboxCount > 0 {
            appearance = (NSColor.systemBlue, false)
        } else if viewState.riskLevel == .warn {
            appearance = (NSColor.systemOrange, false)
        } else {
            appearance = (nil, false)
        }

        guard let color = appearance.color else {
            dot.isHidden = true
            dot.layer?.removeAnimation(forKey: pulseAnimationKey)
            return
        }

        dot.isHidden = false
        dot.layer?.backgroundColor = color.cgColor

        if appearance.pulse {
            if dot.layer?.animation(forKey: pulseAnimationKey) == nil {
                let animation = CABasicAnimation(keyPath: "opacity")
                animation.fromValue = 0.6
                animation.toValue = 1.0
                animation.duration = 0.75
                animation.autoreverses = true
                animation.repeatCount = .infinity
                dot.layer?.add(animation, forKey: pulseAnimationKey)
            }
        } else {
            dot.layer?.removeAnimation(forKey: pulseAnimationKey)
            dot.layer?.opacity = 1.0
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

import AppKit
import CoreGraphics
import TinyCEOCore

protocol ActivitySignalProviding: Sendable {
    func currentSignal(idleThresholdMinutes: Int) -> ActivitySignal
}

struct SystemActivitySignalProvider: ActivitySignalProviding {
    func currentSignal(idleThresholdMinutes: Int) -> ActivitySignal {
        let frontmost = NSWorkspace.shared.frontmostApplication
        let idleThresholdSeconds = Double(max(idleThresholdMinutes, 0) * 60)

        let sampledTypes: [CGEventType] = [.keyDown, .leftMouseDown, .rightMouseDown, .mouseMoved, .scrollWheel]
        let minSecondsSinceInput = sampledTypes
            .map { CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: $0) }
            .min() ?? 0

        return ActivitySignal(
            bundleId: frontmost?.bundleIdentifier,
            processName: frontmost?.localizedName,
            domain: nil,
            isIdle: minSecondsSinceInput >= idleThresholdSeconds
        )
    }
}

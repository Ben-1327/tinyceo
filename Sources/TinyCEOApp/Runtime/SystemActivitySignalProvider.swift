import AppKit
import CoreGraphics
import Foundation
import TinyCEOCore

protocol ActivitySignalProviding: Sendable {
    func currentSignal(idleThresholdMinutes: Int) -> ActivitySignal
}

struct SystemActivitySignalProvider: ActivitySignalProviding {
    func currentSignal(idleThresholdMinutes: Int) -> ActivitySignal {
        let frontmost = NSWorkspace.shared.frontmostApplication
        let bundleID = frontmost?.bundleIdentifier
        let idleThresholdSeconds = Double(max(idleThresholdMinutes, 0) * 60)

        let sampledTypes: [CGEventType] = [.keyDown, .leftMouseDown, .rightMouseDown, .mouseMoved, .scrollWheel]
        let minSecondsSinceInput = sampledTypes
            .map { CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: $0) }
            .min() ?? 0

        return ActivitySignal(
            bundleId: bundleID,
            processName: frontmost?.localizedName,
            domain: browserDomain(bundleID: bundleID),
            isIdle: minSecondsSinceInput >= idleThresholdSeconds
        )
    }

    private func browserDomain(bundleID: String?) -> String? {
        guard let bundleID else { return nil }
        guard let appName = supportedBrowserAppName(for: bundleID) else { return nil }
        guard let rawURL = activeTabURL(appName: appName, bundleID: bundleID) else { return nil }
        return parsedHost(from: rawURL)
    }

    private func supportedBrowserAppName(for bundleID: String) -> String? {
        switch bundleID {
        case "com.apple.Safari":
            return "Safari"
        case "com.google.Chrome":
            return "Google Chrome"
        case "com.brave.Browser":
            return "Brave Browser"
        case "com.microsoft.edgemac":
            return "Microsoft Edge"
        case "company.thebrowser.Browser":
            return "Arc"
        default:
            return nil
        }
    }

    private func activeTabURL(appName: String, bundleID: String) -> String? {
        let scriptSource: String
        if bundleID == "com.apple.Safari" {
            scriptSource = """
            tell application "\(appName)"
                if (count of windows) = 0 then return ""
                return URL of current tab of front window
            end tell
            """
        } else {
            scriptSource = """
            tell application "\(appName)"
                if (count of windows) = 0 then return ""
                return URL of active tab of front window
            end tell
            """
        }

        var error: NSDictionary?
        guard let script = NSAppleScript(source: scriptSource),
              let descriptor = script.executeAndReturnError(&error).stringValue else {
            return nil
        }

        let normalized = descriptor.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.isEmpty || normalized == "missing value" {
            return nil
        }
        return normalized
    }

    private func parsedHost(from rawURL: String) -> String? {
        let normalized = rawURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if let host = URLComponents(string: normalized)?.host?.lowercased(), !host.isEmpty {
            return host
        }
        if let host = URLComponents(string: "https://\(normalized)")?.host?.lowercased(), !host.isEmpty {
            return host
        }
        return nil
    }
}

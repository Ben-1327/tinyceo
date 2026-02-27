import Foundation

public struct ActivitySignal: Sendable {
    public var bundleId: String?
    public var processName: String?
    public var domain: String?
    public var isIdle: Bool

    public init(bundleId: String? = nil, processName: String? = nil, domain: String? = nil, isIdle: Bool = false) {
        self.bundleId = bundleId
        self.processName = processName
        self.domain = domain
        self.isIdle = isIdle
    }
}

public struct ActivityClassifier: Sendable {
    private let rules: ActivityRulesData

    public init(rules: ActivityRulesData) {
        self.rules = rules
    }

    public func classify(signal: ActivitySignal, mode: String? = nil) -> ActivityCategory {
        if signal.isIdle {
            return .rest
        }

        let currentMode = mode ?? rules.defaultMode
        var category = classifyFromAppRules(signal: signal) ?? .research

        if let domain = signal.domain?.lowercased(), shouldApplyDomainOverride(bundleId: signal.bundleId, currentCategory: category) {
            if let override = rules.browserDomainOverrides.first(where: { domain == $0.domain || domain.hasSuffix("." + $0.domain) }) {
                if let mapped = override.modeToCategory[currentMode], let resolved = ActivityCategory(rawValue: mapped) {
                    category = resolved
                }
            }
        }

        return category
    }

    private func classifyFromAppRules(signal: ActivitySignal) -> ActivityCategory? {
        for rule in rules.appCategoryRules {
            switch rule.match {
            case "bundleId":
                guard let bundleId = signal.bundleId else { continue }
                if wildcardMatch(bundleId, pattern: rule.pattern), let category = ActivityCategory(rawValue: rule.category) {
                    return category
                }
            case "processName":
                guard let processName = signal.processName else { continue }
                if processName.range(of: rule.pattern, options: .caseInsensitive) != nil,
                   let category = ActivityCategory(rawValue: rule.category) {
                    return category
                }
            default:
                continue
            }
        }
        return nil
    }

    private func shouldApplyDomainOverride(bundleId: String?, currentCategory: ActivityCategory) -> Bool {
        if currentCategory == .research || currentCategory == .ai {
            return true
        }
        guard let bundle = bundleId?.lowercased() else {
            return false
        }
        return bundle.contains("chrome") || bundle.contains("safari") || bundle.contains("firefox") || bundle.contains("arc")
    }

    private func wildcardMatch(_ value: String, pattern: String) -> Bool {
        if !pattern.contains("*") {
            return value == pattern
        }
        let escaped = NSRegularExpression.escapedPattern(for: pattern)
            .replacingOccurrences(of: "\\*", with: ".*")
        let expression = "^\(escaped)$"
        return value.range(of: expression, options: .regularExpression) != nil
    }
}

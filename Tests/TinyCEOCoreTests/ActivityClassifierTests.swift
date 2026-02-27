import Foundation
import Testing
@testable import TinyCEOCore

@Test("youtube mode mapping changes by focus mode")
func youtubeModeSwitching() throws {
    let data = try DataLoader().loadAll(from: URL(fileURLWithPath: "data", isDirectory: true))
    let classifier = ActivityClassifier(rules: data.activityRules)

    let focus = classifier.classify(
        signal: ActivitySignal(bundleId: "com.google.Chrome", processName: "Chrome", domain: "youtube.com", isIdle: false),
        mode: "FOCUS"
    )
    #expect(focus == .rest)

    let research = classifier.classify(
        signal: ActivitySignal(bundleId: "com.google.Chrome", processName: "Chrome", domain: "youtube.com", isIdle: false),
        mode: "RESEARCH"
    )
    #expect(research == .research)
}

@Test("chatgpt domain maps to ai category")
func chatGPTDomainAlwaysAI() throws {
    let data = try DataLoader().loadAll(from: URL(fileURLWithPath: "data", isDirectory: true))
    let classifier = ActivityClassifier(rules: data.activityRules)

    let category = classifier.classify(
        signal: ActivitySignal(bundleId: "com.google.Chrome", processName: "Chrome", domain: "chatgpt.com", isIdle: false),
        mode: "BREAK"
    )
    #expect(category == .ai)
}

@Test("wildcard bundle id rule matches jetbrains apps")
func wildcardBundleRuleMatchesJetbrains() throws {
    let data = try DataLoader().loadAll(from: URL(fileURLWithPath: "data", isDirectory: true))
    let classifier = ActivityClassifier(rules: data.activityRules)

    let category = classifier.classify(
        signal: ActivitySignal(bundleId: "com.jetbrains.PyCharm", processName: "PyCharm", domain: nil, isIdle: false),
        mode: "FOCUS"
    )
    #expect(category == .dev)
}

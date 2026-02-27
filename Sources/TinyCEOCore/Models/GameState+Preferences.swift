public extension GameState {
    var isWorkIntegrationEnabled: Bool {
        get {
            flags[SystemFlagKeys.workIntegrationEnabled]?.boolValue ?? true
        }
        set {
            flags[SystemFlagKeys.workIntegrationEnabled] = .bool(newValue)
        }
    }

    var hasMissedCardGenerationDueToFullInbox: Bool {
        flags[SystemFlagKeys.inboxOverflowedSinceLastRelief]?.boolValue ?? false
    }
}

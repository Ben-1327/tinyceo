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

    var nextCardIntervalRealMinutes: Int? {
        get {
            flags[SystemFlagKeys.nextCardIntervalRealMinutes]?.intValue
        }
        set {
            if let newValue {
                flags[SystemFlagKeys.nextCardIntervalRealMinutes] = .int(newValue)
            } else {
                flags.removeValue(forKey: SystemFlagKeys.nextCardIntervalRealMinutes)
            }
        }
    }
}

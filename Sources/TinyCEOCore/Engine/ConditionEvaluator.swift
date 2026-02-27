import Foundation

public enum ConditionEvaluator {
    public static func evaluateAll(_ conditions: [CardCondition], state: GameState, data: GameData) -> Bool {
        conditions.allSatisfy { evaluate($0, state: state, data: data) }
    }

    public static func evaluate(_ condition: CardCondition, state: GameState, data: GameData) -> Bool {
        if let flagKey = condition.flag {
            let current = state.flags[flagKey] ?? .bool(false)
            return compareScalar(current: current, op: condition.op, expected: condition.value)
        }

        guard let metric = condition.metric else {
            return false
        }

        switch metric {
        case "policiesUnlocked":
            return compareSet(values: state.unlockedPolicyIDs, op: condition.op, expected: condition.value.stringValue)
        case "policiesEnabled":
            return compareSet(values: state.enabledPolicyIDs, op: condition.op, expected: condition.value.stringValue)
        case "chapterUnlocked":
            return compareChapter(state: state, data: data, op: condition.op, expectedChapterID: condition.value.stringValue)
        default:
            guard let current = scalarMetric(metric, state: state) else {
                return false
            }
            return compareScalar(current: current, op: condition.op, expected: condition.value)
        }
    }

    private static func scalarMetric(_ metric: String, state: GameState) -> FlagValue? {
        switch metric {
        case "day":
            return .int(state.day)
        case "cashJPY":
            return .int(state.metrics.cashJPY)
        case "mrrJPY":
            return .int(state.metrics.mrrJPY)
        case "debtJPY":
            return .int(state.metrics.debtJPY)
        case "reputation":
            return .double(state.metrics.reputation)
        case "teamHealth":
            return .double(state.metrics.teamHealth)
        case "techDebt":
            return .double(state.metrics.techDebt)
        case "aiMaturityLevel":
            return .int(state.metrics.aiMaturityLevel)
        case "teamSize":
            return .int(state.teamSize)
        case "projectsCompletedContracts":
            return .int(state.completedProjectsByType["CONTRACT", default: 0])
        case "hasProductLaunched":
            return .bool(state.hasProductLaunched)
        default:
            if let value = state.flags[metric] {
                return value
            }
            return nil
        }
    }

    private static func compareSet(values: Set<String>, op: String, expected: String) -> Bool {
        switch op {
        case "CONTAINS":
            return values.contains(expected)
        case "NOT_CONTAINS":
            return !values.contains(expected)
        default:
            return false
        }
    }

    private static func compareChapter(state: GameState, data: GameData, op: String, expectedChapterID: String) -> Bool {
        let chapterIDs = data.progression.chapters.map(\.id)
        guard state.chapterIndex >= 0,
              state.chapterIndex < chapterIDs.count,
              let expectedIndex = chapterIDs.firstIndex(of: expectedChapterID) else {
            return false
        }

        return compareInt(current: state.chapterIndex, op: op, expected: expectedIndex)
    }

    private static func compareScalar(current: FlagValue, op: String, expected: FlagValue) -> Bool {
        if let currentNumber = current.doubleValue, let expectedNumber = expected.doubleValue {
            return compareDouble(current: currentNumber, op: op, expected: expectedNumber)
        }

        if let currentBool = current.boolValue, let expectedBool = expected.boolValue, ["==", "!="].contains(op) {
            return op == "==" ? currentBool == expectedBool : currentBool != expectedBool
        }

        let currentString = current.stringValue
        let expectedString = expected.stringValue
        switch op {
        case "==":
            return currentString == expectedString
        case "!=":
            return currentString != expectedString
        case ">":
            return currentString > expectedString
        case ">=":
            return currentString >= expectedString
        case "<":
            return currentString < expectedString
        case "<=":
            return currentString <= expectedString
        default:
            return false
        }
    }

    private static func compareDouble(current: Double, op: String, expected: Double) -> Bool {
        switch op {
        case "==":
            return abs(current - expected) < 0.00001
        case "!=":
            return abs(current - expected) >= 0.00001
        case ">":
            return current > expected
        case ">=":
            return current >= expected
        case "<":
            return current < expected
        case "<=":
            return current <= expected
        default:
            return false
        }
    }

    private static func compareInt(current: Int, op: String, expected: Int) -> Bool {
        switch op {
        case "==":
            return current == expected
        case "!=":
            return current != expected
        case ">":
            return current > expected
        case ">=":
            return current >= expected
        case "<":
            return current < expected
        case "<=":
            return current <= expected
        default:
            return false
        }
    }
}

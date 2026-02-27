import Foundation

public struct SeededGenerator: Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        self.state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
    }

    public mutating func nextUInt64() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }

    public mutating func nextDouble() -> Double {
        let value = nextUInt64() >> 11
        return Double(value) / Double(1 << 53)
    }

    public mutating func chooseIndex(weights: [Double]) -> Int? {
        let positiveWeights = weights.map { max(0, $0) }
        let total = positiveWeights.reduce(0, +)
        guard total > 0 else { return nil }
        let ticket = nextDouble() * total
        var running = 0.0
        for (index, weight) in positiveWeights.enumerated() {
            running += weight
            if ticket <= running {
                return index
            }
        }
        return positiveWeights.indices.last
    }

    public mutating func chooseElement<T>(_ values: [T]) -> T? {
        guard !values.isEmpty else { return nil }
        let index = Int(nextUInt64() % UInt64(values.count))
        return values[index]
    }
}

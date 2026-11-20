/// Removes the 1 degree jitter of the lid sensor, so the number on screen
/// does not flicker (for example 112, 113, 112) when the lid does not move.
///
/// - A change smaller than `jumpLimit` shows only after the reading stays
///   at the new value for `settleTime`.
/// - A change of `jumpLimit` or more shows at once, so a moving lid has no lag.
public struct AngleStabilizer: Sendable {
    public static let jumpLimit = 2.0
    public static let settleTime = 0.1

    public private(set) var value: Double?
    private var pending: (value: Double, since: Double)?

    public init() {}

    /// Adds a reading taken at `time` (seconds). Returns the new value when it changes.
    @discardableResult
    public mutating func update(_ raw: Double, at time: Double) -> Double? {
        guard let current = value, abs(raw - current) < Self.jumpLimit else {
            return accept(raw)
        }
        guard raw != current else {
            pending = nil
            return nil
        }
        guard let pending, pending.value == raw else {
            self.pending = (raw, time)
            return nil
        }
        // Small tolerance: sums of sample times are not exact in floating point.
        return time - pending.since >= Self.settleTime - 1e-9 ? accept(raw) : nil
    }

    private mutating func accept(_ raw: Double) -> Double? {
        pending = nil
        guard raw != value else { return nil }
        value = raw
        return raw
    }
}

import Foundation

/// Freezes the shown angle until the user unlocks it.
///
/// With a key: a tap locks and the next press unlocks. A long hold
/// (at least `holdThreshold`) locks only while the key is held.
public struct AngleLock: Equatable, Sendable {
    public enum Change: Equatable, Sendable {
        case locked
        case unlocked
    }

    public static let holdThreshold: TimeInterval = 0.4

    public private(set) var lockedAngle: Double?
    /// Time of the key press that locked, while that key is still down.
    private var heldSince: TimeInterval?

    public init() {}

    public var isLocked: Bool { lockedAngle != nil }

    /// Locks the current angle, or unlocks if already locked.
    /// Without a reading there is nothing to lock, so it stays unlocked.
    @discardableResult
    public mutating func toggle(current: Double?) -> Change? {
        heldSince = nil
        if isLocked {
            lockedAngle = nil
            return .unlocked
        }
        guard let current else { return nil }
        lockedAngle = current
        return .locked
    }

    /// Key down: locks when unlocked, unlocks when locked.
    @discardableResult
    public mutating func press(current: Double?, at time: TimeInterval) -> Change? {
        let change = toggle(current: current)
        if change == .locked { heldSince = time }
        return change
    }

    /// Key up: unlocks if the press that locked was a long hold.
    @discardableResult
    public mutating func release(at time: TimeInterval) -> Change? {
        guard let start = heldSince else { return nil }
        heldSince = nil
        guard time - start >= Self.holdThreshold else { return nil }
        lockedAngle = nil
        return .unlocked
    }

    /// The angle to show: the locked angle, else the live angle.
    public func displayed(live: Double?) -> Double? {
        lockedAngle ?? live
    }
}

public enum LidAngle {
    /// True when the angle shows as 90 degrees.
    public static func isRightAngle(_ degrees: Double) -> Bool {
        degrees.rounded() == 90
    }
}

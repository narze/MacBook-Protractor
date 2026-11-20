/// Freezes the shown angle until the user unlocks it.
public struct AngleLock: Equatable, Sendable {
    public private(set) var lockedAngle: Double?

    public init() {}

    public var isLocked: Bool { lockedAngle != nil }

    /// Locks the current angle, or unlocks if already locked.
    /// Without a reading there is nothing to lock, so it stays unlocked.
    public mutating func toggle(current: Double?) {
        lockedAngle = isLocked ? nil : current
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

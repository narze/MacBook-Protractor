/// Decodes an input report of the built-in accelerometer (Bosch BMI286 behind the SPU).
///
/// Report layout (22 bytes): x, y, z start at byte 6, each a little-endian
/// Int32 in Q16 fixed point (65536 = 1 g). Axes are in the base: lying flat
/// gives z = -1, standing on the left edge gives x = -1, on the right edge x = +1.
public enum AccelerometerReport {
    public static let length = 22

    public static func gravity(from bytes: [UInt8]) -> (x: Double, y: Double, z: Double)? {
        guard bytes.count == length else { return nil }
        func value(at offset: Int) -> Double {
            let raw = UInt32(bytes[offset])
                | UInt32(bytes[offset + 1]) << 8
                | UInt32(bytes[offset + 2]) << 16
                | UInt32(bytes[offset + 3]) << 24
            return Double(Int32(bitPattern: raw)) / 65536
        }
        return (value(at: 6), value(at: 10), value(at: 14))
    }
}

/// How to rotate the UI so that it reads upright.
public enum ScreenRotation: Equatable, Sendable {
    case upright
    /// The Mac stands on its left edge.
    case clockwise
    /// The Mac stands on its right edge.
    case counterClockwise

    /// Rotation in degrees, positive is clockwise (as in SwiftUI `rotationEffect`).
    public var degrees: Double {
        switch self {
        case .upright: 0
        case .clockwise: 90
        case .counterClockwise: -90
        }
    }
}

/// Finds the screen rotation from the gravity along the hinge axis (x).
///
/// A low-pass filter ignores short bumps, and hysteresis (enter at 0.75 g,
/// leave at 0.45 g) stops the UI from flipping back and forth at the edge.
public struct OrientationDetector: Sendable {
    public static let enterLimit = 0.75
    public static let exitLimit = 0.45
    /// Filter weight of a new sample. At 100 Hz this settles in about 0.2 s.
    public static let smoothing = 0.1

    public private(set) var rotation: ScreenRotation = .upright
    private var filteredX = 0.0

    public init() {}

    /// Adds a sample. Returns the new rotation when it changes.
    @discardableResult
    public mutating func update(gravityX x: Double) -> ScreenRotation? {
        filteredX += (x - filteredX) * Self.smoothing
        let next = nextRotation(for: filteredX)
        guard next != rotation else { return nil }
        rotation = next
        return next
    }

    private func nextRotation(for x: Double) -> ScreenRotation {
        if x <= -Self.enterLimit { return .clockwise }
        if x >= Self.enterLimit { return .counterClockwise }
        switch rotation {
        case .clockwise where x <= -Self.exitLimit: return .clockwise
        case .counterClockwise where x >= Self.exitLimit: return .counterClockwise
        default: return .upright
        }
    }
}

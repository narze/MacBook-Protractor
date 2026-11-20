import Testing
@testable import LidAngleCore

@Suite("AccelerometerReport.gravity(from:)")
struct AccelerometerReportTests {
    // A real 22-byte report from the BMI286 with the Mac lying flat.
    let flat: [UInt8] = [
        0x49, 0x4f, 0x00, 0x00, 0x00, 0x00,
        0x1a, 0xfc, 0xff, 0xff,   // x = -998
        0xe6, 0x41, 0x00, 0x00,   // y = 16870
        0x9f, 0x0d, 0xff, 0xff,   // z = -62049
        0x80, 0xdd, 0x25, 0x00,
    ]

    @Test("Reads x, y, z as little-endian Int32 in Q16 (g) from byte 6")
    func parsesRealReport() throws {
        let g = try #require(AccelerometerReport.gravity(from: flat))
        #expect(g.x == -998.0 / 65536)
        #expect(g.y == 16870.0 / 65536)
        #expect(g.z == -62049.0 / 65536)
    }

    @Test("Returns nil when the report is not 22 bytes", arguments: [0, 18, 21, 23])
    func rejectsWrongLength(length: Int) {
        #expect(AccelerometerReport.gravity(from: [UInt8](repeating: 0, count: length)) == nil)
    }
}

@Suite("OrientationDetector")
struct OrientationDetectorTests {
    /// Feeds the same reading long enough for the filter to settle.
    func settle(_ detector: inout OrientationDetector, x: Double, steps: Int = 100) {
        for _ in 0..<steps { detector.update(gravityX: x) }
    }

    @Test("Starts upright")
    func startsUpright() {
        #expect(OrientationDetector().rotation == .upright)
    }

    @Test("Standing on the left edge (x = -1) rotates clockwise")
    func leftEdgeDown() {
        var detector = OrientationDetector()
        settle(&detector, x: -1)
        #expect(detector.rotation == .clockwise)
        #expect(detector.rotation.degrees == 90)
    }

    @Test("Standing on the right edge (x = +1) rotates counter-clockwise")
    func rightEdgeDown() {
        var detector = OrientationDetector()
        settle(&detector, x: 1)
        #expect(detector.rotation == .counterClockwise)
        #expect(detector.rotation.degrees == -90)
    }

    @Test("Lying flat (x = 0) is upright")
    func flat() {
        var detector = OrientationDetector()
        settle(&detector, x: -1)
        settle(&detector, x: 0)
        #expect(detector.rotation == .upright)
    }

    @Test("A small tilt does not rotate")
    func smallTilt() {
        var detector = OrientationDetector()
        settle(&detector, x: 0.5)
        #expect(detector.rotation == .upright)
    }

    @Test("Hysteresis: a rotated screen stays rotated until the tilt is clearly gone")
    func hysteresis() {
        var detector = OrientationDetector()
        settle(&detector, x: -1)
        settle(&detector, x: -0.6)   // between the enter and exit limits
        #expect(detector.rotation == .clockwise)
        settle(&detector, x: -0.3)
        #expect(detector.rotation == .upright)
    }

    @Test("A short bump does not rotate")
    func shortBump() {
        var detector = OrientationDetector()
        for _ in 0..<3 { detector.update(gravityX: -1) }
        #expect(detector.rotation == .upright)
    }

    @Test("update returns the rotation only when it changes")
    func reportsChange() {
        var detector = OrientationDetector()
        var changes: [ScreenRotation] = []
        for _ in 0..<100 {
            if let change = detector.update(gravityX: -1) { changes.append(change) }
        }
        #expect(changes == [.clockwise])
    }
}

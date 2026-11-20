import Testing
@testable import LidAngleCore

@Suite("AngleStabilizer")
struct AngleStabilizerTests {
    /// One sample per tick at 30 Hz.
    let tick = 1.0 / 30.0

    @Test("Shows the first reading at once")
    func firstReading() {
        var stabilizer = AngleStabilizer()
        #expect(stabilizer.update(100, at: 0) == 100)
        #expect(stabilizer.value == 100)
    }

    @Test("Ignores 1 degree jitter that does not stay")
    func ignoresJitter() {
        var stabilizer = AngleStabilizer()
        stabilizer.update(100, at: 0)
        var changes: [Double] = []
        for i in 1...30 {
            let raw: Double = i.isMultiple(of: 2) ? 100 : 101
            if let change = stabilizer.update(raw, at: Double(i) * tick) { changes.append(change) }
        }
        #expect(changes.isEmpty)
        #expect(stabilizer.value == 100)
    }

    @Test("Shows a 1 degree change after it stays for the settle time")
    func acceptsSettledStep() {
        var stabilizer = AngleStabilizer()
        stabilizer.update(100, at: 0)
        #expect(stabilizer.update(101, at: 1) == nil)
        #expect(stabilizer.update(101, at: 1 + AngleStabilizer.settleTime / 2) == nil)
        #expect(stabilizer.update(101, at: 1 + AngleStabilizer.settleTime) == 101)
        #expect(stabilizer.value == 101)
    }

    @Test("Shows a change of 2 degrees or more at once", arguments: [102.0, 98.0, 150.0])
    func acceptsLargeStep(raw: Double) {
        var stabilizer = AngleStabilizer()
        stabilizer.update(100, at: 0)
        #expect(stabilizer.update(raw, at: tick) == raw)
    }

    @Test("A steady 1 degree per sample movement is shown with at most one sample delay")
    func followsSlowSweep() {
        var stabilizer = AngleStabilizer()
        stabilizer.update(100, at: 0)
        #expect(stabilizer.update(101, at: tick) == nil)
        #expect(stabilizer.update(102, at: 2 * tick) == 102)
        #expect(stabilizer.update(103, at: 3 * tick) == nil)
        #expect(stabilizer.update(104, at: 4 * tick) == 104)
    }

    @Test("A pending step resets when the reading goes back")
    func pendingResets() {
        var stabilizer = AngleStabilizer()
        stabilizer.update(100, at: 0)
        stabilizer.update(101, at: 0.05)
        stabilizer.update(100, at: 0.10)
        // 101 again, but the earlier 101 must not count toward the settle time.
        #expect(stabilizer.update(101, at: 0.16) == nil)
        #expect(stabilizer.update(101, at: 0.16 + AngleStabilizer.settleTime) == 101)
    }
}

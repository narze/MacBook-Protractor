import Testing
@testable import LidAngleCore

@Suite("AngleLock")
struct AngleLockTests {
    @Test("Starts unlocked and shows the live angle")
    func startsUnlocked() {
        let lock = AngleLock()
        #expect(!lock.isLocked)
        #expect(lock.displayed(live: 100) == 100)
    }

    @Test("Toggle locks the current angle and keeps it when the live angle changes")
    func locksCurrentAngle() {
        var lock = AngleLock()
        lock.toggle(current: 95)
        #expect(lock.isLocked)
        #expect(lock.lockedAngle == 95)
        #expect(lock.displayed(live: 120) == 95)
        #expect(lock.displayed(live: nil) == 95)
    }

    @Test("Second toggle unlocks and shows the live angle again")
    func secondToggleUnlocks() {
        var lock = AngleLock()
        lock.toggle(current: 95)
        lock.toggle(current: 120)
        #expect(!lock.isLocked)
        #expect(lock.lockedAngle == nil)
        #expect(lock.displayed(live: 120) == 120)
    }

    @Test("Toggle without a reading stays unlocked")
    func toggleWithoutReading() {
        var lock = AngleLock()
        lock.toggle(current: nil)
        #expect(!lock.isLocked)
    }
}

@Suite("LidAngle.isRightAngle")
struct RightAngleTests {
    @Test("True when the angle rounds to 90", arguments: [90.0, 89.6, 90.4])
    func rightAngle(degrees: Double) {
        #expect(LidAngle.isRightAngle(degrees))
    }

    @Test("False for other angles", arguments: [0.0, 89.4, 90.6, 91.0, 180.0])
    func notRightAngle(degrees: Double) {
        #expect(!LidAngle.isRightAngle(degrees))
    }
}

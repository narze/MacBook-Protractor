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

@Suite("AngleLock press and release")
struct AngleLockHoldTests {
    @Test("Tap locks and stays locked after release")
    func tapLocks() {
        var lock = AngleLock()
        #expect(lock.press(current: 100, at: 0) == .locked)
        #expect(lock.release(at: 0.1) == nil)
        #expect(lock.isLocked)
        #expect(lock.lockedAngle == 100)
    }

    @Test("Second tap unlocks on press")
    func secondTapUnlocks() {
        var lock = AngleLock()
        lock.press(current: 100, at: 0)
        lock.release(at: 0.1)
        #expect(lock.press(current: 120, at: 1) == .unlocked)
        #expect(!lock.isLocked)
        #expect(lock.release(at: 1.1) == nil)
        #expect(!lock.isLocked)
    }

    @Test("Long hold locks while held and unlocks on release")
    func holdUnlocksOnRelease() {
        var lock = AngleLock()
        #expect(lock.press(current: 100, at: 0) == .locked)
        #expect(lock.isLocked)
        #expect(lock.release(at: AngleLock.holdThreshold) == .unlocked)
        #expect(!lock.isLocked)
    }

    @Test("Press without a reading does nothing")
    func pressWithoutReading() {
        var lock = AngleLock()
        #expect(lock.press(current: nil, at: 0) == nil)
        #expect(lock.release(at: 1) == nil)
        #expect(!lock.isLocked)
    }

    @Test("Release without a press does nothing")
    func releaseWithoutPress() {
        var lock = AngleLock()
        #expect(lock.release(at: 1) == nil)
        #expect(!lock.isLocked)
    }

    @Test("Toggle reports the change")
    func toggleReportsChange() {
        var lock = AngleLock()
        #expect(lock.toggle(current: 90) == .locked)
        #expect(lock.toggle(current: 90) == .unlocked)
        #expect(lock.toggle(current: nil) == nil)
    }

    @Test("Toggle during a hold cancels the hold")
    func toggleCancelsHold() {
        var lock = AngleLock()
        lock.press(current: 100, at: 0)
        lock.toggle(current: 100)   // unlock from the menu
        lock.toggle(current: 110)   // lock again from the menu
        #expect(lock.release(at: 5) == nil)
        #expect(lock.lockedAngle == 110)
    }
}

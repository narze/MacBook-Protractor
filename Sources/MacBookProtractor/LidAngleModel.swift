import Foundation
import LidAngleCore
import Observation

@MainActor
@Observable
final class LidAngleModel {
    /// Latest sensor reading.
    private(set) var liveAngle: Double?
    private(set) var errorMessage: String?
    private(set) var lock = AngleLock()

    /// The angle to show: frozen while locked.
    var angle: Double? { lock.displayed(live: liveAngle) }
    var isLocked: Bool { lock.isLocked }

    private let poller: SensorPoller?

    /// 120 Hz: one reading per frame on a ProMotion display.
    init(pollInterval: TimeInterval = 1.0 / 120.0) {
        do {
            poller = SensorPoller(sensor: try LidAngleSensor())
        } catch {
            poller = nil
            errorMessage = String(describing: error)
            return
        }
        poller?.start(interval: pollInterval) { [weak self] value in
            self?.update(value)
        }
    }

    func toggleLock() {
        play(lock.toggle(current: liveAngle))
    }

    /// Space key down.
    func pressLock() {
        play(lock.press(current: liveAngle, at: ProcessInfo.processInfo.systemUptime))
    }

    /// Space key up.
    func releaseLock() {
        play(lock.release(at: ProcessInfo.processInfo.systemUptime))
    }

    private func play(_ change: AngleLock.Change?) {
        switch change {
        case .locked: LockSound.locked.play()
        case .unlocked: LockSound.unlocked.play()
        case nil: break
        }
    }

    /// Called by the poller when the reading changes.
    private func update(_ value: Double?) {
        if let value {
            liveAngle = value
            errorMessage = nil
        } else if liveAngle == nil {
            errorMessage = "Cannot read the lid angle sensor."
        }
    }
}

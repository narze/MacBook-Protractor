import AppKit
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

    /// How to rotate the UI when the Mac stands on a side edge.
    private(set) var rotation: ScreenRotation = .upright

    private let poller: SensorPoller?
    private let accelerometer: AccelerometerSensor?
    // Updated about 100 times per second: not observed, only `rotation` is.
    @ObservationIgnored private var orientation = OrientationDetector()

    /// 30 Hz: often enough for a moving lid, and the digit animation
    /// smooths the steps between readings.
    init(pollInterval: TimeInterval = 1.0 / 30.0) {
        accelerometer = try? AccelerometerSensor()
        do {
            poller = SensorPoller(sensor: try LidAngleSensor())
        } catch {
            poller = nil
            errorMessage = String(describing: error)
        }
        poller?.start(interval: pollInterval) { [weak self] value in
            self?.update(value)
        }
        startAccelerometer()
    }

    private func startAccelerometer() {
        accelerometer?.start { [weak self] gravity in
            self?.updateOrientation(gravityX: gravity.x)
        }
        // Turn the accelerometer off again when the app quits.
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.accelerometer?.stop() }
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

    private func updateOrientation(gravityX: Double) {
        if let change = orientation.update(gravityX: gravityX) {
            rotation = change
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

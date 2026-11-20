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

    private let sensor: LidAngleSensor?
    private var timer: Timer?

    init(pollInterval: TimeInterval = 1.0 / 30.0) {
        do {
            sensor = try LidAngleSensor()
        } catch {
            sensor = nil
            errorMessage = String(describing: error)
            return
        }
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
    }

    func toggleLock() {
        lock.toggle(current: liveAngle)
    }

    private func refresh() {
        guard let sensor else { return }
        if let value = sensor.readAngle() {
            if value != liveAngle { liveAngle = value }
            errorMessage = nil
        } else if liveAngle == nil {
            errorMessage = "Cannot read the lid angle sensor."
        }
    }
}

import Foundation
import LidAngleCore
import Observation

@MainActor
@Observable
final class LidAngleModel {
    private(set) var angle: Double?
    private(set) var errorMessage: String?

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

    private func refresh() {
        guard let sensor else { return }
        if let value = sensor.readAngle() {
            if value != angle { angle = value }
            errorMessage = nil
        } else if angle == nil {
            errorMessage = "Cannot read the lid angle sensor."
        }
    }
}

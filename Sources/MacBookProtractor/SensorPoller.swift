import Foundation
import LidAngleCore

/// Reads the sensor on a background queue at a high rate and reports only
/// changed values on the main thread. A sensor read blocks for about 0.5 ms,
/// so it must not run on the main thread at this rate.
final class SensorPoller: @unchecked Sendable {
    // `sensor`, `timer` and `last` are only used on `queue` (after `start`).
    private let sensor: LidAngleSensor
    private let queue = DispatchQueue(label: "MacBookProtractor.sensor", qos: .userInteractive)
    private var timer: DispatchSourceTimer?
    private var last: Double??

    init(sensor: LidAngleSensor) {
        self.sensor = sensor
    }

    deinit {
        timer?.cancel()
    }

    func start(interval: TimeInterval, onChange: @escaping @MainActor @Sendable (Double?) -> Void) {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: interval, leeway: .milliseconds(1))
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            let value = self.sensor.readAngle()
            guard value != self.last else { return }
            self.last = value
            DispatchQueue.main.async {
                MainActor.assumeIsolated { onChange(value) }
            }
        }
        self.timer = timer
        timer.resume()
    }
}

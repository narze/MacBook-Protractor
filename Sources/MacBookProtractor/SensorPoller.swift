import Foundation
import LidAngleCore

/// Reads the sensor on a background queue and reports only changed, stable
/// values on the main thread. A sensor read blocks for about 0.5 ms, and on
/// a background queue the reads continue during menu tracking and resizing.
final class SensorPoller: @unchecked Sendable {
    // `sensor`, `timer`, `stabilizer` and `last` are only used on `queue` (after `start`).
    private let sensor: LidAngleSensor
    private let queue = DispatchQueue(label: "MacBookProtractor.sensor", qos: .userInteractive)
    private var timer: DispatchSourceTimer?
    private var stabilizer = AngleStabilizer()
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
            // The stabilizer sees every sample, so a 1 degree step can settle.
            let value = self.sensor.readAngle().map {
                self.stabilizer.update($0, at: ProcessInfo.processInfo.systemUptime)
                return self.stabilizer.value ?? $0
            }
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

import Foundation
import IOKit
import IOKit.hid

/// Streams gravity from the built-in accelerometer (vendor usage page 0xFF00,
/// usage 3 on the SPU HID device). It needs no root.
///
/// The SPU driver does not send reports until a client turns it on, so
/// `start` turns it on and `stop` turns it off again. Reports arrive on the
/// main run loop at about 100 Hz.
public final class AccelerometerSensor {
    public typealias Handler = @MainActor (_ gravity: (x: Double, y: Double, z: Double)) -> Void

    static let usagePage = 0xFF00
    static let usage = 3
    static let reportIntervalMicroseconds = 10_000
    static let bufferSize = 64

    private let manager: IOHIDManager
    private let device: IOHIDDevice
    private let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: AccelerometerSensor.bufferSize)
    private var handler: Handler?
    private var running = false

    public init() throws {
        manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        let matching: [String: Int] = [
            kIOHIDVendorIDKey: 0x05AC,
            kIOHIDProductIDKey: 0x8104,
            kIOHIDPrimaryUsagePageKey: Self.usagePage,
            kIOHIDPrimaryUsageKey: Self.usage,
        ]
        IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)
        let openResult = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        guard openResult == kIOReturnSuccess else {
            throw LidAngleSensor.SensorError.managerOpenFailed(openResult)
        }
        guard let device = (IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice>)?.first else {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
            throw LidAngleSensor.SensorError.deviceNotFound
        }
        let deviceOpen = IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone))
        guard deviceOpen == kIOReturnSuccess else {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
            throw LidAngleSensor.SensorError.deviceOpenFailed(deviceOpen)
        }
        self.device = device
    }

    deinit {
        stop()
        IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        buffer.deallocate()
    }

    /// Turns the sensor on and calls `handler` on the main thread for each report.
    public func start(handler: @escaping Handler) {
        guard !running else { return }
        running = true
        self.handler = handler
        Self.setDriverPower(on: true)
        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDDeviceRegisterInputReportCallback(device, buffer, Self.bufferSize, { context, _, _, _, _, report, length in
            guard let context else { return }
            let sensor = Unmanaged<AccelerometerSensor>.fromOpaque(context).takeUnretainedValue()
            let bytes = Array(UnsafeBufferPointer(start: report, count: length))
            guard let gravity = AccelerometerReport.gravity(from: bytes), let handler = sensor.handler else { return }
            // Scheduled on the main run loop below.
            MainActor.assumeIsolated { handler(gravity) }
        }, context)
        IOHIDDeviceScheduleWithRunLoop(device, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
    }

    /// Stops the reports and turns the sensor off.
    public func stop() {
        guard running else { return }
        running = false
        IOHIDDeviceUnscheduleFromRunLoop(device, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
        IOHIDDeviceRegisterInputReportCallback(device, buffer, Self.bufferSize, nil, nil)
        handler = nil
        Self.setDriverPower(on: false)
    }

    /// Sets the power properties on the AppleSPUHIDDriver below the
    /// accelerometer device (device -> IOHIDInterface -> AppleSPUHIDDriver).
    static func setDriverPower(on: Bool) {
        let state = on ? 1 : 0
        let properties: [(String, Int)] = [
            ("SensorPropertyReportingState", state),
            ("SensorPropertyPowerState", state),
            ("ReportInterval", on ? reportIntervalMicroseconds : 0),
        ]
        var devices: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("AppleSPUHIDDevice"), &devices) == KERN_SUCCESS else { return }
        defer { IOObjectRelease(devices) }
        while case let device = IOIteratorNext(devices), device != 0 {
            defer { IOObjectRelease(device) }
            guard intProperty(device, "PrimaryUsagePage") == usagePage, intProperty(device, "PrimaryUsage") == usage else { continue }
            var children: io_iterator_t = 0
            guard IORegistryEntryCreateIterator(device, kIOServicePlane, IOOptionBits(kIORegistryIterateRecursively), &children) == KERN_SUCCESS else { continue }
            defer { IOObjectRelease(children) }
            while case let child = IOIteratorNext(children), child != 0 {
                defer { IOObjectRelease(child) }
                guard IOObjectConformsTo(child, "AppleSPUHIDDriver") != 0 else { continue }
                for (key, value) in properties {
                    IORegistryEntrySetCFProperty(child, key as CFString, value as CFNumber)
                }
            }
        }
    }

    private static func intProperty(_ entry: io_registry_entry_t, _ key: String) -> Int? {
        IORegistryEntryCreateCFProperty(entry, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Int
    }
}

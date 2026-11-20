# Lid Angle

A small SwiftUI app that shows the MacBook lid angle from the built-in hinge sensor.

The sensor is a HID device: Apple vendor `0x05AC`, product `0x8104`,
usage page `0x20` (Sensor), usage `0x8A` (Orientation). The app reads
feature report 1. Bytes 1-2 are the angle in degrees (little-endian `UInt16`).

Newer MacBooks (2019 MacBook Pro 16" and later, Apple silicon) have this sensor.
Some models (for example M1 MacBook Air / Pro) do not expose it.

## Run

```sh
swift run LidAngleApp          # window + menu bar item
swift run LidAngleApp --once   # print the angle and exit
swift test                     # unit tests for the report parser
```

## Layout

- `Sources/LidAngleCore` - `LidAngleReport` (report parser) and `LidAngleSensor` (IOKit HID reader)
- `Sources/LidAngleApp` - SwiftUI window, menu bar item, 30 Hz polling
- `Tests/LidAngleCoreTests` - Swift Testing tests for the parser

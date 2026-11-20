# MacBook Protractor

A small SwiftUI app that shows the MacBook lid angle from the built-in hinge sensor,
as a large number on a black screen.

The sensor is a HID device: Apple vendor `0x05AC`, product `0x8104`,
usage page `0x20` (Sensor), usage `0x8A` (Orientation). The app reads
feature report 1. Bytes 1-2 are the angle in degrees (little-endian `UInt16`).

Newer MacBooks (2019 MacBook Pro 16" and later, Apple silicon) have this sensor.
Some models (for example M1 MacBook Air / Pro) do not expose it.

## Run

```sh
swift run MacBookProtractor               # window + menu bar item
swift run MacBookProtractor --fullscreen  # start in full screen
swift run MacBookProtractor --once        # print the angle and exit
swift test                                # unit tests
```

## Controls

| Action | Result |
| --- | --- |
| Space | Lock the shown angle. Press again to unlock. |
| Double-click, Ctrl-Cmd-F | Toggle full screen |
| Menu bar item | Lock / unlock, full screen, quit |

At 90 degrees the angle marker under the degree symbol changes from an arc to a right-angle square.

## Layout

- `Sources/LidAngleCore` - `LidAngleReport` (report parser), `LidAngleSensor` (IOKit HID reader), `AngleLock` and `LidAngle.isRightAngle`
- `Sources/MacBookProtractor` - SwiftUI window, menu bar item, 30 Hz polling
- `Tests/LidAngleCoreTests` - Swift Testing tests for the core logic

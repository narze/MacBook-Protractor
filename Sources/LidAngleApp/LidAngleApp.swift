import AppKit
import LidAngleCore
import SwiftUI

@main
struct LidAngleApp: App {
    @State private var model = LidAngleModel()

    init() {
        // `--once`: print the angle and exit (useful in a terminal).
        if CommandLine.arguments.contains("--once") {
            do {
                let sensor = try LidAngleSensor()
                guard let angle = sensor.readAngle() else {
                    FileHandle.standardError.write(Data("Cannot read the lid angle sensor.\n".utf8))
                    exit(1)
                }
                print(Int(angle.rounded()))
                exit(0)
            } catch {
                FileHandle.standardError.write(Data("\(error)\n".utf8))
                exit(1)
            }
        }
        // Show a Dock icon and a focused window also when run with `swift run`.
        NSApplication.shared.setActivationPolicy(.regular)
        DispatchQueue.main.async { NSApplication.shared.activate() }
    }

    var body: some Scene {
        Window("Lid Angle", id: "main") {
            ContentView(model: model)
        }
        .windowResizability(.contentSize)

        MenuBarExtra {
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        } label: {
            Text(model.angle.map { "\(Int($0.rounded()))°" } ?? "--°")
                .monospacedDigit()
        }
    }
}

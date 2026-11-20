import SwiftUI

struct ContentView: View {
    let model: LidAngleModel

    var body: some View {
        VStack(spacing: 20) {
            LaptopSideView(angle: model.angle ?? 0)
                .frame(width: 260, height: 170)
                .opacity(model.angle == nil ? 0.3 : 1)

            if let angle = model.angle {
                Text("\(Int(angle.rounded()))°")
                    .font(.system(size: 64, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: angle))
                    .animation(.snappy, value: angle)
                Text(label(for: angle))
                    .font(.headline)
                    .foregroundStyle(.secondary)
            } else {
                Text("--°")
                    .font(.system(size: 64, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(model.errorMessage ?? "Reading sensor...")
                    .font(.callout)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(32)
        .frame(minWidth: 340, minHeight: 360)
    }

    private func label(for angle: Double) -> String {
        switch angle {
        case ..<5: "Closed"
        case ..<45: "Almost closed"
        case ..<90: "Half open"
        case ..<135: "Open"
        default: "Wide open"
        }
    }
}

/// Side view of a laptop: a fixed base and a lid that rotates around the hinge.
struct LaptopSideView: View {
    let angle: Double

    var body: some View {
        Canvas { context, size in
            let thickness: CGFloat = 8
            let baseLength = size.width * 0.55
            let lidLength = baseLength * 0.95
            let hinge = CGPoint(x: size.width * 0.38, y: size.height - thickness)
            let bar = StrokeStyle(lineWidth: thickness, lineCap: .round)

            // Base: extends right from the hinge.
            var base = Path()
            base.move(to: hinge)
            base.addLine(to: CGPoint(x: hinge.x + baseLength, y: hinge.y))
            context.stroke(base, with: .color(.secondary), style: bar)

            // Arc that shows the angle.
            var arc = Path()
            arc.addArc(center: hinge, radius: 36, startAngle: .degrees(0),
                       endAngle: .degrees(-angle), clockwise: true)
            context.stroke(arc, with: .color(.accentColor.opacity(0.6)),
                           style: StrokeStyle(lineWidth: 3, lineCap: .round))

            // Lid: lies on the base at 0 deg and opens counter-clockwise around the hinge.
            let radians = angle * .pi / 180
            var lid = Path()
            lid.move(to: hinge)
            lid.addLine(to: CGPoint(x: hinge.x + lidLength * cos(radians),
                                    y: hinge.y - lidLength * sin(radians)))
            context.stroke(lid, with: .color(.accentColor), style: bar)
        }
        .animation(.snappy, value: angle)
        .accessibilityLabel("Laptop lid at \(Int(angle.rounded())) degrees")
    }
}

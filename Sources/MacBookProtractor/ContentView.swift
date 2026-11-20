import SwiftUI

struct ContentView: View {
    let model: LidAngleModel

    var body: some View {
        GeometryReader { geometry in
            let padding = geometry.size.height * 0.06
            let drawingHeight = geometry.size.height * 0.2
            let numberHeight = max(10, geometry.size.height - drawingHeight - padding * 2)

            VStack(spacing: 0) {
                LaptopSideView(angle: model.angle ?? 0)
                    .frame(width: drawingHeight * 1.5, height: drawingHeight)
                    .opacity(model.angle == nil ? 0.3 : 1)

                angleText(fontSize: numberHeight)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if model.angle == nil {
                    Text(model.errorMessage ?? "Reading sensor...")
                        .font(.title3)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(padding)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(minWidth: 320, idealWidth: 480, minHeight: 240, idealHeight: 360)
        .background(.black)
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { FullScreen.toggle() }
    }

    private func angleText(fontSize: CGFloat) -> some View {
        Text(model.angle.map { "\(Int($0.rounded()))°" } ?? "--°")
            // As tall as the free space, then shrink if it is too wide.
            .font(.system(size: fontSize, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .minimumScaleFactor(0.01)
            .lineLimit(1)
            .foregroundStyle(model.angle == nil ? .gray : .white)
            .contentTransition(.numericText(value: model.angle ?? 0))
            .animation(.snappy, value: model.angle)
    }
}

/// Side view of a laptop: a fixed base and a lid that rotates around the hinge.
struct LaptopSideView: View {
    let angle: Double

    var body: some View {
        Canvas { context, size in
            let thickness = max(4, size.height * 0.05)
            let baseLength = size.width * 0.55
            let lidLength = baseLength * 0.95
            let hinge = CGPoint(x: size.width * 0.38, y: size.height - thickness)
            let bar = StrokeStyle(lineWidth: thickness, lineCap: .round)

            // Base: extends right from the hinge.
            var base = Path()
            base.move(to: hinge)
            base.addLine(to: CGPoint(x: hinge.x + baseLength, y: hinge.y))
            context.stroke(base, with: .color(.gray), style: bar)

            // Arc that shows the angle.
            var arc = Path()
            arc.addArc(center: hinge, radius: lidLength * 0.25, startAngle: .degrees(0),
                       endAngle: .degrees(-angle), clockwise: true)
            context.stroke(arc, with: .color(.accentColor.opacity(0.6)),
                           style: StrokeStyle(lineWidth: thickness * 0.4, lineCap: .round))

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

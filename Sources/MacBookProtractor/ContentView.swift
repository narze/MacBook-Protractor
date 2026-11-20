import LidAngleCore
import SwiftUI

struct ContentView: View {
    let model: LidAngleModel
    @FocusState private var focused: Bool

    var body: some View {
        GeometryReader { geometry in
            // Standing on a side edge: lay out in the swapped size, then turn upright.
            let turned = model.rotation != .upright
            let size = turned
                ? CGSize(width: geometry.size.height, height: geometry.size.width)
                : geometry.size
            AngleReadout(angle: model.angle)
                .frame(width: size.width, height: size.height)
                .overlay(alignment: .bottom) {
                    statusLine
                        .font(.system(size: max(13, size.height * 0.035), weight: .semibold, design: .rounded))
                        .padding(.bottom, size.height * 0.04)
                }
                .rotationEffect(.degrees(model.rotation.degrees))
                .frame(width: geometry.size.width, height: geometry.size.height)
                .animation(.easeInOut(duration: 0.35), value: model.rotation)
        }
        .frame(minWidth: 320, idealWidth: 480, minHeight: 240, idealHeight: 360)
        .background(.black)
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { FullScreen.toggle() }
        .focusable()
        .focusEffectDisabled()
        .focused($focused)
        .onAppear { focused = true }
        // Tap: lock / unlock. Long hold: locked only while held.
        .onKeyPress(.space, phases: [.down, .repeat, .up]) { press in
            switch press.phase {
            case .down: model.pressLock()
            case .up: model.releaseLock()
            default: break   // ignore key repeat
            }
            return .handled
        }
    }

    @ViewBuilder
    private var statusLine: some View {
        if model.isLocked {
            Label("Locked", systemImage: "lock.fill")
                .foregroundStyle(.yellow)
        } else if model.angle == nil {
            Text(model.errorMessage ?? "Reading sensor...")
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

/// The large number with the laptop drawing in the free space under the degree symbol.
struct AngleReadout: View {
    let angle: Double?

    var body: some View {
        GeometryReader { geometry in
            let digits = angle.map { String(Int($0.rounded())) } ?? "--"
            let text = digits + AngleFont.degree
            // Size the font from the widest value, so it does not jump between 99 and 100.
            let font = AngleFont.fitting(
                "888" + AngleFont.degree,
                in: CGSize(width: geometry.size.width * 0.9, height: geometry.size.height * 0.72)
            )
            let degree = font.degreeBounds
            let gap = font.nsFont.capHeight * 0.08
            let drawingSize = CGSize(width: degree.width * 1.2, height: max(0, degree.minY - gap))
            let degreeShift = font.degreeAdvance - degree.midX

            ZStack(alignment: Alignment(horizontal: .trailing, vertical: .lastTextBaseline)) {
                Text(text)
                    .font(font.font)
                    .foregroundStyle(angle == nil ? .gray : .white)
                    .fixedSize()

                LaptopSideView(angle: angle ?? 0)
                    .frame(width: drawingSize.width, height: drawingSize.height)
                    .opacity(angle == nil ? 0.3 : 1)
                    // Bottom on the baseline, centered under the degree glyph ink.
                    .alignmentGuide(.lastTextBaseline) { $0[.bottom] }
                    .alignmentGuide(.trailing) {
                        $0[HorizontalAlignment.center] + degreeShift
                    }
            }
            .offset(y: font.capCenteringOffset)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

/// Side view of a laptop: a fixed base and a lid that rotates around the hinge.
struct LaptopSideView: View {
    let angle: Double

    var body: some View {
        Canvas { context, size in
            let thickness = max(3, size.width * 0.06)
            // Hinge in the middle: the lid stays inside the frame from 0 to 180 degrees.
            let baseLength = max(0, min(size.width / 2 - thickness / 2, size.height - thickness))
            let lidLength = baseLength
            let hinge = CGPoint(x: size.width / 2, y: size.height - thickness / 2)
            let bar = StrokeStyle(lineWidth: thickness, lineCap: .round)
            let marker = StrokeStyle(lineWidth: thickness * 0.4, lineCap: .round, lineJoin: .round)
            let markerColor = GraphicsContext.Shading.color(.accentColor.opacity(0.6))
            let markerSize = lidLength * 0.32

            // Base: extends right from the hinge.
            var base = Path()
            base.move(to: hinge)
            base.addLine(to: CGPoint(x: hinge.x + baseLength, y: hinge.y))
            context.stroke(base, with: .color(.gray), style: bar)

            // Angle marker: a square at 90 degrees, else an arc.
            var mark = Path()
            if LidAngle.isRightAngle(angle) {
                let side = markerSize * 0.8
                mark.move(to: CGPoint(x: hinge.x + side, y: hinge.y))
                mark.addLine(to: CGPoint(x: hinge.x + side, y: hinge.y - side))
                mark.addLine(to: CGPoint(x: hinge.x, y: hinge.y - side))
            } else {
                mark.addArc(center: hinge, radius: markerSize, startAngle: .degrees(0),
                            endAngle: .degrees(-angle), clockwise: true)
            }
            context.stroke(mark, with: markerColor, style: marker)

            // Lid: lies on the base at 0 deg and opens counter-clockwise around the hinge.
            let radians = angle * .pi / 180
            var lid = Path()
            lid.move(to: hinge)
            lid.addLine(to: CGPoint(x: hinge.x + lidLength * cos(radians),
                                    y: hinge.y - lidLength * sin(radians)))
            context.stroke(lid, with: .color(.accentColor), style: bar)
        }
        .accessibilityLabel("Laptop lid at \(Int(angle.rounded())) degrees")
    }
}

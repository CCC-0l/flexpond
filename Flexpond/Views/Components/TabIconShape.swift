import SwiftUI

/// Line-icon shapes transcribed from the mockup's inline SVG paths
/// (`dc.html` lines 654-671), in a 24x24 coordinate space. Curved segments
/// use quadratic approximations rather than SVG arc flags so the bulge
/// direction is unambiguous without needing a simulator to eyeball it.
enum TabIconKind {
    case workout, diet, home, readiness, physique

    var segments: [Path] {
        switch self {
        case .workout:
            return [
                Self.line(CGPoint(x: 4, y: 9), CGPoint(x: 4, y: 15)),
                Self.line(CGPoint(x: 7, y: 7), CGPoint(x: 7, y: 17)),
                Self.line(CGPoint(x: 17, y: 7), CGPoint(x: 17, y: 17)),
                Self.line(CGPoint(x: 20, y: 9), CGPoint(x: 20, y: 15)),
                Self.line(CGPoint(x: 7, y: 12), CGPoint(x: 17, y: 12)),
            ]
        case .diet:
            var bowl = Path()
            bowl.move(to: CGPoint(x: 4.5, y: 11))
            bowl.addQuadCurve(to: CGPoint(x: 19.5, y: 11), control: CGPoint(x: 12, y: 22))
            return [
                Self.line(CGPoint(x: 3.5, y: 11), CGPoint(x: 20.5, y: 11)),
                bowl,
                Self.line(CGPoint(x: 10, y: 3.5), CGPoint(x: 10, y: 7.5)),
                Self.line(CGPoint(x: 13, y: 3), CGPoint(x: 13, y: 7.5)),
            ]
        case .home:
            var roof = Path()
            roof.move(to: CGPoint(x: 3, y: 10.5))
            roof.addLine(to: CGPoint(x: 12, y: 3))
            roof.addLine(to: CGPoint(x: 21, y: 10.5))
            var walls = Path()
            walls.move(to: CGPoint(x: 5, y: 9.5))
            walls.addLine(to: CGPoint(x: 5, y: 21))
            walls.addLine(to: CGPoint(x: 19, y: 21))
            walls.addLine(to: CGPoint(x: 19, y: 9.5))
            return [roof, walls]
        case .readiness:
            var pulse = Path()
            pulse.move(to: CGPoint(x: 3, y: 12))
            pulse.addLine(to: CGPoint(x: 7, y: 12))
            pulse.addLine(to: CGPoint(x: 9.5, y: 6))
            pulse.addLine(to: CGPoint(x: 13.5, y: 18))
            pulse.addLine(to: CGPoint(x: 16, y: 12))
            pulse.addLine(to: CGPoint(x: 21, y: 12))
            return [pulse]
        case .physique:
            var head = Path()
            head.addEllipse(in: CGRect(x: 12 - 3.2, y: 7 - 3.2, width: 6.4, height: 6.4))
            var shoulders = Path()
            shoulders.move(to: CGPoint(x: 5.5, y: 21))
            shoulders.addQuadCurve(to: CGPoint(x: 18.5, y: 21), control: CGPoint(x: 12, y: 10))
            return [head, shoulders]
        }
    }

    private static func line(_ from: CGPoint, _ to: CGPoint) -> Path {
        var p = Path()
        p.move(to: from)
        p.addLine(to: to)
        return p
    }
}

/// Renders a `TabIconKind`'s 24x24-space segments scaled to fill the view.
struct TabIconShape: View {
    var kind: TabIconKind
    var color: Color
    var lineWidth: CGFloat = 1.7

    var body: some View {
        GeometryReader { geo in
            let scale = geo.size.width / 24
            ZStack {
                ForEach(Array(kind.segments.enumerated()), id: \.offset) { _, path in
                    path
                        .applying(CGAffineTransform(scaleX: scale, y: scale))
                        .strokedPath(StrokeStyle(lineWidth: lineWidth * scale, lineCap: .round, lineJoin: .round))
                        .fill(color)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

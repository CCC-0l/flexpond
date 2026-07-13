import SwiftUI

/// Mini line chart for a readiness contributor's recent trend. Values are
/// normalized against their own min/max — the series is on an arbitrary
/// per-metric scale (see `ReadinessContributor.series`), not a shared axis.
struct Sparkline: View {
    var series: [Double]
    var color: Color = Theme.good
    var lineWidth: CGFloat = 2

    var body: some View {
        Canvas { context, size in
            guard series.count > 1 else { return }
            let minValue = series.min() ?? 0
            let maxValue = series.max() ?? 1
            let range = max(maxValue - minValue, 0.0001)

            var dashedPath = Path()
            let midY = size.height / 2
            dashedPath.move(to: CGPoint(x: 0, y: midY))
            dashedPath.addLine(to: CGPoint(x: size.width, y: midY))
            context.stroke(dashedPath, with: .color(.white.opacity(0.12)), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))

            var linePath = Path()
            for (index, value) in series.enumerated() {
                let x = size.width * CGFloat(index) / CGFloat(series.count - 1)
                let normalized = (value - minValue) / range
                let y = size.height * (1 - CGFloat(normalized))
                if index == 0 {
                    linePath.move(to: CGPoint(x: x, y: y))
                } else {
                    linePath.addLine(to: CGPoint(x: x, y: y))
                }
            }
            context.stroke(linePath, with: .color(color), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
        }
    }
}

/// Seven-bar mini chart for a readiness focus area's weekly trend, 0...1 values.
struct TrendBars: View {
    var values: [Double]
    var color: Color = Theme.warning

    var body: some View {
        HStack(spacing: 5) {
            ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.05))
                        .overlay(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(color.opacity(0.85))
                                .frame(height: geo.size.height * max(0.08, min(1, value)))
                        }
                }
            }
        }
        .frame(height: 44)
    }
}

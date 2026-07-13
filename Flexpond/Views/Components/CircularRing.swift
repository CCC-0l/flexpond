import SwiftUI

/// Progress ring used for the readiness score, small on Home and large on the Readiness tab.
struct CircularRing: View {
    var progress: Double // 0...1
    var lineWidth: CGFloat
    var trackColor: Color = Color.white.opacity(0.08)
    var tintColor: Color = Theme.accent

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(tintColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

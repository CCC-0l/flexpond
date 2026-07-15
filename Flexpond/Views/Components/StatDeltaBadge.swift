import SwiftUI

/// A small "+2 lb" / "−0.3" pill showing a change in a stat. Used both in
/// Physique's Timeline (vs. the previous entry) and Compare (A vs. B).
/// Deliberately neutral in color — gaining or losing weight isn't
/// inherently good or bad, it depends on the user's goal.
struct StatDeltaBadge: View {
    var value: Double
    var suffix: String
    var decimals: Int = 0

    private var formatted: String {
        let magnitude = abs(value)
        let number = magnitude.formatted(.number.precision(.fractionLength(decimals)))
        let sign = value > 0 ? "+" : (value < 0 ? "\u{2212}" : "\u{00B1}")
        return suffix.isEmpty ? "\(sign)\(number)" : "\(sign)\(number) \(suffix)"
    }

    var body: some View {
        Text(formatted)
            .font(.label(10.5))
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

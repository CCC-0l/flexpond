import SwiftUI

/// Matches the mockup's generic `placeholderA` empty state — Diet has no
/// screens designed yet.
struct DietPlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.card)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.hairline, lineWidth: 1))
                .frame(width: 58, height: 58)
            Text("Diet")
                .font(.system(size: 21, weight: .heavy))
                .foregroundStyle(Theme.textPrimary)
            Text("This section isn't built yet — tap Workout, Readiness, or Physique to explore the flow.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 220)
        }
        .frame(maxWidth: .infinity, minHeight: 520)
        .padding(40)
    }
}

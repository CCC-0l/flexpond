import SwiftUI

/// Small colored rounded-square badge with a short mono code, e.g. "BB", "PL", "WK".
struct IconBadge: View {
    var text: String
    var size: CGFloat = 44
    var cornerRadius: CGFloat = 12
    var background: Color = Theme.accent.opacity(0.14)
    var foreground: Color = Theme.accent

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(background)
            .frame(width: size, height: size)
            .overlay(
                Text(text)
                    .font(.label(size >= 44 ? 15 : 14, weight: .semibold))
                    .foregroundStyle(foreground)
            )
    }
}

/// Small trailing chevron matching the mockup's list-row affordance.
struct RowChevron: View {
    var color: Color = Theme.textFaint

    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(color)
    }
}

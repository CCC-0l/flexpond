import SwiftUI

/// Ported from the mockup's inline hex/rgba palette. Swap these for real
/// asset-catalog colors (with light/dark variants) once you have brand
/// guidelines — the app is dark-only for now, matching the design.
enum Theme {
    static let background = Color(hex: 0x0F0F11)
    static let card = Color(hex: 0x17171A)
    static let cardHover = Color(hex: 0x1E1E22)
    static let hairline = Color.white.opacity(0.06)
    static let accent = Color(hex: 0x4CA6FF)
    static let accentText = Color(hex: 0x08131F)
    static let good = Color(hex: 0x5FD08A)
    static let warning = Color(hex: 0xE8B44D)
    static let danger = Color(hex: 0xFF6B6B)

    static let textPrimary = Color(hex: 0xF5F5F4)
    static let textSecondary = Color.white.opacity(0.55)
    static let textTertiary = Color.white.opacity(0.4)
    static let textFaint = Color.white.opacity(0.25)
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

extension Font {
    /// Stand-in for the mockup's "JetBrains Mono" eyebrow/label styling.
    static func label(_ size: CGFloat = 11, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

/// Reusable card container matching the mockup's `#17171A` rounded rows.
struct CardBackground: ViewModifier {
    var radius: CGFloat = 18
    var stroke: Color = Theme.hairline

    func body(content: Content) -> some View {
        content
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(stroke, lineWidth: 1)
            )
    }
}

extension View {
    func cardBackground(radius: CGFloat = 18, stroke: Color = Theme.hairline) -> some View {
        modifier(CardBackground(radius: radius, stroke: stroke))
    }
}

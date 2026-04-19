/// Theme.swift
/// Purpose: Design tokens for the Gem visual direction — palette, gradients,
///   typography, spacing, radii, and glow helpers. All visual constants live here;
///   consumers must not introduce ad-hoc colors or sizes elsewhere.
/// Dependencies: SwiftUI.
/// Key concepts:
///   - Colors are approximated from OKLCH via HSB because SwiftUI has no native
///     OKLCH support. `gemColor(hue:)` accepts an OKLCH hue angle (0–360).
///   - Named gem hues (amethyst, emerald, etc.) are convenience aliases over `gemColor`.
///   - `glow(_:radius:)` returns a blurred, tinted shape for shadow-glow effects.

import SwiftUI

/// Design tokens for the Gem visual direction. Values mined from
/// `gem-app/shared.jsx` (the prototype's palette object) and
/// `Gem App v2.html` CSS. Do not introduce ad-hoc colors/sizes elsewhere —
/// consumers always read from Theme.
enum Theme {

    // MARK: - Palette (OKLCH → Color)
    // Gem palette: fixed chroma/lightness, varying hue. Rendered via Color(hue:,saturation:,brightness:)
    // as an approximation of OKLCH since SwiftUI has no native OKLCH. Use `gemColor(hue:)`
    // for tag colors; named colors are convenience aliases.

    static let bg        = Color(red: 0.047, green: 0.028, blue: 0.078)   // #0c0820
    static let bg2       = Color(red: 0.102, green: 0.059, blue: 0.208)   // #1a0f35
    static let bg3       = Color(red: 0.020, green: 0.012, blue: 0.059)   // #05030f

    static let card      = Color.white.opacity(0.04)
    static let cardHi    = Color.white.opacity(0.065)
    static let border    = Color.white.opacity(0.08)
    static let borderHi  = Color.white.opacity(0.14)

    static let text      = Color(red: 0.957, green: 0.933, blue: 0.988)   // #f4eefc
    static let dim       = Color(red: 0.957, green: 0.933, blue: 0.988).opacity(0.6)
    static let dimmer    = Color(red: 0.957, green: 0.933, blue: 0.988).opacity(0.32)
    static let dimmest   = Color(red: 0.957, green: 0.933, blue: 0.988).opacity(0.14)

    /// Gem colors by hue, using fixed chroma and lightness.
    /// `hue` is an OKLCH hue angle 0–360.
    static func gemColor(hue: Double) -> Color {
        // Approximate OKLCH(0.62 / 0.22) with HSB-based conversion.
        // Hue mapping: OKLCH hue 300 ≈ purple, 250 ≈ blue, 160 ≈ green, 85 ≈ yellow, 20 ≈ red.
        let normalizedHue = (hue.truncatingRemainder(dividingBy: 360)) / 360.0
        return Color(hue: normalizedHue, saturation: 0.75, brightness: 0.82)
    }

    // Named gem hues — match prototype palette exactly
    static let amethyst = gemColor(hue: 300)
    static let emerald  = gemColor(hue: 160)
    static let citrine  = gemColor(hue: 85)
    static let ruby     = gemColor(hue: 20)
    static let sapphire = gemColor(hue: 250)
    static let peridot  = gemColor(hue: 135)
    static let rose     = gemColor(hue: 350)
    static let aqua     = gemColor(hue: 210)

    // MARK: - Gradients

    static var backgroundGradient: RadialGradient {
        RadialGradient(
            colors: [bg2, bg],
            center: .init(x: 0.5, y: 1.1),
            startRadius: 0,
            endRadius: 600
        )
    }

    // MARK: - Typography
    // Inter Tight via system fallback. App's Info.plist should register
    // InterTight-Regular.ttf through Bold at Phase 4 setup; until then system
    // fonts are fine.

    static func display(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func body(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func eyebrow() -> Font {
        .system(size: 11, weight: .semibold, design: .default)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 28
    }

    // MARK: - Radii

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 14
        static let lg: CGFloat = 18
        static let xl: CGFloat = 22
        static let pill: CGFloat = 999
    }

    // MARK: - Shadows (glow)

    static func glow(_ color: Color, radius: CGFloat = 14) -> some View {
        color.opacity(0.33).blur(radius: radius)
    }
}

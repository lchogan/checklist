import SwiftUI

/// Segmented progress bar — each "segment" is a tiny gem, colored in palette
/// rotation. Lit segments glow; unlit are dim. Staggered animation as percent
/// advances.
struct GemBar: View {
    let progress: Double    // 0.0 ... 1.0
    var segments: Int = 14

    private let palette: [Color] = [
        Theme.amethyst, Theme.sapphire, Theme.emerald, Theme.citrine, Theme.ruby, Theme.peridot,
    ]

    var body: some View {
        HStack(spacing: 2.5) {
            ForEach(0..<segments, id: \.self) { i in
                let lit = Double(i) < progress * Double(segments)
                let color = palette[i % palette.count]
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(
                        lit
                            ? LinearGradient(
                                colors: [color.opacity(0.95), color],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            : LinearGradient(colors: [Color.white.opacity(0.06), Color.white.opacity(0.06)], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 8, height: 16)
                    .shadow(color: lit ? color.opacity(0.53) : .clear, radius: 3, x: 0, y: 0)
                    .animation(
                        .spring(response: 0.32, dampingFraction: 0.6).delay(Double(i) * 0.018),
                        value: progress
                    )
            }
        }
    }
}

#Preview("GemBar progression") {
    VStack(spacing: 16) {
        GemBar(progress: 0.0)
        GemBar(progress: 0.25)
        GemBar(progress: 0.5)
        GemBar(progress: 0.75)
        GemBar(progress: 1.0)
    }
    .padding()
    .background(Theme.bg)
}

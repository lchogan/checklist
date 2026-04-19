import SwiftUI

/// Large celebratory gem rendered at the top of completion sheets. Visual
/// stand-in for the richer gem-minting in the v2 delight layer.
struct HeroGem: View {
    let color: Color
    var progress: Double = 1.0
    var size: CGFloat = 62

    /// Driven by onAppear for the mint-in spring.
    @State private var appeared = false

    var body: some View {
        ZStack {
            // Backdrop glow
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: size * 1.4, height: size * 1.4)
                .blur(radius: size * 0.35)

            // Gem body
            RoundedRectangle(cornerRadius: size * 0.25)
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .rotationEffect(.degrees(45))
                .frame(width: size * 0.72, height: size * 0.72)
                .overlay(
                    // Facet highlight
                    RoundedRectangle(cornerRadius: size * 0.25)
                        .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                        .rotationEffect(.degrees(45))
                        .frame(width: size * 0.72, height: size * 0.72)
                        .opacity(progress)
                )
        }
        .frame(width: size * 1.4, height: size * 1.4)
        .scaleEffect(appeared ? 1 : 0.6)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: appeared)
        .onAppear { appeared = true }
    }
}

#Preview("HeroGem") {
    HStack(spacing: 20) {
        HeroGem(color: Theme.emerald, progress: 1.0)
        HeroGem(color: Theme.citrine, progress: 0.6)
        HeroGem(color: Theme.amethyst, progress: 0.3, size: 80)
    }
    .padding()
    .background(Theme.bg)
}

import SwiftUI

/// The signature gem-faceted checkbox. Unchecked = outlined hexagon; checked =
/// filled gradient with white checkmark and a soft glow. Springy scale on toggle.
struct Facet: View {
    let color: Color
    let checked: Bool
    var size: CGFloat = 26

    var body: some View {
        ZStack {
            // Background shape
            FacetShape()
                .fill(
                    checked
                        ? LinearGradient(
                            colors: [color.opacity(0.95), color.opacity(0.55)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(colors: [.clear, .clear], startPoint: .top, endPoint: .bottom)
                )
                .overlay(
                    FacetShape()
                        .stroke(
                            checked ? color.opacity(0.7) : Theme.dimmer,
                            lineWidth: 1.5
                        )
                )
                .shadow(color: checked ? color.opacity(0.45) : .clear, radius: 6, x: 0, y: 0)

            // Checkmark
            if checked {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundColor(.white)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(checked ? 1.0 : 0.96)
        .animation(.spring(response: 0.32, dampingFraction: 0.55), value: checked)
    }
}

/// A squircle-ish hexagonal facet. Close to the prototype's rounded hex shape.
private struct FacetShape: Shape {
    func path(in rect: CGRect) -> Path {
        let r = min(rect.width, rect.height) * 0.3
        return Path(roundedRect: rect, cornerSize: CGSize(width: r, height: r))
    }
}

#Preview("Facet states") {
    HStack(spacing: 16) {
        Facet(color: Theme.amethyst, checked: false)
        Facet(color: Theme.amethyst, checked: true)
        Facet(color: Theme.citrine, checked: true)
        Facet(color: Theme.emerald, checked: true, size: 36)
    }
    .padding()
    .background(Theme.bg)
}

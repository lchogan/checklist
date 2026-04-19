import SwiftUI

/// Primary CTA button in the Gem style: gradient fill with a subtle glow, or a
/// ghost variant with a hairline border. `tone: .solid | .ghost`.
struct PillButton: View {
    enum Tone { case solid, ghost }

    let title: String
    var color: Color = Theme.amethyst
    var tone: Tone = .solid
    var wide: Bool = false
    var small: Bool = false
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: small ? 13 : 14.5, weight: .semibold, design: .default))
                .foregroundColor(tone == .solid ? .white : Theme.text)
                .padding(.horizontal, small ? 16 : 22)
                .padding(.vertical, small ? 9 : 12)
                .frame(maxWidth: wide ? .infinity : nil)
                .background(backgroundFill)
                .overlay(border)
                .shadow(color: tone == .solid ? color.opacity(0.33) : .clear, radius: 10, x: 0, y: 0)
                .opacity(disabled ? 0.4 : 1)
        }
        .disabled(disabled)
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var backgroundFill: some View {
        switch tone {
        case .solid:
            LinearGradient(
                colors: [color, color.opacity(0.72)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(Capsule())
        case .ghost:
            Color.white.opacity(0.05).clipShape(Capsule())
        }
    }

    @ViewBuilder
    private var border: some View {
        if tone == .ghost {
            Capsule().stroke(Theme.borderHi, lineWidth: 1)
        }
    }
}

#Preview("PillButton variants") {
    VStack(spacing: 12) {
        PillButton(title: "Complete", color: Theme.amethyst) {}
        PillButton(title: "Complete", color: Theme.emerald, wide: true) {}
        PillButton(title: "Complete", color: Theme.citrine, wide: true) {}
        PillButton(title: "Not yet", tone: .ghost, wide: true) {}
        PillButton(title: "Discard", color: Theme.ruby, small: true) {}
        PillButton(title: "Disabled", disabled: true) {}
    }
    .padding()
    .background(Theme.bg)
}

import SwiftUI

/// Consistent top-of-screen bar with optional left/right icon button slots.
struct TopBar<Left: View, Right: View>: View {
    @ViewBuilder let left: () -> Left
    @ViewBuilder let right: () -> Right

    var body: some View {
        HStack {
            left()
            Spacer()
            right()
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.sm)
        .frame(minHeight: 40)
    }
}

/// Circular icon button. `solid: true` fills with a gem-color gradient + glow
/// (used for the home `+` add button). `solid: false` is a hairline circle.
struct IconButton: View {
    let iconName: String
    var size: CGFloat = 36
    var solid: Bool = false
    var color: Color = Theme.amethyst
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if solid {
                    GemIcons.image(iconName)
                        .font(.system(size: size * 0.4, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    GemIcons.image(iconName)
                        .font(.system(size: size * 0.4, weight: .semibold))
                        .foregroundColor(Theme.dim)
                }
            }
            .frame(width: size, height: size)
            .background(
                Group {
                    if solid {
                        Circle().fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    } else {
                        Circle().fill(Color.white.opacity(0.05))
                    }
                }
            )
            .overlay(
                Group {
                    if !solid {
                        Circle().stroke(Theme.border, lineWidth: 1)
                    }
                }
            )
            .shadow(color: solid ? color.opacity(0.4) : .clear, radius: 10)
        }
        .buttonStyle(.plain)
    }
}

#Preview("TopBar") {
    VStack {
        TopBar(
            left: { IconButton(iconName: "back") {} },
            right: { IconButton(iconName: "more") {} }
        )
        TopBar(
            left: { IconButton(iconName: "sun") {} },
            right: { IconButton(iconName: "plus", solid: true) {} }
        )
        Spacer()
    }
    .background(Theme.bg)
}

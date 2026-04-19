import SwiftUI

/// A compact tag badge shown inside item rows. Muted variant used when the
/// parent item is completed.
struct TagChip: View {
    let name: String
    let iconName: String
    let colorHue: Double
    var muted: Bool = false
    var small: Bool = false

    var body: some View {
        HStack(spacing: small ? 3 : 4) {
            GemIcons.image(iconName)
                .font(.system(size: small ? 9 : 10, weight: .bold))
            Text(name.uppercased())
                .font(.system(size: small ? 9 : 10, weight: .bold))
                .tracking(0.6)
        }
        .foregroundColor(muted ? Theme.dim : Theme.gemColor(hue: colorHue))
        .padding(.horizontal, small ? 7 : 8)
        .padding(.vertical, small ? 3 : 3)
        .background(
            Capsule().fill(Theme.gemColor(hue: colorHue).opacity(muted ? 0.08 : 0.15))
        )
        .overlay(
            Capsule().stroke(Theme.gemColor(hue: colorHue).opacity(muted ? 0.12 : 0.35), lineWidth: 1)
        )
    }
}

/// Tag filter chip at the top of ChecklistRunView. Tap to toggle "hide items
/// with this tag" for the current run.
struct TagHideChip: View {
    let name: String
    let iconName: String
    let colorHue: Double
    let hidden: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 5) {
                GemIcons.image(hidden ? "eye-off" : iconName)
                    .font(.system(size: 11, weight: .bold))
                Text(name)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(hidden ? Theme.dim : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Group {
                    if hidden {
                        Capsule().fill(Color.white.opacity(0.04))
                    } else {
                        Capsule().fill(
                            LinearGradient(
                                colors: [
                                    Theme.gemColor(hue: colorHue),
                                    Theme.gemColor(hue: colorHue).opacity(0.7),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    }
                }
            )
            .overlay(
                Capsule().stroke(
                    hidden ? Theme.border : Theme.gemColor(hue: colorHue).opacity(0.5),
                    lineWidth: 1
                )
            )
            .opacity(hidden ? 0.72 : 1)
        }
        .buttonStyle(.plain)
    }
}

#Preview("Tag chips") {
    VStack(spacing: 12) {
        HStack(spacing: 6) {
            TagChip(name: "Beach", iconName: "sun", colorHue: 85)
            TagChip(name: "Snow", iconName: "snow", colorHue: 250)
            TagChip(name: "Hike", iconName: "leaf", colorHue: 160, muted: true)
        }
        HStack(spacing: 6) {
            TagHideChip(name: "Beach", iconName: "sun", colorHue: 85, hidden: false) {}
            TagHideChip(name: "Snow", iconName: "snow", colorHue: 250, hidden: true) {}
            TagHideChip(name: "Hike", iconName: "leaf", colorHue: 160, hidden: false) {}
        }
    }
    .padding()
    .background(Theme.bg)
}

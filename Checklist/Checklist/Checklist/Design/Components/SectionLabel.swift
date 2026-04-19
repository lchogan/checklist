import SwiftUI

/// Uppercase eyebrow caption used throughout the app (e.g. "YOUR CATEGORIES",
/// "PREVIOUS RUNS", "DANGER ZONE"). Optional right-aligned hint.
struct SectionLabel: View {
    let text: String
    var hint: String? = nil

    var body: some View {
        HStack {
            Text(text.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(2)
                .foregroundColor(Theme.dim)
            Spacer()
            if let hint {
                Text(hint.uppercased())
                    .font(.system(size: 11, weight: .regular))
                    .tracking(0.5)
                    .foregroundColor(Theme.dimmer)
            }
        }
    }
}

#Preview("SectionLabel") {
    VStack(alignment: .leading, spacing: 18) {
        SectionLabel(text: "Your categories")
        SectionLabel(text: "Previous runs", hint: "3")
        SectionLabel(text: "Danger zone")
    }
    .padding()
    .background(Theme.bg)
    .foregroundColor(Theme.text)
}

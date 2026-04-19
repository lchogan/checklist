import SwiftUI

/// Home-screen grid card. Shows category eyebrow (+ optional run label), the
/// checklist name, progress fraction, GemBar, and an optional "N RUNS" badge
/// when multiple live runs exist.
struct ChecklistCard: View {
    let categoryName: String?
    let primaryRunLabel: String?
    let name: String
    let progress: (done: Int, total: Int)
    let liveRunCount: Int
    let onTap: () -> Void

    private var pct: Double {
        guard progress.total > 0 else { return 0 }
        return Double(progress.done) / Double(progress.total)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    eyebrow
                    Spacer()
                    fraction
                }

                Text(name)
                    .font(Theme.display(size: 22))
                    .foregroundColor(Theme.text)

                GemBar(progress: pct, segments: 16)
                    .padding(.top, 2)
            }
            .padding(Theme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.xl)
                    .fill(Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.xl)
                    .stroke(Theme.border, lineWidth: 1)
            )
            .overlay(alignment: .topTrailing) {
                if liveRunCount >= 2 {
                    Text("\(liveRunCount) RUNS")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.6)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(
                                LinearGradient(
                                    colors: [Theme.amethyst, Theme.amethyst.opacity(0.72)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        )
                        .padding(Theme.Spacing.md)
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var eyebrow: some View {
        HStack(spacing: 6) {
            if let categoryName {
                Text(categoryName.uppercased())
                    .foregroundColor(Theme.dim)
            }
            if let label = primaryRunLabel {
                Text("·")
                    .foregroundColor(Theme.dimmer)
                Text(label.uppercased())
                    .foregroundColor(Theme.citrine)
            }
        }
        .font(Theme.eyebrow())
        .tracking(2)
    }

    private var fraction: some View {
        Text("\(progress.done)/\(progress.total)")
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(Theme.dim)
    }
}

#Preview("ChecklistCard") {
    VStack(spacing: 10) {
        ChecklistCard(
            categoryName: "Travel",
            primaryRunLabel: "Tokyo",
            name: "Packing List",
            progress: (done: 4, total: 18),
            liveRunCount: 2
        ) {}
        ChecklistCard(
            categoryName: "Daily",
            primaryRunLabel: nil,
            name: "Morning Routine",
            progress: (done: 3, total: 8),
            liveRunCount: 1
        ) {}
        ChecklistCard(
            categoryName: "Home",
            primaryRunLabel: nil,
            name: "Weekly Groceries",
            progress: (done: 0, total: 12),
            liveRunCount: 0
        ) {}
    }
    .padding()
    .background(Theme.bg)
}

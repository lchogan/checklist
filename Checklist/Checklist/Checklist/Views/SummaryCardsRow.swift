/// SummaryCardsRow.swift
/// Purpose: Two decorative summary cards shown at the bottom of HomeView:
///   Tags count + History (completed-run) count. Tapping them is a no-op in
///   Plan 2; navigation to Tags / History screens is deferred to a later plan.
/// Dependencies: SwiftUI, GemIcons, Theme.
/// Key concepts:
///   - Counts are passed in as plain Ints (derived from @Query in HomeView).
///   - onTagsTap / onHistoryTap are no-ops by default; callers can override.

import SwiftUI

/// Two decorative summary cards shown at the bottom of HomeView: Tags count +
/// History (completed-run) count. Tapping them is a no-op in Plan 2;
/// navigation to Tags / History screens is deferred to a later plan.
struct SummaryCardsRow: View {
    /// Total number of tags in the store.
    let tagCount: Int

    /// Total number of completed runs in the store.
    let historyCount: Int

    /// Called when the user taps the Tags card. No-op by default.
    var onTagsTap: () -> Void = {}

    /// Called when the user taps the History card. No-op by default.
    var onHistoryTap: () -> Void = {}

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            summaryCard(icon: "tag", title: "Tags", count: tagCount, onTap: onTagsTap)
            summaryCard(icon: "history", title: "History", count: historyCount, onTap: onHistoryTap)
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    /// Renders a single summary card with an icon, title, and count.
    ///
    /// - Parameters:
    ///   - icon: GemIcons token name for the leading icon.
    ///   - title: Label displayed beside the icon.
    ///   - count: Numeric value displayed prominently below the header.
    ///   - onTap: Action to call when the card is tapped.
    /// - Returns: A styled card button.
    private func summaryCard(icon: String, title: String, count: Int, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    GemIcons.image(icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.dim)
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.text)
                }
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(count)")
                        .font(Theme.display(size: 22))
                        .foregroundColor(Theme.text)
                    Text("TOTAL")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.5)
                        .foregroundColor(Theme.dimmer)
                }
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .fill(Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .stroke(Theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview("Summary cards") {
    SummaryCardsRow(tagCount: 6, historyCount: 11)
        .padding(.vertical)
        .background(Theme.bg)
}

/// PreviousRunsStrip.swift
/// Purpose: Read-only list of the most recent completed runs for a checklist,
///   shown when no live run is active (the "no-current-run" state, capture 12).
/// Dependencies: SwiftUI, CompletedRun, Theme, GemIcons, SectionLabel.
/// Key concepts:
///   - Tapping a row invokes `onTap(run)`; ChecklistRunView wires it to push
///     CompletedRunView on the NavigationPath.
///   - Duration is computed from startedAt → completedAt on each CompletedRun.
///   - Subtitle counts complete items from the frozen snapshot (not the live checklist).

import SwiftUI

/// Read-only strip showing the most recent completed runs for a checklist.
/// Tapping a row invokes `onTap(run)`; the parent view (ChecklistRunView)
/// appends the tapped `CompletedRun` to the root NavigationPath.
struct PreviousRunsStrip: View {
    let completedRuns: [CompletedRun]
    var onTap: (CompletedRun) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionLabel(text: "Previous runs", hint: "\(completedRuns.count)")
                .padding(.horizontal, Theme.Spacing.xl)

            VStack(spacing: Theme.Spacing.xs) {
                ForEach(completedRuns) { run in
                    Button {
                        onTap(run)
                    } label: {
                        HStack {
                            Circle()
                                .fill(Theme.citrine.opacity(0.85))
                                .frame(width: 10, height: 10)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(dateLabel(for: run))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Theme.text)
                                Text(subtitle(for: run))
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.dim)
                            }
                            Spacer()
                            GemIcons.image("right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Theme.dimmer)
                        }
                        .padding(.horizontal, Theme.Spacing.md).padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Theme.card))
                        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, Theme.Spacing.xl)
                }
            }
        }
    }

    /// Formats a `CompletedRun` date as "Day, Month d" (e.g. "Wed, Apr 16").
    ///
    /// - Parameter run: The completed run whose `completedAt` timestamp is formatted.
    /// - Returns: A localized short date string.
    private func dateLabel(for run: CompletedRun) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: run.completedAt)
    }

    /// Builds the subtitle shown below the date: "N/M · Xm" where N is the
    /// number of completed items from the frozen snapshot, M is the total item
    /// count, and X is the run duration in minutes (or hours if ≥60 min).
    ///
    /// - Parameter run: The completed run to summarise.
    /// - Returns: A formatted subtitle string.
    private func subtitle(for run: CompletedRun) -> String {
        let snap = run.snapshot
        let complete = snap.checks.filter { $0.value == .complete }.count
        let total = snap.items.count
        let duration = Int(run.completedAt.timeIntervalSince(run.startedAt) / 60)
        return "\(complete)/\(total) · \(durationString(minutes: duration))"
    }

    /// Converts a minute count into a human-readable duration string.
    ///
    /// - Parameter minutes: Duration in whole minutes.
    /// - Returns: "<1m" for sub-minute, "Xm" for under an hour, "Xh Ym" otherwise.
    private func durationString(minutes: Int) -> String {
        if minutes < 1 { return "<1m" }
        if minutes < 60 { return "\(minutes)m" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }
}

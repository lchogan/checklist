/// RunChooserSheet.swift
/// Purpose: Sheet shown when the user taps the "N live runs ▾" pill on
///   ChecklistRunView. Lists all live runs with a conic progress circle,
///   name, started-time, and checks count. Provides options to switch runs
///   or start a new one.
/// Dependencies: SwiftUI, SwiftData, BottomSheet, PillButton, GemIcons,
///   Theme, Run, Checklist models.
/// Key concepts:
///   - onSelect(run) switches the caller's currentRunID.
///   - onStartNew() opens StartRunSheet from the caller.
///   - Runs are sorted by startedAt (ascending) for a stable, predictable order.

import SwiftUI
import SwiftData

/// Shown when the user taps the "N live runs ▾" pill on ChecklistRunView.
/// Lists all live runs with a conic progress circle + name + started-time +
/// checks count. Tapping a run switches the current run. "+ Start new run"
/// opens StartRunSheet.
struct RunChooserSheet: View {
    @Environment(\.dismiss) private var dismiss
    let checklist: Checklist
    let onSelect: (Run) -> Void
    let onStartNew: () -> Void

    private var sortedRuns: [Run] {
        (checklist.runs ?? []).sorted { $0.startedAt < $1.startedAt }
    }

    var body: some View {
        BottomSheet {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text(checklist.name.uppercased())
                    .font(Theme.eyebrow()).tracking(2).foregroundColor(Theme.dim)
                Text("Which run?")
                    .font(Theme.display(size: 22)).foregroundColor(Theme.text)

                VStack(spacing: Theme.Spacing.xs) {
                    ForEach(sortedRuns) { run in
                        runRow(run)
                    }
                }

                PillButton(title: "+ Start new run", color: Theme.amethyst, wide: true) {
                    onStartNew()
                    dismiss()
                }
                PillButton(title: "Cancel", tone: .ghost, wide: true) { dismiss() }
            }
        }
    }

    /// Renders a single run row with a conic progress circle, name, and
    /// started-at / checks-done metadata.
    ///
    /// - Parameter run: The live Run to display.
    /// - Returns: A tappable row that calls onSelect and dismisses the sheet.
    private func runRow(_ run: Run) -> some View {
        Button {
            onSelect(run)
            dismiss()
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                progressCircle(for: run)
                VStack(alignment: .leading, spacing: 2) {
                    Text(run.name ?? "Unnamed")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.text)
                    Text("Started \(relativeStarted(run)) · \(doneCount(run))/\(totalItems)")
                        .font(.system(size: 12)).foregroundColor(Theme.dim)
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
    }

    /// Renders a 36 pt conic progress circle showing what fraction of items
    /// are complete on the given run. Uses the checklist's total item count
    /// as the denominator (no hidden-tag filtering here — the chooser is a
    /// quick overview, not the full run view).
    ///
    /// - Parameter run: The live Run whose progress to display.
    /// - Returns: A `ZStack` containing the circle and a done-count label.
    private func progressCircle(for run: Run) -> some View {
        let total = totalItems
        let done  = doneCount(run)
        let percent = total == 0 ? 0.0 : Double(done) / Double(total)
        return ZStack {
            Circle().stroke(Theme.border, lineWidth: 3)
            Circle()
                .trim(from: 0, to: percent)
                .stroke(Theme.amethyst, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(done)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Theme.text)
        }
        .frame(width: 36, height: 36)
    }

    /// Total number of items on the checklist (unfiltered).
    private var totalItems: Int { checklist.items?.count ?? 0 }

    /// Count of checks with state `.complete` on the given run.
    ///
    /// - Parameter run: The run to count completed checks for.
    /// - Returns: Number of complete checks.
    private func doneCount(_ run: Run) -> Int {
        (run.checks ?? []).filter { $0.state == .complete }.count
    }

    /// Returns a human-readable relative time string for when the run started
    /// (e.g. "just now", "5m ago", "2h ago", "3d ago").
    ///
    /// - Parameter run: The run whose `startedAt` to format.
    /// - Returns: A locale-independent short relative string.
    private func relativeStarted(_ run: Run) -> String {
        let s = Date().timeIntervalSince(run.startedAt)
        if s < 60 { return "just now" }
        if s < 3600 { return "\(Int(s / 60))m ago" }
        if s < 86_400 { return "\(Int(s / 3600))h ago" }
        return "\(Int(s / 86_400))d ago"
    }
}

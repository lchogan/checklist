/// CompletionSheet.swift
/// Purpose: Sheet presented when the user taps "Complete" on ChecklistRunView's
///   action row, or auto-presented when the last visible item is checked.
///   Switches between three variants internally: all-done (emerald), partial
///   (citrine), and discard-confirm (ruby).
/// Dependencies: SwiftUI, SwiftData, Checklist/Run models, BottomSheet,
///   HeroGem, PillButton, Theme, RunStore, RunProgress.
/// Key concepts:
///   - `Stage` enum drives the currently-visible variant (primary vs. discard confirm).
///   - `isAllDone` derived from RunProgress: all visible items must be checked.
///   - commitComplete() calls RunStore.complete(_:in:) — creates CompletedRun + deletes Run.
///   - commitDiscard() calls RunStore.discard(_:in:) — deletes Run without history.

import SwiftUI

/// Shown when the user taps "Complete" on ChecklistRunView's action row, or
/// auto-presented when the last visible item is checked. Three variants:
/// all-done, partial, discard-confirm. Switches between them internally.
struct CompletionSheet: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    let checklist: Checklist
    let run: Run

    @State private var stage: Stage = .primary
    enum Stage { case primary, discardConfirm }

    private var progress: RunProgress {
        RunProgress.compute(
            items: (checklist.items ?? []).sorted { $0.sortKey < $1.sortKey },
            checks: run.checks ?? [],
            hiddenTagIDs: run.hiddenTagIDs
        )
    }

    private var isAllDone: Bool {
        progress.total > 0 && progress.done == progress.total
    }

    var body: some View {
        BottomSheet {
            switch stage {
            case .primary:         primaryContent
            case .discardConfirm:  discardContent
            }
        }
    }

    // MARK: - Primary (all-done OR partial)

    /// The primary variant: emerald if all visible items are checked (all-done),
    /// citrine if some remain unchecked (partial).
    private var primaryContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.md) {
                HeroGem(color: isAllDone ? Theme.emerald : Theme.citrine, size: 48)
                VStack(alignment: .leading, spacing: 4) {
                    Text(eyebrowText)
                        .font(Theme.eyebrow()).tracking(2)
                        .foregroundColor(isAllDone ? Theme.emerald : Theme.citrine)
                    Text(titleLine)
                        .font(Theme.display(size: 22))
                        .foregroundColor(Theme.text)
                    Text("Started \(relativeStartedString) ago")
                        .font(.system(size: 12)).foregroundColor(Theme.dim)
                }
            }

            Text(bodyCopy)
                .font(.system(size: 13))
                .foregroundColor(Theme.dim)

            PillButton(
                title: isAllDone ? "Complete" : "Complete anyway · \(progress.done)/\(progress.total)",
                color: isAllDone ? Theme.emerald : Theme.citrine,
                wide: true
            ) { commitComplete() }

            PillButton(title: "Not yet — keep going", tone: .ghost, wide: true) { dismiss() }

            Button("Discard run") { stage = .discardConfirm }
                .foregroundColor(Theme.dim)
                .font(.system(size: 13))
                .frame(maxWidth: .infinity)
        }
    }

    /// Eyebrow label: "ALL DONE" for the all-done variant, "X OF Y" for partial.
    private var eyebrowText: String {
        isAllDone ? "ALL DONE" : "\(progress.done) OF \(progress.total)"
    }

    /// Title line: includes the run name when present (e.g. "Packing List · Tokyo").
    private var titleLine: String {
        if let runName = run.name {
            return "\(checklist.name) · \(runName)"
        }
        return checklist.name
    }

    /// Human-readable elapsed time since the run started.
    /// Returns "just now" for <60 s, "Xm" for <1 h, "Xh Ym" for <24 h,
    /// "Xd Yh" for ≥24 h.
    private var relativeStartedString: String {
        let seconds = Date().timeIntervalSince(run.startedAt)
        switch seconds {
        case ..<60:       return "just now"
        case ..<3600:     return "\(Int(seconds / 60))m"
        case ..<86_400:   return "\(Int(seconds / 3600))h \(Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60))m"
        default:          return "\(Int(seconds / 86_400))d \(Int((seconds.truncatingRemainder(dividingBy: 86_400)) / 3600))h"
        }
    }

    /// Body copy explaining what completing does. Same text for both all-done and
    /// partial variants; the eyebrow + CTA label carry the distinction.
    private var bodyCopy: String {
        if isAllDone {
            return "Finishing saves this run to history and clears the list for next time. \(checklist.name) stays on your home screen, ready for a fresh run."
        } else {
            return "Finishing saves this run to history and clears the list for next time. \(checklist.name) stays on your home screen, ready for a fresh run."
        }
    }

    /// Commits the run as a CompletedRun via RunStore.complete, then dismisses.
    private func commitComplete() {
        try? RunStore.complete(run, in: ctx)
        dismiss()
    }

    // MARK: - Discard confirm

    /// The discard-confirm variant: ruby eyebrow + destructive CTA.
    /// Tapping "Cancel" returns to the primary variant; "Discard" deletes the run.
    private var discardContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("DISCARD RUN?")
                .font(Theme.eyebrow()).tracking(2).foregroundColor(Theme.ruby)
            Text("This run won't be saved to history.")
                .font(Theme.display(size: 22)).foregroundColor(Theme.text)
            Text("You checked \(progress.done) item\(progress.done == 1 ? "" : "s"). Discarding removes this run entirely — use this when you started by accident or it didn't really happen.")
                .font(.system(size: 13)).foregroundColor(Theme.dim)

            HStack(spacing: Theme.Spacing.sm) {
                PillButton(title: "Cancel", tone: .ghost, wide: true) { stage = .primary }
                PillButton(title: "Discard", color: Theme.ruby, wide: true) { commitDiscard() }
            }
        }
    }

    /// Discards the run via RunStore.discard (no CompletedRun created), then dismisses.
    private func commitDiscard() {
        try? RunStore.discard(run, in: ctx)
        dismiss()
    }
}

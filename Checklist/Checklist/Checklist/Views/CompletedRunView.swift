/// CompletedRunView.swift
/// Purpose: Read-only presentation of a sealed CompletedRun. Shows the eyebrow
///   ("COMPLETED RUN · LIST NAME"), completion date, completion/partial badge,
///   duration, a "Completed" notice banner, item rows (complete / ignored /
///   unchecked variants), and a "New run with checks from here" fork CTA.
/// Dependencies: SwiftUI, SwiftData, CompletedRun, Checklist, Run, Theme, TopBar,
///   GemIcons, Facet, TagChip, PillButton, CompletedRunProgress, RunStore.
/// Key concepts:
///   - The view is driven entirely by `completedRun.snapshot`; the source
///     Checklist may have been deleted or edited since, which is fine — the
///     snapshot is self-contained (spec §3 decision 3).
///   - Items render in three visual variants driven by the per-item check state:
///       .complete  → filled facet, strikethrough
///       .ignored   → empty facet, "IGNORED" trailing label, dimmed row
///       (absent)   → empty facet, no trailing label, standard row
///   - Tag grouping is added in Task 6.3; this scaffold lays out a flat list.
///   - The fork CTA calls RunStore.startRun(on:name:withChecksFrom:in:) which
///     lands in Task 6.4; until then the button dismisses.

import SwiftUI
import SwiftData

/// Read-only view of a sealed `CompletedRun`. Drives everything from the frozen
/// snapshot; the source `Checklist` is optional and used only for fork actions.
struct CompletedRunView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    let completedRun: CompletedRun

    /// Resolved snapshot, read once per body invocation.
    private var snap: CompletedRunSnapshot { completedRun.snapshot }

    private var progress: CompletedRunProgress {
        CompletedRunProgress.compute(snapshot: snap)
    }

    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        headerBlock
                        statusCard
                        completedBanner
                        itemsFlat
                        forkCTA
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.top, Theme.Spacing.md)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Top bar

    private var topBar: some View {
        TopBar(
            left: { IconButton(iconName: "back") { dismiss() } },
            right: { Color.clear.frame(width: 36, height: 36) }
        )
    }

    // MARK: - Header

    /// Eyebrow ("COMPLETED RUN · LIST NAME") + large completion-date title.
    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                GemIcons.image("history")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Theme.dim)
                Text("COMPLETED RUN")
                    .foregroundColor(Theme.dim)
                if let name = checklistName {
                    Text("·").foregroundColor(Theme.dimmer)
                    Text(name.uppercased()).foregroundColor(Theme.dim)
                }
            }
            .font(Theme.eyebrow())
            .tracking(2)

            Text(titleLine)
                .font(Theme.display(size: 30))
                .foregroundColor(Theme.text)
        }
    }

    /// Large title — a formatted completion date (e.g. "Fri, Apr 17") suffixed
    /// with a run name when present.
    private var titleLine: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        let date = formatter.string(from: completedRun.completedAt)
        if let name = completedRun.name, !name.isEmpty {
            return "\(date) · \(name)"
        }
        return date
    }

    /// Resolved checklist name — from the live relationship if still present,
    /// otherwise blank (snapshot intentionally does not store the list name).
    private var checklistName: String? { completedRun.checklist?.name }

    // MARK: - Status card (badge + fraction + date/duration)

    /// Card summarising the run: HeroGem + "COMPLETE"/"PARTIAL RUN" badge,
    /// N/M fraction, and date + duration sub-line.
    private var statusCard: some View {
        HStack(spacing: Theme.Spacing.md) {
            HeroGem(
                color: progress.isAllDone ? Theme.emerald : Theme.citrine,
                size: 44
            )
            VStack(alignment: .leading, spacing: 4) {
                Text(progress.isAllDone ? "COMPLETE" : "PARTIAL RUN")
                    .font(Theme.eyebrow()).tracking(2)
                    .foregroundColor(progress.isAllDone ? Theme.emerald : Theme.citrine)
                Text("\(progress.done)/\(progress.total)")
                    .font(Theme.display(size: 22))
                    .foregroundColor(Theme.text)
                Text(dateAndDurationLine)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.dim)
            }
            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.lg).fill(Theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .stroke(Theme.border, lineWidth: 1)
        )
    }

    /// Combined "Fri, Apr 17 · took 12m" sub-line for the status card.
    private var dateAndDurationLine: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return "\(formatter.string(from: completedRun.completedAt)) · took \(durationString)"
    }

    /// Formats the run's start→completion duration as "<1m", "Xm", or "Xh Ym".
    private var durationString: String {
        let minutes = Int(completedRun.completedAt.timeIntervalSince(completedRun.startedAt) / 60)
        if minutes < 1 { return "<1m" }
        if minutes < 60 { return "\(minutes)m" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }

    // MARK: - Completed banner

    /// Amber-tinted notice banner reminding the user the record is permanent.
    /// Per §7 translation: "Sealed" → "Completed".
    private var completedBanner: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("Completed.")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Theme.citrine)
            Text("This is a permanent record of what you did. Can't be edited.")
                .font(.system(size: 13))
                .foregroundColor(Theme.dim)
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .fill(Theme.citrine.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .stroke(Theme.citrine.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Items (flat)

    /// Flat list of item rows, sorted by snapshot sortKey. Tag grouping lands
    /// in Task 6.3.
    private var itemsFlat: some View {
        VStack(spacing: Theme.Spacing.xs) {
            ForEach(snap.items.sorted { $0.sortKey < $1.sortKey }) { item in
                CompletedItemRow(
                    text: item.text,
                    state: snap.checks[item.id],
                    tagColor: facetColor(for: item)
                )
            }
        }
    }

    /// Picks a facet tint from the first tag on the item, falling back to
    /// amethyst when the item is untagged.
    private func facetColor(for item: ItemSnapshot) -> Color {
        guard let firstID = item.tagIDs.first,
              let tag = snap.tags.first(where: { $0.id == firstID })
        else { return Theme.amethyst }
        return Theme.gemColor(hue: tag.colorHue)
    }

    // MARK: - Fork CTA

    /// "New run with checks from here" ghost pill at the bottom. Task 6.4 wires
    /// the RunStore call; this scaffold dismisses back to the caller.
    private var forkCTA: some View {
        VStack(alignment: .leading, spacing: 6) {
            PillButton(title: "New run with checks from here", tone: .ghost, wide: true) {
                // Wired in Task 6.4. Placeholder: dismiss.
                dismiss()
            }
            Text("Creates a live run pre-filled with the same checks. This completed record stays unchanged.")
                .font(.system(size: 12))
                .foregroundColor(Theme.dim)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.top, Theme.Spacing.md)
    }
}

// MARK: - Private row

/// A single item row in `CompletedRunView`. Stateless: parent passes the
/// display state via `state` (a `CheckState?`).
private struct CompletedItemRow: View {
    let text: String
    let state: CheckState?
    let tagColor: Color

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Facet(color: tagColor, checked: state == .complete, size: 22)
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(state == .complete ? Theme.dim : Theme.text)
                .strikethrough(state == .complete, color: Theme.dim)
            Spacer()
            if state == .ignored {
                Text("IGNORED")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Theme.dimmer)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .fill(Theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .stroke(Theme.border, lineWidth: 1)
        )
        .opacity(state == .ignored ? 0.55 : 1.0)
    }
}

// MARK: - Previews

#Preview("Completed run — all done") {
    let container = try! SeedStore.container(for: .historicalRuns)
    let ctx = ModelContext(container)
    let runs = try! ctx.fetch(FetchDescriptor<CompletedRun>())
    return NavigationStack {
        CompletedRunView(completedRun: runs.first!)
    }
    .modelContainer(container)
}

/// ChecklistRunView.swift
/// Purpose: Main list-run view. Hosts the item rows, progress bar, tag hide
///   chips, add-item inline, menu sheet, and completion sheets. Items live on
///   the Checklist; per-run state (checks, hiddenTagIDs) lives on the current Run.
/// Dependencies: SwiftUI, SwiftData, Checklist/Run/Item models, Theme,
///   TopBar, BackButton, AddItemRowStub.
/// Key concepts:
///   - Current-run selection: the earliest live Run (by startedAt) is the
///     "current" one. If no live runs exist, certain interactions auto-create
///     one (per ARCHITECTURE §3e).
///   - `ensureCurrentRun()` is called on appear; it only selects, never creates.
///   - The empty-items body shows a dashed AddItemRowStub (capture 11).
///   - BackButton is private to this file; it wraps IconButton to match the
///     circular-button design language.

import SwiftUI
import SwiftData

/// Main list-run view. Hosts the item rows, progress bar, tag hide chips,
/// add-item inline, menu sheet, and completion sheets. Items live on the
/// Checklist; per-run state (checks, hiddenTagIDs) lives on the current Run.
///
/// Current-run selection: the earliest live Run (by startedAt) is the
/// "current" one. If no live runs exist, certain interactions auto-create
/// one (per ARCHITECTURE §3e).
struct ChecklistRunView: View {
    @Environment(\.modelContext) private var ctx
    let checklist: Checklist

    @State private var currentRunID: UUID? = nil
    @State private var showMenu = false
    @State private var showAddItem = false
    @State private var editingItem: Item? = nil
    @State private var showCompletionSheet = false
    @State private var showDiscardConfirm = false
    @State private var showRunChooser = false
    @State private var showStartRunSheet = false

    /// The current live Run resolved from `currentRunID`. Nil when no run is active.
    private var currentRun: Run? {
        guard let id = currentRunID else { return nil }
        return (checklist.runs ?? []).first(where: { $0.id == id })
    }

    /// Items on this checklist sorted by their `sortKey` for stable ordering.
    private var sortedItems: [Item] {
        (checklist.items ?? []).sorted { $0.sortKey < $1.sortKey }
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
                        tagChipBar
                        progressRow
                        // Body fills in across Tasks 5.3 through 5.13.
                        if sortedItems.isEmpty {
                            emptyItemsBody
                        } else {
                            itemsSection
                        }
                        Spacer(minLength: 60)
                    }
                    .padding(.top, Theme.Spacing.md)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear { ensureCurrentRun() }
    }

    // MARK: - Sections

    /// Top navigation bar: back chevron on the left, kebab menu on the right.
    private var topBar: some View {
        TopBar(
            left: { BackButton() },
            right: { IconButton(iconName: "more") { showMenu = true } }
        )
    }

    /// Eyebrow (category · run name) + checklist name title block (capture 04).
    @ViewBuilder
    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                if let cat = checklist.category?.name {
                    Text(cat.uppercased())
                        .foregroundColor(Theme.dim)
                }
                if let run = currentRun, let runName = run.name {
                    Text("·").foregroundColor(Theme.dimmer)
                    Text(runName.uppercased())
                        .foregroundColor(Theme.citrine)
                }
            }
            .font(Theme.eyebrow())
            .tracking(2)

            Text(checklist.name)
                .font(Theme.display(size: 30))
                .foregroundColor(Theme.text)
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    // MARK: - Tag hide chip bar (Task 5.6)

    /// All tags referenced by at least one item on this checklist, sorted
    /// alphabetically for a stable display order.
    private var usedTags: [Tag] {
        let ids = Set((sortedItems.flatMap { $0.tags ?? [] }).map(\.id))
        // Deduplicate while preserving insertion order, then sort alphabetically.
        return (sortedItems.flatMap { $0.tags ?? [] })
            .reduce(into: [Tag]()) { acc, t in
                if !acc.contains(where: { $0.id == t.id }) { acc.append(t) }
            }
            .filter { ids.contains($0.id) }
            .sorted { $0.name < $1.name }
    }

    /// Horizontal tag-hide chip row. Visible only when a live run exists and
    /// the checklist has at least one tagged item.
    @ViewBuilder
    private var tagChipBar: some View {
        if let run = currentRun, !usedTags.isEmpty {
            TagHideChipBar(
                tags: usedTags,
                hiddenTagIDs: run.hiddenTagIDs
            ) { tagID in
                try? RunStore.toggleHideTag(run: run, tagID: tagID, in: ctx)
            }
        }
    }

    // MARK: - Progress row (Task 5.5)

    /// Progress bar showing done/total count and percentage. Visible only when
    /// a live run exists and the checklist has items (capture 04).
    @ViewBuilder
    private var progressRow: some View {
        if let run = currentRun, !sortedItems.isEmpty {
            let progress = RunProgress.compute(
                items: sortedItems,
                checks: run.checks ?? [],
                hiddenTagIDs: run.hiddenTagIDs
            )
            HStack(spacing: Theme.Spacing.md) {
                GemBar(progress: progress.percent, segments: 14)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("PROGRESS")
                            .font(Theme.eyebrow())
                            .tracking(1.5)
                            .foregroundColor(Theme.dim)
                        Text("\(progress.done) of \(progress.total)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Theme.text)
                    }
                    Text("\(Int((progress.percent * 100).rounded()))%")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Theme.citrine)
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
        }
    }

    /// Shown when the checklist has no items (capture 11): a dashed "+ Add item" stub row.
    private var emptyItemsBody: some View {
        AddItemRowStub { showAddItem = true }
            .padding(.horizontal, Theme.Spacing.xl)
    }

    // MARK: - Items section (Task 5.3)

    /// Renders all items as ItemRows plus a trailing AddItemRowStub.
    /// Check toggling wired to handleToggleCheck; body tap opens ItemEditInline in Task 5.9.
    private var itemsSection: some View {
        LazyVStack(spacing: Theme.Spacing.xs) {
            ForEach(sortedItems) { item in
                ItemRow(
                    text: item.text,
                    tags: tagTuples(for: item),
                    display: display(for: item),
                    onToggleCheck: { handleToggleCheck(item) },
                    onTapBody:     { editingItem = item }
                )
            }
            AddItemRowStub { showAddItem = true }
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    // MARK: - Check toggling (Task 5.4)

    /// Toggles the check state for an item on the current run. If no run
    /// exists, auto-creates one first (per ARCHITECTURE §3e).
    private func handleToggleCheck(_ item: Item) {
        do {
            let run = try currentRunOrCreate()
            try RunStore.toggleCheck(run: run, itemID: item.id, in: ctx)
        } catch {
            // Surface via error banner later; for now log.
            print("toggleCheck failed: \(error)")
        }
    }

    /// Returns the current Run. If none exists, auto-creates one (§3e) and
    /// updates currentRunID.
    private func currentRunOrCreate() throws -> Run {
        if let run = currentRun { return run }
        let run = try RunStore.startRun(on: checklist, in: ctx)
        currentRunID = run.id
        return run
    }

    /// Derives the `ItemRow.Display` state for an item from the current run's
    /// checks. Returns `.incomplete` when there is no run or no check record.
    private func display(for item: Item) -> ItemRow.Display {
        guard let run = currentRun,
              let check = (run.checks ?? []).first(where: { $0.itemID == item.id })
        else { return .incomplete }
        switch check.state {
        case .complete: return .complete
        case .ignored:  return .ignored
        }
    }

    /// Maps a SwiftData `Item`'s `Tag` relationships into the plain-value tuple
    /// array expected by `ItemRow`. Avoids passing SwiftData objects into a view
    /// that should not own a model reference.
    private func tagTuples(for item: Item) -> [(name: String, iconName: String, colorHue: Double)] {
        (item.tags ?? []).map { (name: $0.name, iconName: $0.iconName, colorHue: $0.colorHue) }
    }

    // MARK: - Current-run management

    /// Selects the current Run per ARCHITECTURE §3e. Called on appear.
    /// If multiple live runs exist, picks the earliest by startedAt — matching
    /// the same "primary run" definition used on Home. Does NOT auto-create;
    /// auto-creation happens on the first mutating interaction (Task 5.4).
    private func ensureCurrentRun() {
        let liveRuns = (checklist.runs ?? []).sorted(by: { $0.startedAt < $1.startedAt })
        if let primary = liveRuns.first {
            currentRunID = primary.id
        } else {
            // No live run — leave currentRunID nil so the "no current run"
            // view state (capture 12) is reachable.
            currentRunID = nil
        }
    }
}

// MARK: - Private supporting views

/// System-back-style chevron rendered as an IconButton so the visual style
/// matches the prototype's circular icon buttons.
private struct BackButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        IconButton(iconName: "back") { dismiss() }
    }
}

/// Temporary dashed "+ Add item" row. Replaced by the full AddItemInline in Task 5.8.
private struct AddItemRowStub: View {
    /// Called when the user taps the row.
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                GemIcons.image("plus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Theme.dim)
                Text("Add item")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.dim)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .stroke(Theme.border, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Empty items") {
    let container = try! SeedStore.container(for: .oneList)
    let ctx = ModelContext(container)
    let lists = try! ctx.fetch(FetchDescriptor<Checklist>())
    let list = lists.first!
    // Remove all items so the empty-items body is exercised (capture 11).
    for item in list.items ?? [] { ctx.delete(item) }
    try! ctx.save()
    return NavigationStack { ChecklistRunView(checklist: list) }
        .modelContainer(container)
}

#Preview("Seeded (Packing List)") {
    let container = try! SeedStore.container(for: .seededMulti)
    let ctx = ModelContext(container)
    let lists = try! ctx.fetch(FetchDescriptor<Checklist>())
    // Prefer the seeded "Packing List"; fall back to the first available checklist.
    let list = lists.first(where: { $0.name == "Packing List" }) ?? lists.first!
    return NavigationStack { ChecklistRunView(checklist: list) }
        .modelContainer(container)
}

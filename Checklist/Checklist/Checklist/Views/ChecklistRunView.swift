/// ChecklistRunView.swift
/// Purpose: Main list-run view. Hosts the item rows, progress bar, tag hide
///   chips, add-item inline, menu sheet, and completion sheets. Items live on
///   the Checklist; per-run state (checks, hiddenTagIDs) lives on the current Run.
/// Dependencies: SwiftUI, SwiftData, Checklist/Run/Item models, Theme,
///   TopBar, BackButton, AddItemRowStub, PreviousRunsStrip.
/// Key concepts:
///   - Current-run selection: the earliest live Run (by startedAt) is the
///     "current" one. If no live runs exist, certain interactions auto-create
///     one (per ARCHITECTURE §3e).
///   - `ensureCurrentRun()` is called on appear; it only selects, never creates.
///   - The empty-items body shows a dashed AddItemRowStub (capture 11).
///   - BackButton is private to this file; it wraps IconButton to match the
///     circular-button design language.
///   - `actionRowIfApplicable` gates the Complete / New-run buttons behind
///     `!sortedItems.isEmpty && currentRun != nil` (Task 5.14).

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
    /// NavigationPath binding owned by HomeView. Used by sheets + strip rows
    /// that need to request a push after dismissing themselves.
    @Binding var path: NavigationPath

    @State private var currentRunID: UUID? = nil
    @State private var showMenu = false
    @State private var showAddItem = false
    @State private var editingItem: Item? = nil
    @State private var showCompletionSheet = false
    @State private var showRunChooser = false
    @State private var showStartRunSheet = false
    // Task 5.7: swipe-to-delete state
    @State private var pendingDelete: Item? = nil
    @State private var showDeleteWarning = false

    /// The current live Run resolved from `currentRunID`. Nil when no run is active.
    private var currentRun: Run? {
        guard let id = currentRunID else { return nil }
        return (checklist.runs ?? []).first(where: { $0.id == id })
    }

    /// Items on this checklist sorted by their `sortKey` for stable ordering.
    private var sortedItems: [Item] {
        (checklist.items ?? []).sorted { $0.sortKey < $1.sortKey }
    }

    /// Task 5.13: Completed runs for this checklist sorted newest-first.
    private var completedRunsSorted: [CompletedRun] {
        (checklist.completedRuns ?? []).sorted { $0.completedAt > $1.completedAt }
    }

    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            Theme.bg.ignoresSafeArea()

            // Task 5.7: List is its own scroller, so the outer ScrollView is
            // removed. Fixed sections (topBar, headerBlock, tagChipBar,
            // progressRow) sit above; itemsSection provides the scrollable body.
            VStack(spacing: 0) {
                topBar
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    headerBlock
                    // Task 5.13: shown only when no live run and completed runs exist.
                    lastFinishedSubtitle
                    multiRunPill
                    tagChipBar
                    progressRow
                }
                .padding(.top, Theme.Spacing.md)

                if sortedItems.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            emptyItemsBody
                            Spacer(minLength: 60)
                        }
                        .padding(.top, Theme.Spacing.md)
                    }
                } else {
                    itemsSection
                }

                // Task 5.14: Action row only when items exist and a live run is active.
                actionRowIfApplicable
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear { ensureCurrentRun() }
        // Task 5.7: multi-run delete warning alert
        .alert("Delete '\(pendingDelete?.text ?? "item")'?",
               isPresented: $showDeleteWarning,
               presenting: pendingDelete) { item in
            Button("Delete from \(checklist.runs?.count ?? 0) live runs",
                   role: .destructive) { commitDelete(item) }
            Button("Cancel", role: .cancel) {
                pendingDelete = nil
                showDeleteWarning = false
            }
        } message: { _ in
            Text("This also removes any checks on this item. Runs already saved to history are untouched.")
        }
        .sheet(isPresented: $showMenu) {
            ChecklistMenuSheet(checklist: checklist, currentRun: currentRun)
        }
        .sheet(isPresented: $showAddItem) {
            AddItemInline(checklist: checklist)
        }
        .sheet(item: $editingItem) { item in
            ItemEditInline(item: item, currentRun: currentRun)
        }
        .sheet(isPresented: $showCompletionSheet) {
            if let run = currentRun {
                CompletionSheet(checklist: checklist, run: run)
            }
        }
        .sheet(isPresented: $showRunChooser) {
            RunChooserSheet(
                checklist: checklist,
                onSelect: { run in currentRunID = run.id },
                onStartNew: { showStartRunSheet = true }
            )
        }
        .sheet(isPresented: $showStartRunSheet) {
            StartRunSheet(checklist: checklist) { run in
                currentRunID = run.id
            }
        }
        .onChange(of: currentRun?.checks?.count ?? 0) { _, _ in
            maybeAutoPresentCompletion()
        }
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

    // MARK: - Last-finished subtitle (Task 5.13)

    /// Subtitle shown under the checklist title when no live run is active but
    /// at least one completed run exists (capture 12). Displays relative time
    /// since the most recent completed run.
    @ViewBuilder
    private var lastFinishedSubtitle: some View {
        if currentRun == nil, let last = completedRunsSorted.first {
            HStack(spacing: 4) {
                GemIcons.image("check")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Theme.emerald)
                Text("Last finished \(relativeFinishedString(last))")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.dim)
            }
            .padding(.horizontal, Theme.Spacing.xl)
        }
    }

    /// Converts a `CompletedRun`'s completedAt timestamp to a human-readable
    /// relative string such as "just now", "5m ago", "2h ago", or "3d ago".
    ///
    /// - Parameter run: The completed run to measure elapsed time from.
    /// - Returns: A localised relative time string.
    private func relativeFinishedString(_ run: CompletedRun) -> String {
        let s = Date().timeIntervalSince(run.completedAt)
        if s < 60      { return "just now" }
        if s < 3600    { return "\(Int(s / 60))m ago" }
        if s < 86_400  { return "\(Int(s / 3600))h ago" }
        return "\(Int(s / 86_400))d ago"
    }

    // MARK: - Multi-run switcher pill (Task 5.12)

    /// Pill button showing "N live runs ▾". Visible only when the checklist has
    /// ≥2 live runs. Tapping opens RunChooserSheet so the user can switch the
    /// active run or start a new one.
    @ViewBuilder
    private var multiRunPill: some View {
        let count = checklist.runs?.count ?? 0
        if count >= 2 {
            Button {
                showRunChooser = true
            } label: {
                HStack(spacing: 6) {
                    GemIcons.image("stack")
                        .font(.system(size: 11, weight: .bold))
                    Text("\(count) live runs")
                        .font(.system(size: 12, weight: .semibold))
                    GemIcons.image("down")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(Theme.text)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Capsule().fill(Color.white.opacity(0.06)))
                .overlay(Capsule().stroke(Theme.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Theme.Spacing.xl)
        }
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

    // MARK: - Items section (Task 5.3 + 5.7)

    /// Renders all items as ItemRows inside a `List` (required for `.swipeActions`),
    /// plus a trailing AddItemRowStub. Check toggling wired to handleToggleCheck;
    /// body tap opens ItemEditInline in Task 5.9. Swipe right = complete (toggle),
    /// swipe left = delete (with multi-run warning when ≥2 live runs).
    ///
    /// Task 5.13: PreviousRunsStrip is embedded as a Section footer so it scrolls
    /// with the item list rather than being pushed off-screen by a long list.
    private var itemsSection: some View {
        List {
            Section {
                ForEach(sortedItems) { item in
                    ItemRow(
                        text: item.text,
                        tags: tagTuples(for: item),
                        display: display(for: item),
                        onToggleCheck: { handleToggleCheck(item) },
                        onTapBody:     { editingItem = item }
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            handleToggleCheck(item)
                        } label: {
                            Label("Complete", systemImage: "checkmark")
                        }
                        .tint(Theme.emerald)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            attemptDelete(item)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                // Add-item stub lives inside the List so it scrolls with items.
                AddItemRowStub { showAddItem = true }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))
            } footer: {
                // Task 5.13: PreviousRunsStrip as a List footer so it scrolls
                // with the items and is never pushed off-screen on long lists.
                // Task 6.2: tapping a row now pushes CompletedRunView.
                if currentRun == nil, !completedRunsSorted.isEmpty {
                    PreviousRunsStrip(
                        completedRuns: Array(completedRunsSorted.prefix(5)),
                        onTap: { run in path.append(run) }
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .frame(minHeight: CGFloat(sortedItems.count + 1) * 58)
        .padding(.horizontal, Theme.Spacing.xl)
    }

    // MARK: - Action row (Tasks 5.11 + 5.14)

    /// Task 5.14: Wraps `actionRow` with a guard — renders nothing when there are no
    /// items or when no live run is active. Prevents the action row from appearing in
    /// the "no-current-run" state (capture 12) or the "empty items" state (capture 11).
    @ViewBuilder
    private var actionRowIfApplicable: some View {
        if !sortedItems.isEmpty, currentRun != nil {
            actionRow
        }
    }

    /// Bottom action row: "Complete" pill (citrine when partial, emerald when all-done)
    /// and "+ New run" ghost pill. Visible only when a live run exists.
    ///
    /// The Complete pill opens CompletionSheet; "+ New run" sets showStartRunSheet
    /// (Task 5.12 wires the sheet itself).
    private var actionRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            if let run = currentRun {
                let progress = RunProgress.compute(
                    items: sortedItems,
                    checks: run.checks ?? [],
                    hiddenTagIDs: run.hiddenTagIDs
                )
                let label = progress.done == progress.total && progress.total > 0
                    ? "Complete"
                    : "Complete · \(progress.done)/\(progress.total)"
                PillButton(
                    title: label,
                    color: progress.done == progress.total ? Theme.emerald : Theme.citrine
                ) { showCompletionSheet = true }

                PillButton(title: "+ New run", tone: .ghost) {
                    showStartRunSheet = true  // Task 5.12
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .padding(.vertical, Theme.Spacing.sm)
    }

    // MARK: - Delete helpers (Task 5.7)

    /// Attempts to delete an item. Shows a warning alert when ≥2 live runs
    /// exist, because the deletion affects check records across all of them.
    /// Deletes silently when only one (or zero) live runs exist.
    ///
    /// - Parameter item: The item the user swiped to delete.
    private func attemptDelete(_ item: Item) {
        let liveRuns = checklist.runs?.count ?? 0
        if liveRuns >= 2 {
            pendingDelete = item
            showDeleteWarning = true
        } else {
            commitDelete(item)
        }
    }

    /// Executes the item deletion via ChecklistStore and resets pending-delete state.
    ///
    /// - Parameter item: The item to permanently delete.
    private func commitDelete(_ item: Item) {
        try? ChecklistStore.deleteItem(item, in: ctx)
        pendingDelete = nil
        showDeleteWarning = false
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

    /// Auto-presents CompletionSheet when all visible items on the current run
    /// are checked. Called via onChange(of: currentRun?.checks?.count).
    ///
    /// Guard: only fires when progress.total > 0 (non-empty list) and
    /// progress.done == progress.total (every visible item is complete).
    private func maybeAutoPresentCompletion() {
        guard let run = currentRun else { return }
        let progress = RunProgress.compute(
            items: sortedItems,
            checks: run.checks ?? [],
            hiddenTagIDs: run.hiddenTagIDs
        )
        if progress.total > 0, progress.done == progress.total {
            showCompletionSheet = true
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
    return NavigationStack {
        ChecklistRunView(checklist: list, path: .constant(NavigationPath()))
    }
    .modelContainer(container)
}

#Preview("Seeded (Packing List)") {
    let container = try! SeedStore.container(for: .seededMulti)
    let ctx = ModelContext(container)
    let lists = try! ctx.fetch(FetchDescriptor<Checklist>())
    // Prefer the seeded "Packing List"; fall back to the first available checklist.
    let list = lists.first(where: { $0.name == "Packing List" }) ?? lists.first!
    return NavigationStack {
        ChecklistRunView(checklist: list, path: .constant(NavigationPath()))
    }
    .modelContainer(container)
}

/// Task 5.14 verification: Gym Bag with 3-of-4 items complete, action row
/// visible (progress ~75%), no-complete auto-sheet (not all items done).
#Preview("Near complete (Gym Bag)") {
    let container = try! SeedStore.container(for: .nearCompleteRun)
    let ctx = ModelContext(container)
    let list = try! ctx.fetch(FetchDescriptor<Checklist>()).first(where: { $0.name == "Gym Bag" })!
    return NavigationStack {
        ChecklistRunView(checklist: list, path: .constant(NavigationPath()))
    }
    .modelContainer(container)
}

/// HomeView.swift
/// Purpose: Root screen of the app. Displays a grid of checklists with category
///   filter chips, summary cards (Tags / History), and a Create sheet trigger.
/// Dependencies: SwiftUI, SwiftData, Checklist model, ChecklistCategory model,
///   Theme (Design tokens), TopBar, IconButton (Design/Components/TopBar.swift),
///   ChecklistCard, CategoryFilterChipsView, SummaryCardsRow, RunProgress.
///   CreateChecklistSheet is added in a later task.
/// Key concepts:
///   - @Query drives the checklist grid and category list; both are sorted by sortKey.
///   - @State drives transient UI: selectedCategoryID filter, sheet presentation,
///     and navigation path.
///   - topBar is composed from the reusable TopBar + IconButton design components.
///   - eyebrowText reflects live-run count per §7 translation rule.
///   - filteredChecklists narrows the grid when a category chip is selected.

import SwiftUI
import SwiftData

/// Home screen — root of the app. Shows a grid of checklists with category
/// filter chips, summary cards (Tags / History), and the Create sheet trigger.
/// Dependencies: Checklist model, ChecklistCard, CategoryFilterChipsView,
/// SummaryCardsRow, CreateChecklistSheet (later tasks).
/// Key concepts: @Query drives the grid; @State drives transient UI
/// (selectedCategoryID filter, createSheet presentation, navigation path).
struct HomeView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: [SortDescriptor(\Checklist.sortKey, order: .forward)])
    private var checklists: [Checklist]
    @Query(sort: [SortDescriptor(\ChecklistCategory.sortKey, order: .forward)])
    private var categories: [ChecklistCategory]

    @State private var selectedCategoryID: UUID? = nil  // nil = "All"
    @State private var showCreateSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                Theme.bg.ignoresSafeArea()  // solid base under the radial gradient

                VStack(spacing: 0) {
                    topBar
                    ScrollView {
                        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                            titleBlock
                            cardsSection
                            Spacer(minLength: 0)
                        }
                        .padding(.top, Theme.Spacing.md)
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                // CreateChecklistSheet placeholder — real in Task 4.5
                Text("Create sheet placeholder")
                    .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Subviews

    /// Top navigation bar: theme/settings icon on left, add-checklist button on right.
    private var topBar: some View {
        TopBar(
            left: { IconButton(iconName: "sparkle") {} },   // sun/theme — no-op
            right: { IconButton(iconName: "plus", solid: true) { showCreateSheet = true } }
        )
    }

    /// Eyebrow + large title block displayed below the top bar.
    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(eyebrowText)
                .font(Theme.eyebrow())
                .tracking(2)
                .foregroundColor(Theme.dim)
            Text("Checklists.")
                .font(Theme.display(size: 34, weight: .bold))
                .foregroundColor(Theme.text)
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    // MARK: - Helpers

    /// Builds the eyebrow label. Shows live run count when any checklists have
    /// active runs; falls back to a static label (§7 — never "Collections").
    ///
    /// - Returns: Uppercase eyebrow string, e.g. "YOUR CATEGORIES · 2 LIVE".
    private var eyebrowText: String {
        let liveRunCount = checklists.reduce(0) { $0 + ($1.runs?.count ?? 0) }
        if liveRunCount > 0 {
            return "YOUR CATEGORIES · \(liveRunCount) LIVE"
        } else {
            return "YOUR CATEGORIES"
        }
    }

    // MARK: - Cards grid

    /// Cards section: renders either the checklist grid or the empty state.
    @ViewBuilder
    private var cardsSection: some View {
        if filteredChecklists.isEmpty {
            emptyState
        } else {
            LazyVStack(spacing: Theme.Spacing.sm) {
                ForEach(filteredChecklists) { list in
                    card(for: list)
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
        }
    }

    /// Checklists filtered by the currently selected category chip. Returns all
    /// checklists when `selectedCategoryID` is nil ("All").
    private var filteredChecklists: [Checklist] {
        guard let categoryID = selectedCategoryID else { return checklists }
        return checklists.filter { $0.category?.id == categoryID }
    }

    /// Builds a `ChecklistCard` for the given checklist, using the primary run's
    /// progress and label.
    ///
    /// - Parameter list: The `Checklist` to render.
    /// - Returns: A tappable card view.
    @ViewBuilder
    private func card(for list: Checklist) -> some View {
        let progress = primaryProgress(for: list)
        let primaryLabel = primaryRunLabel(for: list)
        ChecklistCard(
            categoryName: list.category?.name,
            primaryRunLabel: primaryLabel,
            name: list.name,
            progress: (done: progress.done, total: progress.total),
            liveRunCount: list.runs?.count ?? 0
        ) {
            // Navigation — wired in Task 4.7
        }
    }

    /// Returns the primary live run's label (e.g. "Tokyo"), or nil. The primary
    /// run is the first live run sorted by `startedAt` ascending. Nil if no live
    /// runs.
    ///
    /// - Parameter list: The `Checklist` whose primary run label to retrieve.
    /// - Returns: The run's `name`, or `nil` if no runs exist or the run has no name.
    private func primaryRunLabel(for list: Checklist) -> String? {
        guard let primary = (list.runs ?? []).sorted(by: { $0.startedAt < $1.startedAt }).first else {
            return nil
        }
        return primary.name
    }

    /// Progress for the primary live run (or 0/total if no live run).
    ///
    /// - Parameter list: The `Checklist` whose progress to compute.
    /// - Returns: A `RunProgress` snapshot reflecting the primary run's state.
    private func primaryProgress(for list: Checklist) -> RunProgress {
        let items = list.items ?? []
        guard let primary = (list.runs ?? []).sorted(by: { $0.startedAt < $1.startedAt }).first else {
            return RunProgress(done: 0, total: items.count)
        }
        return RunProgress.compute(
            items: items,
            checks: primary.checks ?? [],
            hiddenTagIDs: primary.hiddenTagIDs
        )
    }

    // MARK: - Empty state

    /// Empty state shown when `filteredChecklists` is empty. Matches prototype
    /// capture 02 — centered prompt with a "New list" pill button.
    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.md) {
            Spacer(minLength: 60)
            Text("No lists yet.")
                .font(Theme.body(size: 14))
                .foregroundColor(Theme.dim)
            PillButton(title: "+ New list", color: Theme.amethyst) {
                showCreateSheet = true
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Theme.Spacing.xl)
    }
}

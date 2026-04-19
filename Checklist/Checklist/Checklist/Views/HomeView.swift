/// HomeView.swift
/// Purpose: Root screen of the app. Displays a grid of checklists with category
///   filter chips, summary cards (Tags / History), and a Create sheet trigger.
/// Dependencies: SwiftUI, SwiftData, Checklist model, ChecklistCategory model,
///   Theme (Design tokens), TopBar, IconButton (Design/Components/TopBar.swift).
///   ChecklistCard, CategoryFilterChipsView, SummaryCardsRow, and
///   CreateChecklistSheet are added in later tasks.
/// Key concepts:
///   - @Query drives the checklist grid and category list; both are sorted by sortKey.
///   - @State drives transient UI: selectedCategoryID filter, sheet presentation,
///     and navigation path.
///   - topBar is composed from the reusable TopBar + IconButton design components.
///   - eyebrowText reflects live-run count per §7 translation rule.

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
                            // Filter chips + cards grid land in later tasks.
                            // For now: placeholder so the scaffold renders.
                            Text("Home scaffold — cards grid coming next.")
                                .foregroundColor(Theme.dim)
                                .padding(.horizontal, Theme.Spacing.xl)
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
}

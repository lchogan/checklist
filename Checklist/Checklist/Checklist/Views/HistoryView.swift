/// HistoryView.swift
/// Purpose: Reverse-chronological feed of CompletedRun records. Two scopes:
///   .allLists (global) and .checklist(id) (per-list). Filterable in-view by
///   completion state (All / Complete / Partial — partial computed at view time).
/// Dependencies: SwiftUI, SwiftData, CompletedRun, Checklist, Theme, TopBar,
///   GemIcons, CompletedRunProgress, HistoryScope.
/// Key concepts:
///   - @Query drives the feed; scope filter is a static predicate (checklistID),
///     state filter is applied in-memory after fetch because partial/complete
///     is computed from the snapshot, not persisted.
///   - Month grouping uses Calendar to bucket by year+month, with a formatted
///     header ("APRIL 2026"), and a "N RUNS" hint per month.
///   - Rows are tappable — push CompletedRunView (Task 6.8 wires this).

import SwiftUI
import SwiftData

/// Reverse-chronological feed of `CompletedRun` records. Scope is either the
/// global feed or a single Checklist. Filterable in-view by completion state.
struct HistoryView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    /// The feed scope — global or per-checklist.
    let scope: HistoryScope

    /// Query over all completed runs, reverse-chrono by completedAt. Scope
    /// and state filtering are applied in `filteredRuns` so @Query stays
    /// simple (SwiftData #Predicate doesn't cleanly express "all runs" vs
    /// "runs for a specific checklist" in a single expression).
    @Query(sort: [SortDescriptor(\CompletedRun.completedAt, order: .reverse)])
    private var allRuns: [CompletedRun]

    /// Available checklists, used for the "All lists / per-list" scope chip row.
    @Query(sort: [SortDescriptor(\Checklist.sortKey, order: .forward)])
    private var checklists: [Checklist]

    /// The state-filter chip currently selected. Task 6.6 hooks this up.
    @State private var stateFilter: StateFilter = .all

    /// State-filter chip values on the second chip row.
    enum StateFilter: String, CaseIterable {
        case all      = "All"
        case complete = "Complete"
        case partial  = "Partial"
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
                        scopeChips
                        stateChips
                        if filteredRuns.isEmpty {
                            emptyState
                        } else {
                            feed
                        }
                        Spacer(minLength: 40)
                    }
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

    /// "ALL RUNS" or "LIST-NAME · RUNS" eyebrow, large "History." title, and a
    /// subtitle with total-runs + total-items-checked counts.
    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(eyebrowText)
                .font(Theme.eyebrow()).tracking(2)
                .foregroundColor(Theme.dim)

            Text("History.")
                .font(Theme.display(size: 34, weight: .bold))
                .foregroundColor(Theme.text)

            Text(subtitleText)
                .font(.system(size: 13))
                .foregroundColor(Theme.dim)
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    /// Eyebrow: "ALL RUNS" for global, "<LIST NAME> · RUNS" for per-list.
    private var eyebrowText: String {
        guard let id = scope.checklistID,
              let name = checklists.first(where: { $0.id == id })?.name else {
            return "ALL RUNS"
        }
        return "\(name.uppercased()) · RUNS"
    }

    /// Subtitle: "N runs · M items checked" — totals across the scoped feed,
    /// before the state filter. Counts every `.complete` check across all
    /// scoped snapshots.
    private var subtitleText: String {
        let runs = scopedRuns
        let itemsChecked = runs.reduce(0) { acc, run in
            acc + run.snapshot.checks.values.filter { $0 == .complete }.count
        }
        return "\(runs.count) run\(runs.count == 1 ? "" : "s") · \(itemsChecked) items checked"
    }

    // MARK: - Scope chips (Task 6.7 populates per-list chips; 6.5 just shows "All lists")

    /// Horizontal chip row letting the user switch between the global feed and
    /// each individual checklist. Placeholder scaffold in Task 6.5 — the chips
    /// are non-interactive here; Task 6.7 wires them to update `scope`.
    private var scopeChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.xs) {
                scopeChip(title: "All lists", isSelected: scope.checklistID == nil)
                ForEach(checklists) { list in
                    scopeChip(
                        title: list.name,
                        isSelected: scope.checklistID == list.id
                    )
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
        }
    }

    /// Single scope chip — gradient fill when selected; ghost otherwise. Non-
    /// interactive in Task 6.5 (the view reads `scope` from init).
    private func scopeChip(title: String, isSelected: Bool) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(isSelected ? .white : Theme.text)
            .padding(.horizontal, 14).padding(.vertical, 7)
            .background(
                Group {
                    if isSelected {
                        Capsule().fill(
                            LinearGradient(
                                colors: [Theme.amethyst, Theme.sapphire.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    } else {
                        Capsule().fill(Color.white.opacity(0.05))
                    }
                }
            )
            .overlay(
                Capsule().stroke(isSelected ? Color.clear : Theme.border, lineWidth: 1)
            )
    }

    // MARK: - State chips (All / Complete / Partial) — wired in Task 6.6

    /// Horizontal chip row for state filtering. Fully wired in Task 6.6; Task
    /// 6.5 renders them but the selection is ignored until 6.6 adds the
    /// filter predicate.
    private var stateChips: some View {
        HStack(spacing: Theme.Spacing.xs) {
            ForEach(StateFilter.allCases, id: \.self) { filter in
                Button {
                    stateFilter = filter
                } label: {
                    Text(filter.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(stateFilter == filter ? .white : Theme.text)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(
                            Group {
                                if stateFilter == filter {
                                    Capsule().fill(
                                        LinearGradient(
                                            colors: [Theme.amethyst, Theme.sapphire.opacity(0.85)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                } else {
                                    Capsule().fill(Color.white.opacity(0.05))
                                }
                            }
                        )
                        .overlay(
                            Capsule().stroke(stateFilter == filter ? Color.clear : Theme.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    // MARK: - Feed + empty state (flat list in Task 6.5; month grouping in 6.6)

    /// Flat list of rows. Month grouping lands in Task 6.6.
    private var feed: some View {
        VStack(spacing: Theme.Spacing.xs) {
            ForEach(filteredRuns) { run in
                historyRow(run)
            }
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    /// Tappable row per run — name + date + N/M. Task 6.8 wires the tap to
    /// push CompletedRunView.
    private func historyRow(_ run: CompletedRun) -> some View {
        let prog = CompletedRunProgress.compute(snapshot: run.snapshot)
        return Button {
            // Wired in Task 6.8 (HistoryView accepts a path binding then).
        } label: {
            HStack {
                HeroGem(
                    color: prog.isAllDone ? Theme.emerald : Theme.citrine,
                    size: 22
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text(run.checklist?.name ?? "Unknown list")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.text)
                    Text("\(formattedDate(run.completedAt)) · \(prog.done)/\(prog.total)")
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
    }

    /// "Fri, Apr 17" short-form date.
    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: date)
    }

    /// Empty state per capture 22: "No runs yet. / Complete a checklist to save it here."
    /// Note: prototype says "seal it here" — v4 replaces per §7.
    private var emptyState: some View {
        VStack(spacing: 6) {
            Text("No runs yet.")
                .font(.system(size: 14))
                .foregroundColor(Theme.dim)
            Text("Complete a checklist to save it here.")
                .font(.system(size: 14))
                .foregroundColor(Theme.dim)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Filtering

    /// Runs reduced to the `scope` only (checklist-scoped when non-nil).
    private var scopedRuns: [CompletedRun] {
        guard let id = scope.checklistID else { return allRuns }
        return allRuns.filter { $0.checklist?.id == id }
    }

    /// Runs passed through both scope and state-filter chips. Task 6.6 expands
    /// this to honour `stateFilter`; Task 6.5 returns `scopedRuns` as-is.
    private var filteredRuns: [CompletedRun] { scopedRuns }
}

// MARK: - Previews

#Preview("History — all (seeded)") {
    let container = try! SeedStore.container(for: .historicalRuns)
    return NavigationStack {
        HistoryView(scope: .allLists)
    }
    .modelContainer(container)
}

#Preview("History — empty") {
    let container = try! SeedStore.container(for: .empty)
    return NavigationStack {
        HistoryView(scope: .allLists)
    }
    .modelContainer(container)
}

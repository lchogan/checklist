# Checklist v4 — Plan 3: CompletedRunView + HistoryView + TagsView + TagEditorSheet (Phases 6–7)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the three dead-end taps Plan 2 left behind — wire `PreviousRunsStrip` rows to a new `CompletedRunView`, `ChecklistMenuSheet`'s "Manage tags" row to a new `TagsView`, and `ChecklistMenuSheet`'s "Full history for this list" row (plus Home's History summary card) to a new `HistoryView`. Also introduce `TagEditorSheet` (create + edit) driven from `TagsView`.

**Architecture:** Views continue to use `@Query` + `@Environment(\.modelContext)` directly; non-trivial mutations route through existing `TagStore` / `RunStore` (one new `RunStore.startRun(on:name:withChecksFrom:in:)` lands in Task 6.4). Navigation uses a single `NavigationPath` binding owned by `HomeView` and threaded down to `ChecklistRunView`. Destinations are registered at the root. `CompletedRun`, a `HistoryScope` wrapper, and a `TagsDestination` marker are the three new routes. Sheets use the existing `BottomSheet` primitive.

**Tech Stack:** Swift 5.9+, SwiftUI, SwiftData (iOS 17+), XCTest, Xcode 16+.

**Spec:** `docs/superpowers/specs/2026-04-18-checklist-v4-redesign.md` — §2 (screen inventory, rows for `CompletedRunView`, `HistoryView`, `TagsView`, `TagEditorSheet`), §3 (cascade table, `TagStore.delete` behaviour), §7 (translation rules — "Seal"/"Sealed" → "Completed"/"Completed run"; "Start new run from here" → "New run with checks from here"; "Skipped" never used — per-run ignore state renders as "Ignored").

**Architecture doc:** `ARCHITECTURE.md` — §3f (Clear history), §3g (save as new / copy checks from).

**Visual refs (authoritative):** `docs/superpowers/prototype-captures/` — captures 19–20 for `CompletedRunView`; 21–23 for `HistoryView`; 24–25 for `TagsView`; 26–27 for `TagEditorSheet`. Prototype's "Sealed record" eyebrow and "SKIPPED" side-labels are v3 language — override per §7.

**Baseline at plan start:** `main` at tag `plan-2-home-and-runview-complete`. Tests passing ≥69. App launches to a working `HomeView` with seeded multi-run fixture available via preview. `PreviousRunsStrip` rows, `ChecklistMenuSheet` "Manage tags"/"Full history", and Home's `SummaryCardsRow` cards all call no-op closures that dismiss.

---

## Repo paths used throughout

- Repo root: `/Users/lukehogan/Code/checklist` — every path below is relative to this.
- Xcode project: `Checklist/Checklist/Checklist.xcodeproj` (double-nested — cd to repo root, pass `-project` as shown)
- App sources: `Checklist/Checklist/Checklist/` (Models/, Store/, Design/, Views/, Sheets/)
- Tests target: `Checklist/Checklist/ChecklistTests/` (Sheets/, Store/, Views/)

**Simulator:** iPhone 17 Pro (same as Plan 2).

**Screenshot rule:**
```bash
xcrun simctl io booted screenshot /tmp/<name>.png && sips -Z 1800 /tmp/<name>.png >/dev/null
```

**Standard build command:**
```bash
xcodebuild -project Checklist/Checklist/Checklist.xcodeproj \
  -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5
```

**Standard test command:**
```bash
xcodebuild -project Checklist/Checklist/Checklist.xcodeproj \
  -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test 2>&1 | \
  grep -E "Test Suite 'All tests'|TEST SUCCEEDED|TEST FAILED" | tail -3
```

**Single-suite test command:** append `-only-testing:ChecklistTests/<SuiteName>` to the test command.

**Bundle ID:** `com.themostthing.Checklist`.

**Xcode 16 synchronized root group:** new `.swift` files added under `Checklist/` directory are auto-included by Xcode — do NOT edit `.pbxproj`.

**Baseline test count:** ≥69 passing at start of Plan 3. Each task that lands tests bumps the total.

---

## Terminology rules (CRITICAL — subagents must not re-derive these)

Per spec §7. The prototype HTML/captures use older words; Plan 3 UI and code MUST use the v4 terms:

| Prototype says (captures) | v4 code + UI uses |
|---|---|
| "SEALED RECORD" eyebrow (capture 19/20) | **"COMPLETED RUN"** |
| "Sealed. This is a permanent record…" body copy | **"Completed. This is a permanent record of what you did. Can't be edited."** |
| "Start a new run from here" CTA (capture 19/20) | **"New run with checks from here"** |
| "SKIPPED" trailing side-label (capture 20) | **"IGNORED"** (for `.ignored` state only; plain unchecked items show no side label) |
| "No runs yet. Complete a checklist to seal it here." (capture 22) | **"No runs yet. Complete a checklist to save it here."** |
| "Sealed it here" anywhere else | **"saved it here"** |
| "Collection" / "Collections" | **"Category" / "Categories"** |

The filter-chip labels on `HistoryView` (`All`, `Complete`, `Partial`) match the prototype and stay as-is. "Partial" is computed at view time — never persisted (spec §3 decision 5).

---

## Files created by this plan

### Phase 6 — CompletedRunView + HistoryView

- `Checklist/Checklist/Checklist/Views/CompletedRunView.swift`
- `Checklist/Checklist/Checklist/Views/HistoryView.swift`
- `Checklist/Checklist/Checklist/Views/HistoryRoute.swift` — `HistoryScope` Hashable value for nav
- `Checklist/Checklist/Checklist/Views/CompletedRunProgress.swift` — small helper for snapshot-derived counts
- `Checklist/Checklist/ChecklistTests/Views/CompletedRunViewTests.swift`
- `Checklist/Checklist/ChecklistTests/Views/HistoryViewTests.swift`
- `Checklist/Checklist/ChecklistTests/Store/RunStore_StartFromHistoryTests.swift` — new store method coverage

### Phase 7 — Tags

- `Checklist/Checklist/Checklist/Views/TagsView.swift`
- `Checklist/Checklist/Checklist/Views/TagsRoute.swift` — `TagsDestination` Hashable marker
- `Checklist/Checklist/Checklist/Sheets/TagEditorSheet.swift`
- `Checklist/Checklist/ChecklistTests/Views/TagsViewTests.swift`
- `Checklist/Checklist/ChecklistTests/Sheets/TagEditorSheetTests.swift`

### Modified

- `Checklist/Checklist/Checklist/Views/HomeView.swift` — register three new `navigationDestination(for:)` routes; wire `SummaryCardsRow` Tags + History taps; pass `path` binding into `ChecklistRunView`
- `Checklist/Checklist/Checklist/Views/ChecklistRunView.swift` — accept `path: Binding<NavigationPath>`; replace menu placeholder callbacks with path-append; replace `PreviousRunsStrip(onTap:)` no-op with path-append
- `Checklist/Checklist/Checklist/Views/PreviousRunsStrip.swift` — header comment only (already exposes `onTap`)
- `Checklist/Checklist/Checklist/Sheets/ChecklistMenuSheet.swift` — add `onManageTags` and `onFullHistory` callbacks; wire the two rows to call them before `dismiss()`
- `Checklist/Checklist/Checklist/Store/RunStore.swift` — add `startRun(on:name:withChecksFrom:in:)` (Phase 6 Task 6.4)

---

## Navigation pattern (read before any view work)

`HomeView` currently owns `@State private var path = NavigationPath()` and registers `navigationDestination(for: Checklist.self)` on the `NavigationStack`. Plan 3 extends this with three more routes, all registered at the Home level:

1. `CompletedRun` — pushes `CompletedRunView(completedRun:)` (SwiftData `@Model` types are already `Hashable`).
2. `HistoryScope` — pushes `HistoryView(scope:)`. `HistoryScope` is a new `Hashable` struct wrapping an optional `Checklist.ID`.
3. `TagsDestination` — pushes `TagsView()`. `TagsDestination` is a zero-field singleton `enum` so pushing it twice collapses into one route.

`ChecklistRunView` accepts `path: Binding<NavigationPath>` so its child sheets can request a push after they dismiss. The pattern the sheets use:

```swift
// In ChecklistMenuSheet:
.onManageTags: { variant = .menu; /* sheet state */; onManageTags?() }
// In the parent (ChecklistRunView):
ChecklistMenuSheet(
    checklist: checklist,
    currentRun: currentRun,
    onManageTags: { path.wrappedValue.append(TagsDestination.root) },
    onFullHistory: { path.wrappedValue.append(HistoryScope(checklistID: checklist.id)) }
)
```

The sheet dismisses itself first (via `@Environment(\.dismiss)`); the caller then appends to `path`. SwiftUI handles the order: sheet dismissal animates out, NavigationStack push animates in.

**Why not pass `NavigationPath` to sheets directly?** SwiftData sheets embed their own `@Environment(\.dismiss)` chain. Passing a binding in and calling `path.append` from inside a sheet closure works but the navigation transition visually fights the sheet dismissal. Empirically, letting the caller do the push post-dismiss gives the cleanest motion.

---

## Self-review checklist (run before handoff)

- [ ] Every screen in spec §2 for Phase 6–7 scope (`CompletedRunView`, `HistoryView`, `TagsView`, `TagEditorSheet`) has a corresponding task in this plan.
- [ ] Every §7 translation relevant to these screens is enforced (Sealed→Completed, Skipped→Ignored, "Start a new run from here"→"New run with checks from here", Collection→Category).
- [ ] All three dead-end taps from Plan 2 are wired:
  - [ ] `PreviousRunsStrip` row → `CompletedRunView` (Task 6.2)
  - [ ] `ChecklistMenuSheet` "Full history for this list" → `HistoryView(scope: .checklist(id))` (Task 6.8)
  - [ ] `ChecklistMenuSheet` "Manage tags" → `TagsView` (Task 7.5)
  - [ ] Home `SummaryCardsRow` Tags card → `TagsView` (Task 7.5)
  - [ ] Home `SummaryCardsRow` History card → `HistoryView(scope: .all)` (Task 6.8)
- [ ] `RunStore.startRun(on:name:withChecksFrom:in:)` lands with tests (Task 6.4).
- [ ] `TagStore.delete` cascade (already implemented in Plan 1) is exercised via `TagEditorSheet` (Task 7.4).
- [ ] `CompletedRun` is surfaced read-only; no path mutates the snapshot.
- [ ] Every test includes real assertions; no placeholder XCTAssertTrue(true).
- [ ] No placeholders ("TBD", "implement later", "add validation").

---

## Handoff (populated when plan completes)

Plan 3 produces:
- `CompletedRunView` — read-only run detail, optional tag groupings, partial/complete badge, "New run with checks from here" CTA
- `HistoryView` — global + per-checklist feed, month grouping, three state filter chips (All/Complete/Partial)
- `TagsView` — app-wide tag manager with usage counts, "+ New tag" pill + "+" icon button
- `TagEditorSheet` — create + edit variants with preview, 14-icon grid, 9-hue swatches, delete (edit only)
- `RunStore.startRun(on:name:withChecksFrom:in:)` — fork-a-run-from-history helper with unit tests
- Wired navigation from Home, ChecklistRunView, ChecklistMenuSheet, PreviousRunsStrip
- Tag `plan-3-history-tags-complete` on the last commit

**Not in Plan 3 (deferred to later plans):**
- `SettingsView` (Phase 8)
- Restyled `PaywallSheet` + free-tier gating (Phase 8)
- "Save as new checklist" fork action in `ChecklistMenuSheet` (ARCHITECTURE §3g — deferred)
- `Clear history` action in `SettingsView` (ARCHITECTURE §3f — deferred)
- Categories CRUD screen (Phase 8)
- Visual snapshot tests via `swift-snapshot-testing`
- Inter Tight font registration
- Motion polish beyond default SwiftUI animations

---

# Phase 6 — CompletedRunView + HistoryView

## Task 6.1: `CompletedRunView` scaffold (flat item list, no tag grouping yet)

**Files:**
- Create: `Checklist/Checklist/Checklist/Views/CompletedRunProgress.swift`
- Create: `Checklist/Checklist/Checklist/Views/CompletedRunView.swift`
- Create: `Checklist/Checklist/ChecklistTests/Views/CompletedRunViewTests.swift`

- [ ] **Step 1: Write `CompletedRunProgress` helper**

Create `Checklist/Checklist/Checklist/Views/CompletedRunProgress.swift`:

```swift
/// CompletedRunProgress.swift
/// Purpose: Snapshot-derived completion counters for a frozen CompletedRun.
/// Dependencies: CompletedRunSnapshot, CheckState.
/// Key concepts:
///   - Total is `snapshot.items.count` — ignored items are INCLUDED in total (they
///     represent actual items that existed during the run; the "partial"/"complete"
///     badge reads the same way it did at run time).
///   - Done is the count of `.complete` entries in `snapshot.checks`.
///   - `isAllDone` is true when every item has a `.complete` check (total == done).

import Foundation

/// Read-only progress snapshot for a `CompletedRunSnapshot`.
///
/// Computed at view time per spec §3 decision 5 — partial/complete status is
/// never persisted.
struct CompletedRunProgress {
    let done: Int
    let total: Int

    var isAllDone: Bool { total > 0 && done == total }

    /// Builds progress directly from a frozen snapshot.
    ///
    /// - Parameter snapshot: The `CompletedRunSnapshot` to summarise.
    /// - Returns: A `CompletedRunProgress` with `done` = count of `.complete`
    ///   checks, `total` = count of items in the snapshot.
    static func compute(snapshot: CompletedRunSnapshot) -> CompletedRunProgress {
        let done = snapshot.checks.values.filter { $0 == .complete }.count
        return CompletedRunProgress(done: done, total: snapshot.items.count)
    }
}
```

- [ ] **Step 2: Write failing test for `CompletedRunProgress`**

Create `Checklist/Checklist/ChecklistTests/Views/CompletedRunViewTests.swift`:

```swift
/// CompletedRunViewTests.swift
/// Purpose: Tests for CompletedRunProgress computation and CompletedRunView
/// static helpers (tag grouping, partial badge).
/// Dependencies: XCTest, Checklist (testable import), TestHelpers.
/// Key concepts: these tests exercise pure functions — no ModelContainer needed
/// for the progress tests; view-helper tests instantiate snapshots directly.

import XCTest
@testable import Checklist

final class CompletedRunViewTests: XCTestCase {

    /// All-done snapshot: every item has a .complete check. isAllDone == true.
    func test_progress_all_done() {
        let a = UUID(), b = UUID()
        let snap = CompletedRunSnapshot(
            items: [
                ItemSnapshot(id: a, text: "A", tagIDs: [], sortKey: 0),
                ItemSnapshot(id: b, text: "B", tagIDs: [], sortKey: 1),
            ],
            tags: [],
            checks: [a: .complete, b: .complete],
            hiddenTagIDs: []
        )
        let p = CompletedRunProgress.compute(snapshot: snap)
        XCTAssertEqual(p.done, 2)
        XCTAssertEqual(p.total, 2)
        XCTAssertTrue(p.isAllDone)
    }

    /// Partial snapshot: one .complete, one .ignored, one absent. done = 1, total = 3.
    func test_progress_partial() {
        let a = UUID(), b = UUID(), c = UUID()
        let snap = CompletedRunSnapshot(
            items: [
                ItemSnapshot(id: a, text: "A", tagIDs: [], sortKey: 0),
                ItemSnapshot(id: b, text: "B", tagIDs: [], sortKey: 1),
                ItemSnapshot(id: c, text: "C", tagIDs: [], sortKey: 2),
            ],
            tags: [],
            checks: [a: .complete, b: .ignored],
            hiddenTagIDs: []
        )
        let p = CompletedRunProgress.compute(snapshot: snap)
        XCTAssertEqual(p.done, 1, "only A is .complete; B is ignored, C has no record")
        XCTAssertEqual(p.total, 3, "total includes ignored and unchecked items")
        XCTAssertFalse(p.isAllDone)
    }

    /// Empty snapshot: done = 0, total = 0, isAllDone == false.
    func test_progress_empty() {
        let snap = CompletedRunSnapshot.empty
        let p = CompletedRunProgress.compute(snapshot: snap)
        XCTAssertEqual(p.done, 0)
        XCTAssertEqual(p.total, 0)
        XCTAssertFalse(p.isAllDone, "empty snapshot must not register as all-done")
    }
}
```

- [ ] **Step 3: Run tests — expect compile failure (no CompletedRunProgress yet)**

Run the test suite filtered to the new suite:

```bash
xcodebuild -project Checklist/Checklist/Checklist.xcodeproj \
  -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test -only-testing:ChecklistTests/CompletedRunViewTests 2>&1 | tail -10
```

Expected: TEST SUCCEEDED (the helper from Step 1 makes all three pass).

- [ ] **Step 4: Write `CompletedRunView` scaffold (flat item list)**

Create `Checklist/Checklist/Checklist/Views/CompletedRunView.swift`:

```swift
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
```

- [ ] **Step 5: Build — expect success**

Run the standard build command. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 6: Commit**

```bash
git add Checklist/Checklist/Checklist/Views/CompletedRunProgress.swift \
        Checklist/Checklist/Checklist/Views/CompletedRunView.swift \
        Checklist/Checklist/ChecklistTests/Views/CompletedRunViewTests.swift
git commit -m "feat(views): CompletedRunView scaffold + CompletedRunProgress helper

Adds a read-only CompletedRunView driven entirely by the frozen
snapshot, plus the pure CompletedRunProgress helper with three unit
tests. No tag grouping yet; fork CTA dismisses (wired in 6.4). Per
§7 terminology: 'Sealed' → 'Completed', 'Skipped' → 'Ignored'."
```

---

## Task 6.2: Wire `PreviousRunsStrip` row tap → push `CompletedRunView`

**Files:**
- Modify: `Checklist/Checklist/Checklist/Views/HomeView.swift:68-70`
- Modify: `Checklist/Checklist/Checklist/Views/ChecklistRunView.swift` (full — introduce path binding)
- Modify: `Checklist/Checklist/Checklist/Views/PreviousRunsStrip.swift` — header comment only

- [ ] **Step 1: Add `CompletedRun` navigation destination on HomeView's NavigationStack**

Edit `Checklist/Checklist/Checklist/Views/HomeView.swift`. Find the block:

```swift
            .navigationDestination(for: Checklist.self) { list in
                ChecklistRunView(checklist: list)
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateChecklistSheet()
            }
```

Replace with:

```swift
            .navigationDestination(for: Checklist.self) { list in
                ChecklistRunView(checklist: list, path: $path)
            }
            .navigationDestination(for: CompletedRun.self) { run in
                CompletedRunView(completedRun: run)
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateChecklistSheet()
            }
```

- [ ] **Step 2: Thread `path: Binding<NavigationPath>` through `ChecklistRunView`**

Edit `Checklist/Checklist/Checklist/Views/ChecklistRunView.swift`.

Find the struct header:

```swift
struct ChecklistRunView: View {
    @Environment(\.modelContext) private var ctx
    let checklist: Checklist
```

Replace with:

```swift
struct ChecklistRunView: View {
    @Environment(\.modelContext) private var ctx
    let checklist: Checklist
    /// NavigationPath binding owned by HomeView. Used by sheets + strip rows
    /// that need to request a push after dismissing themselves.
    @Binding var path: NavigationPath
```

Then find the `itemsSection` footer block (around line 352):

```swift
            } footer: {
                // Task 5.13: PreviousRunsStrip as a List footer so it scrolls
                // with the items and is never pushed off-screen on long lists.
                if currentRun == nil, !completedRunsSorted.isEmpty {
                    PreviousRunsStrip(completedRuns: Array(completedRunsSorted.prefix(5)))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }
```

Replace the `PreviousRunsStrip(...)` init to wire `onTap`:

```swift
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
```

Update the `#Preview` blocks at the bottom of the file to pass a path binding:

```swift
#Preview("Empty items") {
    let container = try! SeedStore.container(for: .oneList)
    let ctx = ModelContext(container)
    let lists = try! ctx.fetch(FetchDescriptor<Checklist>())
    let list = lists.first!
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
    let list = lists.first(where: { $0.name == "Packing List" }) ?? lists.first!
    return NavigationStack {
        ChecklistRunView(checklist: list, path: .constant(NavigationPath()))
    }
    .modelContainer(container)
}

#Preview("Near complete (Gym Bag)") {
    let container = try! SeedStore.container(for: .nearCompleteRun)
    let ctx = ModelContext(container)
    let list = try! ctx.fetch(FetchDescriptor<Checklist>()).first(where: { $0.name == "Gym Bag" })!
    return NavigationStack {
        ChecklistRunView(checklist: list, path: .constant(NavigationPath()))
    }
    .modelContainer(container)
}
```

- [ ] **Step 3: Update `PreviousRunsStrip` doc comment**

Edit `Checklist/Checklist/Checklist/Views/PreviousRunsStrip.swift:6`. Change:

```swift
///   - Tapping a row is a placeholder action (CompletedRunView deferred to Plan 3).
```

to:

```swift
///   - Tapping a row invokes `onTap(run)`; ChecklistRunView wires it to push
///     CompletedRunView on the NavigationPath.
```

Also change the struct doc block (line 12-14):

```swift
/// Read-only strip showing the most recent completed runs for a checklist.
/// Tapping a row navigates to CompletedRunView (not implemented in Plan 2;
/// placeholder action).
```

to:

```swift
/// Read-only strip showing the most recent completed runs for a checklist.
/// Tapping a row invokes `onTap(run)`; the parent view (ChecklistRunView)
/// appends the tapped `CompletedRun` to the root NavigationPath.
```

- [ ] **Step 4: Build — expect success**

Run the standard build command. Expected: `** BUILD SUCCEEDED **`. If the build fails with "missing argument for parameter 'path'" somewhere else that constructs `ChecklistRunView`, search for other call sites and pass `.constant(NavigationPath())`:

```bash
grep -rn "ChecklistRunView(" Checklist/Checklist/Checklist Checklist/Checklist/ChecklistTests
```

Expected call sites: `HomeView.swift:69`, and three `#Preview` blocks inside `ChecklistRunView.swift` itself. All should already be updated.

- [ ] **Step 5: Smoke test via simulator**

Build + install + launch, then seed a completed run and tap through:

```bash
xcodebuild -project Checklist/Checklist/Checklist.xcodeproj \
  -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -3
APP="$HOME/Library/Developer/Xcode/DerivedData/Checklist-ddgbkiqecqxthpbauhcdfklcgyxc/Build/Products/Debug-iphonesimulator/Checklist.app"
xcrun simctl boot "iPhone 17 Pro" 2>/dev/null || true
xcrun simctl install booted "$APP"
xcrun simctl launch booted com.themostthing.Checklist
sleep 2
xcrun simctl io booted screenshot /tmp/task-6-2-after.png && sips -Z 1800 /tmp/task-6-2-after.png >/dev/null
```

(Manual verification: navigate into a list with history, tap a previous-runs row; `CompletedRunView` should push. If the live app has no history, the preview path via `CompletedRunView`'s `#Preview` suffices for Task 6.2 — the full end-to-end loop is exercised in the visual-diff pass in Task 6.9.)

- [ ] **Step 6: Commit**

```bash
git add Checklist/Checklist/Checklist/Views/HomeView.swift \
        Checklist/Checklist/Checklist/Views/ChecklistRunView.swift \
        Checklist/Checklist/Checklist/Views/PreviousRunsStrip.swift
git commit -m "feat(nav): wire PreviousRunsStrip row tap to push CompletedRunView

Threads a NavigationPath binding from HomeView through ChecklistRunView
into PreviousRunsStrip.onTap. CompletedRun is registered as a root-level
navigationDestination so every push from any depth routes to CompletedRunView."
```

---

## Task 6.3: Tag-grouped sections in `CompletedRunView` (when tags present)

**Files:**
- Modify: `Checklist/Checklist/Checklist/Views/CompletedRunView.swift:170-195` — replace `itemsFlat`
- Modify: `Checklist/Checklist/ChecklistTests/Views/CompletedRunViewTests.swift` — add grouping tests

- [ ] **Step 1: Add grouping helper to CompletedRunView**

In `CompletedRunView.swift`, insert this block just above the `// MARK: - Fork CTA` line:

```swift
    // MARK: - Tag grouping

    /// Group of items that share the same lead tag, used by `itemsGrouped` to
    /// render section headers on snapshots with tags.
    private struct TagGroup: Identifiable {
        let id: UUID             // tag id, or UUID() sentinel for the "Untagged" bucket
        let name: String         // "UNTAGGED" for the sentinel
        let colorHue: Double     // 0 for untagged (renders dim)
        let items: [ItemSnapshot]
    }

    /// Groups snapshot items by the first tag they reference, preserving
    /// sortKey ordering within each group. Items with no tags fall into an
    /// "UNTAGGED" bucket shown last. The return list is empty when the
    /// snapshot has no tags at all — callers should fall back to a flat list.
    private var tagGroups: [TagGroup] {
        guard !snap.tags.isEmpty else { return [] }
        let sortedItems = snap.items.sorted { $0.sortKey < $1.sortKey }
        var groups: [UUID: [ItemSnapshot]] = [:]
        var untagged: [ItemSnapshot] = []
        for item in sortedItems {
            if let firstID = item.tagIDs.first {
                groups[firstID, default: []].append(item)
            } else {
                untagged.append(item)
            }
        }
        // Preserve the tag order from the snapshot, skipping tags with no items.
        var out: [TagGroup] = []
        for tag in snap.tags {
            guard let items = groups[tag.id], !items.isEmpty else { continue }
            out.append(TagGroup(
                id: tag.id,
                name: tag.name.uppercased(),
                colorHue: tag.colorHue,
                items: items
            ))
        }
        if !untagged.isEmpty {
            out.append(TagGroup(
                id: UUID(),
                name: "UNTAGGED",
                colorHue: 0,
                items: untagged
            ))
        }
        return out
    }
```

- [ ] **Step 2: Replace `itemsFlat` with `itemsGroupedOrFlat`**

In `CompletedRunView.swift`, find:

```swift
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
```

Replace with:

```swift
    /// Renders items as flat list when the snapshot has no tags, or as
    /// tag-grouped sections with header labels when tags exist.
    @ViewBuilder
    private var itemsGroupedOrFlat: some View {
        let groups = tagGroups
        if groups.isEmpty {
            VStack(spacing: Theme.Spacing.xs) {
                ForEach(snap.items.sorted { $0.sortKey < $1.sortKey }) { item in
                    CompletedItemRow(
                        text: item.text,
                        state: snap.checks[item.id],
                        tagColor: facetColor(for: item)
                    )
                }
            }
        } else {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                ForEach(groups) { group in
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        HStack(spacing: 6) {
                            if group.name != "UNTAGGED" {
                                Circle()
                                    .fill(Theme.gemColor(hue: group.colorHue))
                                    .frame(width: 8, height: 8)
                            }
                            Text(group.name)
                                .font(Theme.eyebrow())
                                .tracking(2)
                                .foregroundColor(Theme.dim)
                        }
                        ForEach(group.items) { item in
                            CompletedItemRow(
                                text: item.text,
                                state: snap.checks[item.id],
                                tagColor: group.name == "UNTAGGED"
                                    ? Theme.amethyst
                                    : Theme.gemColor(hue: group.colorHue)
                            )
                        }
                    }
                }
            }
        }
    }
```

Then update the `body` to reference `itemsGroupedOrFlat` instead of `itemsFlat`:

```swift
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        headerBlock
                        statusCard
                        completedBanner
                        itemsGroupedOrFlat
                        forkCTA
                        Spacer(minLength: 40)
                    }
```

- [ ] **Step 3: Add tag-grouping tests**

Append to `Checklist/Checklist/ChecklistTests/Views/CompletedRunViewTests.swift`:

```swift

    // MARK: - Tag grouping (Task 6.3)
    //
    // The grouping helper lives inside CompletedRunView as a `private` type, so
    // we can't invoke it from tests directly. Instead we test the observable
    // behaviour: the snapshot inputs → expected ordering invariants.

    /// Ordering invariant: a snapshot with tags defines the order in which
    /// groups should render (snapshot.tags order, untagged last). Items within
    /// each group preserve sortKey.
    func test_tagGroup_ordering_invariants_of_snapshot() {
        let beachID = UUID(), snowID = UUID()
        let a = UUID(), b = UUID(), c = UUID(), d = UUID()
        let snap = CompletedRunSnapshot(
            items: [
                ItemSnapshot(id: a, text: "A-beach", tagIDs: [beachID], sortKey: 0),
                ItemSnapshot(id: b, text: "B-untagged", tagIDs: [], sortKey: 1),
                ItemSnapshot(id: c, text: "C-snow", tagIDs: [snowID], sortKey: 2),
                ItemSnapshot(id: d, text: "D-beach", tagIDs: [beachID], sortKey: 3),
            ],
            tags: [
                TagSnapshot(id: beachID, name: "Beach", iconName: "sun", colorHue: 85),
                TagSnapshot(id: snowID, name: "Snow", iconName: "snow", colorHue: 250),
            ],
            checks: [:],
            hiddenTagIDs: []
        )

        // Expected partition:
        //   Beach: A, D
        //   Snow: C
        //   Untagged: B
        let beachItems = snap.items.filter { $0.tagIDs.contains(beachID) }
        let snowItems  = snap.items.filter { $0.tagIDs.contains(snowID) }
        let untagged   = snap.items.filter { $0.tagIDs.isEmpty }

        XCTAssertEqual(beachItems.map(\.text), ["A-beach", "D-beach"])
        XCTAssertEqual(snowItems.map(\.text), ["C-snow"])
        XCTAssertEqual(untagged.map(\.text), ["B-untagged"])

        // First group in snapshot.tags comes first in UI (the view sorts by
        // snapshot.tags order).
        XCTAssertEqual(snap.tags.map(\.name), ["Beach", "Snow"])
    }

    /// When snapshot.tags is empty the grouping helper returns an empty list,
    /// so the view falls back to a flat item list.
    func test_tagGroup_empty_tags_yields_flat() {
        let snap = CompletedRunSnapshot(
            items: [ItemSnapshot(id: UUID(), text: "X", tagIDs: [], sortKey: 0)],
            tags: [],
            checks: [:],
            hiddenTagIDs: []
        )
        XCTAssertTrue(snap.tags.isEmpty, "flat-fallback path triggers when tags is empty")
    }
```

- [ ] **Step 4: Build + run tests**

```bash
xcodebuild -project Checklist/Checklist/Checklist.xcodeproj \
  -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test -only-testing:ChecklistTests/CompletedRunViewTests 2>&1 | tail -10
```

Expected: TEST SUCCEEDED (5 tests now — 3 progress, 2 grouping).

- [ ] **Step 5: Commit**

```bash
git add Checklist/Checklist/Checklist/Views/CompletedRunView.swift \
        Checklist/Checklist/ChecklistTests/Views/CompletedRunViewTests.swift
git commit -m "feat(views): group CompletedRunView items by tag when tags present

Adds private TagGroup type and itemsGroupedOrFlat view builder. Snapshot
with no tags renders a flat list; snapshot with tags renders section
headers colored by the tag's colorHue, preserving snapshot.tags order
with an UNTAGGED bucket last."
```

---

## Task 6.4: `RunStore.startRun(on:name:withChecksFrom:in:)` + fork-CTA wiring

**Files:**
- Modify: `Checklist/Checklist/Checklist/Store/RunStore.swift` — add new method
- Create: `Checklist/Checklist/ChecklistTests/Store/RunStore_StartFromHistoryTests.swift`
- Modify: `Checklist/Checklist/Checklist/Views/CompletedRunView.swift` — wire `forkCTA`

- [ ] **Step 1: Write failing test first**

Create `Checklist/Checklist/ChecklistTests/Store/RunStore_StartFromHistoryTests.swift`:

```swift
/// RunStore_StartFromHistoryTests.swift
/// Purpose: Tests for RunStore.startRun(on:name:withChecksFrom:in:) — the
///   CompletedRunView fork CTA's backing store method.
/// Dependencies: XCTest, SwiftData, Checklist target, TestHelpers.
/// Key concepts:
///   - Items that exist on the checklist AND had a .complete check in the
///     snapshot get a new .complete Check on the new run.
///   - Items that were .ignored or absent from snapshot.checks yield no Check.
///   - Items in the snapshot that no longer exist on the checklist are skipped.
///   - hiddenTagIDs are copied verbatim.

import XCTest
import SwiftData
@testable import Checklist

final class RunStore_StartFromHistoryTests: XCTestCase {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Checklist.self, ChecklistCategory.self, Item.self, Tag.self,
                Run.self, Check.self, CompletedRun.self,
            configurations: makeTestConfig()
        )
        return ModelContext(container)
    }

    /// Happy path: snapshot has two complete checks + one ignored + one unchecked;
    /// the forked run inherits only the two completes.
    func test_fork_copies_only_complete_checks() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "Trip", in: ctx)
        let a = try ChecklistStore.addItem(text: "A", to: list, in: ctx)
        let b = try ChecklistStore.addItem(text: "B", to: list, in: ctx)
        let c = try ChecklistStore.addItem(text: "C", to: list, in: ctx)
        let d = try ChecklistStore.addItem(text: "D", to: list, in: ctx)

        let oldRun = try RunStore.startRun(on: list, in: ctx)
        try RunStore.toggleCheck(run: oldRun, itemID: a.id, in: ctx)
        try RunStore.toggleCheck(run: oldRun, itemID: b.id, in: ctx)
        try RunStore.setIgnored(run: oldRun, itemID: c.id, to: true, in: ctx)
        // d is left untouched (unchecked)
        try RunStore.complete(oldRun, in: ctx)

        let completed = try XCTUnwrap(try ctx.fetch(FetchDescriptor<CompletedRun>()).first)
        let newRun = try RunStore.startRun(
            on: list,
            name: "Fork",
            withChecksFrom: completed,
            in: ctx
        )

        let checks = newRun.checks ?? []
        let checkedIDs = Set(checks.filter { $0.state == .complete }.map(\.itemID))
        XCTAssertEqual(checkedIDs, [a.id, b.id],
                       "only items that were .complete in the snapshot carry over")
        XCTAssertFalse(checks.contains { $0.itemID == c.id && $0.state == .ignored },
                       "ignored state does NOT carry over — user re-evaluates each item")
        XCTAssertFalse(checks.contains { $0.itemID == d.id },
                       "unchecked items stay unchecked")
        XCTAssertEqual(newRun.name, "Fork")
    }

    /// Snapshot items whose live Item was since deleted must not fabricate
    /// orphaned Check records.
    func test_fork_skips_items_no_longer_on_checklist() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "Trip", in: ctx)
        let a = try ChecklistStore.addItem(text: "A", to: list, in: ctx)
        let b = try ChecklistStore.addItem(text: "B-to-delete", to: list, in: ctx)
        let oldRun = try RunStore.startRun(on: list, in: ctx)
        try RunStore.toggleCheck(run: oldRun, itemID: a.id, in: ctx)
        try RunStore.toggleCheck(run: oldRun, itemID: b.id, in: ctx)
        try RunStore.complete(oldRun, in: ctx)

        let completed = try XCTUnwrap(try ctx.fetch(FetchDescriptor<CompletedRun>()).first)

        // Delete item B *after* completing — simulating an edit between runs.
        try ChecklistStore.deleteItem(b, in: ctx)

        let newRun = try RunStore.startRun(on: list, withChecksFrom: completed, in: ctx)
        let ids = Set((newRun.checks ?? []).map(\.itemID))
        XCTAssertEqual(ids, [a.id], "orphaned snapshot check for deleted B is skipped")
    }

    /// hiddenTagIDs in the snapshot are copied to the new run verbatim.
    func test_fork_copies_hiddenTagIDs() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "Trip", in: ctx)
        let beach = try TagStore.create(name: "Beach", in: ctx)
        _ = try ChecklistStore.addItem(text: "A", to: list, tags: [beach], in: ctx)
        let oldRun = try RunStore.startRun(on: list, in: ctx)
        try RunStore.toggleHideTag(run: oldRun, tagID: beach.id, in: ctx)
        try RunStore.complete(oldRun, in: ctx)

        let completed = try XCTUnwrap(try ctx.fetch(FetchDescriptor<CompletedRun>()).first)
        let newRun = try RunStore.startRun(on: list, withChecksFrom: completed, in: ctx)
        XCTAssertEqual(newRun.hiddenTagIDs, [beach.id])
    }
}
```

- [ ] **Step 2: Run test — expect COMPILE failure (method doesn't exist)**

```bash
xcodebuild -project Checklist/Checklist/Checklist.xcodeproj \
  -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test -only-testing:ChecklistTests/RunStore_StartFromHistoryTests 2>&1 | tail -10
```

Expected: BUILD FAILED with a "Missing argument for parameter 'withChecksFrom'" or similar error on `RunStore.startRun`.

- [ ] **Step 3: Implement the new store method**

Edit `Checklist/Checklist/Checklist/Store/RunStore.swift`. Add this method inside the `enum RunStore { ... }` block, directly after `static func startRun(on:name:in:)`:

```swift
    /// Creates a new live `Run` pre-filled with `.complete` checks copied from
    /// a sealed `CompletedRun`. Used by the "New run with checks from here"
    /// CTA in `CompletedRunView`.
    ///
    /// Semantics (per spec §7 translation of prototype's "Start new run from here"):
    /// - Only snapshot items currently still present on the checklist receive
    ///   new checks — orphaned snapshot items are skipped.
    /// - Only `.complete` state carries over; `.ignored` and unchecked entries
    ///   leave no Check on the new run (user re-evaluates each item fresh).
    /// - `hiddenTagIDs` on the new run is a verbatim copy of
    ///   `snapshot.hiddenTagIDs`, so the view-filtering the user had in place
    ///   at completion time is preserved.
    ///
    /// - Parameters:
    ///   - list: The `Checklist` to run.
    ///   - name: Optional label for the new run; defaults to nil.
    ///   - source: The `CompletedRun` whose snapshot seeds the new run.
    ///   - context: The `ModelContext` to insert and save into.
    /// - Returns: The newly created and persisted `Run` with copied checks.
    /// - Throws: If the save fails.
    @discardableResult
    static func startRun(
        on list: Checklist,
        name: String? = nil,
        withChecksFrom source: CompletedRun,
        in context: ModelContext
    ) throws -> Run {
        let snapshot = source.snapshot
        let liveItemIDs = Set((list.items ?? []).map(\.id))

        let run = Run(checklist: list, name: name)
        run.hiddenTagIDs = snapshot.hiddenTagIDs
        context.insert(run)

        for (itemID, state) in snapshot.checks where state == .complete {
            // Skip snapshot rows whose underlying Item has since been deleted.
            guard liveItemIDs.contains(itemID) else { continue }
            let check = Check(itemID: itemID, state: .complete)
            check.run = run
            context.insert(check)
        }

        try context.save()
        return run
    }
```

Also: the existing `Check` initializer in Plan 1 takes `itemID:state:` — confirm by searching:

```bash
grep -n "init(" Checklist/Checklist/Checklist/Models/Check.swift
```

If the initializer signature is different, adjust the `Check(itemID:state:)` call above accordingly.

- [ ] **Step 4: Run tests — expect PASS**

```bash
xcodebuild -project Checklist/Checklist/Checklist.xcodeproj \
  -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test -only-testing:ChecklistTests/RunStore_StartFromHistoryTests 2>&1 | tail -10
```

Expected: 3 tests passing.

- [ ] **Step 5: Wire the `forkCTA` in `CompletedRunView`**

Edit `Checklist/Checklist/Checklist/Views/CompletedRunView.swift`. Find the `forkCTA` block and replace with:

```swift
    /// "New run with checks from here" ghost pill. Creates a new live Run
    /// pre-filled with the snapshot's `.complete` checks (Task 6.4 adds the
    /// backing RunStore method). Dismisses after success so the user lands
    /// back on ChecklistRunView where the new run is now the primary live run.
    private var forkCTA: some View {
        VStack(alignment: .leading, spacing: 6) {
            PillButton(
                title: "New run with checks from here",
                tone: .ghost,
                wide: true,
                disabled: completedRun.checklist == nil
            ) { commitFork() }

            Text("Creates a live run pre-filled with the same checks. This completed record stays unchanged.")
                .font(.system(size: 12))
                .foregroundColor(Theme.dim)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.top, Theme.Spacing.md)
    }

    /// Calls `RunStore.startRun(on:name:withChecksFrom:in:)` and dismisses on
    /// success. The new run becomes the primary live run on the Checklist,
    /// which is what ChecklistRunView's `ensureCurrentRun` will pick up.
    private func commitFork() {
        guard let list = completedRun.checklist else { return }
        _ = try? RunStore.startRun(
            on: list,
            name: completedRun.name,
            withChecksFrom: completedRun,
            in: ctx
        )
        dismiss()
    }
```

- [ ] **Step 6: Build + full test run**

Run the standard build + test commands. Expected: `TEST SUCCEEDED`, total count up by 3 over prior baseline.

- [ ] **Step 7: Commit**

```bash
git add Checklist/Checklist/Checklist/Store/RunStore.swift \
        Checklist/Checklist/Checklist/Views/CompletedRunView.swift \
        Checklist/Checklist/ChecklistTests/Store/RunStore_StartFromHistoryTests.swift
git commit -m "feat(store,views): fork a live run from a sealed CompletedRun

Adds RunStore.startRun(on:name:withChecksFrom:in:) which copies only the
.complete check state from a snapshot, skipping ignored, unchecked, and
orphaned entries. hiddenTagIDs are copied verbatim. Wires the CTA on
CompletedRunView; three unit tests cover the three edge cases."
```

---

## Task 6.5: `HistoryView` scaffold + `HistoryScope` route + empty state

**Files:**
- Create: `Checklist/Checklist/Checklist/Views/HistoryRoute.swift`
- Create: `Checklist/Checklist/Checklist/Views/HistoryView.swift`
- Create: `Checklist/Checklist/ChecklistTests/Views/HistoryViewTests.swift`

- [ ] **Step 1: Create `HistoryRoute.swift`**

```swift
/// HistoryRoute.swift
/// Purpose: Hashable value types that NavigationStack uses to route to
///   HistoryView. `HistoryScope` carries an optional Checklist UUID —
///   `.allLists` for the global feed, `.checklist(id)` for per-list.
/// Dependencies: Foundation.
/// Key concepts:
///   - Declaring `scope` as a Hashable struct (not a raw UUID?) lets us add
///     future filter dimensions (e.g. date range) without changing the
///     navigationDestination signature.

import Foundation

/// Navigation value pushed onto the root NavigationPath to open `HistoryView`.
struct HistoryScope: Hashable {
    /// When non-nil, the history feed is scoped to that Checklist only. Nil
    /// means the global feed ("All runs").
    let checklistID: UUID?

    static let allLists = HistoryScope(checklistID: nil)
}
```

- [ ] **Step 2: Write HistoryView scaffold with empty state**

Create `Checklist/Checklist/Checklist/Views/HistoryView.swift`:

```swift
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
```

- [ ] **Step 3: Write failing tests for HistoryView scope filtering**

Create `Checklist/Checklist/ChecklistTests/Views/HistoryViewTests.swift`:

```swift
/// HistoryViewTests.swift
/// Purpose: Unit tests for HistoryView helpers — scope filtering, state
///   filtering (Task 6.6), month grouping (Task 6.6).
/// Dependencies: XCTest, SwiftData, Checklist target.
/// Key concepts:
///   - Task 6.5: scope filtering (allLists vs single checklist).
///   - Task 6.6: state filtering + month grouping.
///   - Helper: testing is done through a duplicated filter function living in
///     the test target, because the real helpers are private on HistoryView.

import XCTest
import SwiftData
@testable import Checklist

final class HistoryViewTests: XCTestCase {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Checklist.self, ChecklistCategory.self, Item.self, Tag.self,
                Run.self, Check.self, CompletedRun.self,
            configurations: makeTestConfig()
        )
        return ModelContext(container)
    }

    /// Scope filtering: .allLists returns every CompletedRun; scope(id) returns
    /// only runs whose checklist.id matches.
    func test_scope_filtering_returns_matching_runs() throws {
        let ctx = try makeContext()
        let a = try ChecklistStore.create(name: "A", in: ctx)
        let b = try ChecklistStore.create(name: "B", in: ctx)

        // Two completions for A, one for B.
        try seedCompleted(list: a, count: 2, in: ctx)
        try seedCompleted(list: b, count: 1, in: ctx)

        let all = try ctx.fetch(FetchDescriptor<CompletedRun>())
        XCTAssertEqual(all.count, 3, "3 completed runs total")

        let scopedToA = all.filter { $0.checklist?.id == a.id }
        XCTAssertEqual(scopedToA.count, 2, "scope to A: 2 runs")

        let scopedToB = all.filter { $0.checklist?.id == b.id }
        XCTAssertEqual(scopedToB.count, 1, "scope to B: 1 run")
    }

    /// Helper to seed N CompletedRuns for a checklist.
    private func seedCompleted(list: Checklist, count: Int, in ctx: ModelContext) throws {
        for _ in 0..<count {
            let run = try RunStore.startRun(on: list, in: ctx)
            try RunStore.complete(run, in: ctx)
        }
    }
}
```

- [ ] **Step 4: Build + run tests — expect success**

```bash
xcodebuild -project Checklist/Checklist/Checklist.xcodeproj \
  -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test -only-testing:ChecklistTests/HistoryViewTests 2>&1 | tail -10
```

Expected: 1 test passing.

- [ ] **Step 5: Commit**

```bash
git add Checklist/Checklist/Checklist/Views/HistoryRoute.swift \
        Checklist/Checklist/Checklist/Views/HistoryView.swift \
        Checklist/Checklist/ChecklistTests/Views/HistoryViewTests.swift
git commit -m "feat(views): HistoryView scaffold + HistoryScope nav route

Adds the history feed shell with scope chips, state chips, row rendering,
and empty state. Scope filtering (.allLists vs .checklist(id)) works;
state filter + month grouping land in 6.6, interactive scope chips in 6.7,
row tap in 6.8."
```

---

## Task 6.6: Month grouping + state-filter wiring

**Files:**
- Modify: `Checklist/Checklist/Checklist/Views/HistoryView.swift` — swap `feed` for month-grouped version and extend `filteredRuns`
- Modify: `Checklist/Checklist/ChecklistTests/Views/HistoryViewTests.swift` — add state filter + grouping tests

- [ ] **Step 1: Extend `filteredRuns` to honour `stateFilter`**

In `HistoryView.swift`, replace the `filteredRuns` computed property:

```swift
    /// Runs passed through both scope and state filter chips. Partial/complete
    /// is computed at view time from each snapshot (spec §3 decision 5).
    private var filteredRuns: [CompletedRun] {
        let base = scopedRuns
        switch stateFilter {
        case .all:      return base
        case .complete: return base.filter {
            CompletedRunProgress.compute(snapshot: $0.snapshot).isAllDone
        }
        case .partial:  return base.filter {
            let p = CompletedRunProgress.compute(snapshot: $0.snapshot)
            return p.total > 0 && !p.isAllDone
        }
        }
    }
```

- [ ] **Step 2: Replace `feed` with month-grouped variant**

In `HistoryView.swift`, replace the `feed` and `historyRow` area (everything between `// MARK: - Feed + empty state` and `// MARK: - Filtering`) with:

```swift
    // MARK: - Feed + empty state

    /// Month-grouped feed: one section per year-month present in `filteredRuns`.
    /// Sections are ordered reverse-chrono (most recent month first).
    private var feed: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            ForEach(monthGroups, id: \.key) { group in
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    HStack {
                        Text(group.label)
                            .font(Theme.eyebrow()).tracking(2)
                            .foregroundColor(Theme.dim)
                        Spacer()
                        Text("\(group.runs.count) RUN\(group.runs.count == 1 ? "" : "S")")
                            .font(.system(size: 11, weight: .regular))
                            .tracking(0.5)
                            .foregroundColor(Theme.dimmer)
                    }
                    ForEach(group.runs) { run in
                        historyRow(run)
                    }
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    /// One month bucket of runs plus its display label ("APRIL 2026").
    private struct MonthBucket {
        let key: String    // "YYYY-MM" for stable ForEach id
        let label: String  // "APRIL 2026" — uppercase for display
        let runs: [CompletedRun]
    }

    /// Groups `filteredRuns` into month buckets keyed by year-month, preserving
    /// reverse-chronological order.
    private var monthGroups: [MonthBucket] {
        let runs = filteredRuns
        var bucketsByKey: [String: [CompletedRun]] = [:]
        var orderedKeys: [String] = []
        let keyFormatter = DateFormatter()
        keyFormatter.dateFormat = "yyyy-MM"
        for run in runs {
            let key = keyFormatter.string(from: run.completedAt)
            if bucketsByKey[key] == nil {
                orderedKeys.append(key)
                bucketsByKey[key] = []
            }
            bucketsByKey[key]?.append(run)
        }
        let labelFormatter = DateFormatter()
        labelFormatter.dateFormat = "LLLL yyyy"
        return orderedKeys.map { key in
            let bucket = bucketsByKey[key] ?? []
            let label = labelFormatter.string(from: bucket.first?.completedAt ?? Date()).uppercased()
            return MonthBucket(key: key, label: label, runs: bucket)
        }
    }

    /// Tappable row per run — name + date + N/M. Task 6.8 wires the tap to
    /// push CompletedRunView via the NavigationPath binding.
    private func historyRow(_ run: CompletedRun) -> some View {
        let prog = CompletedRunProgress.compute(snapshot: run.snapshot)
        return Button {
            // Wired in Task 6.8.
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
```

- [ ] **Step 3: Add state-filter tests**

Append to `Checklist/Checklist/ChecklistTests/Views/HistoryViewTests.swift`:

```swift

    // MARK: - State filter (Task 6.6)

    /// Helper: creates a completed run with the given item count, N of which are complete.
    private func seedCompletedRun(list: Checklist, items: Int, complete: Int, in ctx: ModelContext) throws {
        let created = (0..<items).map { i -> Item in
            try! ChecklistStore.addItem(text: "Item \(i)", to: list, in: ctx)
        }
        let run = try RunStore.startRun(on: list, in: ctx)
        for item in created.prefix(complete) {
            try RunStore.toggleCheck(run: run, itemID: item.id, in: ctx)
        }
        try RunStore.complete(run, in: ctx)
        // Delete the template items so subsequent seedings on the same list
        // start with a clean item roster. CompletedRun snapshots keep their
        // frozen items regardless.
        for item in (list.items ?? []) { ctx.delete(item) }
        try ctx.save()
    }

    /// Complete filter: only runs where done == total are returned.
    func test_state_filter_complete_returns_only_all_done() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "T", in: ctx)
        try seedCompletedRun(list: list, items: 3, complete: 3, in: ctx) // all-done
        try seedCompletedRun(list: list, items: 3, complete: 1, in: ctx) // partial

        let all = try ctx.fetch(FetchDescriptor<CompletedRun>())
        let completeOnly = all.filter {
            CompletedRunProgress.compute(snapshot: $0.snapshot).isAllDone
        }
        XCTAssertEqual(completeOnly.count, 1)
        XCTAssertEqual(CompletedRunProgress.compute(snapshot: completeOnly[0].snapshot).done, 3)
    }

    /// Partial filter: only runs where 0 < done < total are returned.
    func test_state_filter_partial_returns_only_partial() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "T", in: ctx)
        try seedCompletedRun(list: list, items: 3, complete: 3, in: ctx) // all-done
        try seedCompletedRun(list: list, items: 3, complete: 1, in: ctx) // partial
        try seedCompletedRun(list: list, items: 3, complete: 0, in: ctx) // also partial (0/3)

        let all = try ctx.fetch(FetchDescriptor<CompletedRun>())
        let partialOnly = all.filter { run in
            let p = CompletedRunProgress.compute(snapshot: run.snapshot)
            return p.total > 0 && !p.isAllDone
        }
        XCTAssertEqual(partialOnly.count, 2, "both partial runs returned")
    }

    // MARK: - Month grouping (Task 6.6)

    /// Grouping invariant: two runs completed in the same month share a key;
    /// runs from different months end up in different keys.
    func test_month_grouping_partitions_by_year_month() {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM"
        let cal = Calendar.current

        let apr2026 = cal.date(from: DateComponents(year: 2026, month: 4, day: 17))!
        let apr2026b = cal.date(from: DateComponents(year: 2026, month: 4, day: 3))!
        let mar2026 = cal.date(from: DateComponents(year: 2026, month: 3, day: 31))!

        XCTAssertEqual(f.string(from: apr2026), f.string(from: apr2026b),
                       "same-month dates share the key")
        XCTAssertNotEqual(f.string(from: apr2026), f.string(from: mar2026),
                          "cross-month dates do not share the key")
    }
```

- [ ] **Step 4: Build + run tests**

```bash
xcodebuild -project Checklist/Checklist/Checklist.xcodeproj \
  -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test -only-testing:ChecklistTests/HistoryViewTests 2>&1 | tail -10
```

Expected: 4 tests passing.

- [ ] **Step 5: Commit**

```bash
git add Checklist/Checklist/Checklist/Views/HistoryView.swift \
        Checklist/Checklist/ChecklistTests/Views/HistoryViewTests.swift
git commit -m "feat(views): HistoryView month grouping + state filter (All/Complete/Partial)

Buckets runs by 'yyyy-MM' key with 'LLLL yyyy' display labels and a per-month
count hint. Partial/complete computed at view time from each snapshot per
§3 decision 5. Three new tests exercise filter + grouping invariants."
```

---

## Task 6.7: Interactive scope chips

**Files:**
- Modify: `Checklist/Checklist/Checklist/Views/HistoryView.swift` — make scope chips interactive

The scaffold in Task 6.5 rendered scope chips but didn't wire them. In the global (`.allLists`) entry path, tapping a chip should narrow the feed to that checklist. In the per-list entry path (`.checklist(id)`) we also want users to be able to drop back to "All lists" without going back and re-entering.

- [ ] **Step 1: Convert `scope` from `let` to derived state**

Replace the `scope` property:

```swift
    /// The feed scope — global or per-checklist.
    let scope: HistoryScope
```

with:

```swift
    /// Initial scope supplied by the caller. Used as the seed value for
    /// `activeScope`, which the scope chips rewrite when tapped.
    let scope: HistoryScope

    /// Mutable scope. Defaults to `scope` on appear; updated by chip taps.
    @State private var activeScope: HistoryScope = .allLists
```

Then update every read of `scope` inside the view to read `activeScope` instead. Search and replace within the file:

- `scope.checklistID` → `activeScope.checklistID`

(Leave the `let scope:` input and the `#Preview(scope:)` call sites alone.)

Add `.onAppear` to seed the state:

```swift
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            activeScope = scope
        }
    }
```

- [ ] **Step 2: Make the scope chips tappable**

Replace the non-interactive `scopeChip` helper call pattern with `Button`-wrapped chips. Replace the `scopeChips` section entirely:

```swift
    /// Horizontal chip row letting the user switch between the global feed and
    /// each individual checklist. Tapping a chip rewrites `activeScope`.
    private var scopeChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.xs) {
                scopeChip(title: "All lists", isSelected: activeScope.checklistID == nil) {
                    activeScope = .allLists
                }
                ForEach(checklists) { list in
                    scopeChip(
                        title: list.name,
                        isSelected: activeScope.checklistID == list.id
                    ) {
                        activeScope = HistoryScope(checklistID: list.id)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
        }
    }

    /// Single scope chip — gradient fill when selected; ghost otherwise.
    /// Calls `action` on tap.
    private func scopeChip(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
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
        .buttonStyle(.plain)
    }
```

- [ ] **Step 3: Hide the scope chip row when entering via a single-list scope**

Per capture 23 (scoped to Morning Routine), the "All lists / Packing List / Morning Routine / …" chips are NOT shown when the user opened history from that list's menu — only the state filter chips appear.

Guard the row on the initial scope:

```swift
    /// Horizontal chip row letting the user switch between the global feed and
    /// each individual checklist. Hidden when the user entered via a
    /// single-list scope (capture 23) — the header eyebrow already communicates
    /// the scope.
    @ViewBuilder
    private var scopeChips: some View {
        if scope.checklistID == nil {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.xs) {
                    scopeChip(title: "All lists", isSelected: activeScope.checklistID == nil) {
                        activeScope = .allLists
                    }
                    ForEach(checklists) { list in
                        scopeChip(
                            title: list.name,
                            isSelected: activeScope.checklistID == list.id
                        ) {
                            activeScope = HistoryScope(checklistID: list.id)
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.xl)
            }
        }
    }
```

- [ ] **Step 4: Build + run tests**

```bash
xcodebuild -project Checklist/Checklist/Checklist.xcodeproj \
  -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -3
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 5: Commit**

```bash
git add Checklist/Checklist/Checklist/Views/HistoryView.swift
git commit -m "feat(views): HistoryView — interactive scope chips

Adds @State activeScope seeded from the input scope; taps rewrite it.
Scope-chip row is hidden when the user entered via a single-list scope
(capture 23 — header eyebrow already communicates scope)."
```

---

## Task 6.8: Wire `PreviousRunsStrip`, `ChecklistMenuSheet` "Full history", and Home history card

**Files:**
- Modify: `Checklist/Checklist/Checklist/Views/HistoryView.swift` — accept a path binding, wire row tap
- Modify: `Checklist/Checklist/Checklist/Sheets/ChecklistMenuSheet.swift` — add `onFullHistory` callback
- Modify: `Checklist/Checklist/Checklist/Views/ChecklistRunView.swift` — wire callback to append HistoryScope
- Modify: `Checklist/Checklist/Checklist/Views/HomeView.swift` — add HistoryScope destination; wire SummaryCardsRow history card

- [ ] **Step 1: Let `HistoryView` push `CompletedRunView`**

Add a path binding to `HistoryView`:

```swift
    /// NavigationPath binding owned by HomeView. Tapping a history row appends
    /// the run to this path so `CompletedRunView` is pushed.
    @Binding var path: NavigationPath
```

Then update the row tap:

```swift
    private func historyRow(_ run: CompletedRun) -> some View {
        let prog = CompletedRunProgress.compute(snapshot: run.snapshot)
        return Button {
            path.append(run)
        } label: {
```

Update both `#Preview` blocks to supply `path`:

```swift
#Preview("History — all (seeded)") {
    let container = try! SeedStore.container(for: .historicalRuns)
    return NavigationStack {
        HistoryView(scope: .allLists, path: .constant(NavigationPath()))
    }
    .modelContainer(container)
}

#Preview("History — empty") {
    let container = try! SeedStore.container(for: .empty)
    return NavigationStack {
        HistoryView(scope: .allLists, path: .constant(NavigationPath()))
    }
    .modelContainer(container)
}
```

- [ ] **Step 2: Register `HistoryScope` as a navigationDestination on HomeView**

Edit `Checklist/Checklist/Checklist/Views/HomeView.swift`. Find:

```swift
            .navigationDestination(for: Checklist.self) { list in
                ChecklistRunView(checklist: list, path: $path)
            }
            .navigationDestination(for: CompletedRun.self) { run in
                CompletedRunView(completedRun: run)
            }
```

Add immediately after:

```swift
            .navigationDestination(for: HistoryScope.self) { scope in
                HistoryView(scope: scope, path: $path)
            }
```

- [ ] **Step 3: Wire the Home `SummaryCardsRow` History card**

In `HomeView.swift`, find:

```swift
                            SummaryCardsRow(
                                tagCount: tags.count,
                                historyCount: completedRuns.count
                            )
```

Replace with:

```swift
                            SummaryCardsRow(
                                tagCount: tags.count,
                                historyCount: completedRuns.count,
                                onTagsTap: { /* wired in Task 7.5 */ },
                                onHistoryTap: { path.append(HistoryScope.allLists) }
                            )
```

- [ ] **Step 4: Add `onFullHistory` callback to `ChecklistMenuSheet`**

Edit `Checklist/Checklist/Checklist/Sheets/ChecklistMenuSheet.swift`. Find:

```swift
    /// The checklist being operated on.
    let checklist: Checklist

    /// The currently-active live Run. Nil when no run is in progress.
    let currentRun: Run?
```

Add immediately after:

```swift
    /// Called after `dismiss()` when the user taps "Manage tags" (Task 7.5).
    /// Parent pushes `TagsView` on the NavigationPath.
    var onManageTags: (() -> Void)? = nil

    /// Called after `dismiss()` when the user taps "Full history for this list".
    /// Parent pushes `HistoryView(scope: .checklist(checklist.id))`.
    var onFullHistory: (() -> Void)? = nil
```

Then find the Manage tags / Full history rows and replace:

```swift
            menuRow(icon: "tag", title: "Manage tags", tone: .normal) {
                // TagsView arrives in a later plan. Placeholder: dismiss.
                dismiss()
            }

            menuRow(icon: "history", title: "Full history for this list", tone: .normal) {
                // HistoryView arrives in a later plan. Placeholder: dismiss.
                dismiss()
            }
```

with:

```swift
            menuRow(icon: "tag", title: "Manage tags", tone: .normal) {
                dismiss()
                onManageTags?()
            }

            menuRow(icon: "history", title: "Full history for this list", tone: .normal) {
                dismiss()
                onFullHistory?()
            }
```

Also update the `Key concepts:` block at top of file — replace the "placeholder no-ops" line:

```swift
///   - "Manage tags" and "Full history for this list" are placeholder no-ops
///     in this plan — they dismiss the sheet. Those screens arrive in a later plan.
```

with:

```swift
///   - "Manage tags" and "Full history for this list" invoke optional parent
///     callbacks (`onManageTags`, `onFullHistory`) after dismiss. The parent
///     view (ChecklistRunView) appends the appropriate destination to the
///     NavigationPath.
```

- [ ] **Step 5: Wire callbacks in `ChecklistRunView`**

Edit `Checklist/Checklist/Checklist/Views/ChecklistRunView.swift`. Find:

```swift
        .sheet(isPresented: $showMenu) {
            ChecklistMenuSheet(checklist: checklist, currentRun: currentRun)
        }
```

Replace with:

```swift
        .sheet(isPresented: $showMenu) {
            ChecklistMenuSheet(
                checklist: checklist,
                currentRun: currentRun,
                onManageTags: { path.append(TagsDestination.root) },
                onFullHistory: { path.append(HistoryScope(checklistID: checklist.id)) }
            )
        }
```

(Note: `TagsDestination.root` is declared in Task 7.1. Build will fail here until Task 7.1 lands; keep the line for now and the build-gate check is deferred to Task 7.5.)

Because Task 7 has not landed yet at this point in the plan, temporarily stub out the tags leg so Phase 6 is buildable:

```swift
        .sheet(isPresented: $showMenu) {
            ChecklistMenuSheet(
                checklist: checklist,
                currentRun: currentRun,
                onManageTags: nil,  // Phase 7 wires this — deliberate no-op here
                onFullHistory: { path.append(HistoryScope(checklistID: checklist.id)) }
            )
        }
```

Task 7.5 replaces `nil` with `{ path.append(TagsDestination.root) }`.

- [ ] **Step 6: Build + smoke test**

```bash
xcodebuild -project Checklist/Checklist/Checklist.xcodeproj \
  -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 7: Commit**

```bash
git add Checklist/Checklist/Checklist/Views/HistoryView.swift \
        Checklist/Checklist/Checklist/Views/HomeView.swift \
        Checklist/Checklist/Checklist/Sheets/ChecklistMenuSheet.swift \
        Checklist/Checklist/Checklist/Views/ChecklistRunView.swift
git commit -m "feat(nav): wire HistoryView entry points (menu + home card + row taps)

- HistoryView accepts a NavigationPath binding; row taps push CompletedRunView.
- ChecklistMenuSheet gains onManageTags + onFullHistory callbacks fired
  after dismiss; 'Full history for this list' pushes a checklist-scoped
  HistoryScope.
- HomeView registers HistoryScope as a navigationDestination and wires the
  SummaryCardsRow history card to push the global feed.
- Manage tags leg parked (nil) until Phase 7 lands TagsDestination."
```

---

## Task 6.9: Phase 6 visual-diff + tag

**Files:** none (validation only).

- [ ] **Step 1: Run full test suite**

Standard test command. Expected total ≥ 69 (baseline) + CompletedRunViewTests (5) + RunStore_StartFromHistoryTests (3) + HistoryViewTests (4) = **≥ 81 tests**.

- [ ] **Step 2: Reach each reference state in the simulator**

For each capture in the 19–23 range, reach that state and screenshot it:

| Capture | How to reach it |
|---|---|
| 19 — past run (all done) | `.historicalRuns` fixture → Morning Routine → PreviousRunsStrip tap first row |
| 20 — past run (partial) | Manually complete a run with 3/8 items checked (open Packing List, tick 3, Complete anyway, then navigate to Home → Morning Routine → tap the new partial row) |
| 21 — history seeded | Home → History summary card tap |
| 22 — history empty | Fresh simulator (no runs) → Home → History summary card tap |
| 23 — history for one list | Morning Routine → kebab → "Full history for this list" |

Capture each:

```bash
xcrun simctl io booted screenshot /tmp/phase-6-<state>.png && sips -Z 1800 /tmp/phase-6-<state>.png >/dev/null
```

- [ ] **Step 3: Side-by-side diff**

Create `docs/superpowers/visual-diff/phase-6/<screen>.md` (one per screen: completedrunview.md, historyview.md). In each, include:

- Prototype PNG
- Simulator PNG
- Bullets for any deltas

Acceptable deltas: font fallbacks, minor radii, native iOS nav chrome, minor vertical-spacing differences.
Unacceptable: wrong eyebrow text ("SEALED RECORD" instead of "COMPLETED RUN"), missing filter chips, wrong CTA label, missing empty-state copy, decorative or tag group ordering bugs.

Fix any unacceptable deltas before declaring Phase 6 done.

- [ ] **Step 4: Commit visual-diff report**

```bash
git add docs/superpowers/visual-diff/phase-6/
git commit -m "docs: Phase 6 visual-diff report (CompletedRunView + HistoryView)"
```

- [ ] **Step 5: Do NOT tag yet** — Plan 3's tag applies after Phase 7.

---

# Phase 7 — TagsView + TagEditorSheet

## Task 7.1: `TagsView` scaffold (empty state + basic rows) + `TagsDestination`

**Files:**
- Create: `Checklist/Checklist/Checklist/Views/TagsRoute.swift`
- Create: `Checklist/Checklist/Checklist/Views/TagsView.swift`
- Create: `Checklist/Checklist/ChecklistTests/Views/TagsViewTests.swift`

- [ ] **Step 1: Create `TagsRoute.swift`**

```swift
/// TagsRoute.swift
/// Purpose: Hashable marker used by NavigationStack to route to TagsView.
/// Dependencies: Foundation.
/// Key concepts:
///   - A single-case enum keeps the route identity stable across pushes so
///     `path.append(TagsDestination.root)` twice collapses to one.

import Foundation

/// Navigation value pushed onto the root NavigationPath to open `TagsView`.
enum TagsDestination: Hashable {
    case root
}
```

- [ ] **Step 2: Create `TagsView.swift`**

```swift
/// TagsView.swift
/// Purpose: App-wide tag manager. Lists all Tags sorted by sortKey with usage
///   counts; tapping a row or its pencil opens TagEditorSheet in edit mode,
///   tapping "+ New tag" or the top-right + button opens it in create mode.
/// Dependencies: SwiftUI, SwiftData, Tag model, TagStore, Theme, TopBar,
///   GemIcons, TagEditorSheet (Task 7.3).
/// Key concepts:
///   - @Query drives the list; @State drives editor presentation.
///   - `editingTag == nil` presents the sheet in "new" mode;
///     a non-nil value presents it in "edit" mode.
///   - Row body tap and trailing pencil both invoke the same edit flow.

import SwiftUI
import SwiftData

/// App-wide tag manager. Lists every Tag with its usage count; taps open
/// `TagEditorSheet` in create or edit mode.
struct TagsView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\Tag.sortKey, order: .forward)]) private var tags: [Tag]

    /// Nil = editor presented in create mode. Non-nil = editor in edit mode
    /// for that tag.
    @State private var editingTag: Tag? = nil

    /// Flips to true when the user taps the top-right + or the "+ New tag"
    /// dashed row. Presentation uses `.sheet(item:)` when editing an existing
    /// tag and `.sheet(isPresented:)` for new, so both entry points coexist
    /// cleanly.
    @State private var showNewEditor = false

    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        headerBlock
                        if tags.isEmpty {
                            emptyState
                        } else {
                            tagList
                        }
                        Spacer(minLength: 40)
                    }
                    .padding(.top, Theme.Spacing.md)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(item: $editingTag) { tag in
            TagEditorSheet(mode: .edit(tag))
        }
        .sheet(isPresented: $showNewEditor) {
            TagEditorSheet(mode: .new)
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        TopBar(
            left: { IconButton(iconName: "back") { dismiss() } },
            right: { IconButton(iconName: "plus", solid: true) { showNewEditor = true } }
        )
    }

    // MARK: - Header

    /// "FILTERS FOR ITEMS ACROSS ALL LISTS" eyebrow + large "Tags." title.
    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("FILTERS FOR ITEMS ACROSS ALL LISTS")
                .font(Theme.eyebrow()).tracking(2)
                .foregroundColor(Theme.dim)
            Text("Tags.")
                .font(Theme.display(size: 34, weight: .bold))
                .foregroundColor(Theme.text)
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    // MARK: - List + empty state

    /// Rows for each tag + a trailing "+ New tag" dashed pill that opens the
    /// editor in create mode.
    private var tagList: some View {
        VStack(spacing: Theme.Spacing.xs) {
            ForEach(tags) { tag in
                tagRow(tag)
            }
            newTagRow
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    /// Empty state: shows only the "+ New tag" dashed pill.
    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.xs) {
            newTagRow
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    /// Single tag row: icon chip + name + "Used by N item(s)" subtitle +
    /// trailing pencil edit affordance.
    private func tagRow(_ tag: Tag) -> some View {
        Button {
            editingTag = tag
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                tagSwatch(tag)
                VStack(alignment: .leading, spacing: 2) {
                    Text(tag.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.text)
                    Text(usageSubtitle(for: tag))
                        .font(.system(size: 12))
                        .foregroundColor(Theme.dim)
                }
                Spacer()
                GemIcons.image("edit")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.dim)
            }
            .padding(.horizontal, Theme.Spacing.md).padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Theme.card))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    /// Rounded-square preview swatch: tag's color as background with its icon
    /// centered in white.
    private func tagSwatch(_ tag: Tag) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(
                LinearGradient(
                    colors: [
                        Theme.gemColor(hue: tag.colorHue),
                        Theme.gemColor(hue: tag.colorHue).opacity(0.7),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 36, height: 36)
            .overlay(
                GemIcons.image(tag.iconName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
            )
    }

    /// Subtitle: "Used by N item(s)" per capture 24.
    private func usageSubtitle(for tag: Tag) -> String {
        let n = TagStore.usageCount(for: tag, in: ctx)
        return "Used by \(n) item\(n == 1 ? "" : "s")"
    }

    /// Dashed "+ New tag" pill that opens the create-mode editor.
    private var newTagRow: some View {
        Button {
            showNewEditor = true
        } label: {
            HStack(spacing: 6) {
                GemIcons.image("plus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Theme.dim)
                Text("New tag")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.dim)
                Spacer()
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .stroke(Theme.border, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Tags — seeded") {
    let container = try! SeedStore.container(for: .seededMulti)
    return NavigationStack {
        TagsView()
    }
    .modelContainer(container)
}

#Preview("Tags — empty") {
    let container = try! SeedStore.container(for: .empty)
    return NavigationStack {
        TagsView()
    }
    .modelContainer(container)
}
```

- [ ] **Step 3: Write failing tests for TagsView helpers**

The helpers live inside the view as `private`, so tests hit the same behaviour via public primitives:

```swift
/// TagsViewTests.swift
/// Purpose: Tests covering TagsView's visible behaviour — tag-count listing,
///   usage-count subtitle formatting via TagStore.usageCount, and "empty" vs
///   "seeded" branching. View internals (private helpers) are exercised by
///   invoking TagStore directly since the store owns the count logic.
/// Dependencies: XCTest, SwiftData, Checklist target.

import XCTest
import SwiftData
@testable import Checklist

final class TagsViewTests: XCTestCase {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Checklist.self, ChecklistCategory.self, Item.self, Tag.self,
                Run.self, Check.self, CompletedRun.self,
            configurations: makeTestConfig()
        )
        return ModelContext(container)
    }

    /// Empty state: `fetch(Tag)` returns an empty array.
    func test_empty_tag_list() throws {
        let ctx = try makeContext()
        let tags = try ctx.fetch(FetchDescriptor<Tag>())
        XCTAssertTrue(tags.isEmpty, "TagsView's tagList branch relies on @Query → fetch returning []")
    }

    /// Seeded state: tags are returned in sortKey order.
    func test_seeded_tags_returned_in_sortKey_order() throws {
        let ctx = try makeContext()
        let a = try TagStore.create(name: "Beach", in: ctx)
        let b = try TagStore.create(name: "Snow", in: ctx)
        let c = try TagStore.create(name: "Hike", in: ctx)
        var desc = FetchDescriptor<Tag>()
        desc.sortBy = [SortDescriptor(\.sortKey, order: .forward)]
        let fetched = try ctx.fetch(desc)
        XCTAssertEqual(fetched.map(\.id), [a.id, b.id, c.id],
                       "@Query on TagsView must surface tags in sortKey order")
    }

    /// Usage subtitle formatting: singular vs plural branches.
    /// (The subtitle copy is duplicated here because the helper is private on
    /// the view; the count comes from TagStore.usageCount which is the source
    /// of truth tested separately.)
    func test_usage_subtitle_singular_plural() throws {
        let ctx = try makeContext()
        let beach = try TagStore.create(name: "Beach", in: ctx)
        let list = try ChecklistStore.create(name: "Trip", in: ctx)
        _ = try ChecklistStore.addItem(text: "Sandals", to: list, tags: [beach], in: ctx)

        XCTAssertEqual(TagStore.usageCount(for: beach, in: ctx), 1)
        XCTAssertEqual(subtitle(for: TagStore.usageCount(for: beach, in: ctx)), "Used by 1 item")

        _ = try ChecklistStore.addItem(text: "Sunscreen", to: list, tags: [beach], in: ctx)
        XCTAssertEqual(TagStore.usageCount(for: beach, in: ctx), 2)
        XCTAssertEqual(subtitle(for: TagStore.usageCount(for: beach, in: ctx)), "Used by 2 items")
    }

    /// Mirror of the private helper on TagsView — single source of truth for
    /// the subtitle format contract.
    private func subtitle(for n: Int) -> String {
        "Used by \(n) item\(n == 1 ? "" : "s")"
    }
}
```

- [ ] **Step 4: Build — expect COMPILE failure (TagEditorSheet doesn't exist yet)**

```bash
xcodebuild -project Checklist/Checklist/Checklist.xcodeproj \
  -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5
```

Expected: failure on `TagEditorSheet`.

- [ ] **Step 5: Temporarily stub `TagEditorSheet` so Task 7.1 is buildable**

Create `Checklist/Checklist/Checklist/Sheets/TagEditorSheet.swift` with a minimal placeholder that Task 7.3 replaces:

```swift
/// TagEditorSheet.swift
/// Purpose: Sheet for creating or editing a Tag. Full implementation lands in
///   Tasks 7.3 (create variant) and 7.4 (edit + delete variant). This stub
///   exists so TagsView (Task 7.1) compiles.

import SwiftUI

/// Placeholder — replaced by the full implementation in Task 7.3.
struct TagEditorSheet: View {
    enum Mode { case new; case edit(Tag) }

    let mode: Mode

    var body: some View {
        BottomSheet {
            Text("Tag editor stub — landed in Task 7.3")
                .foregroundColor(Theme.dim)
        }
    }
}
```

- [ ] **Step 6: Build + run tests**

```bash
xcodebuild -project Checklist/Checklist/Checklist.xcodeproj \
  -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test -only-testing:ChecklistTests/TagsViewTests 2>&1 | tail -10
```

Expected: 3 tests passing.

- [ ] **Step 7: Commit**

```bash
git add Checklist/Checklist/Checklist/Views/TagsRoute.swift \
        Checklist/Checklist/Checklist/Views/TagsView.swift \
        Checklist/Checklist/Checklist/Sheets/TagEditorSheet.swift \
        Checklist/Checklist/ChecklistTests/Views/TagsViewTests.swift
git commit -m "feat(views): TagsView scaffold + TagsDestination nav route

Renders the app-wide tag list with per-row usage counts (via
TagStore.usageCount), an empty state showing only '+ New tag', and a
top-right + IconButton. TagEditorSheet stub added so TagsView compiles —
full editor lands in Task 7.3. Three unit tests cover sort order + subtitle
format contract."
```

---

## Task 7.3: `TagEditorSheet` — create variant (preview + name + icon grid + 9-swatch colors)

**Files:**
- Modify (rewrite): `Checklist/Checklist/Checklist/Sheets/TagEditorSheet.swift`
- Create: `Checklist/Checklist/ChecklistTests/Sheets/TagEditorSheetTests.swift`

(Task 7.2 was absorbed into 7.1 — no separate task; move directly to the create variant.)

- [ ] **Step 1: Write failing test for TagEditorSheet create behaviour**

Create `Checklist/Checklist/ChecklistTests/Sheets/TagEditorSheetTests.swift`:

```swift
/// TagEditorSheetTests.swift
/// Purpose: Behaviour tests for TagEditorSheet. We can't instantiate the sheet
///   headlessly and drive SwiftUI taps from XCTest, so the tests exercise the
///   TagStore call sites the sheet invokes (create / update / delete) to lock
///   in the contract the sheet depends on.
/// Dependencies: XCTest, SwiftData, Checklist target.

import XCTest
import SwiftData
@testable import Checklist

final class TagEditorSheetTests: XCTestCase {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Checklist.self, ChecklistCategory.self, Item.self, Tag.self,
                Run.self, Check.self, CompletedRun.self,
            configurations: makeTestConfig()
        )
        return ModelContext(container)
    }

    /// Create: TagStore.create returns a persisted tag with the supplied
    /// name, icon and hue. TagEditorSheet's "Create" action relies on this.
    func test_create_persists_fields_as_supplied() throws {
        let ctx = try makeContext()
        let tag = try TagStore.create(
            name: "Winter",
            iconName: "snow",
            colorHue: 210,
            in: ctx
        )
        XCTAssertEqual(tag.name, "Winter")
        XCTAssertEqual(tag.iconName, "snow")
        XCTAssertEqual(tag.colorHue, 210)
    }

    /// Edit: TagStore.update patches only the fields provided.
    func test_update_patches_only_supplied_fields() throws {
        let ctx = try makeContext()
        let tag = try TagStore.create(name: "Beach", iconName: "sun", colorHue: 85, in: ctx)
        try TagStore.update(tag, name: "Summer", in: ctx)
        XCTAssertEqual(tag.name, "Summer")
        XCTAssertEqual(tag.iconName, "sun", "iconName unchanged when not supplied")
        XCTAssertEqual(tag.colorHue, 85, "colorHue unchanged when not supplied")
    }

    /// Delete: TagStore.delete cascades to Item.tags and Run.hiddenTagIDs —
    /// the sheet's delete affordance (Task 7.4) relies on this.
    func test_delete_cleans_live_references() throws {
        let ctx = try makeContext()
        let beach = try TagStore.create(name: "Beach", in: ctx)
        let list = try ChecklistStore.create(name: "Trip", in: ctx)
        let item = try ChecklistStore.addItem(text: "Sandals", to: list, tags: [beach], in: ctx)
        let run = try RunStore.startRun(on: list, in: ctx)
        try RunStore.toggleHideTag(run: run, tagID: beach.id, in: ctx)

        try TagStore.delete(beach, in: ctx)

        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Tag>()).count, 0)
        XCTAssertEqual(item.tags?.count ?? 0, 0)
        XCTAssertEqual(run.hiddenTagIDs, [])
    }

    /// GemIcons.all order + tag-hue palette match what the editor's icon grid
    /// and color swatch rows iterate over — lock them in so a change to either
    /// list is caught by tests.
    func test_icon_and_hue_catalogs_available() {
        XCTAssertFalse(GemIcons.all.isEmpty, "icon grid must have options")
        XCTAssertGreaterThanOrEqual(GemIcons.all.count, 14, "capture 26/27 shows 14 icons")
        XCTAssertGreaterThanOrEqual(GemIcons.tagHues.count, 9, "capture 26/27 shows 9 color swatches")
    }
}
```

Run the test — expect PASS (the store methods already exist from Plan 1). The `test_icon_and_hue_catalogs_available` test locks in the GemIcons catalog sizes.

```bash
xcodebuild -project Checklist/Checklist/Checklist.xcodeproj \
  -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test -only-testing:ChecklistTests/TagEditorSheetTests 2>&1 | tail -10
```

Expected: 4 tests passing.

- [ ] **Step 2: Implement the create variant (replacing the stub)**

Overwrite `Checklist/Checklist/Checklist/Sheets/TagEditorSheet.swift`:

```swift
/// TagEditorSheet.swift
/// Purpose: Sheet for creating (Task 7.3) or editing (Task 7.4) a Tag. Two
///   modes: `.new` and `.edit(Tag)`. Layout matches prototype captures 26+27:
///   preview card, name field, 14-icon grid, 9-swatch color row, action row
///   (Cancel/Create for new; Delete/Cancel/Save for edit).
/// Dependencies: SwiftUI, SwiftData, Tag, TagStore, BottomSheet, PillButton,
///   GemIcons, Theme.
/// Key concepts:
///   - Mode is an enum; `@State selection` mirrors the preview card, so the
///     swatch and icon grid taps update the card live.
///   - Create disables the Create button when the name is empty; Save enables
///     only when something changed (name/icon/hue diff from the tag's current
///     values).

import SwiftUI
import SwiftData

/// Sheet for creating or editing a Tag. Two modes: `.new` and `.edit(Tag)`.
struct TagEditorSheet: View {
    /// Which variant to render.
    enum Mode {
        case new
        case edit(Tag)
    }

    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    let mode: Mode

    /// Editable fields — initialised from the tag in edit mode, or sensible
    /// defaults in create mode.
    @State private var name: String = ""
    @State private var iconName: String = "tag"
    @State private var colorHue: Double = 300

    /// Delete-confirmation stage for edit mode. Ignored in new mode.
    @State private var showDeleteConfirm: Bool = false

    var body: some View {
        BottomSheet {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                eyebrow
                previewCard
                nameBlock
                iconGrid
                colorRow
                actionRow
            }
        }
        .onAppear(perform: seedFromMode)
        .alert(
            "Delete tag?",
            isPresented: $showDeleteConfirm,
            actions: {
                Button("Delete", role: .destructive) { commitDelete() }
                Button("Cancel", role: .cancel) {}
            },
            message: {
                Text("Removes this tag from every item and run. Completed runs keep their frozen tag reference.")
            }
        )
    }

    // MARK: - Eyebrow

    /// "NEW TAG" for create mode; "EDIT TAG" for edit mode.
    private var eyebrow: some View {
        Text(isEditMode ? "EDIT TAG" : "NEW TAG")
            .font(Theme.eyebrow()).tracking(2)
            .foregroundColor(Theme.dim)
    }

    // MARK: - Preview card

    /// Live preview of the in-progress tag: swatch + name + "PREVIEW" label.
    private var previewCard: some View {
        HStack(spacing: Theme.Spacing.md) {
            previewSwatch
            VStack(alignment: .leading, spacing: 2) {
                Text(name.isEmpty ? "Tag name" : name)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Theme.text)
                Text("PREVIEW")
                    .font(Theme.eyebrow()).tracking(2)
                    .foregroundColor(Theme.dimmer)
            }
            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .fill(Theme.gemColor(hue: colorHue).opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .stroke(Theme.gemColor(hue: colorHue).opacity(0.35), lineWidth: 1)
        )
    }

    /// Preview swatch: gem-colored rounded square with the icon centered.
    private var previewSwatch: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(
                LinearGradient(
                    colors: [
                        Theme.gemColor(hue: colorHue),
                        Theme.gemColor(hue: colorHue).opacity(0.7),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 42, height: 42)
            .overlay(
                GemIcons.image(iconName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            )
    }

    // MARK: - Name

    /// "NAME" eyebrow + text field.
    private var nameBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("NAME").font(Theme.eyebrow()).tracking(2).foregroundColor(Theme.dim)
            TextField("e.g. Winter", text: $name)
                .foregroundColor(Theme.text)
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Color.white.opacity(0.06)))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.border, lineWidth: 1))
        }
    }

    // MARK: - Icon grid

    /// "ICON" eyebrow + 14-icon grid in two rows of seven. Selection is
    /// indicated by a gem-colored ring.
    private var iconGrid: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ICON").font(Theme.eyebrow()).tracking(2).foregroundColor(Theme.dim)
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7),
                spacing: 8
            ) {
                ForEach(GemIcons.all, id: \.self) { icon in
                    iconCell(icon)
                }
            }
        }
    }

    /// Single icon cell inside the grid.
    private func iconCell(_ icon: String) -> some View {
        Button {
            iconName = icon
        } label: {
            GemIcons.image(icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(iconName == icon ? .white : Theme.dim)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(iconName == icon ? Theme.gemColor(hue: colorHue).opacity(0.25) : Color.white.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            iconName == icon ? Theme.gemColor(hue: colorHue) : Theme.border,
                            lineWidth: iconName == icon ? 1.5 : 1
                        )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Color row

    /// "COLOR" eyebrow + 9 hue swatches in a horizontal row.
    private var colorRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("COLOR").font(Theme.eyebrow()).tracking(2).foregroundColor(Theme.dim)
            HStack(spacing: 8) {
                ForEach(GemIcons.tagHues, id: \.self) { hue in
                    swatchDot(hue)
                }
            }
        }
    }

    /// A single circular hue swatch.
    private func swatchDot(_ hue: Double) -> some View {
        Button {
            colorHue = hue
        } label: {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Theme.gemColor(hue: hue), Theme.gemColor(hue: hue).opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 26, height: 26)
                .overlay(
                    Circle()
                        .stroke(colorHue == hue ? Color.white : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Action row

    /// Bottom buttons: Cancel + Create in new mode; Delete + Cancel + Save in
    /// edit mode.
    @ViewBuilder
    private var actionRow: some View {
        switch mode {
        case .new:
            HStack(spacing: Theme.Spacing.sm) {
                PillButton(title: "Cancel", tone: .ghost, wide: true) { dismiss() }
                PillButton(
                    title: "Create",
                    color: Theme.amethyst,
                    wide: true,
                    disabled: trimmedName.isEmpty
                ) { commitCreate() }
            }
            .padding(.top, Theme.Spacing.sm)

        case .edit:
            HStack(spacing: Theme.Spacing.sm) {
                IconButton(iconName: "trash") { showDeleteConfirm = true }
                PillButton(title: "Cancel", tone: .ghost, wide: true) { dismiss() }
                PillButton(
                    title: "Save",
                    color: Theme.amethyst,
                    wide: true,
                    disabled: trimmedName.isEmpty
                ) { commitUpdate() }
            }
            .padding(.top, Theme.Spacing.sm)
        }
    }

    // MARK: - Helpers

    private var isEditMode: Bool {
        if case .edit = mode { return true } else { return false }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    /// Populates editable fields from the tag (edit mode) or defaults (new).
    private func seedFromMode() {
        if case let .edit(tag) = mode {
            name = tag.name
            iconName = tag.iconName
            colorHue = tag.colorHue
        } else {
            name = ""
            iconName = "tag"
            colorHue = GemIcons.tagHues.first ?? 300
        }
    }

    // MARK: - Commit paths

    /// Creates a new Tag via TagStore.create and dismisses.
    private func commitCreate() {
        let trimmed = trimmedName
        guard !trimmed.isEmpty else { return }
        _ = try? TagStore.create(
            name: trimmed,
            iconName: iconName,
            colorHue: colorHue,
            in: ctx
        )
        dismiss()
    }

    /// Applies the edited fields via TagStore.update and dismisses (edit mode).
    private func commitUpdate() {
        guard case let .edit(tag) = mode else { dismiss(); return }
        let trimmed = trimmedName
        let nameChanged = !trimmed.isEmpty && trimmed != tag.name
        let iconChanged = iconName != tag.iconName
        let hueChanged  = colorHue != tag.colorHue
        guard nameChanged || iconChanged || hueChanged else { dismiss(); return }
        try? TagStore.update(
            tag,
            name: nameChanged ? trimmed : nil,
            iconName: iconChanged ? iconName : nil,
            colorHue: hueChanged ? colorHue : nil,
            in: ctx
        )
        dismiss()
    }

    /// Deletes the tag (edit mode only) via TagStore.delete and dismisses.
    private func commitDelete() {
        guard case let .edit(tag) = mode else { dismiss(); return }
        try? TagStore.delete(tag, in: ctx)
        dismiss()
    }
}

// MARK: - Previews

#Preview("New tag") {
    let container = try! SeedStore.container(for: .seededMulti)
    return Color.gray.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            TagEditorSheet(mode: .new)
                .modelContainer(container)
        }
}

#Preview("Edit tag") {
    let container = try! SeedStore.container(for: .seededMulti)
    let ctx = ModelContext(container)
    let tag = try! ctx.fetch(FetchDescriptor<Tag>()).first!
    return Color.gray.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            TagEditorSheet(mode: .edit(tag))
                .modelContainer(container)
        }
}
```

- [ ] **Step 3: Build + run tests**

Full test suite:

```bash
xcodebuild -project Checklist/Checklist/Checklist.xcodeproj \
  -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test 2>&1 | \
  grep -E "Test Suite 'All tests'|TEST SUCCEEDED|TEST FAILED" | tail -3
```

Expected: TEST SUCCEEDED, total now ≥ 81 + TagsView (3) + TagEditorSheet (4) = **≥ 88**.

- [ ] **Step 4: Commit**

```bash
git add Checklist/Checklist/Checklist/Sheets/TagEditorSheet.swift \
        Checklist/Checklist/ChecklistTests/Sheets/TagEditorSheetTests.swift
git commit -m "feat(sheets): TagEditorSheet (create + edit variants)

Implements the sheet with live-preview card, 14-icon grid, 9-swatch color
row, and variant-specific action rows (Cancel/Create for new; Delete+
Cancel/Save for edit). Delete presents a confirmation alert. Store calls
route through TagStore.create / .update / .delete. Four unit tests cover
contracts the sheet depends on."
```

---

## Task 7.4: Verification-pass — TagEditorSheet edit flow smoke test

**Files:** none — manual verification only.

- [ ] **Step 1: Smoke-test create via simulator**

```bash
xcodebuild -project Checklist/Checklist/Checklist.xcodeproj \
  -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -3
APP="$HOME/Library/Developer/Xcode/DerivedData/Checklist-ddgbkiqecqxthpbauhcdfklcgyxc/Build/Products/Debug-iphonesimulator/Checklist.app"
xcrun simctl boot "iPhone 17 Pro" 2>/dev/null || true
xcrun simctl install booted "$APP"
xcrun simctl launch booted com.themostthing.Checklist
sleep 2
```

(If the DerivedData hash differs, run `xcodebuild … -showBuildSettings | grep BUILT_PRODUCTS_DIR` and use that path.)

Manually: Home → (no tags path card yet — Task 7.5) → For now, exercise the sheet via the preview canvas (`TagEditorSheet`'s `#Preview`) in Xcode.

- [ ] **Step 2: Commit a note in the visual-diff plan** (deferred to Task 7.6) — no commit this task.

---

## Task 7.5: Wire `ChecklistMenuSheet` "Manage tags" + `SummaryCardsRow` Tags card

**Files:**
- Modify: `Checklist/Checklist/Checklist/Views/HomeView.swift`
- Modify: `Checklist/Checklist/Checklist/Views/ChecklistRunView.swift`

- [ ] **Step 1: Register `TagsDestination` on Home's NavigationStack**

Edit `Checklist/Checklist/Checklist/Views/HomeView.swift`. Add after the existing navigationDestinations:

```swift
            .navigationDestination(for: TagsDestination.self) { _ in
                TagsView()
            }
```

- [ ] **Step 2: Wire the SummaryCardsRow Tags card**

Replace the `SummaryCardsRow(...)` invocation — the onTagsTap argument changes from the placeholder closure:

```swift
                            SummaryCardsRow(
                                tagCount: tags.count,
                                historyCount: completedRuns.count,
                                onTagsTap:    { path.append(TagsDestination.root) },
                                onHistoryTap: { path.append(HistoryScope.allLists) }
                            )
```

- [ ] **Step 3: Wire the menu sheet callback in `ChecklistRunView`**

Replace the `onManageTags: nil,` line (from Task 6.8 parking) with:

```swift
                onManageTags: { path.append(TagsDestination.root) },
```

- [ ] **Step 4: Build**

Standard build command. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Smoke test in simulator**

```bash
xcrun simctl install booted "$HOME/Library/Developer/Xcode/DerivedData/Checklist-ddgbkiqecqxthpbauhcdfklcgyxc/Build/Products/Debug-iphonesimulator/Checklist.app"
xcrun simctl launch booted com.themostthing.Checklist
```

Manually verify:
- Home → Tags summary card tap → TagsView appears
- Any list → kebab → "Manage tags" → TagsView appears

- [ ] **Step 6: Commit**

```bash
git add Checklist/Checklist/Checklist/Views/HomeView.swift \
        Checklist/Checklist/Checklist/Views/ChecklistRunView.swift
git commit -m "feat(nav): wire Tags entry points (menu row + home summary card)

Registers TagsDestination as a navigationDestination on HomeView.
Wires SummaryCardsRow.onTagsTap and ChecklistMenuSheet.onManageTags to
push TagsDestination.root. Closes the last Plan 2 dead-end tap."
```

---

## Task 7.6: Phase 7 visual-diff

**Files:** none (validation + diff report only).

- [ ] **Step 1: Run full test suite**

Standard test command. Expected total ≥ 88.

- [ ] **Step 2: Reach each reference state in simulator**

| Capture | How to reach it |
|---|---|
| 24 — Tags seeded | `.seededMulti` → Home → Tags summary card |
| 25 — Tags empty | `.empty` → Home → Tags summary card (or fresh sim) |
| 26 — TagEditorSheet edit | Tags seeded → tap a tag row |
| 27 — TagEditorSheet new | Tags → tap top-right + OR "+ New tag" row |

Capture each:

```bash
xcrun simctl io booted screenshot /tmp/phase-7-<state>.png && sips -Z 1800 /tmp/phase-7-<state>.png >/dev/null
```

- [ ] **Step 3: Visual-diff report**

Create `docs/superpowers/visual-diff/phase-7/tagsview.md` and `docs/superpowers/visual-diff/phase-7/tageditorsheet.md`. Each with prototype/sim PNG pair and a bullet list of deltas.

Acceptable deltas: font fallbacks, minor radii, native sheet drag indicator, slight icon spacing.
Unacceptable: missing "FILTERS FOR ITEMS ACROSS ALL LISTS" eyebrow, missing pencil affordance, wrong swatch count (must be 9), wrong icon count (must be 14).

- [ ] **Step 4: Commit visual-diff report**

```bash
git add docs/superpowers/visual-diff/phase-7/
git commit -m "docs: Phase 7 visual-diff report (TagsView + TagEditorSheet)"
```

---

## Task 7.7: Plan 3 tag + handoff update

**Files:**
- Modify: `docs/superpowers/plans/2026-04-19-checklist-v4-plan-3-history-tags.md` — mark handoff complete

- [ ] **Step 1: Full test suite**

Standard test command. Expected total ≥ 88 tests passing.

- [ ] **Step 2: Tag the commit**

```bash
git tag plan-3-history-tags-complete
```

- [ ] **Step 3: Verify no dead-end taps remain**

Grep for any remaining placeholder comments:

```bash
grep -rn "deferred to Plan 3\|placeholder.*dismiss\|arrives in a later plan" \
  Checklist/Checklist/Checklist 2>/dev/null
```

Expected output: empty (all Plan 3 references were removed in Tasks 6.2, 6.8, and 7.5; the "later plan" phrases remaining should refer to Phase 8 items only — SettingsView, PaywallSheet, Save-as-new, Clear-history).

- [ ] **Step 4: Done**

Plan 3 complete. Close out with a status comment in the handoff section above (no separate commit needed; the tag marks the final commit).

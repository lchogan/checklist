# Checklist v4 — Plan 2: Home + ChecklistRunView (Phases 4–5)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the two user-facing screens that let a user create a checklist and actually run through it — `HomeView` (grid + create flow) and `ChecklistRunView` (items + checks + sheets) — on top of the Plan 1 foundation.

**Architecture:** Views use `@Query` + `@Environment(\.modelContext)` directly (no view models). Non-trivial mutations route through the existing `ChecklistStore` / `RunStore` / `TagStore` / `CategoryStore` namespaces. Transient UI state uses `@State` on the view. `NavigationStack` handles navigation. Sheets use the existing `BottomSheet` primitive from Plan 1.

**Tech Stack:** Swift 5.9+, SwiftUI, SwiftData (iOS 17+), XCTest, Xcode 16+.

**Spec:** `docs/superpowers/specs/2026-04-18-checklist-v4-redesign.md` — especially §2 (screen inventory), §7 (prototype→v4 translation table), §3 (cascade table).
**Architecture:** `ARCHITECTURE.md` — especially §3 (user-facing actions), §4 (lifecycle examples).
**Visual refs (authoritative):** `docs/superpowers/prototype-captures/` — captures 01–03, 29–30 for Home; 04–17 for ChecklistRunView.

**Baseline at plan start:** `main` at tag `plan-1-foundation-complete` (58 tests green). App launches to a placeholder `ContentView` reading "Checklist / Foundation phase — UI coming in Plan 2." This plan replaces that placeholder.

---

## Repo paths used throughout

- Repo root: `/Users/lukehogan/Library/Mobile Documents/com~apple~CloudDocs/Code/checklist` — every path below is relative to this.
- Xcode project: `Checklist/Checklist/Checklist.xcodeproj` (double-nested)
- App sources: `Checklist/Checklist/Checklist/` (Models/, Store/, Design/, Purchases/)
- Tests target: `Checklist/Checklist/ChecklistTests/`

**Simulator:** iPhone 17 Pro.

**Screenshot rule (use everywhere a screenshot is captured):** pipe through `sips -Z 1800` so the resulting image stays under Claude's 2000 px-per-edge limit:
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

**Bundle ID:** `com.themostthing.Checklist` (already set in the project).

**Tests target:** filenames for new test files follow the pattern `Checklist/Checklist/ChecklistTests/Views/<Name>Tests.swift` or `Sheets/<Name>Tests.swift`. Xcode 16 auto-adds files under the synchronized root group — do NOT touch `.pbxproj`.

**Baseline test count:** 58 passing at start of Plan 2. The count climbs as new tests land.

---

## Terminology rules (CRITICAL — subagents must not re-derive these)

Per spec §7. The prototype HTML/captures use older words; the v4 codebase and UI MUST use these:

| Prototype says (captures) | v4 code + UI uses |
|---|---|
| "Collection" / "Collections" | **Category** / **Categories** |
| "YOUR COLLECTIONS · N LIVE" eyebrow | **"YOUR CATEGORIES · N LIVE"** |
| "Finish run" / "Finish as partial · N/M" | **"Complete"** / **"Complete anyway · N/M"** |
| "Seal" / "Sealed" / "Sealed record" | **"Complete"** / **"Completed"** / **"Completed run"** |
| "Archive list" / archive action | *(removed — permanent delete only)* |
| "Set due date" / "Set repeat schedule" menu rows | *(removed — reserved for v1.1+)* |
| "Adds to: Future only" chip on AddItemInline | *(removed — always adds to all live runs)* |
| "Start a run" sheet with due-date field | **StartRunSheet** — name only |

Translations for screen/sheet file names are already correct in `§4 post-reset project structure` of the spec.

---

## Files created by this plan

### Phase 4 — Home

- `Checklist/Checklist/Checklist/Views/HomeView.swift`
- `Checklist/Checklist/Checklist/Views/CategoryFilterChipsView.swift`
- `Checklist/Checklist/Checklist/Views/SummaryCardsRow.swift`
- `Checklist/Checklist/Checklist/Sheets/CreateChecklistSheet.swift`
- `Checklist/Checklist/ChecklistTests/Views/HomeViewTests.swift`
- `Checklist/Checklist/ChecklistTests/Sheets/CreateChecklistSheetTests.swift`

Modified:
- `Checklist/Checklist/Checklist/ChecklistApp.swift` — replace the placeholder `ContentView` with `HomeView` wrapped in a `NavigationStack`.

### Phase 5 — ChecklistRunView

- `Checklist/Checklist/Checklist/Views/ChecklistRunView.swift`
- `Checklist/Checklist/Checklist/Views/ItemRow.swift`
- `Checklist/Checklist/Checklist/Views/TagHideChipBar.swift`
- `Checklist/Checklist/Checklist/Views/PreviousRunsStrip.swift`
- `Checklist/Checklist/Checklist/Sheets/AddItemInline.swift`
- `Checklist/Checklist/Checklist/Sheets/ItemEditInline.swift`
- `Checklist/Checklist/Checklist/Sheets/ChecklistMenuSheet.swift`
- `Checklist/Checklist/Checklist/Sheets/CompletionSheet.swift`
- `Checklist/Checklist/Checklist/Sheets/RunChooserSheet.swift`
- `Checklist/Checklist/Checklist/Sheets/StartRunSheet.swift`
- `Checklist/Checklist/ChecklistTests/Views/ChecklistRunViewTests.swift`
- `Checklist/Checklist/ChecklistTests/Sheets/CompletionSheetTests.swift` (state computation tests only)

Modified:
- `Checklist/Checklist/Checklist/Views/HomeView.swift` — wire `ChecklistCard` tap to push `ChecklistRunView` (replacing the Phase 4 placeholder).

---

## Shared helpers introduced in this plan

### `RunProgress` struct (computed, not stored)

Used by HomeView cards and ChecklistRunView header to display `done / total` and percent.

Define once at `Checklist/Checklist/Checklist/Views/RunProgress.swift`:

```swift
import Foundation

/// Computed progress snapshot for a Run. Not persisted — derived from the
/// Run's current checks and the Checklist's current items, with hidden-tag
/// filtering applied.
///
/// Rules:
/// - `total` = items whose tags are NOT all in `run.hiddenTagIDs`, excluding
///   items with `Check.state == .ignored` (ignored items are hidden from both
///   numerator and denominator, matching ARCHITECTURE §3b semantics).
/// - `done` = of those visible items, the count with `Check.state == .complete`.
struct RunProgress {
    let done: Int
    let total: Int
    var percent: Double { total == 0 ? 0 : Double(done) / Double(total) }

    static func compute(items: [Item], checks: [Check], hiddenTagIDs: [UUID]) -> RunProgress {
        let ignored = Set(checks.filter { $0.state == .ignored }.map(\.itemID))
        let visible = items.filter { item in
            if ignored.contains(item.id) { return false }
            // Hidden if EVERY tag on the item is in hiddenTagIDs (an untagged
            // item can never be hidden).
            guard let tags = item.tags, !tags.isEmpty else { return true }
            let itemTagIDs = Set(tags.map(\.id))
            let hidden = Set(hiddenTagIDs)
            return !itemTagIDs.isSubset(of: hidden)
        }
        let visibleIDs = Set(visible.map(\.id))
        let done = checks.filter { visibleIDs.contains($0.itemID) && $0.state == .complete }.count
        return RunProgress(done: done, total: visible.count)
    }
}
```

Tests for this helper land in Task 5.5 (the first task that actually uses it).

---

# Phase 4 — Home

## Task 4.1: HomeView scaffold + TopBar

**Files:**
- Create: `Checklist/Checklist/Checklist/Views/HomeView.swift`
- Modify: `Checklist/Checklist/Checklist/ChecklistApp.swift`

- [ ] **Step 1: Create HomeView scaffold**

Write `Checklist/Checklist/Checklist/Views/HomeView.swift`:

```swift
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
                // CreateChecklistSheet placeholder — real in Task 4.6
                Text("Create sheet placeholder")
                    .presentationDetents([.medium])
            }
        }
    }

    private var topBar: some View {
        TopBar(
            left: { IconButton(iconName: "sparkle") {} },   // sun/theme — no-op
            right: { IconButton(iconName: "plus", solid: true) { showCreateSheet = true } }
        )
    }

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

    private var eyebrowText: String {
        // "YOUR CATEGORIES · N LIVE" (per §7 translation rule — never "Collections")
        let liveRunCount = checklists.reduce(0) { $0 + ($1.runs?.count ?? 0) }
        if liveRunCount > 0 {
            return "YOUR CATEGORIES · \(liveRunCount) LIVE"
        } else {
            return "YOUR CATEGORIES"
        }
    }
}
```

- [ ] **Step 2: Rewire `ChecklistApp` to present HomeView**

Edit `Checklist/Checklist/Checklist/ChecklistApp.swift`. Find the `AppRoot` body where it currently shows the placeholder `ContentView` (a `VStack` with "Checklist" + "Foundation phase…"). Replace with `HomeView()`:

```swift
// BEFORE (placeholder):
//   VStack { Text("Checklist")... Text("Foundation phase — UI coming in Plan 2.")... }
//     .modelContainer(container)

// AFTER:
HomeView()
    .modelContainer(container)
    .environmentObject(entitlementManager)
    .environmentObject(storeKit)
```

Read the current `ChecklistApp.swift` first; the exact lines depend on the current structure. Remove the `struct ContentView` if it's defined in that file and no longer used.

- [ ] **Step 3: Build**

Run the standard build command. Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Launch simulator, verify scaffold renders**

```bash
APP="$HOME/Library/Developer/Xcode/DerivedData/Checklist-ddgbkiqecqxthpbauhcdfklcgyxc/Build/Products/Debug-iphonesimulator/Checklist.app"
xcrun simctl install booted "$APP"
xcrun simctl launch booted com.themostthing.Checklist
sleep 2
xcrun simctl io booted screenshot /tmp/task-4-1-scaffold.png && sips -Z 1800 /tmp/task-4-1-scaffold.png >/dev/null
```

(If the `DerivedData` path has a different hash, read it from `xcodebuild … -showBuildSettings | grep BUILT_PRODUCTS_DIR`.)

Expected visually: dark violet background, "YOUR CATEGORIES" eyebrow, "Checklists." title, placeholder "Home scaffold …" text, no crashes.

- [ ] **Step 5: Commit**

```bash
git add Checklist/Checklist/Checklist/Views/HomeView.swift \
        Checklist/Checklist/Checklist/ChecklistApp.swift
git commit -m "feat(views): HomeView scaffold with top bar + title block"
```

---

## Task 4.2: Checklist cards grid + empty state

**Files:**
- Modify: `Checklist/Checklist/Checklist/Views/HomeView.swift`

Binds the `@Query<Checklist>` results to `ChecklistCard` instances, handles the empty state (capture 02), and computes per-checklist progress via `RunProgress`.

- [ ] **Step 1: Create RunProgress helper**

Write `Checklist/Checklist/Checklist/Views/RunProgress.swift` using the struct defined at the top of this plan (Shared helpers § `RunProgress`).

- [ ] **Step 2: Extend HomeView with cards grid**

Replace the placeholder `Text("Home scaffold …")` in `HomeView.body` with a computed `cardsSection`:

```swift
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

private var filteredChecklists: [Checklist] {
    guard let categoryID = selectedCategoryID else { return checklists }
    return checklists.filter { $0.category?.id == categoryID }
}

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
private func primaryRunLabel(for list: Checklist) -> String? {
    guard let primary = (list.runs ?? []).sorted(by: { $0.startedAt < $1.startedAt }).first else {
        return nil
    }
    return primary.name
}

/// Progress for the primary live run (or 0/total if no live run).
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
```

And the empty state matching capture 02:

```swift
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
```

Then insert `cardsSection` into the `ScrollView` `VStack` below `titleBlock`.

- [ ] **Step 3: Build + visual check**

Standard build. With zero checklists in the ModelContainer, the empty state shows. (SwiftData persists across runs — if the simulator has stale checklists from prior testing, delete the app and reinstall, or use `xcrun simctl uninstall booted com.themostthing.Checklist` first.)

Screenshot and visually compare to `docs/superpowers/prototype-captures/02-home-empty.png`.

- [ ] **Step 4: Add a sanity unit test**

Create `Checklist/Checklist/ChecklistTests/Views/HomeViewTests.swift`:

```swift
import XCTest
import SwiftData
@testable import Checklist

final class HomeViewTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Checklist.self, ChecklistCategory.self, Item.self, Tag.self,
                Run.self, Check.self, CompletedRun.self,
            configurations: makeTestConfig()
        )
        return ModelContext(container)
    }

    func test_runProgress_with_no_runs_returns_total_eq_items() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "T", in: ctx)
        _ = try ChecklistStore.addItem(text: "A", to: list, in: ctx)
        _ = try ChecklistStore.addItem(text: "B", to: list, in: ctx)

        let progress = RunProgress.compute(items: list.items ?? [], checks: [], hiddenTagIDs: [])
        XCTAssertEqual(progress.done, 0)
        XCTAssertEqual(progress.total, 2)
    }

    func test_runProgress_ignored_items_excluded_from_both() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "T", in: ctx)
        let a = try ChecklistStore.addItem(text: "A", to: list, in: ctx)
        let b = try ChecklistStore.addItem(text: "B", to: list, in: ctx)
        let c = try ChecklistStore.addItem(text: "C", to: list, in: ctx)

        let run = try RunStore.startRun(on: list, in: ctx)
        try RunStore.toggleCheck(run: run, itemID: a.id, in: ctx)
        try RunStore.setIgnored(run: run, itemID: b.id, to: true, in: ctx)
        _ = c

        let progress = RunProgress.compute(
            items: list.items ?? [],
            checks: run.checks ?? [],
            hiddenTagIDs: run.hiddenTagIDs
        )
        XCTAssertEqual(progress.done, 1, "only A complete")
        XCTAssertEqual(progress.total, 2, "B ignored, excluded; total = A + C")
    }

    func test_runProgress_hidden_tag_filters_items_whose_all_tags_hidden() throws {
        let ctx = try makeContext()
        let beach = try TagStore.create(name: "Beach", in: ctx)
        let list = try ChecklistStore.create(name: "T", in: ctx)
        _ = try ChecklistStore.addItem(text: "Untagged", to: list, in: ctx)
        _ = try ChecklistStore.addItem(text: "BeachOnly", to: list, tags: [beach], in: ctx)

        let run = try RunStore.startRun(on: list, in: ctx)
        try RunStore.toggleHideTag(run: run, tagID: beach.id, in: ctx)

        let progress = RunProgress.compute(
            items: list.items ?? [],
            checks: run.checks ?? [],
            hiddenTagIDs: run.hiddenTagIDs
        )
        XCTAssertEqual(progress.total, 1, "BeachOnly hidden, Untagged visible")
    }
}
```

- [ ] **Step 2b: Run tests**

Standard test command. Expected: 58 prior + 3 new = 61 tests passing.

- [ ] **Step 5: Commit**

```bash
git add Checklist/Checklist/Checklist/Views/RunProgress.swift \
        Checklist/Checklist/Checklist/Views/HomeView.swift \
        Checklist/Checklist/ChecklistTests/Views/HomeViewTests.swift
git commit -m "feat(views): Home cards grid with RunProgress helper + empty state"
```

---

## Task 4.3: Category filter chips

**Files:**
- Create: `Checklist/Checklist/Checklist/Views/CategoryFilterChipsView.swift`
- Modify: `Checklist/Checklist/Checklist/Views/HomeView.swift`

Prototype ref: capture 01 — row of chips "All · Daily · Travel · Home · Seasonal" under the title. "All" is selected by default and uses a gradient fill; others are ghost-style.

- [ ] **Step 1: Create the chip component**

Write `Checklist/Checklist/Checklist/Views/CategoryFilterChipsView.swift`:

```swift
import SwiftUI

/// Horizontal scrolling row of category filter chips. The selected chip uses
/// the gem gradient fill; others are ghost capsules. An "All" chip
/// (selectedCategoryID == nil) is always first.
struct CategoryFilterChipsView: View {
    let categories: [ChecklistCategory]
    @Binding var selectedCategoryID: UUID?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.xs) {
                chip(title: "All", isSelected: selectedCategoryID == nil) {
                    selectedCategoryID = nil
                }
                ForEach(categories) { cat in
                    chip(title: cat.name, isSelected: selectedCategoryID == cat.id) {
                        selectedCategoryID = cat.id
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
        }
    }

    private func chip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? .white : Theme.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
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
                    Capsule().stroke(
                        isSelected ? Color.clear : Theme.border,
                        lineWidth: 1
                    )
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview("Category filter chips") {
    struct Wrapper: View {
        @State var selected: UUID? = nil
        var body: some View {
            CategoryFilterChipsView(
                categories: [],
                selectedCategoryID: $selected
            )
            .padding(.vertical)
            .background(Theme.bg)
        }
    }
    return Wrapper()
}
```

- [ ] **Step 2: Wire into HomeView**

In `HomeView.body`'s scrolling `VStack`, insert between `titleBlock` and `cardsSection`:

```swift
if !categories.isEmpty {
    CategoryFilterChipsView(
        categories: categories,
        selectedCategoryID: $selectedCategoryID
    )
}
```

The `filteredChecklists` computed property already uses `selectedCategoryID`, so filtering works end-to-end once the chips are wired.

- [ ] **Step 3: Build, run simulator with seeded fixtures**

To exercise the chips visually, temporarily swap the `ChecklistApp`'s production ModelContainer for a SeedStore `.seededMulti` fixture. **Do NOT commit this swap** — it's a local-only debugging aid.

Alternatively, use Xcode's SwiftUI preview on HomeView with a seeded container:

Add a `#Preview` to the bottom of `HomeView.swift`:

```swift
#Preview("Home — seeded") {
    let container = try! SeedStore.container(for: .seededMulti)
    return HomeView().modelContainer(container)
}

#Preview("Home — empty") {
    let container = try! SeedStore.container(for: .empty)
    return HomeView().modelContainer(container)
}

#Preview("Home — one list") {
    let container = try! SeedStore.container(for: .oneList)
    return HomeView().modelContainer(container)
}
```

- [ ] **Step 4: Visually verify each preview**

Open `HomeView.swift` in Xcode, activate the canvas (⌥⌘↵), cycle through the three previews. Expected:
- **seeded:** 4 cards (Packing List, Morning Routine, Weekly Groceries, Gym Bag). Filter chips show "All · Travel · Daily · Home". Tapping "Daily" filters to 2 cards. Tapping "Travel" filters to 1.
- **empty:** no cards, empty state shows, no chip row.
- **one list:** one card (Road Trip), one chip ("Travel").

- [ ] **Step 5: Commit**

```bash
git add Checklist/Checklist/Checklist/Views/CategoryFilterChipsView.swift \
        Checklist/Checklist/Checklist/Views/HomeView.swift
git commit -m "feat(views): Home category filter chips with All + per-category"
```

---

## Task 4.4: Summary cards row (Tags / History) + sun icon

**Files:**
- Create: `Checklist/Checklist/Checklist/Views/SummaryCardsRow.swift`
- Modify: `Checklist/Checklist/Checklist/Views/HomeView.swift`

Prototype ref: both capture 01 and capture 02 show a two-card row at the bottom of the home content: Tags (N TOTAL) + History (N TOTAL). Each card has an icon and a count. Tapping them will (in a later plan) navigate to the Tags/History screens — for now they're decorative.

- [ ] **Step 1: Create the component**

Write `Checklist/Checklist/Checklist/Views/SummaryCardsRow.swift`:

```swift
import SwiftUI

/// Two decorative summary cards shown at the bottom of HomeView: Tags count +
/// History (completed-run) count. Tapping them is a no-op in Plan 2;
/// navigation to Tags / History screens is deferred to a later plan.
struct SummaryCardsRow: View {
    let tagCount: Int
    let historyCount: Int
    var onTagsTap: () -> Void = {}
    var onHistoryTap: () -> Void = {}

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            summaryCard(icon: "tag", title: "Tags", count: tagCount, onTap: onTagsTap)
            summaryCard(icon: "history", title: "History", count: historyCount, onTap: onHistoryTap)
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    private func summaryCard(icon: String, title: String, count: Int, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    GemIcons.image(icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.dim)
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.text)
                }
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(count)")
                        .font(Theme.display(size: 22))
                        .foregroundColor(Theme.text)
                    Text("TOTAL")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.5)
                        .foregroundColor(Theme.dimmer)
                }
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .fill(Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .stroke(Theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview("Summary cards") {
    SummaryCardsRow(tagCount: 6, historyCount: 11)
        .padding(.vertical)
        .background(Theme.bg)
}
```

- [ ] **Step 2: Wire into HomeView**

In `HomeView`, add queries for tags and completed runs:

```swift
@Query private var tags: [Tag]
@Query private var completedRuns: [CompletedRun]
```

Append the summary row to the scrolling `VStack` (below `cardsSection`, always visible — both empty-state and seeded-state layouts include it per captures 01 and 02):

```swift
SummaryCardsRow(
    tagCount: tags.count,
    historyCount: completedRuns.count
)
.padding(.top, Theme.Spacing.md)
```

- [ ] **Step 3: Adjust the sun/theme icon**

The placeholder `IconButton(iconName: "sparkle")` needs to be `"sparkle"` which is in the GemIcons map → maps to SF Symbol `"sparkle"`. This matches capture 01's decorative top-left sun icon close enough. No change needed — just confirm the icon renders.

- [ ] **Step 4: Build + verify previews**

Refresh the three `HomeView` previews in Xcode canvas. Expected:
- **seeded:** Tags 3 (Beach, Snow, Intl), History 0 — summary row visible below cards.
- **empty:** Tags 0, History 0 — summary row visible below the empty-state button.
- **one list:** Tags 0, History 0.

- [ ] **Step 5: Commit**

```bash
git add Checklist/Checklist/Checklist/Views/SummaryCardsRow.swift \
        Checklist/Checklist/Checklist/Views/HomeView.swift
git commit -m "feat(views): Home summary cards row (tags + history totals)"
```

---

## Task 4.5: CreateChecklistSheet

**Files:**
- Create: `Checklist/Checklist/Checklist/Sheets/CreateChecklistSheet.swift`
- Create: `Checklist/Checklist/ChecklistTests/Sheets/CreateChecklistSheetTests.swift`
- Modify: `Checklist/Checklist/Checklist/Views/HomeView.swift`

Prototype ref: captures 29 + 30. "NEW LIST" eyebrow, "Name your checklist." title, single text field (placeholder "e.g. Road Trip"), "CATEGORY" label (NOT "COLLECTION" — §7 rule), chips row ending with "+ New" dashed pill, Cancel + Create buttons. Create is disabled when the name is empty.

Behavior: "+ New" opens an inline text row (same sheet, no nested sheet); typing + return creates the category immediately via `CategoryStore.create`, then selects it.

- [ ] **Step 1: Write CreateChecklistSheet**

Write `Checklist/Checklist/Checklist/Sheets/CreateChecklistSheet.swift`:

```swift
import SwiftUI
import SwiftData

/// Sheet presented from HomeView's "+" button. Collects name + category
/// selection (with inline + New category). Commits via ChecklistStore.create
/// and dismisses.
struct CreateChecklistSheet: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\ChecklistCategory.sortKey, order: .forward)])
    private var categories: [ChecklistCategory]

    @State private var name: String = ""
    @State private var selectedCategoryID: UUID? = nil
    @State private var showNewCategoryInput = false
    @State private var newCategoryName: String = ""

    var body: some View {
        BottomSheet {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("NEW LIST")
                    .font(Theme.eyebrow())
                    .tracking(2)
                    .foregroundColor(Theme.dim)

                Text("Name your checklist.")
                    .font(Theme.display(size: 26))
                    .foregroundColor(Theme.text)

                nameField

                Text("CATEGORY")
                    .font(Theme.eyebrow())
                    .tracking(2)
                    .foregroundColor(Theme.dim)
                    .padding(.top, Theme.Spacing.sm)

                categoryChips

                if showNewCategoryInput {
                    newCategoryField
                }

                actionRow
            }
        }
    }

    private var nameField: some View {
        TextField("e.g. Road Trip", text: $name)
            .foregroundColor(Theme.text)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Color.white.opacity(0.06)))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.border, lineWidth: 1))
            .submitLabel(.done)
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(categories) { cat in
                    chip(title: cat.name, isSelected: selectedCategoryID == cat.id) {
                        selectedCategoryID = (selectedCategoryID == cat.id) ? nil : cat.id
                    }
                }
                newChip
            }
        }
    }

    private var newChip: some View {
        Button {
            showNewCategoryInput = true
        } label: {
            Text("+ New")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.dim)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Capsule().fill(Color.clear))
                .overlay(
                    Capsule().stroke(Theme.border, style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                )
        }
        .buttonStyle(.plain)
    }

    private func chip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? .white : Theme.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
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

    private var newCategoryField: some View {
        HStack {
            TextField("New category name", text: $newCategoryName)
                .foregroundColor(Theme.text)
            Button("Add") {
                commitNewCategory()
            }
            .disabled(newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
            .buttonStyle(.plain)
            .foregroundColor(Theme.amethyst)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Color.white.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.border, lineWidth: 1))
    }

    private var actionRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            PillButton(title: "Cancel", tone: .ghost, wide: true) {
                dismiss()
            }
            PillButton(
                title: "Create",
                color: Theme.amethyst,
                wide: true,
                disabled: trimmedName.isEmpty
            ) {
                commitCreate()
            }
        }
        .padding(.top, Theme.Spacing.md)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    private func commitNewCategory() {
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        do {
            let cat = try CategoryStore.create(name: trimmed, in: ctx)
            selectedCategoryID = cat.id
            newCategoryName = ""
            showNewCategoryInput = false
        } catch {
            // Non-fatal — surface later via an error banner; for now swallow.
        }
    }

    private func commitCreate() {
        let trimmed = trimmedName
        guard !trimmed.isEmpty else { return }
        let category = categories.first(where: { $0.id == selectedCategoryID })
        _ = try? ChecklistStore.create(name: trimmed, category: category, in: ctx)
        dismiss()
    }
}
```

- [ ] **Step 2: Wire into HomeView**

Replace the placeholder `.sheet(isPresented: $showCreateSheet) { ... }` in `HomeView` with:

```swift
.sheet(isPresented: $showCreateSheet) {
    CreateChecklistSheet()
}
```

- [ ] **Step 3: Write tests for Create behavior**

Create `Checklist/Checklist/ChecklistTests/Sheets/CreateChecklistSheetTests.swift`:

```swift
import XCTest
import SwiftData
@testable import Checklist

/// Tests the Store-layer commits that CreateChecklistSheet invokes. The view
/// itself is exercised via SwiftUI previews; this file verifies the
/// data-side contract.
final class CreateChecklistSheetTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Checklist.self, ChecklistCategory.self, Item.self, Tag.self,
                Run.self, Check.self, CompletedRun.self,
            configurations: makeTestConfig()
        )
        return ModelContext(container)
    }

    func test_create_without_category_persists_checklist() throws {
        let ctx = try makeContext()
        _ = try ChecklistStore.create(name: "Road Trip", category: nil, in: ctx)
        let lists = try ctx.fetch(FetchDescriptor<Checklist>())
        XCTAssertEqual(lists.count, 1)
        XCTAssertEqual(lists.first?.name, "Road Trip")
        XCTAssertNil(lists.first?.category)
    }

    func test_create_with_category_assigns_relationship() throws {
        let ctx = try makeContext()
        let travel = try CategoryStore.create(name: "Travel", in: ctx)
        _ = try ChecklistStore.create(name: "Europe 2026", category: travel, in: ctx)
        let lists = try ctx.fetch(FetchDescriptor<Checklist>())
        XCTAssertEqual(lists.first?.category?.id, travel.id)
    }

    func test_new_category_then_use_it_in_same_context() throws {
        let ctx = try makeContext()
        // Simulates "+ New" inline flow
        let cat = try CategoryStore.create(name: "Weekend", in: ctx)
        let list = try ChecklistStore.create(name: "Beach Day", category: cat, in: ctx)
        XCTAssertEqual(list.category?.name, "Weekend")
    }
}
```

- [ ] **Step 4: Build + test**

Standard build and test. Expected: 61 prior + 3 new = 64 tests passing.

- [ ] **Step 5: Visual verify in preview**

Add `#Preview` blocks to `CreateChecklistSheet.swift`:

```swift
#Preview("Empty") {
    let container = try! SeedStore.container(for: .seededMulti)
    return Color.gray.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            CreateChecklistSheet()
                .modelContainer(container)
        }
}
```

Open in Xcode canvas; confirm the sheet renders with seeded categories (Travel, Daily, Home). Compare visually to capture 29 (empty form) and capture 30 (name typed → Create enabled).

- [ ] **Step 6: Commit**

```bash
git add Checklist/Checklist/Checklist/Sheets/CreateChecklistSheet.swift \
        Checklist/Checklist/Checklist/Views/HomeView.swift \
        Checklist/Checklist/ChecklistTests/Sheets/CreateChecklistSheetTests.swift
git commit -m "feat(sheets): CreateChecklistSheet with inline + New category"
```

---

## Task 4.6: Placeholder RunView target + Home navigation wiring

**Files:**
- Create: `Checklist/Checklist/Checklist/Views/ChecklistRunView.swift` (placeholder)
- Modify: `Checklist/Checklist/Checklist/Views/HomeView.swift`

Phase 5 owns the full `ChecklistRunView`. Phase 4 needs a minimal placeholder target so the Home→Run tap navigation works end-to-end and can be visually verified.

- [ ] **Step 1: Create placeholder ChecklistRunView**

Write `Checklist/Checklist/Checklist/Views/ChecklistRunView.swift`:

```swift
import SwiftUI
import SwiftData

/// PLACEHOLDER (Task 4.6). Full implementation lands in Phase 5. For now the
/// view just renders the checklist's name and an item count so Home's
/// navigation push is verifiable end-to-end.
struct ChecklistRunView: View {
    let checklist: Checklist

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 16) {
                Text(checklist.category?.name.uppercased() ?? "")
                    .font(Theme.eyebrow())
                    .tracking(2)
                    .foregroundColor(Theme.dim)
                Text(checklist.name)
                    .font(Theme.display(size: 28))
                    .foregroundColor(Theme.text)
                Text("\(checklist.items?.count ?? 0) items · Phase-5 UI coming")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.dim)
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                // System nav bar will supply the back chevron; nothing extra needed here.
                EmptyView()
            }
        }
    }
}
```

- [ ] **Step 2: Wire NavigationStack in HomeView**

Modify `HomeView`: add a `@State private var path = NavigationPath()` and use `NavigationStack(path: $path)`. Inside, add `.navigationDestination(for: Checklist.self) { ChecklistRunView(checklist: $0) }`. Update the card tap closure to push:

```swift
ChecklistCard(...) {
    path.append(list)
}
```

Full updated `body` structure reference:

```swift
var body: some View {
    NavigationStack(path: $path) {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        titleBlock
                        if !categories.isEmpty {
                            CategoryFilterChipsView(
                                categories: categories,
                                selectedCategoryID: $selectedCategoryID
                            )
                        }
                        cardsSection
                        SummaryCardsRow(
                            tagCount: tags.count,
                            historyCount: completedRuns.count
                        )
                        .padding(.top, Theme.Spacing.md)
                        Spacer(minLength: 40)
                    }
                    .padding(.top, Theme.Spacing.md)
                }
            }
        }
        .navigationDestination(for: Checklist.self) { list in
            ChecklistRunView(checklist: list)
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateChecklistSheet()
        }
    }
}
```

Because `Checklist` is a SwiftData `@Model` class, it conforms to `Hashable` via its `id`. `NavigationPath` accepts it directly.

- [ ] **Step 3: Build + run, exercise navigation**

Standard build. Run the simulator. With at least one checklist created (either via the Create sheet or because the seed persists), tap a card. Verify:
- Push animation
- Placeholder screen shows the category (uppercased), name, item count
- Back chevron returns to Home

Screenshot both states:

```bash
xcrun simctl io booted screenshot /tmp/task-4-6-home.png && sips -Z 1800 /tmp/task-4-6-home.png >/dev/null
xcrun simctl io booted screenshot /tmp/task-4-6-runview.png && sips -Z 1800 /tmp/task-4-6-runview.png >/dev/null
```

- [ ] **Step 4: Commit**

```bash
git add Checklist/Checklist/Checklist/Views/ChecklistRunView.swift \
        Checklist/Checklist/Checklist/Views/HomeView.swift
git commit -m "feat(views): placeholder ChecklistRunView + Home push navigation"
```

---

## Task 4.7: Phase 4 visual verification

**Files:** none modified; validation only.

- [ ] **Step 1: Drive app through each seeded state via preview canvas**

In Xcode, open `HomeView.swift` and activate the canvas. Cycle through the three `#Preview` variants (seeded / empty / one list). Take a screenshot of each (use Xcode's canvas "Export Preview Image" or the simulator with a SeedStore deep link).

Alternative: if the simulator's runtime data is at an inconvenient state, temporarily wrap the ModelContainer in `ChecklistApp.swift` with `try! SeedStore.container(for: .seededMulti)` for a visual check, screenshot, revert. **Do not commit the seeded swap.**

- [ ] **Step 2: Diff against prototype captures**

Compare side-by-side to:
- `docs/superpowers/prototype-captures/01-home-seeded.png` — seeded, all lists visible
- `docs/superpowers/prototype-captures/02-home-empty.png` — empty state + "+ New list" button
- `docs/superpowers/prototype-captures/03-home-one-list.png` — single card
- `docs/superpowers/prototype-captures/29-create-checklist-sheet.png` — create sheet empty
- `docs/superpowers/prototype-captures/30-create-checklist-with-name.png` — create sheet with name

Read both PNGs side by side. Flag any layout/color/typography deltas. **Acceptable deltas:** font metrics (system fallback vs Inter Tight), chip corner sharpness, minor spacing. **Unacceptable:** wrong eyebrow text ("Collections" instead of "Categories"), missing chips, wrong selection highlight color, empty state missing button, Create button enabled when name empty.

Document any unacceptable deltas in `docs/superpowers/visual-diff/phase-4/home.md` with checkboxes — fix before proceeding.

- [ ] **Step 3: Run full test suite**

Standard test command. Expected: 64 tests passing (58 prior + 3 RunProgress + 3 CreateChecklistSheet).

- [ ] **Step 4: Commit the visual-diff notes (if any)**

```bash
git add docs/superpowers/visual-diff/phase-4/
git commit -m "docs: Phase 4 Home visual-diff report vs prototype captures"
```

(Skip if no diff doc was needed.)

---

# Phase 5 — ChecklistRunView

## Task 5.1: ChecklistRunView scaffold + empty-items state

**Files:**
- Modify: `Checklist/Checklist/Checklist/Views/ChecklistRunView.swift` (replace placeholder)

Prototype ref: capture 11 (empty items). Shows just "CATEGORY" eyebrow, checklist name, and dashed "+ Add item" row. No progress bar, no tag chip row, no items.

- [ ] **Step 1: Replace the placeholder with a real scaffold**

Overwrite `Checklist/Checklist/Checklist/Views/ChecklistRunView.swift`:

```swift
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

    private var currentRun: Run? {
        guard let id = currentRunID else { return nil }
        return (checklist.runs ?? []).first(where: { $0.id == id })
    }

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
                        // Body fills in across Tasks 5.3 through 5.13.
                        if sortedItems.isEmpty {
                            emptyItemsBody
                        } else {
                            Text("Items list coming in Task 5.3")
                                .foregroundColor(Theme.dim)
                                .padding(.horizontal, Theme.Spacing.xl)
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

    private var topBar: some View {
        TopBar(
            left: { BackButton() },
            right: { IconButton(iconName: "more") { showMenu = true } }
        )
    }

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

    private var emptyItemsBody: some View {
        // Dashed "+ Add item" row (capture 11)
        AddItemRowStub { showAddItem = true }
            .padding(.horizontal, Theme.Spacing.xl)
    }

    // MARK: - Current-run management

    /// Selects or auto-creates a current Run per ARCHITECTURE §3e. Called
    /// on appear. If multiple live runs exist, picks the earliest by
    /// startedAt — matching the same "primary run" definition used on Home.
    private func ensureCurrentRun() {
        let liveRuns = (checklist.runs ?? []).sorted(by: { $0.startedAt < $1.startedAt })
        if let primary = liveRuns.first {
            currentRunID = primary.id
        } else {
            // Do NOT auto-create here. Auto-create happens on first mutating
            // interaction (Tasks 5.3 / 5.4 / 5.8). This keeps the
            // "no current run" view (capture 12) reachable.
            currentRunID = nil
        }
    }
}

/// System-back-style chevron rendered as an IconButton so the visual style
/// matches the prototype's circular icon buttons.
private struct BackButton: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        IconButton(iconName: "back") { dismiss() }
    }
}

/// Temporary until Task 5.8 replaces it with the full AddItemInline.
private struct AddItemRowStub: View {
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
```

- [ ] **Step 2: Add preview for empty-items state**

Append to `ChecklistRunView.swift`:

```swift
#Preview("Empty items") {
    let container = try! SeedStore.container(for: .oneList)
    let ctx = ModelContext(container)
    let list = try! ctx.fetch(FetchDescriptor<Checklist>()).first!
    // Remove all items to exercise the empty body
    for item in list.items ?? [] { ctx.delete(item) }
    try! ctx.save()
    return NavigationStack { ChecklistRunView(checklist: list) }
        .modelContainer(container)
}

#Preview("Seeded (Packing List)") {
    let container = try! SeedStore.container(for: .seededMulti)
    let ctx = ModelContext(container)
    let list = try! ctx.fetch(FetchDescriptor<Checklist>()).first(where: { $0.name == "Packing List" })!
    return NavigationStack { ChecklistRunView(checklist: list) }
        .modelContainer(container)
}
```

- [ ] **Step 3: Build + verify previews**

Standard build. Open in Xcode canvas. Both previews render without crash. "Empty items" shows dashed row only.

- [ ] **Step 4: Commit**

```bash
git add Checklist/Checklist/Checklist/Views/ChecklistRunView.swift
git commit -m "feat(views): ChecklistRunView scaffold with empty-items state"
```

---

## Task 5.2: ItemRow component

**Files:**
- Create: `Checklist/Checklist/Checklist/Views/ItemRow.swift`

Prototype ref: capture 04. Rows are capsule cards with `Facet` on the left, text (struck-through when complete), optional `TagChip`s on the right. Completed rows dim the text.

- [ ] **Step 1: Write ItemRow**

Write `Checklist/Checklist/Checklist/Views/ItemRow.swift`:

```swift
import SwiftUI

/// A single row in ChecklistRunView. Displays the Facet checkbox, item text,
/// and any tag chips. State (complete / ignored / neither) is passed in by
/// the parent; this view does not read from SwiftData.
///
/// Interactions: tapping the facet invokes onToggleCheck; tapping the row
/// body invokes onTapBody (typically opens ItemEditInline).
struct ItemRow: View {
    enum Display { case incomplete, complete, ignored }

    let text: String
    let tags: [(name: String, iconName: String, colorHue: Double)]
    let display: Display
    let onToggleCheck: () -> Void
    let onTapBody: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Button(action: onToggleCheck) {
                Facet(
                    color: facetColor,
                    checked: display == .complete,
                    size: 24
                )
            }
            .buttonStyle(.plain)

            Button(action: onTapBody) {
                HStack {
                    Text(text)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(textColor)
                        .strikethrough(display == .complete, color: Theme.dim)
                    Spacer()
                    tagChips
                }
            }
            .buttonStyle(.plain)
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
        .opacity(display == .ignored ? 0.45 : 1)
    }

    private var facetColor: Color {
        // First tag's hue drives the facet tint, else amethyst default.
        if let hue = tags.first?.colorHue { return Theme.gemColor(hue: hue) }
        return Theme.amethyst
    }

    private var textColor: Color {
        switch display {
        case .incomplete: return Theme.text
        case .complete:   return Theme.dim
        case .ignored:    return Theme.dimmer
        }
    }

    private var tagChips: some View {
        HStack(spacing: 4) {
            ForEach(tags.indices, id: \.self) { i in
                let t = tags[i]
                TagChip(
                    name: t.name,
                    iconName: t.iconName,
                    colorHue: t.colorHue,
                    muted: display != .incomplete,
                    small: true
                )
            }
        }
    }
}

#Preview("ItemRow states") {
    VStack(spacing: 10) {
        ItemRow(
            text: "Toothbrush",
            tags: [],
            display: .complete,
            onToggleCheck: {}, onTapBody: {}
        )
        ItemRow(
            text: "Sandals",
            tags: [(name: "Beach", iconName: "sun", colorHue: 85)],
            display: .incomplete,
            onToggleCheck: {}, onTapBody: {}
        )
        ItemRow(
            text: "Skis",
            tags: [(name: "Snow", iconName: "snow", colorHue: 250)],
            display: .ignored,
            onToggleCheck: {}, onTapBody: {}
        )
    }
    .padding()
    .background(Theme.bg)
}
```

- [ ] **Step 2: Build + preview check**

Standard build. Open in Xcode canvas. All three rows render correctly: struck-through / clean / dimmed.

- [ ] **Step 3: Commit**

```bash
git add Checklist/Checklist/Checklist/Views/ItemRow.swift
git commit -m "feat(views): ItemRow with Facet + tag chips + complete/ignored states"
```

---

## Task 5.3: Wire item list into ChecklistRunView

**Files:**
- Modify: `Checklist/Checklist/Checklist/Views/ChecklistRunView.swift`

Replace the `Text("Items list coming …")` placeholder with a real rendered list. No check toggling yet — that's Task 5.4.

- [ ] **Step 1: Add the items section**

In `ChecklistRunView`, add a computed section:

```swift
private var itemsSection: some View {
    LazyVStack(spacing: Theme.Spacing.xs) {
        ForEach(sortedItems) { item in
            ItemRow(
                text: item.text,
                tags: tagTuples(for: item),
                display: display(for: item),
                onToggleCheck: { /* Task 5.4 */ },
                onTapBody:     { editingItem = item }  // Opens ItemEditInline in Task 5.9
            )
        }
        AddItemRowStub { showAddItem = true }
    }
    .padding(.horizontal, Theme.Spacing.xl)
}

private func display(for item: Item) -> ItemRow.Display {
    guard let run = currentRun,
          let check = (run.checks ?? []).first(where: { $0.itemID == item.id })
    else { return .incomplete }
    switch check.state {
    case .complete: return .complete
    case .ignored:  return .ignored
    }
}

private func tagTuples(for item: Item) -> [(name: String, iconName: String, colorHue: Double)] {
    (item.tags ?? []).map { (name: $0.name, iconName: $0.iconName, colorHue: $0.colorHue) }
}
```

Replace the placeholder `else` branch in `body` with `itemsSection`.

- [ ] **Step 2: Build + verify preview**

Standard build. Open the "Seeded (Packing List)" preview. Expected: 4 items render (Toothbrush, Passport, Sandals, Thermal layers), none checked (seeded run has no checks).

- [ ] **Step 3: Commit**

```bash
git add Checklist/Checklist/Checklist/Views/ChecklistRunView.swift
git commit -m "feat(views): render item list in ChecklistRunView (no toggle yet)"
```

---

## Task 5.4: Tap-to-toggle checks + auto-create run

**Files:**
- Modify: `Checklist/Checklist/Checklist/Views/ChecklistRunView.swift`

Per ARCHITECTURE §3e, tapping a facet on a Checklist with no live run should auto-create a Run before toggling.

- [ ] **Step 1: Implement tap toggle**

Add to `ChecklistRunView`:

```swift
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
```

Replace the empty closure in `itemsSection`'s `onToggleCheck:` with `{ handleToggleCheck(item) }`.

- [ ] **Step 2: Build + verify interaction**

Build. Run the simulator (or use the preview canvas with interactive mode enabled). Tap a facet on a seeded checklist without a live run: item becomes checked, a Run is silently created.

- [ ] **Step 3: Add a unit test for the auto-create contract**

Append to `Checklist/Checklist/ChecklistTests/Views/HomeViewTests.swift` (reusing its context helpers), or create a dedicated `ChecklistRunViewTests.swift`:

Create `Checklist/Checklist/ChecklistTests/Views/ChecklistRunViewTests.swift`:

```swift
import XCTest
import SwiftData
@testable import Checklist

/// Tests for the view-level behaviors that are easy to verify without
/// rendering: current-run selection, auto-create, state derivation.
final class ChecklistRunViewTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Checklist.self, ChecklistCategory.self, Item.self, Tag.self,
                Run.self, Check.self, CompletedRun.self,
            configurations: makeTestConfig()
        )
        return ModelContext(container)
    }

    func test_first_toggle_auto_creates_run() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "T", in: ctx)
        let item = try ChecklistStore.addItem(text: "A", to: list, in: ctx)

        // Simulate what ChecklistRunView.handleToggleCheck does:
        // no run exists → startRun → toggleCheck.
        XCTAssertEqual(list.runs?.count ?? 0, 0)
        let run = try RunStore.startRun(on: list, in: ctx)
        try RunStore.toggleCheck(run: run, itemID: item.id, in: ctx)

        XCTAssertEqual(list.runs?.count, 1)
        XCTAssertEqual(run.checks?.count, 1)
        XCTAssertEqual(run.checks?.first?.state, .complete)
    }

    func test_second_toggle_clears_check() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "T", in: ctx)
        let item = try ChecklistStore.addItem(text: "A", to: list, in: ctx)
        let run = try RunStore.startRun(on: list, in: ctx)

        try RunStore.toggleCheck(run: run, itemID: item.id, in: ctx)
        try RunStore.toggleCheck(run: run, itemID: item.id, in: ctx)

        XCTAssertEqual(run.checks?.count ?? 0, 0)
    }
}
```

Standard test. Expected: 64 prior + 2 new = 66 tests passing.

- [ ] **Step 4: Commit**

```bash
git add Checklist/Checklist/Checklist/Views/ChecklistRunView.swift \
        Checklist/Checklist/ChecklistTests/Views/ChecklistRunViewTests.swift
git commit -m "feat(views): tap-to-toggle checks with auto-create run (§3e)"
```

---

## Task 5.5: Progress bar + fraction

**Files:**
- Modify: `Checklist/Checklist/Checklist/Views/ChecklistRunView.swift`

Prototype ref: capture 04. Progress block sits between the title and the item list. Layout: GemBar on the left, "PROGRESS X of Y" eyebrow + "X%" percentage on the right.

- [ ] **Step 1: Add progress row to the scaffold**

In `ChecklistRunView`, add a `progressRow` view and insert it into the scrolling `VStack` just above `itemsSection` (but only when `currentRun != nil` and `sortedItems.isNotEmpty`):

```swift
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
```

Insert `progressRow` in the `body`'s scroll `VStack` between `headerBlock` and the items section.

- [ ] **Step 2: Build + preview**

Build. In the Seeded (Packing List) preview, with the seeded Tokyo run (no checks), the progress should read `0 of 4` and `0%` (matching the 4 seeded items). Toggle a few facets and watch the number update.

- [ ] **Step 3: Commit**

```bash
git add Checklist/Checklist/Checklist/Views/ChecklistRunView.swift
git commit -m "feat(views): progress bar with done/total + percent on run view"
```

---

## Task 5.6: Tag hide chip bar

**Files:**
- Create: `Checklist/Checklist/Checklist/Views/TagHideChipBar.swift`
- Modify: `Checklist/Checklist/Checklist/Views/ChecklistRunView.swift`

Prototype ref: capture 04. Horizontal scrolling row of `TagHideChip` instances — one per tag referenced by any item on this checklist. Tap toggles the tag's hide state on the current run.

- [ ] **Step 1: Create TagHideChipBar**

Write `Checklist/Checklist/Checklist/Views/TagHideChipBar.swift`:

```swift
import SwiftUI

/// Horizontal scrolling chip row. One chip per tag used by at least one item
/// on the checklist. Tapping toggles whether that tag is hidden on the
/// current run (the chip's visual muted/filled state reflects this).
struct TagHideChipBar: View {
    let tags: [Tag]
    let hiddenTagIDs: [UUID]
    let onToggle: (UUID) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(tags) { tag in
                    TagHideChip(
                        name: tag.name,
                        iconName: tag.iconName,
                        colorHue: tag.colorHue,
                        hidden: hiddenTagIDs.contains(tag.id)
                    ) {
                        onToggle(tag.id)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
        }
    }
}
```

- [ ] **Step 2: Wire into ChecklistRunView**

In `ChecklistRunView`, add:

```swift
private var usedTags: [Tag] {
    let ids = Set((sortedItems.flatMap { $0.tags ?? [] }).map(\.id))
    // Fetch in a stable order — use the name alphabetically.
    return (sortedItems.flatMap { $0.tags ?? [] })
        .reduce(into: [Tag]()) { acc, t in
            if !acc.contains(where: { $0.id == t.id }) { acc.append(t) }
        }
        .filter { ids.contains($0.id) }
        .sorted { $0.name < $1.name }
}

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
```

Insert `tagChipBar` in the scrolling `VStack` between `headerBlock` and `progressRow`.

- [ ] **Step 3: Build + preview**

Build. The seeded Packing List preview should show 3 chips (Beach, Intl, Snow — ordered alphabetically) in fully-lit state. Tap one; chip switches to the hidden style, and `progressRow` updates because items with that tag drop out of `RunProgress.total`.

- [ ] **Step 4: Commit**

```bash
git add Checklist/Checklist/Checklist/Views/TagHideChipBar.swift \
        Checklist/Checklist/Checklist/Views/ChecklistRunView.swift
git commit -m "feat(views): tag hide chip bar on run view"
```

---

## Task 5.7: Swipe actions (complete + delete with multi-run warning)

**Files:**
- Modify: `Checklist/Checklist/Checklist/Views/ChecklistRunView.swift`

Per spec §7: swipe right = complete (toggle check), swipe left = delete (warn if ≥2 live runs).

- [ ] **Step 1: Add swipe actions to the ForEach**

Replace the simple `ForEach` in `itemsSection` with one that attaches `.swipeActions`:

```swift
ForEach(sortedItems) { item in
    ItemRow(...) // unchanged
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
```

- [ ] **Step 2: Add delete handler with multi-run warning**

```swift
@State private var pendingDelete: Item? = nil
@State private var showDeleteWarning = false

private func attemptDelete(_ item: Item) {
    let liveRuns = checklist.runs?.count ?? 0
    if liveRuns >= 2 {
        pendingDelete = item
        showDeleteWarning = true
    } else {
        commitDelete(item)
    }
}

private func commitDelete(_ item: Item) {
    try? ChecklistStore.deleteItem(item, in: ctx)
    pendingDelete = nil
    showDeleteWarning = false
}
```

Add the warning alert to `body`:

```swift
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
```

**Important note:** `swipeActions` works inside a `List`, not a `LazyVStack`. This is a SwiftUI limitation. Decision: **migrate `itemsSection` from `LazyVStack` to `List`**. Because `List` has its own background and separators, apply these modifiers to keep the gem look:

```swift
.listStyle(.plain)
.scrollContentBackground(.hidden)
.listRowBackground(Color.clear)   // on each row
.listRowSeparator(.hidden)        // on each row
.listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
```

Full updated `itemsSection`:

```swift
private var itemsSection: some View {
    List {
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
        // Add-item row as a List row at the end so it lives in the same
        // scroll. Manage tags from Task 5.8 replaces the stub.
        AddItemRowStub { showAddItem = true }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .frame(minHeight: CGFloat(sortedItems.count + 1) * 58)
    .padding(.horizontal, Theme.Spacing.xl)
}
```

Also remove the outer `ScrollView` around the sections — `List` is its own scroller. Restructure `body` so the top is fixed (topBar, headerBlock, tagChipBar, progressRow) and the bottom is `itemsSection`:

```swift
VStack(spacing: 0) {
    topBar
    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
        headerBlock
        tagChipBar
        progressRow
    }
    .padding(.top, Theme.Spacing.md)
    itemsSection
}
```

- [ ] **Step 3: Build + verify swipes**

Build and exercise on the simulator with a seeded multi-run fixture: swipe right on an item → check applied; swipe left on an item → delete warning if multi-run else deletes silently.

- [ ] **Step 4: Commit**

```bash
git add Checklist/Checklist/Checklist/Views/ChecklistRunView.swift
git commit -m "feat(views): swipe actions (complete + delete w/ multi-run warning)"
```

---

## Task 5.8: AddItemInline

**Files:**
- Create: `Checklist/Checklist/Checklist/Sheets/AddItemInline.swift`
- Modify: `Checklist/Checklist/Checklist/Views/ChecklistRunView.swift`

Prototype ref: capture 13. The dashed "+ Add item" row, when tapped, expands in place to a form: text input, tag chip row (each chip toggles), optional new-tag pill, Save + Cancel. No "ADDS TO: all live / future only" chip (§7 rule).

Implementation decision: a sheet (not truly inline) because SwiftUI `List` + inline expanding rows is messy. Present as a `.sheet(isPresented: $showAddItem)` with `.presentationDetents([.medium])`.

- [ ] **Step 1: Write AddItemInline**

Write `Checklist/Checklist/Checklist/Sheets/AddItemInline.swift`:

```swift
import SwiftUI
import SwiftData

/// Sheet for adding a new item to a checklist. Collects text + optional tags.
/// Invokes ChecklistStore.addItem on save.
///
/// Note: presented as a sheet rather than an inline-expand row because
/// SwiftUI Lists don't tolerate inline expansion cleanly. Visual match to
/// capture 13 is close-enough given the sheet chrome.
struct AddItemInline: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    let checklist: Checklist
    @Query(sort: [SortDescriptor(\Tag.sortKey, order: .forward)]) private var allTags: [Tag]

    @State private var text: String = ""
    @State private var selectedTagIDs: Set<UUID> = []

    var body: some View {
        BottomSheet {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("NEW ITEM")
                    .font(Theme.eyebrow())
                    .tracking(2)
                    .foregroundColor(Theme.dim)

                TextField("Item", text: $text)
                    .foregroundColor(Theme.text)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Color.white.opacity(0.06)))
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.border, lineWidth: 1))
                    .submitLabel(.done)

                if !allTags.isEmpty {
                    Text("TAGS")
                        .font(Theme.eyebrow())
                        .tracking(2)
                        .foregroundColor(Theme.dim)

                    tagSelectRow
                }

                HStack(spacing: Theme.Spacing.sm) {
                    PillButton(title: "Cancel", tone: .ghost, wide: true) { dismiss() }
                    PillButton(
                        title: "Add",
                        color: Theme.amethyst,
                        wide: true,
                        disabled: trimmed.isEmpty
                    ) { commit() }
                }
                .padding(.top, Theme.Spacing.sm)
            }
        }
    }

    private var trimmed: String { text.trimmingCharacters(in: .whitespaces) }

    private var tagSelectRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(allTags) { tag in
                    tagChip(tag)
                }
            }
        }
    }

    private func tagChip(_ tag: Tag) -> some View {
        let selected = selectedTagIDs.contains(tag.id)
        return Button {
            if selected {
                selectedTagIDs.remove(tag.id)
            } else {
                selectedTagIDs.insert(tag.id)
            }
        } label: {
            TagChip(
                name: tag.name,
                iconName: tag.iconName,
                colorHue: tag.colorHue,
                muted: !selected,
                small: false
            )
        }
        .buttonStyle(.plain)
    }

    private func commit() {
        guard !trimmed.isEmpty else { return }
        let tags = allTags.filter { selectedTagIDs.contains($0.id) }
        _ = try? ChecklistStore.addItem(text: trimmed, to: checklist, tags: tags, in: ctx)
        dismiss()
    }
}
```

- [ ] **Step 2: Wire into ChecklistRunView**

Add to `body`:

```swift
.sheet(isPresented: $showAddItem) {
    AddItemInline(checklist: checklist)
}
```

- [ ] **Step 3: Build + exercise**

Build. On seeded Packing List, tap `+ Add item`, type a name, select tags, tap Add. New row appears.

- [ ] **Step 4: Commit**

```bash
git add Checklist/Checklist/Checklist/Sheets/AddItemInline.swift \
        Checklist/Checklist/Checklist/Views/ChecklistRunView.swift
git commit -m "feat(sheets): AddItemInline (name + tag select) via sheet"
```

---

## Task 5.9: ItemEditInline (with ignore toggle)

**Files:**
- Create: `Checklist/Checklist/Checklist/Sheets/ItemEditInline.swift`
- Modify: `Checklist/Checklist/Checklist/Views/ChecklistRunView.swift`

Editing an existing item: rename, re-tag, OR toggle ignore state for the current run. Per spec §2, no Delete here (swipe covers it).

- [ ] **Step 1: Write ItemEditInline**

Write `Checklist/Checklist/Checklist/Sheets/ItemEditInline.swift`:

```swift
import SwiftUI
import SwiftData

/// Sheet for editing an existing item. Supports rename, tag reassignment,
/// and per-run ignore toggle. Invoked from ItemRow's body tap.
struct ItemEditInline: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    let item: Item
    let currentRun: Run?

    @Query(sort: [SortDescriptor(\Tag.sortKey, order: .forward)]) private var allTags: [Tag]

    @State private var text: String = ""
    @State private var selectedTagIDs: Set<UUID> = []
    @State private var ignored: Bool = false

    var body: some View {
        BottomSheet {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("EDIT ITEM")
                    .font(Theme.eyebrow())
                    .tracking(2)
                    .foregroundColor(Theme.dim)

                TextField("Item", text: $text)
                    .foregroundColor(Theme.text)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Color.white.opacity(0.06)))
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.border, lineWidth: 1))

                if !allTags.isEmpty {
                    Text("TAGS")
                        .font(Theme.eyebrow()).tracking(2).foregroundColor(Theme.dim)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Theme.Spacing.xs) {
                            ForEach(allTags) { tag in
                                let selected = selectedTagIDs.contains(tag.id)
                                Button {
                                    if selected { selectedTagIDs.remove(tag.id) }
                                    else        { selectedTagIDs.insert(tag.id) }
                                } label: {
                                    TagChip(
                                        name: tag.name, iconName: tag.iconName,
                                        colorHue: tag.colorHue,
                                        muted: !selected, small: false
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                if currentRun != nil {
                    Toggle("Ignore for this run", isOn: $ignored)
                        .foregroundColor(Theme.text)
                        .tint(Theme.citrine)
                }

                HStack(spacing: Theme.Spacing.sm) {
                    PillButton(title: "Cancel", tone: .ghost, wide: true) { dismiss() }
                    PillButton(title: "Save", color: Theme.amethyst, wide: true) { commit() }
                }
                .padding(.top, Theme.Spacing.sm)
            }
        }
        .onAppear {
            text = item.text
            selectedTagIDs = Set((item.tags ?? []).map(\.id))
            if let run = currentRun,
               let check = (run.checks ?? []).first(where: { $0.itemID == item.id }),
               check.state == .ignored {
                ignored = true
            }
        }
    }

    private func commit() {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty, trimmed != item.text {
            try? ChecklistStore.renameItem(item, to: trimmed, in: ctx)
        }
        let newTags = allTags.filter { selectedTagIDs.contains($0.id) }
        let existingTagIDs = Set((item.tags ?? []).map(\.id))
        if existingTagIDs != selectedTagIDs {
            try? ChecklistStore.setItemTags(item, to: newTags, in: ctx)
        }
        if let run = currentRun {
            let currentlyIgnored = (run.checks ?? []).first(where: { $0.itemID == item.id })?.state == .ignored
            if ignored != currentlyIgnored {
                try? RunStore.setIgnored(run: run, itemID: item.id, to: ignored, in: ctx)
            }
        }
        dismiss()
    }
}
```

- [ ] **Step 2: Wire into ChecklistRunView**

Add to `body`:

```swift
.sheet(item: $editingItem) { item in
    ItemEditInline(item: item, currentRun: currentRun)
}
```

`Item` already conforms to `Identifiable` via SwiftData's `@Model`, so this works.

- [ ] **Step 3: Build + exercise**

Rename an item, reassign tags, toggle Ignore. Confirm each round-trips.

- [ ] **Step 4: Commit**

```bash
git add Checklist/Checklist/Checklist/Sheets/ItemEditInline.swift \
        Checklist/Checklist/Checklist/Views/ChecklistRunView.swift
git commit -m "feat(sheets): ItemEditInline with rename/tags/ignore"
```

---

## Task 5.10: ChecklistMenuSheet (default + all variants)

**Files:**
- Create: `Checklist/Checklist/Checklist/Sheets/ChecklistMenuSheet.swift`
- Modify: `Checklist/Checklist/Checklist/Views/ChecklistRunView.swift`

Prototype refs: captures 14 (default), 15 (rename list), 16 (name run), 17 (delete confirm). Per spec §2 the v4 menu drops Set due date / Set repeat schedule / Archive list. v4 menu rows:

1. Rename this run
2. Rename list (+ category)
3. Manage tags (→ TagsView, not in this plan — placeholder action)
4. Full history for this list (→ HistoryView, not in this plan — placeholder action)
5. Delete list (danger, ruby)

- [ ] **Step 1: Write ChecklistMenuSheet**

Write `Checklist/Checklist/Checklist/Sheets/ChecklistMenuSheet.swift`:

```swift
import SwiftUI
import SwiftData

/// Sheet presented by the kebab on ChecklistRunView. Has four variants:
/// default menu, rename-run, rename-list (+ category), delete confirm.
///
/// Cut from prototype per spec §2: Set due date, Set repeat schedule,
/// Archive list.
struct ChecklistMenuSheet: View {
    enum Variant {
        case menu
        case nameRun
        case renameList
        case deleteConfirm
    }

    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    let checklist: Checklist
    let currentRun: Run?
    @State var variant: Variant = .menu

    @Query(sort: [SortDescriptor(\ChecklistCategory.sortKey, order: .forward)])
    private var categories: [ChecklistCategory]

    @State private var runNameInput = ""
    @State private var listNameInput = ""
    @State private var selectedCategoryID: UUID? = nil

    var body: some View {
        BottomSheet {
            switch variant {
            case .menu:          menuContent
            case .nameRun:       nameRunContent
            case .renameList:    renameListContent
            case .deleteConfirm: deleteConfirmContent
            }
        }
        .onAppear(perform: seedInputs)
    }

    private func seedInputs() {
        runNameInput = currentRun?.name ?? ""
        listNameInput = checklist.name
        selectedCategoryID = checklist.category?.id
    }

    // MARK: - Default menu (capture 14)
    private var menuContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(checklist.name.uppercased())
                .font(Theme.eyebrow()).tracking(2).foregroundColor(Theme.dim)
                .padding(.bottom, Theme.Spacing.sm)
            menuRow(icon: "edit", title: "Rename this run", tone: .normal) {
                variant = .nameRun
            }
            .disabled(currentRun == nil)
            menuRow(icon: "edit", title: "Rename list", tone: .normal) { variant = .renameList }
            menuRow(icon: "tag", title: "Manage tags", tone: .normal) {
                // → TagsView in a later plan. Placeholder: dismiss.
                dismiss()
            }
            menuRow(icon: "history", title: "Full history for this list", tone: .normal) {
                // → HistoryView in a later plan. Placeholder.
                dismiss()
            }
            Divider().background(Theme.border).padding(.vertical, Theme.Spacing.sm)
            menuRow(icon: "trash", title: "Delete list", tone: .danger) { variant = .deleteConfirm }
        }
    }

    private enum RowTone { case normal, danger }

    private func menuRow(icon: String, title: String, tone: RowTone, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                GemIcons.image(icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(tone == .danger ? Theme.ruby : Theme.dim)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(tone == .danger ? Theme.ruby : Theme.text)
                Spacer()
                GemIcons.image("right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Theme.dimmer)
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Name run (capture 16)
    private var nameRunContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("NAME THIS RUN")
                .font(Theme.eyebrow()).tracking(2).foregroundColor(Theme.dim)
            Text("A short label (e.g. \"Tokyo\", \"Week 14\"). Appears everywhere this run is referenced.")
                .font(.system(size: 13))
                .foregroundColor(Theme.dim)
            TextField("", text: $runNameInput)
                .foregroundColor(Theme.text)
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Color.white.opacity(0.06)))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.border, lineWidth: 1))
            HStack(spacing: Theme.Spacing.sm) {
                PillButton(title: "Cancel", tone: .ghost, wide: true) { variant = .menu }
                PillButton(title: "Save", color: Theme.amethyst, wide: true) { commitRenameRun() }
            }
        }
    }

    private func commitRenameRun() {
        guard let run = currentRun else { dismiss(); return }
        try? RunStore.rename(run, to: runNameInput, in: ctx)
        dismiss()
    }

    // MARK: - Rename list + category (capture 15)
    private var renameListContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("RENAME LIST")
                .font(Theme.eyebrow()).tracking(2).foregroundColor(Theme.dim)
            Text("Rename your checklist.")
                .font(Theme.display(size: 26)).foregroundColor(Theme.text)
            TextField("", text: $listNameInput)
                .foregroundColor(Theme.text)
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Color.white.opacity(0.06)))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.border, lineWidth: 1))

            Text("CATEGORY")
                .font(Theme.eyebrow()).tracking(2).foregroundColor(Theme.dim)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.xs) {
                    ForEach(categories) { cat in
                        categoryChip(cat)
                    }
                }
            }

            HStack(spacing: Theme.Spacing.sm) {
                PillButton(title: "Cancel", tone: .ghost, wide: true) { variant = .menu }
                PillButton(
                    title: "Save",
                    color: Theme.amethyst,
                    wide: true,
                    disabled: listNameInput.trimmingCharacters(in: .whitespaces).isEmpty
                ) { commitRenameList() }
            }
        }
    }

    private func categoryChip(_ cat: ChecklistCategory) -> some View {
        let selected = selectedCategoryID == cat.id
        return Button {
            selectedCategoryID = (selected ? nil : cat.id)
        } label: {
            Text(cat.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(selected ? .white : Theme.text)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(
                    Group {
                        if selected {
                            Capsule().fill(LinearGradient(
                                colors: [Theme.amethyst, Theme.sapphire.opacity(0.85)],
                                startPoint: .leading, endPoint: .trailing
                            ))
                        } else {
                            Capsule().fill(Color.white.opacity(0.05))
                        }
                    }
                )
                .overlay(Capsule().stroke(selected ? Color.clear : Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func commitRenameList() {
        let trimmed = listNameInput.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty, trimmed != checklist.name {
            try? ChecklistStore.rename(checklist, to: trimmed, in: ctx)
        }
        let newCat = categories.first(where: { $0.id == selectedCategoryID })
        if newCat?.id != checklist.category?.id {
            try? ChecklistStore.setCategory(checklist, to: newCat, in: ctx)
        }
        dismiss()
    }

    // MARK: - Delete confirm (capture 17)
    private var deleteConfirmContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("DELETE LIST")
                .font(Theme.eyebrow()).tracking(2).foregroundColor(Theme.ruby)
            Text("Delete \(checklist.name) forever.")
                .font(Theme.display(size: 24)).foregroundColor(Theme.text)
            Text(deleteBodyText)
                .font(.system(size: 13)).foregroundColor(Theme.dim)

            PillButton(title: "Delete forever", color: Theme.ruby, wide: true) { commitDelete() }
            PillButton(title: "Cancel", tone: .ghost, wide: true) { variant = .menu }
        }
    }

    private var deleteBodyText: String {
        let past = checklist.completedRuns?.count ?? 0
        let live = checklist.runs?.count ?? 0
        var bits: [String] = []
        if past > 0 { bits.append("\(past) past \(past == 1 ? "run" : "runs")") }
        if live > 0 { bits.append("\(live) live \(live == 1 ? "run" : "runs")") }
        if bits.isEmpty { return "This can't be undone." }
        return "This also removes \(bits.joined(separator: " + ")) from history. This can't be undone."
    }

    private func commitDelete() {
        try? ChecklistStore.delete(checklist, in: ctx)
        dismiss()
    }
}
```

- [ ] **Step 2: Wire into ChecklistRunView**

Add:

```swift
.sheet(isPresented: $showMenu) {
    ChecklistMenuSheet(checklist: checklist, currentRun: currentRun)
}
```

And after commit, pop back to home when the list is deleted (the view's SwiftData query will return a stale reference; handle via `.onChange(of: checklist.isDeleted)` or use `@Environment(\.dismiss)`):

```swift
// In body, below the .sheet:
.onChange(of: checklist.isDeleted) { _, deleted in
    if deleted {
        dismiss()
    }
}
```

(Actually `@Model` classes don't expose `isDeleted`. Use a different approach: detect via `checklist.modelContext == nil` after the delete, or observe the list count. Simpler: the delete action dismisses the sheet, and the query invalidation will unmount this view automatically when `checklist` no longer exists. Skip the onChange — SwiftUI will handle unmount naturally. If testing reveals a hang, add `.onAppear { if checklist.name.isEmpty { dismiss() } }` as a fallback.)

- [ ] **Step 3: Build + exercise each variant**

Verify:
- Menu default opens on kebab tap
- Rename run updates the run name
- Rename list + category both round-trip
- Delete confirm correctly counts past runs

- [ ] **Step 4: Commit**

```bash
git add Checklist/Checklist/Checklist/Sheets/ChecklistMenuSheet.swift \
        Checklist/Checklist/Checklist/Views/ChecklistRunView.swift
git commit -m "feat(sheets): ChecklistMenuSheet with rename/delete variants"
```

---

## Task 5.11: CompletionSheet (3 variants)

**Files:**
- Create: `Checklist/Checklist/Checklist/Sheets/CompletionSheet.swift`
- Create: `Checklist/Checklist/ChecklistTests/Sheets/CompletionSheetTests.swift`
- Modify: `Checklist/Checklist/Checklist/Views/ChecklistRunView.swift`

Prototype refs: 08 (all-done), 09 (partial), 10 (discard confirm).

Variants:
- **All done:** all visible items are checked. Eyebrow "ALL DONE" (emerald), HeroGem emerald, title + run name, body copy, "Complete" emerald solid, "Not yet — keep going" ghost, "Discard run" text link.
- **Partial:** some visible items unchecked. Eyebrow "X OF Y" (citrine), HeroGem citrine, same title, body, "Complete anyway · X/Y" citrine solid, "Not yet — keep going" ghost, "Discard run" link.
- **Discard confirm:** eyebrow "DISCARD RUN?" (ruby), title "This run won't be saved to history.", body copy mentioning checks-count, Cancel + "Discard" ruby.

- [ ] **Step 1: Write CompletionSheet**

Write `Checklist/Checklist/Checklist/Sheets/CompletionSheet.swift`:

```swift
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

    private var eyebrowText: String {
        isAllDone ? "ALL DONE" : "\(progress.done) OF \(progress.total)"
    }

    private var titleLine: String {
        if let runName = run.name {
            return "\(checklist.name) · \(runName)"
        }
        return checklist.name
    }

    private var relativeStartedString: String {
        let seconds = Date().timeIntervalSince(run.startedAt)
        switch seconds {
        case ..<60:       return "just now"
        case ..<3600:     return "\(Int(seconds / 60))m"
        case ..<86_400:   return "\(Int(seconds / 3600))h \(Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60))m"
        default:          return "\(Int(seconds / 86_400))d \(Int((seconds.truncatingRemainder(dividingBy: 86_400)) / 3600))h"
        }
    }

    private var bodyCopy: String {
        if isAllDone {
            return "Finishing saves this run to history and clears the list for next time. \(checklist.name) stays on your home screen, ready for a fresh run."
        } else {
            return "Finishing saves this run to history and clears the list for next time. \(checklist.name) stays on your home screen, ready for a fresh run."
        }
    }

    private func commitComplete() {
        try? RunStore.complete(run, in: ctx)
        dismiss()
    }

    // MARK: - Discard confirm
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

    private func commitDiscard() {
        try? RunStore.discard(run, in: ctx)
        dismiss()
    }
}
```

- [ ] **Step 2: Wire trigger into ChecklistRunView**

Two triggers:
1. Manual: a "Complete" PillButton appears in a bottom action row whenever a live run has any checks.
2. Auto: when the last visible item gets checked, auto-present.

Add to `ChecklistRunView`:

```swift
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
```

Insert `actionRow` after `itemsSection` in `body` (outside the List). Add:

```swift
.sheet(isPresented: $showCompletionSheet) {
    if let run = currentRun {
        CompletionSheet(checklist: checklist, run: run)
    }
}
.onChange(of: currentRun?.checks?.count ?? 0) { _, _ in
    maybeAutoPresentCompletion()
}

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
```

- [ ] **Step 3: Tests for CompletionSheet's state calculations**

Create `Checklist/Checklist/ChecklistTests/Sheets/CompletionSheetTests.swift`:

```swift
import XCTest
import SwiftData
@testable import Checklist

/// Verifies the data-level behavior CompletionSheet relies on: RunProgress
/// "all done" detection, and that RunStore.complete/discard both clear the
/// Run.
final class CompletionSheetTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Checklist.self, ChecklistCategory.self, Item.self, Tag.self,
                Run.self, Check.self, CompletedRun.self,
            configurations: makeTestConfig()
        )
        return ModelContext(container)
    }

    func test_all_done_detection_all_visible_items_complete() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "T", in: ctx)
        let a = try ChecklistStore.addItem(text: "A", to: list, in: ctx)
        let b = try ChecklistStore.addItem(text: "B", to: list, in: ctx)
        let run = try RunStore.startRun(on: list, in: ctx)
        try RunStore.toggleCheck(run: run, itemID: a.id, in: ctx)
        try RunStore.toggleCheck(run: run, itemID: b.id, in: ctx)

        let progress = RunProgress.compute(
            items: list.items ?? [],
            checks: run.checks ?? [],
            hiddenTagIDs: run.hiddenTagIDs
        )
        XCTAssertEqual(progress.done, 2)
        XCTAssertEqual(progress.total, 2)
    }

    func test_complete_creates_CompletedRun_and_removes_live_run() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "T", in: ctx)
        _ = try ChecklistStore.addItem(text: "A", to: list, in: ctx)
        let run = try RunStore.startRun(on: list, name: "Tokyo", in: ctx)

        try RunStore.complete(run, in: ctx)

        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Run>()).count, 0)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<CompletedRun>()).count, 1)
    }

    func test_discard_destroys_run_without_history() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "T", in: ctx)
        let run = try RunStore.startRun(on: list, in: ctx)

        try RunStore.discard(run, in: ctx)

        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Run>()).count, 0)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<CompletedRun>()).count, 0)
    }
}
```

Standard test. Expected: 66 prior + 3 new = 69 tests passing.

- [ ] **Step 4: Commit**

```bash
git add Checklist/Checklist/Checklist/Sheets/CompletionSheet.swift \
        Checklist/Checklist/Checklist/Views/ChecklistRunView.swift \
        Checklist/Checklist/ChecklistTests/Sheets/CompletionSheetTests.swift
git commit -m "feat(sheets): CompletionSheet with all-done/partial/discard variants"
```

---

## Task 5.12: StartRunSheet + RunChooserSheet + multi-run switcher pill

**Files:**
- Create: `Checklist/Checklist/Checklist/Sheets/StartRunSheet.swift`
- Create: `Checklist/Checklist/Checklist/Sheets/RunChooserSheet.swift`
- Modify: `Checklist/Checklist/Checklist/Views/ChecklistRunView.swift`

Prototype refs: capture 05/06 (multi-run chooser sheet), capture 04 (pill "2 live runs ▾" between title and tag chips).

- [ ] **Step 1: StartRunSheet**

Write `Checklist/Checklist/Checklist/Sheets/StartRunSheet.swift`:

```swift
import SwiftUI
import SwiftData

/// Name-only sheet for starting a new concurrent run when ≥1 live run
/// already exists. Per spec §7 this drops the prototype's due-date field.
struct StartRunSheet: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    let checklist: Checklist
    let onStarted: (Run) -> Void

    @State private var name: String = ""

    var body: some View {
        BottomSheet {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("NEW RUN")
                    .font(Theme.eyebrow()).tracking(2).foregroundColor(Theme.dim)
                Text("Name this run.")
                    .font(Theme.display(size: 22)).foregroundColor(Theme.text)
                Text("A short label like \"Tokyo\" or \"Week 14\". Optional — leave blank if you don't care.")
                    .font(.system(size: 13)).foregroundColor(Theme.dim)
                TextField("", text: $name)
                    .foregroundColor(Theme.text)
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Color.white.opacity(0.06)))
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.border, lineWidth: 1))

                HStack(spacing: Theme.Spacing.sm) {
                    PillButton(title: "Cancel", tone: .ghost, wide: true) { dismiss() }
                    PillButton(title: "Start", color: Theme.amethyst, wide: true) { commit() }
                }
            }
        }
    }

    private func commit() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let run = try? RunStore.startRun(on: checklist, name: trimmed.isEmpty ? nil : trimmed, in: ctx) {
            onStarted(run)
        }
        dismiss()
    }
}
```

- [ ] **Step 2: RunChooserSheet**

Write `Checklist/Checklist/Checklist/Sheets/RunChooserSheet.swift`:

```swift
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

    private var totalItems: Int { checklist.items?.count ?? 0 }

    private func doneCount(_ run: Run) -> Int {
        (run.checks ?? []).filter { $0.state == .complete }.count
    }

    private func relativeStarted(_ run: Run) -> String {
        let s = Date().timeIntervalSince(run.startedAt)
        if s < 60 { return "just now" }
        if s < 3600 { return "\(Int(s / 60))m ago" }
        if s < 86_400 { return "\(Int(s / 3600))h ago" }
        return "\(Int(s / 86_400))d ago"
    }
}
```

- [ ] **Step 3: Add switcher pill to ChecklistRunView**

In `ChecklistRunView`, add a pill just below the title, visible only when `checklist.runs?.count ?? 0 >= 2`:

```swift
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
```

Insert `multiRunPill` between `headerBlock` and `tagChipBar`. Wire sheets:

```swift
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
```

The `actionRow`'s "+ New run" ghost button already sets `showStartRunSheet = true`.

- [ ] **Step 4: Build + exercise**

With a seeded multi-run fixture, verify the pill shows, tapping opens the chooser, selecting switches the current run, "+ Start new run" opens StartRunSheet.

- [ ] **Step 5: Commit**

```bash
git add Checklist/Checklist/Checklist/Sheets/StartRunSheet.swift \
        Checklist/Checklist/Checklist/Sheets/RunChooserSheet.swift \
        Checklist/Checklist/Checklist/Views/ChecklistRunView.swift
git commit -m "feat(sheets): StartRunSheet + RunChooserSheet + multi-run switcher pill"
```

---

## Task 5.13: Previous runs strip (no-current-run state)

**Files:**
- Create: `Checklist/Checklist/Checklist/Views/PreviousRunsStrip.swift`
- Modify: `Checklist/Checklist/Checklist/Views/ChecklistRunView.swift`

Prototype ref: capture 12. When there are zero live runs but completed runs exist, show a "PREVIOUS RUNS" section header + one row per completed run (date, fraction). No current-run progress bar or tag chips in this state. The "Last finished Xd ago" subtitle appears under the title.

- [ ] **Step 1: Write PreviousRunsStrip**

Write `Checklist/Checklist/Checklist/Views/PreviousRunsStrip.swift`:

```swift
import SwiftUI

/// Read-only strip showing the most recent completed runs for a checklist.
/// Tapping a row navigates to CompletedRunView (not implemented in Plan 2;
/// placeholder action).
struct PreviousRunsStrip: View {
    let completedRuns: [CompletedRun]
    var onTap: (CompletedRun) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionLabel(text: "Previous runs", hint: "\(completedRuns.count)")

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
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    private func dateLabel(for run: CompletedRun) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: run.completedAt)
    }

    private func subtitle(for run: CompletedRun) -> String {
        let snap = run.snapshot
        let complete = snap.checks.filter { $0.value == .complete }.count
        let total = snap.items.count
        let duration = Int(run.completedAt.timeIntervalSince(run.startedAt) / 60)
        return "\(complete)/\(total) · \(durationString(minutes: duration))"
    }

    private func durationString(minutes: Int) -> String {
        if minutes < 1 { return "<1m" }
        if minutes < 60 { return "\(minutes)m" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }
}
```

- [ ] **Step 2: Wire into ChecklistRunView**

In `ChecklistRunView`, add a "Last finished Xd ago" subtitle under the title when `currentRun == nil` and `completedRuns` has entries, and show `PreviousRunsStrip` below the items list:

```swift
private var completedRunsSorted: [CompletedRun] {
    (checklist.completedRuns ?? []).sorted { $0.completedAt > $1.completedAt }
}

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

private func relativeFinishedString(_ run: CompletedRun) -> String {
    let s = Date().timeIntervalSince(run.completedAt)
    if s < 60       { return "just now" }
    if s < 3600     { return "\(Int(s / 60))m ago" }
    if s < 86_400   { return "\(Int(s / 3600))h ago" }
    return "\(Int(s / 86_400))d ago"
}
```

Insert `lastFinishedSubtitle` between `headerBlock` and `multiRunPill`.

Insert `PreviousRunsStrip` into the body, BELOW the items `List`, only when `currentRun == nil && !completedRunsSorted.isEmpty`:

```swift
if currentRun == nil, !completedRunsSorted.isEmpty {
    PreviousRunsStrip(completedRuns: Array(completedRunsSorted.prefix(5)))
        .padding(.top, Theme.Spacing.md)
}
```

**Caveat on layout:** `List` eats the scroll axis, so a strip below it won't scroll together. Options:
(a) Take the strip in a separate `ScrollView` below — works but two scrollers feel weird.
(b) Embed the strip as a List footer.
Use option (b):

```swift
.listStyle(.plain)
.scrollContentBackground(.hidden)
```

and add a `Section` or footer:

```swift
Section {
    // items + add row
} footer: {
    if currentRun == nil, !completedRunsSorted.isEmpty {
        PreviousRunsStrip(completedRuns: Array(completedRunsSorted.prefix(5)))
            .padding(.top, Theme.Spacing.md)
    }
}
.listRowInsets(...)
```

Apply `.listRowBackground(Color.clear)` and `.listRowSeparator(.hidden)` to the footer row too.

- [ ] **Step 3: Build + exercise**

Complete a run on a seeded checklist. The current run disappears (RunStore.complete deletes it). Verify:
- `lastFinishedSubtitle` shows "Last finished just now"
- `PreviousRunsStrip` appears under the items
- Tag chip bar + progress bar are HIDDEN (no currentRun)

- [ ] **Step 4: Commit**

```bash
git add Checklist/Checklist/Checklist/Views/PreviousRunsStrip.swift \
        Checklist/Checklist/Checklist/Views/ChecklistRunView.swift
git commit -m "feat(views): previous runs strip + last-finished subtitle (no-live-run state)"
```

---

## Task 5.14: Near-complete state polish + empty-items refinement

**Files:**
- Modify: `Checklist/Checklist/Checklist/Views/ChecklistRunView.swift`

Prototype refs: capture 07 (near complete — progress 94%, "Finish run" CTA at bottom); capture 11 (empty items — no action row, no progress).

- [ ] **Step 1: Hide actionRow when there are no items**

In `ChecklistRunView`, gate `actionRow` behind `!sortedItems.isEmpty && currentRun != nil`:

```swift
@ViewBuilder
private var actionRowIfApplicable: some View {
    if !sortedItems.isEmpty, let _ = currentRun {
        actionRow
    }
}
```

Use `actionRowIfApplicable` instead of `actionRow` in `body`.

- [ ] **Step 2: Verify near-complete looks right**

Use the `.nearCompleteRun` seed fixture:

```swift
#Preview("Near complete (Gym Bag)") {
    let container = try! SeedStore.container(for: .nearCompleteRun)
    let ctx = ModelContext(container)
    let list = try! ctx.fetch(FetchDescriptor<Checklist>()).first(where: { $0.name == "Gym Bag" })!
    return NavigationStack { ChecklistRunView(checklist: list) }
        .modelContainer(container)
}
```

Expected: 4 of 4 items render with 3 complete + 1 unchecked, progress at 75% — NOTE: actual nearComplete fixture count depends on Gym Bag's item count from SeedStore (4 items, .nearCompleteRun checks all-but-one = 3 complete). Adjust expectation when confirming visually.

- [ ] **Step 3: Commit**

```bash
git add Checklist/Checklist/Checklist/Views/ChecklistRunView.swift
git commit -m "feat(views): gate action row on items+run; polish near-complete state"
```

---

## Task 5.15: Phase 5 visual verification

**Files:** none; validation only.

- [ ] **Step 1: Run full test suite**

Standard test command. Expected total: 69 tests (the new tests land across Tasks 5.4 and 5.11).

- [ ] **Step 2: Drive app through each state via preview canvas or simulator**

For each prototype capture in the 04-17 range, reach that state in either (a) Xcode canvas with the appropriate `#Preview`, or (b) the running simulator with a SeedStore fixture and some manual interaction.

State → capture mapping:

| Capture | Fixture to start from | Interaction needed |
|---|---|---|
| 04 — single live run | `.seededMulti` → Packing List | Tap Home card |
| 05/06 — multi-run chooser | `.seededMulti` → Packing List, then "+ New run" twice | Then tap the "N live runs" pill |
| 07 — near complete | `.nearCompleteRun` → Gym Bag | Tap Home card |
| 08 — completion all-done | `.nearCompleteRun` → Gym Bag → check the last item | Auto-presents |
| 09 — completion partial | Any seeded run with some checks | Tap "Complete · X/Y" |
| 10 — discard confirm | Same as 09 | Tap "Discard run" link |
| 11 — empty items | `.oneList` → Road Trip; manually delete all items | Or: `.empty` then create a list → tap card |
| 12 — no current run | `.seededMulti` → complete a run | After commit, the view stays on that checklist with PreviousRunsStrip |
| 13 — add item open | Any | Tap "+ Add item" |
| 14 — menu default | Any | Tap kebab |
| 15 — rename list | Any | Kebab → Rename list |
| 16 — name run | Seeded run | Kebab → Rename this run |
| 17 — delete confirm | Any with history | Kebab → Delete list |

Capture each via `xcrun simctl io booted screenshot` (pipe through `sips -Z 1800`). Save under `/tmp/phase-5-<state>.png`.

- [ ] **Step 3: Side-by-side visual diff**

Create `docs/superpowers/visual-diff/phase-5/runview.md` with one section per state. In each section, include both PNGs (prototype + simulator) and bullet any deltas. Acceptable: font fallbacks, minor radii, native iOS chrome (nav bar behavior, swipe affordances). Unacceptable: wrong eyebrow text ("Finish run" instead of "Complete"), missing sheets, incorrect progress math.

Fix any unacceptable deltas before declaring Phase 5 done.

- [ ] **Step 4: Commit visual-diff report**

```bash
git add docs/superpowers/visual-diff/phase-5/
git commit -m "docs: Phase 5 ChecklistRunView visual-diff report vs prototype captures"
```

- [ ] **Step 5: Tag**

```bash
git tag plan-2-home-and-runview-complete
```

---

## Self-review checklist (run before handoff)

- [ ] Every screen in spec §2 (rows for HomeView, ChecklistRunView, and the 8 sheets in scope) has a corresponding task in this plan.
- [ ] Every §7 translation (Collection→Category, Finish→Complete, no archive/due/repeat, no future-only chip) is enforced somewhere in the plan.
- [ ] Every sheet from §2 that falls under Phases 4–5 is defined: CreateChecklistSheet, StartRunSheet, CompletionSheet, RunChooserSheet, ChecklistMenuSheet, ItemEditInline, AddItemInline. Deferred to later plan: TagEditorSheet, PaywallSheet.
- [ ] The cascade behaviors from spec §3 that this plan triggers are respected:
  - Delete item warns when ≥2 live runs (Task 5.7)
  - Complete creates CompletedRun + deletes Run (Task 5.11)
  - Discard deletes Run without creating CompletedRun (Task 5.11)
- [ ] ARCHITECTURE §3e auto-create run on first interaction (Task 5.4)
- [ ] Every test includes real assertions on observable state (no mocks replaced with more mocks).
- [ ] No file introduced in this plan relies on a type defined in a later task it doesn't list as a dependency.
- [ ] No placeholders of the form "TBD", "implement later", or "see Task N for code".

---

## Handoff

Plan 2 produces:
- `HomeView` with live-data cards, category filter, empty state, summary cards row, create-checklist sheet
- `ChecklistRunView` with swipe-to-check/delete, inline add/edit, menu sheet (4 variants), completion sheet (3 variants), multi-run chooser + start-run, previous-runs strip, auto-create-run-on-first-interaction behavior
- `RunProgress` helper (ignored items excluded, hidden-tag items excluded)
- ≥69 tests passing
- Tag `plan-2-home-and-runview-complete` on the last commit

**Not in Plan 2 (deferred):**
- `CompletedRunView` — tapping a PreviousRunsStrip row is a no-op in this plan
- `HistoryView` — Home's History summary card is decorative
- `TagsView` / `TagEditorSheet` — ChecklistMenuSheet's "Manage tags" row is a no-op
- `SettingsView` — no settings entry point wired yet
- `PaywallSheet` restyling + free-tier gating in Home's `+` button
- Visual snapshot tests (swift-snapshot-testing) — manual canvas comparison suffices for this plan
- Inter Tight font registration — system font fallback remains
- Motion polish beyond default SwiftUI animations

Next plan (Plan 3) will cover `CompletedRunView`, `HistoryView`, and likely `TagsView` + `TagEditorSheet`.

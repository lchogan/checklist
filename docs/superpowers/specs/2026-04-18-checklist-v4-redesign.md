# Checklist — v4 Data Model + Gem Visual Redesign

**Status:** Design complete, awaiting user review before implementation plan.
**Date:** 2026-04-18
**Authoritative architecture:** `/ARCHITECTURE.md` (v4 draft)
**Authoritative visual:** `gem-screenshots/` (user) + `docs/superpowers/prototype-captures/` (Playwright) + `Gem App v2.html` in the design bundle

## Summary

Two interleaved threads ship as one project:

1. **Data model migration** from v3 (single-run-per-`Checklist` with `ChecklistItem.statusRaw`) to v4 (`Checklist` + `Item` + `Run` + `CompletedRun` + `Check` with ignored state as a per-run toggle). Per-checklist `Tag` scope widens to app-wide. Categories stay app-wide. No due dates, no recurrence, no archive in v1.
2. **Visual redesign** from iOS-native components to the "Gem" design direction (deep violet radial bg, OKLCH gem palette, Inter Tight display, faceted-gem check animation, sheet-heavy UI).

Approach: **reset-in-place**. Keep the Xcode project shell + `Purchases/` subsystem + assets + StoreKit config. Delete all v3 models, views, and stale docs. Build v4 models + views fresh inside the same project.

---

## §1 — Scope and authoritative sources

**In scope (v1):**
- All 6 SwiftData `@Model` classes in §3
- All flows from `ARCHITECTURE.md` §3: editing, check/ignore/hide-tag, complete, new run, auto-create, save-as-new, history, clear history, delete checklist
- "Discard run" action (destroys a live `Run` without creating `CompletedRun`) — added to v4 per user decision
- Visual redesign per `Gem App v2.html`
- StoreKit + freemium limits (1 list / 3 tags / 3 categories on free, unlimited on premium)
- CloudKit sync opt-in on premium

**Reserved (not v1):**
- Gem visuals as a delight layer (`ARCHITECTURE.md` §9)
- Recurrence (§6a), due dates (§6b), bulk edit (§6c), CloudKit sharing (§6d)
- Archive (soft-delete) — cut entirely; delete is permanent with confirmation
- Per-item due dates
- Partial-status stored field — computed at view time only

**Authoritative sources (in priority order when they conflict):**
1. `/ARCHITECTURE.md` — data model + semantics
2. `Gem App v2.html` — visual spec, pixel-level
3. `gem-app/*.jsx` — supplementary reference (may be stale vs. compiled HTML; prefer HTML)
4. `chats/chat1.md` — design rationale
5. `project/screenshots/*.png` + `gem-screenshots/` + `docs/superpowers/prototype-captures/` — visual anchors

**Explicitly non-authoritative:**
- The design bundle's own `project/ARCHITECTURE.md` (v1 template/run draft, superseded)
- `Gem App.html` (superseded by v2)
- `Checklist Redesign.html` (multi-direction canvas, not the chosen direction)
- v3 `.md` docs inside `Checklist/` (archived to `docs/v3-archive/`)

**Terminology rules:**
- User-visible word for `Run` or `CompletedRun` = **"run"**; "CompletedRun" never appears in UI
- "Complete" / "Completed" — never "Finish" or "Seal"
- "Ignore" for the per-run skip state — never "defer" or "hidden"
- "Save as new checklist" for the fork action
- "Category" / "Categories" — never "Collection" (UI and code both)
- App name stays "Checklist" externally; "Gem" is design-direction codename only

---

## §2 — Screen inventory

**6 screens + ~8 sheets.** All editing inline on `ChecklistRunView`; no separate editor screen.

### Screens (`Views/`)

| File | Purpose |
|---|---|
| `HomeView.swift` | Grid of checklists, category filter chips, live-run indicators on cards, settings + add-list in top bar |
| `ChecklistRunView.swift` | Main run view: items, tag-hide chips, progress, previous runs strip, run chooser when ≥2 live, kebab menu, all inline editing |
| `CompletedRunView.swift` | Read-only view of a sealed `CompletedRun`; items grouped by tag when tags present |
| `HistoryView.swift` | Global reverse-chrono feed of `CompletedRun`s, grouped by month, filterable by checklist and by completion state (All / Complete / Partial — partial computed at view time) |
| `TagsView.swift` | App-wide tag manager; edit or delete tags |
| `SettingsView.swift` | Stats row (total lists / completed runs / tags), nav to Tags + Categories + History, danger-zone reset |

### Sheets (`Sheets/`)

| File | Trigger |
|---|---|
| `CreateChecklistSheet.swift` | Home's `+` button; name + category fields |
| `StartRunSheet.swift` | "+ New run" when ≥1 live run exists; name only (no due date) |
| `CompletionSheet.swift` | Auto-opens when last item checked, or tapped "Complete"; variants: all-done (green) / partial (citrine "Complete anyway · N/M") / discard-confirm (ruby) |
| `RunChooserSheet.swift` | Multi-run switcher pill tap; shows live runs with conic progress ring + "+ Start new run" |
| `ChecklistMenuSheet.swift` | Kebab on run view; variants: default menu (Rename run / Rename list + category / Full history / Manage tags / Delete) / rename-list (also edits category) / name-run / delete-confirm (names past-run count) |
| `ItemEditInline.swift` | Long-press or tap on item row body; name input + tag chips + Cancel/Save (no Delete — swipe replaces) |
| `AddItemInline.swift` | Dashed "+ Add item" row's expanded form; text input + tag chips |
| `TagEditorSheet.swift` | Tags screen pencil or "+"; preview card + name + icon grid (14) + color swatches (9) + delete (for existing) |
| `PaywallSheet.swift` | Free-tier limit trigger; restyled in Gem look |

### Shared components (`Design/Components/`)

- `PillButton` (solid/ghost, gem-colored)
- `TagChip`, `TagHideChip`
- `Facet` (gem-facet checkbox, signature check animation)
- `HeroGem` (large celebration gem)
- `GemBar` (segmented progress bar)
- `ChecklistCard` (home grid card with live-run indicator)
- `BottomSheet` (reusable container)
- `TopBar`, `IconButton`
- `SectionLabel` (uppercase caption)

---

## §3 — Data model (SwiftData v4)

Six `@Model` classes + two Codable snapshot structs + one enum.

### Entities

```swift
import Foundation
import SwiftData

@Model final class Category {
    var id: UUID = UUID()
    var name: String = ""
    var sortKey: Int = 0
    var createdAt: Date = Date()

    @Relationship(deleteRule: .nullify, inverse: \Checklist.category)
    var checklists: [Checklist]? = []

    init(name: String, sortKey: Int = 0) { self.name = name; self.sortKey = sortKey }
}

@Model final class Tag {
    var id: UUID = UUID()
    var name: String = ""
    var iconName: String = "tag"
    var colorHue: Double = 300     // OKLCH hue, fixed chroma/lightness in theme
    var sortKey: Int = 0

    init(name: String, iconName: String = "tag", colorHue: Double = 300, sortKey: Int = 0) {
        self.name = name; self.iconName = iconName; self.colorHue = colorHue; self.sortKey = sortKey
    }
}

@Model final class Checklist {
    var id: UUID = UUID()
    var name: String = ""
    var sortKey: Int = 0
    var createdAt: Date = Date()

    @Relationship(deleteRule: .nullify) var category: Category?
    @Relationship(deleteRule: .cascade, inverse: \Item.checklist) var items: [Item]? = []
    @Relationship(deleteRule: .cascade, inverse: \Run.checklist) var runs: [Run]? = []
    @Relationship(deleteRule: .cascade, inverse: \CompletedRun.checklist) var completedRuns: [CompletedRun]? = []

    init(name: String) { self.name = name }
}

@Model final class Item {
    var id: UUID = UUID()
    var text: String = ""
    var sortKey: Int = 0

    @Relationship(deleteRule: .nullify) var checklist: Checklist?
    @Relationship var tags: [Tag]? = []

    init(text: String, sortKey: Int = 0) { self.text = text; self.sortKey = sortKey }
}

@Model final class Run {
    var id: UUID = UUID()
    var name: String? = nil
    var startedAt: Date = Date()
    var hiddenTagIDs: [UUID] = []

    @Relationship(deleteRule: .nullify) var checklist: Checklist?
    @Relationship(deleteRule: .cascade, inverse: \Check.run) var checks: [Check]? = []

    init(checklist: Checklist, name: String? = nil) {
        self.checklist = checklist; self.name = name
    }
}

@Model final class Check {
    var id: UUID = UUID()
    var itemID: UUID = UUID()
    var stateRaw: String = CheckState.complete.rawValue
    var updatedAt: Date = Date()

    @Relationship(deleteRule: .nullify) var run: Run?

    var state: CheckState {
        get { CheckState(rawValue: stateRaw) ?? .complete }
        set { stateRaw = newValue.rawValue; updatedAt = Date() }
    }
}

enum CheckState: String, Codable { case complete, ignored }

@Model final class CompletedRun {
    var id: UUID = UUID()
    var name: String? = nil
    var startedAt: Date = Date()
    var completedAt: Date = Date()

    @Relationship(deleteRule: .nullify) var checklist: Checklist?

    @Attribute(.externalStorage) var snapshotData: Data = Data()

    var snapshot: CompletedRunSnapshot {
        get { (try? JSONDecoder().decode(CompletedRunSnapshot.self, from: snapshotData)) ?? .empty }
        set { snapshotData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
}

struct CompletedRunSnapshot: Codable {
    var items: [ItemSnapshot]
    var tags: [TagSnapshot]
    var checks: [UUID: CheckState]
    var hiddenTagIDs: [UUID]

    static let empty = CompletedRunSnapshot(items: [], tags: [], checks: [:], hiddenTagIDs: [])
}

struct ItemSnapshot: Codable, Identifiable {
    let id: UUID
    let text: String
    let tagIDs: [UUID]
    let sortKey: Int
}

struct TagSnapshot: Codable, Identifiable {
    let id: UUID
    let name: String
    let iconName: String
    let colorHue: Double
}
```

### Key design decisions

1. **Tags are app-wide, not per-checklist.** A future migration to per-checklist scope is possible by adding `checklist: Checklist?` on Tag; not pursued in v1.
2. **`Check.itemID` is a `UUID`, not a relationship.** Cleanest handling of the v4 delete-item cascade.
3. **`CompletedRun` stores a single Codable blob via `@Attribute(.externalStorage)`.** Matches `ARCHITECTURE.md` §7 "All snapshot data inline as JSON blobs (immutable)". Keeps the sealed record self-contained.
4. **CloudKit constraints respected.** Every property has a default; every relationship is optional; no `@Attribute(.unique)`.
5. **No stored completion status.** Partial / complete computed at view time.
6. **`Run.hiddenTagIDs` is `[UUID]`, not a relationship.** Dangling UUIDs silently no-op if a tag is deleted.

### Cascade table

| Action | Behavior |
|---|---|
| Delete `Category` | `Checklist.category` nullifies; checklist stays |
| Delete `Checklist` | Cascades to all `Item`s, `Run`s, `CompletedRun`s (permanent; UI requires confirmation) |
| Delete `Item` | `ChecklistStore.deleteItem` also deletes any `Check` with matching `itemID` in the same transaction; if ≥2 live runs exist on this checklist, UI warns first |
| Delete `Tag` | `TagStore.delete` removes from `Item.tags` arrays and cleans `Run.hiddenTagIDs`; `CompletedRun` snapshots keep the tag frozen |
| Complete `Run` | `RunStore.complete` creates a `CompletedRun` (with snapshot + frozen checks) and deletes the `Run` in one transaction |
| Discard `Run` | `RunStore.discard` deletes the `Run` (and its `Check`s via cascade); no `CompletedRun` is created |

---

## §4 — Post-reset project structure

### Kept (untouched or minor edits)

- `Checklist/Checklist.xcodeproj` — signing, bundle ID, scheme
- `Checklist/Checklist/Assets.xcassets` — AppIcon, AccentColor
- `Checklist/Checklist/Checklist.entitlements`, `Info.plist`
- `Checklist/Checklist/Products.storekit`
- `Checklist/Checklist/Purchases/` entire folder (edit only: `FeatureLimits` "Category" labels)
- `Checklist/Checklist/ChecklistApp.swift` — edit `Schema` array only

### Deleted

- All files in `Checklist/Checklist/Models/` (5 files)
- All files in `Checklist/Checklist/Views/` (11 files)
- `NAVIGATION_FLOW.md`, `PROFILE_FEATURES_README.md`, `QUICK_START.md` (moved to `docs/v3-archive/`)

### New layout (inside `Checklist/Checklist/`)

```
Models/              (7 files)
  Category.swift, Tag.swift, Checklist.swift, Item.swift,
  Run.swift, Check.swift, CompletedRun.swift
Design/
  Theme.swift, GemIcons.swift
  Components/        (9 files)
    PillButton.swift, TagChip.swift, Facet.swift, HeroGem.swift,
    GemBar.swift, ChecklistCard.swift, BottomSheet.swift,
    TopBar.swift, SectionLabel.swift
Store/               (5 files)
  ChecklistStore.swift, RunStore.swift, CompletedRunBuilder.swift,
  TagStore.swift, SeedStore.swift
Views/               (6 files)
  HomeView, ChecklistRunView, CompletedRunView,
  HistoryView, TagsView, SettingsView
Sheets/              (9 files)
  CreateChecklistSheet, StartRunSheet, CompletionSheet,
  RunChooserSheet, ChecklistMenuSheet, ItemEditInline,
  AddItemInline, TagEditorSheet, PaywallSheet
```

### Architectural pattern

- **Views use `@Query` + `@Environment(\.modelContext)` directly.** No view models.
- **Non-trivial operations live in stateless `Store` functions taking `ModelContext`.**
- **`@State` on the view** for transient UI state.

---

## §5 — Implementation sequence

Ten phases. Sequential by default. Parallelizable within phase 4–8 via subagents.

| # | Phase | What lands | Verification gate |
|---|---|---|---|
| 0 | Reset | Archive 3 `.md` docs, delete v3 models + views, edit `ChecklistApp` to boot empty placeholder | `xcodebuild` succeeds; sim launches |
| 1 | Data model | All 6 `@Model` classes + `CheckState` + snapshot structs | Build + model unit tests |
| 2 | Store layer | `ChecklistStore`, `RunStore`, `CompletedRunBuilder`, `TagStore`, `SeedStore` | Unit tests with in-memory `ModelContext`, ≥85% line coverage for `Store/` |
| 3 | Design tokens + primitives | `Theme.swift`, `GemIcons.swift`, every component | All `#Preview`s render |
| 4 | Home screen | `HomeView` + `CreateChecklistSheet` + empty-state | Visual diff vs captures 01, 02, 29, 30; user approval |
| 5 | Checklist run screen | `ChecklistRunView` with tap/swipe/long-press; `AddItemInline`, `ItemEditInline`, `ChecklistMenuSheet`, `CompletionSheet` (3 variants), `RunChooserSheet`, `StartRunSheet`, multi-run switcher | Visual diff vs captures 04–17 |
| 6 | Completed run + History | `CompletedRunView` (tag-grouped), `HistoryView` | Visual diff vs captures 19–23 |
| 7 | Tags | `TagsView` + `TagEditorSheet` | Visual diff vs captures 24–27 |
| 8 | Settings + Paywall | `SettingsView`, restyled `PaywallSheet`, categories CRUD | Visual diff vs capture 28 |
| 9 | Integration pass | Full walk-through, motion polish, end-to-end tests | `scripts/capture_simulator.py` assembled diff report |
| 10 | CloudKit + Premium | Verify CloudKit sync, free-tier gates | Manual cross-device test |

---

## §6 — Visual iteration workflow

Every screen phase (4–8) ends with this self-driven loop:

1. `xcodebuild -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build`
2. `xcrun simctl boot "iPhone 16 Pro"`; install; launch
3. `scripts/capture_simulator.py` drives the app (XCUITest or deep-link `checklist://seed/<state>`) to each reference state; `xcrun simctl io booted screenshot`
4. Side-by-side markdown page per state in `docs/superpowers/visual-diff/<phase>/<screen>.md`; read both PNGs, flag deltas
5. Fix + re-capture until self-review passes
6. Post diff doc to user with TL;DR, ask for sign-off

Motion curves validated by reading prototype CSS `@keyframes` / `cubic-bezier` and matching in SwiftUI animations. Crash logs from `~/Library/Logs/DiagnosticReports/` if launch fails.

---

## §7 — Prototype → v4 translation reference

Every prototype concept that differs from v4. Subagents consult this table when implementing screens so they don't re-derive it.

| Prototype says | v4 implementation | Notes |
|---|---|---|
| Template | Checklist | No separate template entity |
| `run.snapshotItems`, `excludedItemIds`, `templateGeneration` | *(gone)* | Items live on `Checklist` only |
| `hiddenItems` on a run | `Check.state = .ignored` | Per-run skip state |
| Finished run (`status: 'finished'`) | `CompletedRun` | Sealed; read-only |
| Partial run (`status: 'partial'`) | `CompletedRun` + computed "Partial" badge | Not stored |
| `archivedTemplateIds` | *(gone)* | Cut archive |
| "Finish run" button | "Complete" | v4 canonical verb |
| "Finish as partial · N/M" | "Complete anyway · N/M" | Same action, rephrased |
| "Sealed" / "Sealed record" | "Completed" / "Completed run" | Never use "seal" |
| "Discard run" | `RunStore.discard(_:)` | Destroys Run; no CompletedRun |
| "Start new run from here" (past run) | "New run with checks from here" | Live Run with checks copied |
| "Save as new checklist" | same | Fork point; deep-copy items + tags |
| "Start a run" sheet | `StartRunSheet` — name only | Due date cut |
| "Set due date" menu row | *(removed)* | |
| "Set repeat schedule" menu row | *(removed)* | |
| "Archive list" / "Unarchive" | *(removed)* | Only permanent delete |
| "Adds to: All live + future / Future only" chip | *(removed)* | Always adds to all live |
| "Manage tags" menu row | navigates to `TagsView` | Full screen for now |
| "Collection" / "Collections" | "Category" / "Categories" | UI and code both |
| "YOUR COLLECTIONS · 3 LIVE" eyebrow | "YOUR CATEGORIES · 3 LIVE" | |
| Prototype's `TemplateEditor` screen | *(not a screen)* | Inline on `ChecklistRunView` |
| Tap item row | opens inline edit panel (expand in place) | Long-press also opens it |
| Tap facet (checkbox only) | toggles complete | Distinct hit target |
| Swipe right on item | complete | New in v4 |
| Swipe left on item | delete (warn if ≥2 live runs) | New in v4 |

---

## §8 — Testing strategy

| Layer | Tool | Scope | Phase |
|---|---|---|---|
| Model unit | XCTest + in-memory `ModelContainer` | `@Model` instantiation, cascade rules, snapshot roundtrip | 1 |
| Store unit | XCTest + in-memory `ModelContainer` | Every Store function; happy + edge cases | 2 |
| View snapshot | swift-snapshot-testing + `#Preview` fixtures | One reference PNG per screen state | 4–8 |
| End-to-end | XCUITest | Golden paths (create → run → complete → history; concurrent runs; multi-run delete warning) | 9 |

**Seed fixtures:** `SeedStore` exposes enum cases (`.empty`, `.oneList`, `.seededMulti`, `.historicalRuns`, `.nearCompleteRun`) returning a fully populated in-memory `ModelContainer`, consumed by both tests and SwiftUI previews. One-to-one with `scripts/capture_prototype.py` states.

**Not automated** (validated manually): SwiftUI animation curves, StoreKit sandbox purchases, CloudKit cross-device sync.

---

## §9 — Open items carried to ARCHITECTURE.md

The following updates to `ARCHITECTURE.md` v4 reflect decisions in this spec:

1. **Tag scope widens to app-wide** — §2 currently says "Tag — scoped to a single Checklist"; should read "Tag — app-wide, referenced by Items across any Checklist. Future v1.x may reintroduce per-Checklist scope."
2. **Add "Discard run" action** under §3 — a new §3j: destroys a live `Run` (and its `Check`s) without creating a `CompletedRun`; confirmation required.
3. **Clarify "partial" status is not stored** — §2 Check semantics should note that "partial" completion is a view-time computation over `CompletedRun.snapshot.checks`, not a persisted field.
4. **Remove due dates and recurrence from the reserved list?** — They're still reserved for later per §6; no change needed.

Planned follow-up commit: update `ARCHITECTURE.md` with the three edits above when starting Phase 0.

---

## §10 — What we're deliberately NOT doing in v1

Carried from `ARCHITECTURE.md` §11, restated for subagent clarity:

- No template editor screen (inline edit only)
- No per-run items (items live on `Checklist` only)
- No "delete from just this run" (use Ignore)
- No unsealing CompletedRuns
- No shared items across checklists (deep copies only)
- No real-time multiplayer (CloudKit silent-push = eventual consistency)
- No automatic history archival (user taps Clear history)
- No cross-checklist item dependencies
- No soft-delete on Checklist records (delete = permanent after confirmation)
- No archive (removed entirely in this spec)
- No due dates or recurrence (reserved for v1.1+)
- No "Adds to: Future only" option (always adds to all live runs)

---

## §11 — Review checklist for user

Before I start Phase 0:

- [ ] Does §3 (data model) match your mental model?
- [ ] Is §5 (phase sequence) acceptable, including the subagent parallelization for 4–8?
- [ ] Are the §7 translations (especially "Collection" → "Category", "Seal" → "Complete") correct?
- [ ] Any v1 feature listed as "reserved" or "cut" that should actually be in v1?
- [ ] OK to update `ARCHITECTURE.md` per §9 before Phase 0?

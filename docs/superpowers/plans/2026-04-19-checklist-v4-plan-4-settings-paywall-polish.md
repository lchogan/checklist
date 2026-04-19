# Checklist v4 — Plan 4: Settings + Paywall + Polish (Phases 8–9 + Phase 10 runbook)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the final v4 app surface — a flexible per-feature plan catalog that decouples StoreKit products from feature limits, a restyled Gem paywall, Settings + Categories CRUD + Clear-history, and a polish pass (Inter Tight font if present, motion curves, deep-link fixture seeder for QA automation). Plan 10 (cross-device CloudKit + StoreKit sandbox verification) ships as a manual runbook.

**Architecture:** Three-layer separation of concerns — **Products** (App Store Connect + `Products.storekit`) → **Entitlements** (active StoreKit transactions → set of product IDs) → **Feature limits** (merged numeric caps + `cloudKitSync: Bool`). A bundled `plans.json` is the single source of truth; `PlanCatalog` loads and merges. `EntitlementManager` continues to expose `isPremium` for back-compat but new call sites read `limits` (the merged `FeatureLimits`) or go through `EntitlementGate.canXxx()` helpers that also trigger the paywall. `ChecklistApp`'s CloudKit wiring moves from `isPremium` → `limits.cloudKitSync`. The design graduates cleanly: swap `PlanCatalog.load()` to a remote fetcher later (Level 2), or swap the whole `EntitlementManager` internals for RevenueCat (Level 3) without touching a single view.

**Tech Stack:** Swift 5.9+, SwiftUI, SwiftData, StoreKit 2, Codable JSON, XCTest, Xcode 16+.

**Spec refs:**
- `docs/superpowers/specs/2026-04-18-checklist-v4-redesign.md` — §2 (SettingsView row), §3 (Clear history §3f), §5 (Phase 8 scope + verification gate)
- `ARCHITECTURE.md` — §3f (Clear history), §3h (delete checklist)
- Prototype captures: 28 (Settings), and 24–27 for the paywall context

**Baseline at plan start:** `main` at tag `plan-3-history-tags-complete`. 88 XCTests green. 5 Plan-2 dead-end taps wired. Existing `Checklist/Checklist/Checklist/Purchases/` has a hardcoded two-tier `FeatureLimits` (`.free` / `.premium`), a binary `EntitlementManager.isPremium: Bool`, and a `StoreKitManager` with two hardcoded product IDs. `Products.storekit` declares two auto-renewable subscriptions (`com.checklist.premium.monthly`, `com.checklist.premium.annual`). Home's `sparkle` top-bar icon is wired to a no-op closure. No `SettingsView`, no `CategoriesView`, no `PaywallSheet` (v4), no `Clear history` action.

---

## Repo paths used throughout

- Repo root: `/Users/lukehogan/Code/checklist`
- Xcode project: `Checklist/Checklist/Checklist.xcodeproj`
- App sources: `Checklist/Checklist/Checklist/`
- Tests target: `Checklist/Checklist/ChecklistTests/`

**Simulator:** iPhone 17 Pro.

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

**Single-suite filter:** append `-only-testing:ChecklistTests/<SuiteName>` to the test command.

**Bundle ID:** `com.themostthing.Checklist`.

**Baseline test count:** 88 at plan start.

**Xcode 16 synchronized root group** — files dropped under `Checklist/` directory are auto-included. Do NOT touch `.pbxproj`. JSON resources go in `Checklist/Checklist/Checklist/Resources/` (new folder — same auto-inclusion rule).

---

## Terminology (additions to Plan 3's §7 table)

| Prototype says | v4 code + UI uses |
|---|---|
| "Collections" summary in Settings | "Categories" — §7 translation |
| "Sealed it here" empty copy | "saved it here" (Plan 3 locked this in) |
| "Premium" tier-only language | Read dynamically from `PlanCatalog`; the paywall pulls `displayName` from the active offer |
| Product-ID strings sprinkled across code | Single source: `plans.json` + `PlanCatalog.plans` |

---

## Files created by this plan

### Phase 8 — Plan catalog + Settings + Paywall + Categories CRUD + Clear history

- `Checklist/Checklist/Checklist/Purchases/Plan.swift` — `Plan` value type
- `Checklist/Checklist/Checklist/Purchases/PlanCatalog.swift` — loads + merges plans
- `Checklist/Checklist/Checklist/Purchases/EntitlementGate.swift` — centralized gate + paywall trigger
- `Checklist/Checklist/Checklist/Resources/plans.json` — bundled plan catalog
- `Checklist/Checklist/Checklist/Views/SettingsView.swift`
- `Checklist/Checklist/Checklist/Views/SettingsRoute.swift` — `SettingsDestination` marker
- `Checklist/Checklist/Checklist/Views/CategoriesView.swift`
- `Checklist/Checklist/Checklist/Sheets/PaywallSheet.swift`
- `Checklist/Checklist/ChecklistTests/Purchases/FeatureLimitsTests.swift`
- `Checklist/Checklist/ChecklistTests/Purchases/PlanCatalogTests.swift`
- `Checklist/Checklist/ChecklistTests/Purchases/EntitlementGateTests.swift`
- `Checklist/Checklist/ChecklistTests/Store/RunStore_ClearHistoryTests.swift`
- `Checklist/Checklist/ChecklistTests/Views/SettingsViewTests.swift`
- `Checklist/Checklist/ChecklistTests/Views/CategoriesViewTests.swift`

### Modified (Phase 8)

- `Checklist/Checklist/Checklist/Purchases/FeatureLimits.swift` — expand dimensions + add `merged(with:)`, remove hardcoded tier constants, make Codable
- `Checklist/Checklist/Checklist/Purchases/EntitlementManager.swift` — rewire around `activePlan` resolved via `PlanCatalog`
- `Checklist/Checklist/Checklist/Purchases/StoreKitManager.swift` — read product IDs from `PlanCatalog`
- `Checklist/Checklist/Checklist/ChecklistApp.swift` — CloudKit wiring reads `limits.cloudKitSync`
- `Checklist/Checklist/Checklist/Views/HomeView.swift` — wire `sparkle` icon to push SettingsView; gate `+` button behind `EntitlementGate.canCreateChecklist`
- `Checklist/Checklist/Checklist/Views/TagsView.swift` — gate `+` + `+ New tag` behind `EntitlementGate.canCreateTag`
- `Checklist/Checklist/Checklist/Sheets/CreateChecklistSheet.swift` — gate `+ New` category chip behind `EntitlementGate.canCreateCategory`
- `Checklist/Checklist/Checklist/Sheets/AddItemInline.swift` — gate item add behind `EntitlementGate.canAddItem(to:)`
- `Checklist/Checklist/Checklist/Sheets/StartRunSheet.swift` — gate "+ New run" behind `EntitlementGate.canStartRun(on:)`
- `Checklist/Checklist/Checklist/Store/RunStore.swift` — add `clearHistory(for:in:)` and `clearAllHistory(in:)`

### Phase 9 — Deep-link fixtures + motion + font (conditional)

- `Checklist/Checklist/Checklist/Store/FixtureRouter.swift` — resolves a `checklist://seed/<fixture>` URL to a SeedStore fixture swap
- `Checklist/Checklist/Checklist/ChecklistApp.swift` (modify) — `onOpenURL` handler + `URL Types` in Info.plist
- `Checklist/Checklist/Checklist/Info.plist` (modify) — register URL scheme `checklist`, optionally register Inter Tight fonts if `.ttf` files exist
- `Checklist/Checklist/Checklist/Design/Components/Facet.swift` (modify) — tune spring curve
- `Checklist/Checklist/Checklist/Design/Components/HeroGem.swift` (modify) — add appear-spring
- `Checklist/Checklist/ChecklistTests/Store/FixtureRouterTests.swift`
- `scripts/capture_states.sh` — drives the sim through seeded states

### Phase 10 — Runbook

- `docs/superpowers/runbooks/phase-10-premium-cloudkit.md` — manual verification checklist

---

## Key architectural decisions (read once before touching code)

### 1. "Active plan" = the most-generous merge of all currently-owned products' plans

Users can momentarily hold overlapping subscriptions (e.g. during an upgrade). Rather than pick one arbitrarily, `EntitlementManager.resolveActivePlan(from:)` merges the limits of every owned plan using `FeatureLimits.merged(with:)`:
- `Int?` (nullable numeric caps): `nil` wins (nil == unlimited); else the larger wins
- `Bool` capabilities: OR (any `true` wins)

Concrete example: two plans "Plus" (maxLists: 10) and "Pro" (maxLists: nil) → merged maxLists is nil (unlimited).

### 2. Paywall triggers are **intent-first, not tier-first**

`EntitlementGate.canCreateChecklist(current: Int)` returns `.allowed` or `.blockedBy(reason, upgradeContext)`. Views call the helper and branch on the return. The paywall is always presented by the view that received `.blocked`, so its copy can speak to the specific feature the user hit ("Unlock more checklists") instead of a generic "go premium" pitch.

### 3. The free plan is not a special case; it's just `plans.first(where: { $0.productID == nil })`

Eliminating the "free vs premium" conditional everywhere simplifies testing and future multi-tier structures ("Free / Plus / Pro"). If you ever want a Lite tier between Free and Pro you add a row to `plans.json`.

### 4. We keep `isPremium: Bool` on `EntitlementManager` for back-compat

Existing code reads it. New code should prefer `entitlementManager.limits` or `EntitlementGate`. A quick TODO-style comment in the file guides new callers.

### 5. CloudKit sync gating moves out of `isPremium`

`ChecklistApp.setupModelContainer()` previously branched on `entitlementManager.isPremium`. New: reads `entitlementManager.limits.cloudKitSync`. If you later want "Plus has sync but limited lists", you change one JSON value.

---

## Self-review checklist (run before handoff)

- [ ] Every Phase 8 screen in spec §2 (`SettingsView`, `CategoriesView` inside Phase 8 per the §5 table, `PaywallSheet` restyled) has a task.
- [ ] Every Phase 8 cascade action (`Clear history` from §3f, `Delete list` cascade already covered in Plan 2) is represented.
- [ ] Plan catalog exercises every limit dimension the user listed: maxChecklists, maxLiveRunsPerChecklist, maxItemsPerChecklist (maxTotalRuns optional), cloudKitSync, maxCategories, maxTags — all in `FeatureLimits`.
- [ ] Every gate call site has a task wiring it (Home `+`, Tags `+`, Category `+`, AddItemInline, StartRunSheet).
- [ ] `ChecklistApp.swift:63` CloudKit read replaced with `limits.cloudKitSync`.
- [ ] Every test includes real assertions.
- [ ] No placeholders.
- [ ] No orphan call sites for old `FeatureLimits.free` / `FeatureLimits.premium` (which get removed in Task 8.1).

---

## Handoff (populated when plan completes)

Plan 4 produces:
- Flexible plan catalog: `plans.json` + `Plan` + `PlanCatalog` + expanded `FeatureLimits` (7 dimensions) + `EntitlementGate`
- All 5 gate call sites wired
- `SettingsView` with stats row, nav to Categories/Tags/History, danger zone (Clear history, delete all)
- `CategoriesView` CRUD
- `PaywallSheet` restyled in Gem visuals
- `RunStore.clearHistory` + `clearAllHistory`
- Home `sparkle` icon → SettingsView
- CloudKit wiring gates off `limits.cloudKitSync`
- Phase 9: deep-link fixture seeder, motion polish, optional font registration
- Phase 10: runbook for manual StoreKit sandbox + CloudKit cross-device verification
- Tag `plan-4-settings-paywall-polish-complete` on the last commit

**Deferred past v4 (tracked as future work, not in this plan):**
- Remote `PlanCatalog` fetcher (CloudKit public DB or flat JSON URL)
- RevenueCat migration
- XCUITest harness + fully-automated visual-diff pipeline
- Promotional offers, introductory pricing, win-back flows (all hooks exist in StoreKit 2)
- In-app restore-purchases UI (Task 8.11 includes a "Restore purchases" row in Settings; this is wired but only manually verifiable)

---

# Phase 8 — Plan catalog + Settings + Paywall + Categories CRUD

## Task 8.1: Expand `FeatureLimits` + make Codable + add `merged(with:)`

**Files:**
- Modify: `Checklist/Checklist/Checklist/Purchases/FeatureLimits.swift`
- Create: `Checklist/Checklist/ChecklistTests/Purchases/FeatureLimitsTests.swift`

- [ ] **Step 1: Write failing tests**

```swift
/// FeatureLimitsTests.swift
/// Purpose: Tests for the expanded FeatureLimits value type — merging, Codable
///   round-trip, and the per-dimension canAdd helpers.
/// Dependencies: XCTest, Checklist target.

import XCTest
@testable import Checklist

final class FeatureLimitsTests: XCTestCase {

    /// Merge: nil (unlimited) beats a numeric cap on a single Int? field.
    func test_merge_nil_beats_numeric() {
        let a = FeatureLimits(maxChecklists: 3, maxItemsPerChecklist: nil,
                              maxLiveRunsPerChecklist: nil, maxTotalRuns: nil,
                              maxTags: 3, maxCategories: 0, cloudKitSync: false)
        let b = FeatureLimits(maxChecklists: nil, maxItemsPerChecklist: nil,
                              maxLiveRunsPerChecklist: nil, maxTotalRuns: nil,
                              maxTags: nil, maxCategories: nil, cloudKitSync: true)
        let merged = a.merged(with: b)
        XCTAssertNil(merged.maxChecklists, "nil unlimited wins over 3")
        XCTAssertNil(merged.maxTags, "nil unlimited wins over 3")
        XCTAssertNil(merged.maxCategories, "nil wins over 0")
        XCTAssertTrue(merged.cloudKitSync, "true OR false = true")
    }

    /// Merge: the larger numeric cap wins when neither side is nil.
    func test_merge_larger_numeric_wins() {
        let a = FeatureLimits(maxChecklists: 3, maxItemsPerChecklist: 50,
                              maxLiveRunsPerChecklist: 2, maxTotalRuns: nil,
                              maxTags: 3, maxCategories: 1, cloudKitSync: false)
        let b = FeatureLimits(maxChecklists: 10, maxItemsPerChecklist: 20,
                              maxLiveRunsPerChecklist: 5, maxTotalRuns: nil,
                              maxTags: 10, maxCategories: 0, cloudKitSync: false)
        let merged = a.merged(with: b)
        XCTAssertEqual(merged.maxChecklists, 10)
        XCTAssertEqual(merged.maxItemsPerChecklist, 50)
        XCTAssertEqual(merged.maxLiveRunsPerChecklist, 5)
        XCTAssertEqual(merged.maxTags, 10)
        XCTAssertEqual(merged.maxCategories, 1)
        XCTAssertFalse(merged.cloudKitSync)
    }

    /// canAddChecklist: nil cap means always allowed; numeric cap honoured.
    func test_canAdd_checklist() {
        let free = FeatureLimits(maxChecklists: 1, maxItemsPerChecklist: nil,
                                 maxLiveRunsPerChecklist: nil, maxTotalRuns: nil,
                                 maxTags: 3, maxCategories: 0, cloudKitSync: false)
        XCTAssertTrue(free.canAddChecklist(current: 0))
        XCTAssertFalse(free.canAddChecklist(current: 1))
        let unlimited = FeatureLimits.unlimited
        XCTAssertTrue(unlimited.canAddChecklist(current: 99_999))
    }

    /// canAddItem / canStartRun: nil = unlimited; numeric cap honoured.
    func test_canAdd_items_and_runs() {
        let free = FeatureLimits(maxChecklists: 1, maxItemsPerChecklist: 10,
                                 maxLiveRunsPerChecklist: 1, maxTotalRuns: nil,
                                 maxTags: 3, maxCategories: 0, cloudKitSync: false)
        XCTAssertTrue(free.canAddItem(currentItemsOnChecklist: 9))
        XCTAssertFalse(free.canAddItem(currentItemsOnChecklist: 10))
        XCTAssertTrue(free.canStartRun(currentLiveRunsOnChecklist: 0))
        XCTAssertFalse(free.canStartRun(currentLiveRunsOnChecklist: 1))
    }

    /// Codable round-trip: JSON encode + decode = original.
    func test_codable_round_trip() throws {
        let original = FeatureLimits(
            maxChecklists: 3, maxItemsPerChecklist: 25,
            maxLiveRunsPerChecklist: 2, maxTotalRuns: nil,
            maxTags: 5, maxCategories: 0, cloudKitSync: true
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FeatureLimits.self, from: data)
        XCTAssertEqual(original, decoded)
    }
}
```

Save to `Checklist/Checklist/ChecklistTests/Purchases/FeatureLimitsTests.swift`.

- [ ] **Step 2: Rewrite `FeatureLimits.swift`**

Overwrite `Checklist/Checklist/Checklist/Purchases/FeatureLimits.swift`:

```swift
/// FeatureLimits.swift
/// Purpose: Value-type numeric + boolean caps for one plan. Hydrated from
///   bundled plans.json via PlanCatalog; merged across multiple active plans
///   by EntitlementManager.
/// Dependencies: Foundation (Codable).
/// Key concepts:
///   - Nullable Int: nil means unlimited.
///   - merged(with:) takes the more generous value per field (nil > number,
///     larger number wins, true wins on Bool).
///   - Static constants: only `unlimited` and `restrictive` exist here — named
///     tiers (free / plus / pro) live in plans.json and flow through PlanCatalog.

import Foundation

/// Per-feature limits for a single plan. All numeric fields are nullable to
/// express "unlimited"; the `cloudKitSync` bool gates iCloud sync independently.
///
/// Merge semantics (`merged(with:)`):
/// - Int? fields: `nil` (unlimited) wins; otherwise the larger number wins.
/// - Bool fields: `true` wins (OR).
///
/// This lets EntitlementManager combine multiple owned plans into a single
/// most-generous effective limits set without branching per dimension.
struct FeatureLimits: Codable, Equatable {
    var maxChecklists: Int?
    var maxItemsPerChecklist: Int?
    var maxLiveRunsPerChecklist: Int?
    var maxTotalRuns: Int?
    var maxTags: Int?
    var maxCategories: Int?
    var cloudKitSync: Bool

    // MARK: - Standard instances

    /// All dimensions unlimited, cloudKitSync on. Used as the final fallback
    /// if plans.json fails to load and as the right-hand identity in merges.
    static let unlimited = FeatureLimits(
        maxChecklists: nil,
        maxItemsPerChecklist: nil,
        maxLiveRunsPerChecklist: nil,
        maxTotalRuns: nil,
        maxTags: nil,
        maxCategories: nil,
        cloudKitSync: true
    )

    /// All dimensions zero, cloudKitSync off. Used as the starting value when
    /// merging up from a set of plans (so the merge monotonically opens access).
    static let restrictive = FeatureLimits(
        maxChecklists: 0,
        maxItemsPerChecklist: 0,
        maxLiveRunsPerChecklist: 0,
        maxTotalRuns: 0,
        maxTags: 0,
        maxCategories: 0,
        cloudKitSync: false
    )

    // MARK: - Merge

    /// Returns the most-generous per-field merge of `self` and `other`.
    func merged(with other: FeatureLimits) -> FeatureLimits {
        FeatureLimits(
            maxChecklists: mergedMax(self.maxChecklists, other.maxChecklists),
            maxItemsPerChecklist: mergedMax(self.maxItemsPerChecklist, other.maxItemsPerChecklist),
            maxLiveRunsPerChecklist: mergedMax(self.maxLiveRunsPerChecklist, other.maxLiveRunsPerChecklist),
            maxTotalRuns: mergedMax(self.maxTotalRuns, other.maxTotalRuns),
            maxTags: mergedMax(self.maxTags, other.maxTags),
            maxCategories: mergedMax(self.maxCategories, other.maxCategories),
            cloudKitSync: self.cloudKitSync || other.cloudKitSync
        )
    }

    /// nil (unlimited) wins; else the larger value wins.
    private func mergedMax(_ a: Int?, _ b: Int?) -> Int? {
        if a == nil || b == nil { return nil }
        return max(a!, b!)
    }

    // MARK: - Per-dimension guard helpers

    /// True iff `current` is below the checklist cap (or no cap).
    func canAddChecklist(current: Int) -> Bool {
        guard let max = maxChecklists else { return true }
        return current < max
    }

    /// True iff the current item count on a checklist is below the per-list cap.
    func canAddItem(currentItemsOnChecklist: Int) -> Bool {
        guard let max = maxItemsPerChecklist else { return true }
        return currentItemsOnChecklist < max
    }

    /// True iff the current live-run count on a checklist is below the per-list cap.
    func canStartRun(currentLiveRunsOnChecklist: Int) -> Bool {
        guard let max = maxLiveRunsPerChecklist else { return true }
        return currentLiveRunsOnChecklist < max
    }

    /// True iff `current` is below the total-runs (live + completed) cap.
    func canCompleteRun(currentTotalRuns: Int) -> Bool {
        guard let max = maxTotalRuns else { return true }
        return currentTotalRuns < max
    }

    /// True iff `current` is below the tag cap.
    func canAddTag(current: Int) -> Bool {
        guard let max = maxTags else { return true }
        return current < max
    }

    /// True iff `current` is below the category cap.
    func canAddCategory(current: Int) -> Bool {
        guard let max = maxCategories else { return true }
        return current < max
    }

    // MARK: - Display helpers (used by PaywallSheet and SettingsView)

    var checklistLimitDescription: String {
        guard let max = maxChecklists else { return "Unlimited checklists" }
        return "\(max) checklist\(max == 1 ? "" : "s")"
    }

    var tagLimitDescription: String {
        guard let max = maxTags else { return "Unlimited tags" }
        return "\(max) tag\(max == 1 ? "" : "s")"
    }

    var categoryLimitDescription: String {
        guard let max = maxCategories else { return "Unlimited categories" }
        if max == 0 { return "No categories" }
        return "\(max) categor\(max == 1 ? "y" : "ies")"
    }
}
```

- [ ] **Step 3: Build — expect compile failures at old `.free` / `.premium` call sites**

Standard build command. You'll see errors at `EntitlementManager.swift` (`.free` / `.premium` vanished). That's fixed in Task 8.3.

- [ ] **Step 4: Leave the build broken for now — continue to 8.2 which adds `Plan` / `PlanCatalog`, and 8.3 which rewires `EntitlementManager`. Do NOT commit yet.**

This chain of 3 tasks is intentionally un-splittable because they form a single "decouple product → entitlement → limits" refactor. Commit after 8.3 builds.

---

## Task 8.2: `Plan` + `PlanCatalog` + bundled `plans.json`

**Files:**
- Create: `Checklist/Checklist/Checklist/Purchases/Plan.swift`
- Create: `Checklist/Checklist/Checklist/Purchases/PlanCatalog.swift`
- Create: `Checklist/Checklist/Checklist/Resources/plans.json`
- Create: `Checklist/Checklist/ChecklistTests/Purchases/PlanCatalogTests.swift`

- [ ] **Step 1: Write `Plan.swift`**

```swift
/// Plan.swift
/// Purpose: One entry in the plan catalog — maps a StoreKit product ID (or
///   nil for the free plan) to a display name and a FeatureLimits.
/// Dependencies: Foundation (Codable).
/// Key concepts:
///   - `productID == nil` identifies the free plan.
///   - `id` is a stable slug used by tests + logs; not user-facing.
///   - `displayName` is shown in PaywallSheet and SettingsView.

import Foundation

/// A named plan tier. `productID` nil = free; non-nil = a StoreKit product.
struct Plan: Codable, Equatable, Identifiable {
    let id: String
    let displayName: String
    let productID: String?
    let limits: FeatureLimits
}
```

- [ ] **Step 2: Write `PlanCatalog.swift`**

```swift
/// PlanCatalog.swift
/// Purpose: Source of truth for all Plans. Loads from bundled plans.json once
///   at first access; falls back to a hardcoded safe default if the JSON is
///   missing or malformed.
/// Dependencies: Foundation, Plan, FeatureLimits.
/// Key concepts:
///   - Sync loader (JSON is in the app bundle — always available at first read).
///   - Design accommodates a future remote override: swap `load()` to async
///     fetch + cache without touching callers.
///   - The free plan is the first plan with `productID == nil`.
///   - `plan(for productID:)` resolves an owned StoreKit productID to its Plan,
///     or returns `nil` when the productID isn't in the catalog.

import Foundation

/// Source of truth for Plans. Loads bundled `plans.json` lazily; safe default
/// fallback keeps the app usable even if the JSON is missing.
enum PlanCatalog {

    // MARK: - Public API

    /// All plans in the catalog, in declaration order from plans.json.
    static var plans: [Plan] { cache.plans }

    /// The free plan — first entry with `productID == nil`. If no free plan is
    /// declared, a safe hardcoded default is returned (which should never
    /// happen in a shipping build, but we defend against it).
    static var freePlan: Plan {
        plans.first(where: { $0.productID == nil }) ?? defaultFreePlan
    }

    /// All StoreKit product IDs declared across non-free plans.
    static var allProductIDs: [String] {
        plans.compactMap(\.productID)
    }

    /// Returns the plan owning the given productID, if any.
    static func plan(for productID: String) -> Plan? {
        plans.first(where: { $0.productID == productID })
    }

    // MARK: - Private cache

    private static let cache: (plans: [Plan], error: Error?) = load()

    private static func load() -> (plans: [Plan], error: Error?) {
        guard let url = Bundle.main.url(forResource: "plans", withExtension: "json") else {
            return ([defaultFreePlan], CatalogError.resourceNotFound)
        }
        do {
            let data = try Data(contentsOf: url)
            let wrapper = try JSONDecoder().decode(Wrapper.self, from: data)
            return (wrapper.plans, nil)
        } catch {
            return ([defaultFreePlan], error)
        }
    }

    private struct Wrapper: Codable { let plans: [Plan] }

    private enum CatalogError: Error { case resourceNotFound }

    /// Hard-coded fallback so the app doesn't crash if plans.json is missing.
    /// Free tier with cap-all-at-zero — the user can still read existing data
    /// but can't create anything. This is deliberately conservative; a missing
    /// plans.json is a build-config bug that should be caught in tests.
    private static let defaultFreePlan = Plan(
        id: "_fallback_free",
        displayName: "Free",
        productID: nil,
        limits: .restrictive
    )
}
```

- [ ] **Step 3: Write `plans.json`**

Create `Checklist/Checklist/Checklist/Resources/plans.json`:

```json
{
  "plans": [
    {
      "id": "free",
      "displayName": "Free",
      "productID": null,
      "limits": {
        "maxChecklists": 1,
        "maxItemsPerChecklist": 25,
        "maxLiveRunsPerChecklist": 1,
        "maxTotalRuns": null,
        "maxTags": 3,
        "maxCategories": 0,
        "cloudKitSync": false
      }
    },
    {
      "id": "plus_monthly",
      "displayName": "Checklist Plus",
      "productID": "com.checklist.premium.monthly",
      "limits": {
        "maxChecklists": null,
        "maxItemsPerChecklist": null,
        "maxLiveRunsPerChecklist": null,
        "maxTotalRuns": null,
        "maxTags": null,
        "maxCategories": null,
        "cloudKitSync": true
      }
    },
    {
      "id": "plus_annual",
      "displayName": "Checklist Plus",
      "productID": "com.checklist.premium.annual",
      "limits": {
        "maxChecklists": null,
        "maxItemsPerChecklist": null,
        "maxLiveRunsPerChecklist": null,
        "maxTotalRuns": null,
        "maxTags": null,
        "maxCategories": null,
        "cloudKitSync": true
      }
    }
  ]
}
```

Note: the `Resources/` folder is picked up automatically by Xcode 16's synchronized root group. No `.pbxproj` edit required.

- [ ] **Step 4: Write tests**

Create `Checklist/Checklist/ChecklistTests/Purchases/PlanCatalogTests.swift`:

```swift
/// PlanCatalogTests.swift
/// Purpose: Tests the shipped plans.json loads correctly and that the catalog
///   exposes the expected free and premium plans.
/// Dependencies: XCTest, Checklist target.

import XCTest
@testable import Checklist

final class PlanCatalogTests: XCTestCase {

    /// plans.json loads and yields ≥2 plans (free + at least one paid).
    func test_catalog_loads_at_least_two_plans() {
        XCTAssertGreaterThanOrEqual(PlanCatalog.plans.count, 2,
                                    "plans.json must ship free + at least one paid tier")
    }

    /// Free plan exists with productID nil.
    func test_free_plan_has_nil_productID() {
        XCTAssertNil(PlanCatalog.freePlan.productID)
    }

    /// Free plan's limits match the ship defaults (1 list / 3 tags / 0 categories).
    func test_free_plan_limits_are_as_documented() {
        let f = PlanCatalog.freePlan.limits
        XCTAssertEqual(f.maxChecklists, 1, "documented free-tier default")
        XCTAssertEqual(f.maxTags, 3)
        XCTAssertEqual(f.maxCategories, 0)
        XCTAssertFalse(f.cloudKitSync, "free tier must NOT sync")
    }

    /// plan(for:) resolves known StoreKit IDs.
    func test_plan_lookup_by_productID() {
        XCTAssertNotNil(PlanCatalog.plan(for: "com.checklist.premium.monthly"))
        XCTAssertNotNil(PlanCatalog.plan(for: "com.checklist.premium.annual"))
        XCTAssertNil(PlanCatalog.plan(for: "com.bogus.product"))
    }

    /// allProductIDs contains each non-free plan's productID.
    func test_allProductIDs_excludes_free() {
        let ids = PlanCatalog.allProductIDs
        XCTAssertFalse(ids.contains(where: { $0.isEmpty }), "nil / empty product IDs filtered out")
        XCTAssertGreaterThanOrEqual(ids.count, 1)
    }
}
```

- [ ] **Step 5: Don't build yet — move on to 8.3 which rewires `EntitlementManager`.**

The build remains broken after 8.2 because `EntitlementManager.swift` still references `FeatureLimits.premium`. Task 8.3 fixes it.

---

## Task 8.3: Rewire `EntitlementManager` + `StoreKitManager` around the catalog

**Files:**
- Modify: `Checklist/Checklist/Checklist/Purchases/EntitlementManager.swift`
- Modify: `Checklist/Checklist/Checklist/Purchases/StoreKitManager.swift`

- [ ] **Step 1: Rewrite `EntitlementManager.swift`**

```swift
/// EntitlementManager.swift
/// Purpose: Single source of truth for the user's current entitlements.
///   Resolves the set of owned StoreKit product IDs to an effective Plan
///   (most-generous merge when multiple are owned) via PlanCatalog.
/// Dependencies: Foundation, Combine, PlanCatalog, Plan, FeatureLimits.
/// Key concepts:
///   - `activePlan` is the Plan currently effective; changes when StoreKitManager
///     updates the owned-product-ID set.
///   - `limits` is `activePlan.limits` — this is what view gates read.
///   - `isPremium` kept for back-compat: true when activePlan != free plan.

import Foundation
import Combine

/// Exposes the user's currently-effective Plan + its merged FeatureLimits.
/// StoreKitManager drives the input via `updateOwnedProducts(_:)`.
@MainActor
final class EntitlementManager: ObservableObject {
    /// The plan in effect. Publishes when StoreKitManager reports a change.
    @Published private(set) var activePlan: Plan = PlanCatalog.freePlan

    /// Back-compat: true when a paid plan is active.
    var isPremium: Bool { activePlan.productID != nil }

    /// The merged limits for the active plan. View gates read this.
    var limits: FeatureLimits { activePlan.limits }

    /// Called by StoreKitManager when the set of owned product IDs changes.
    /// Resolves to the most-generous merge of all owned plans.
    func updateOwnedProducts(_ productIDs: Set<String>) {
        activePlan = Self.resolvePlan(for: productIDs)
    }

    /// Pure function: pick plans matching `productIDs`, merge their limits,
    /// return a synthetic Plan carrying the merged limits. Falls back to the
    /// free plan when no matches.
    static func resolvePlan(for productIDs: Set<String>) -> Plan {
        let owned = PlanCatalog.plans.filter {
            guard let pid = $0.productID else { return false }
            return productIDs.contains(pid)
        }
        if owned.isEmpty { return PlanCatalog.freePlan }

        // Merge starting from `restrictive` so Int fields open monotonically.
        let mergedLimits = owned.reduce(FeatureLimits.restrictive) {
            $0.merged(with: $1.limits)
        }
        // Attribute the effective plan to the first owned plan's name/id for
        // display purposes — a merge of two plans is conceptually still "one
        // active subscription" from the user's perspective.
        let primary = owned[0]
        return Plan(
            id: primary.id,
            displayName: primary.displayName,
            productID: primary.productID,
            limits: mergedLimits
        )
    }
}
```

- [ ] **Step 2: Rewrite `StoreKitManager.swift` to read product IDs from the catalog**

```swift
/// StoreKitManager.swift
/// Purpose: Manages StoreKit 2 product loading, purchasing, and entitlement
///   verification. Product IDs come from PlanCatalog (bundled plans.json),
///   not hardcoded constants.
/// Dependencies: Foundation, StoreKit, Combine, PlanCatalog, EntitlementManager.
/// Key concepts:
///   - `products` is filtered to the IDs declared in PlanCatalog.
///   - `refreshEntitlements` gathers verified, non-revoked, auto-renewable
///     transactions, pulls their productIDs, and notifies EntitlementManager.

import Foundation
import StoreKit
import Combine

/// Loads products matching PlanCatalog.allProductIDs; listens for transactions
/// and forwards the owned-product-ID set to EntitlementManager.
@MainActor
final class StoreKitManager: ObservableObject {

    // MARK: - Published state

    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Private

    private weak var entitlementManager: EntitlementManager?
    private var transactionListenerTask: Task<Void, Error>?

    // MARK: - Init / deinit

    init(entitlementManager: EntitlementManager) {
        self.entitlementManager = entitlementManager
        transactionListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    // MARK: - Computed convenience (used by paywall)

    /// The cheapest monthly-period product, if any. Used by PaywallSheet
    /// when it wants to show a primary "Monthly" CTA.
    var monthlyProduct: Product? {
        products.first { $0.subscription?.subscriptionPeriod.unit == .month }
    }

    /// The cheapest yearly product, if any.
    var annualProduct: Product? {
        products.first { $0.subscription?.subscriptionPeriod.unit == .year }
    }

    // MARK: - Public actions

    /// Fetches all product info for the IDs declared in PlanCatalog.
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let ids = PlanCatalog.allProductIDs
            guard !ids.isEmpty else { products = []; return }
            products = try await Product.products(for: ids)
                .sorted { $0.price < $1.price }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Initiates a purchase. On success, finalizes the transaction and
    /// refreshes entitlements.
    func purchase(_ product: Product) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlements()
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Re-syncs entitlements with the App Store (for Restore Purchases).
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Private helpers

    /// Gathers the set of currently-owned, verified, non-revoked, auto-renewable
    /// product IDs and forwards them to EntitlementManager.
    func refreshEntitlements() async {
        var owned: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productType == .autoRenewable,
               transaction.revocationDate == nil {
                owned.insert(transaction.productID)
            }
        }
        entitlementManager?.updateOwnedProducts(owned)
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.refreshEntitlements()
                }
            }
        }
    }
}
```

- [ ] **Step 3: Update `ChecklistApp.swift` to read `limits.cloudKitSync`**

Find the `setupModelContainer()` function (line ~44):

```swift
    private func setupModelContainer() {
        do {
            let schema = Schema([
                ChecklistCategory.self,
                Tag.self,
                Checklist.self,
                Item.self,
                Run.self,
                Check.self,
                CompletedRun.self,
            ])
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                cloudKitDatabase: entitlementManager.isPremium ? .automatic : .none
            )
            modelContainer = try ModelContainer(for: schema, configurations: configuration)
        } catch {
            print("Failed to create ModelContainer: \(error)")
        }
    }
```

Replace the `cloudKitDatabase: ...` line with:

```swift
                cloudKitDatabase: entitlementManager.limits.cloudKitSync ? .automatic : .none
```

And find the `onChange(of:)` modifier:

```swift
        .onChange(of: entitlementManager.isPremium) { _, _ in setupModelContainer() }
```

Replace with:

```swift
        .onChange(of: entitlementManager.limits.cloudKitSync) { _, _ in setupModelContainer() }
```

- [ ] **Step 4: Build — expect BUILD SUCCEEDED now**

```bash
xcodebuild -project Checklist/Checklist/Checklist.xcodeproj \
  -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`. The Purchases refactor is now internally consistent.

- [ ] **Step 5: Run the new purchases tests**

```bash
xcodebuild -project Checklist/Checklist/Checklist.xcodeproj \
  -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test -only-testing:ChecklistTests/FeatureLimitsTests -only-testing:ChecklistTests/PlanCatalogTests 2>&1 | \
  grep -E "passed|failed" | tail -15
```

Expected: 10 tests passing (5 FeatureLimitsTests + 5 PlanCatalogTests).

- [ ] **Step 6: Commit the decoupling**

```bash
git add Checklist/Checklist/Checklist/Purchases/ \
        Checklist/Checklist/Checklist/Resources/plans.json \
        Checklist/Checklist/Checklist/ChecklistApp.swift \
        Checklist/Checklist/ChecklistTests/Purchases/
git commit -m "feat(purchases): decouple products from feature limits via plans.json

Introduces Plan + PlanCatalog + expanded FeatureLimits (adds items /
live-runs / total-runs / cloudKitSync dimensions). EntitlementManager
resolves the owned-product-ID set to a most-generous merge of all
matching plans' limits. StoreKitManager reads product IDs from the
catalog, not hardcoded constants. ChecklistApp's CloudKit decision
moves from isPremium → limits.cloudKitSync. 10 new unit tests cover
merge semantics + catalog load."
```

---

## Task 8.4: `EntitlementGate` — centralized gate + paywall trigger result

**Files:**
- Create: `Checklist/Checklist/Checklist/Purchases/EntitlementGate.swift`
- Create: `Checklist/Checklist/ChecklistTests/Purchases/EntitlementGateTests.swift`

- [ ] **Step 1: Write failing tests**

```swift
/// EntitlementGateTests.swift
/// Purpose: Tests that the pure EntitlementGate helpers return .allowed or
///   .blocked with the expected reason given a FeatureLimits + a current
///   count. Tests the decision only; the view-side presentation of
///   PaywallSheet is verified manually.
/// Dependencies: XCTest, Checklist target.

import XCTest
@testable import Checklist

final class EntitlementGateTests: XCTestCase {

    private let free = FeatureLimits(
        maxChecklists: 1, maxItemsPerChecklist: 25,
        maxLiveRunsPerChecklist: 1, maxTotalRuns: nil,
        maxTags: 3, maxCategories: 0, cloudKitSync: false
    )

    func test_canCreateChecklist_allowed_when_under_cap() {
        XCTAssertEqual(EntitlementGate.canCreateChecklist(current: 0, limits: free),
                       .allowed)
    }

    func test_canCreateChecklist_blocked_when_at_cap() {
        let result = EntitlementGate.canCreateChecklist(current: 1, limits: free)
        if case .blocked(let reason) = result {
            XCTAssertEqual(reason.dimension, .checklists)
            XCTAssertEqual(reason.limit, 1)
        } else {
            XCTFail("expected .blocked, got \(result)")
        }
    }

    func test_canAddTag_blocked_at_3_with_plural_copy() {
        let result = EntitlementGate.canCreateTag(current: 3, limits: free)
        if case .blocked(let reason) = result {
            XCTAssertTrue(reason.message.contains("3"), "message must include the cap")
        } else { XCTFail("expected .blocked") }
    }

    func test_canAddCategory_blocked_when_cap_is_zero() {
        let result = EntitlementGate.canCreateCategory(current: 0, limits: free)
        // cap of 0 means "not allowed at all" — always blocked
        if case .blocked = result {} else { XCTFail("cap of 0 must always block") }
    }

    func test_canAddItem_uses_per_checklist_cap() {
        XCTAssertEqual(EntitlementGate.canAddItem(
            currentItemsOnChecklist: 24, limits: free
        ), .allowed)
        let blocked = EntitlementGate.canAddItem(currentItemsOnChecklist: 25, limits: free)
        if case .blocked = blocked {} else { XCTFail("at 25 items must block") }
    }

    func test_canStartRun_uses_live_runs_cap() {
        XCTAssertEqual(EntitlementGate.canStartRun(
            currentLiveRunsOnChecklist: 0, limits: free
        ), .allowed)
        let blocked = EntitlementGate.canStartRun(
            currentLiveRunsOnChecklist: 1, limits: free
        )
        if case .blocked = blocked {} else { XCTFail("at 1 live run free must block") }
    }

    func test_allowed_when_limits_unlimited() {
        let u = FeatureLimits.unlimited
        XCTAssertEqual(EntitlementGate.canCreateChecklist(current: 10_000, limits: u), .allowed)
        XCTAssertEqual(EntitlementGate.canCreateTag(current: 10_000, limits: u), .allowed)
        XCTAssertEqual(EntitlementGate.canCreateCategory(current: 10_000, limits: u), .allowed)
    }
}
```

- [ ] **Step 2: Implement `EntitlementGate.swift`**

```swift
/// EntitlementGate.swift
/// Purpose: Pure gating decisions for feature access. Returns .allowed or
///   .blocked(reason); views pattern-match on the result and present the
///   paywall when blocked.
/// Dependencies: FeatureLimits.
/// Key concepts:
///   - Intent-first: one method per user-facing feature, not one per tier.
///   - Blocked carries a structured Reason so the paywall can show feature-
///     specific copy ("Unlock more checklists" vs "Unlock tags").
///   - Pure — no singletons, no state. Views pass `entitlementManager.limits`.

import Foundation

/// Outcome of a gate decision.
enum GateDecision: Equatable {
    case allowed
    case blocked(Reason)

    /// Structured blocked reason carried to the paywall for feature-specific copy.
    struct Reason: Equatable {
        let dimension: Dimension
        /// Cap value hit (or nil when semantics are "not available at all").
        let limit: Int?
        /// Human-readable message shown on the paywall banner.
        let message: String
    }

    /// Feature categories the gate reasons about.
    enum Dimension: String, Equatable {
        case checklists
        case items
        case liveRuns
        case totalRuns
        case tags
        case categories
        case cloudKitSync
    }
}

/// Pure gating helpers. Views call these; views own the paywall presentation.
enum EntitlementGate {

    /// Can the user create another checklist given the current count?
    static func canCreateChecklist(current: Int, limits: FeatureLimits) -> GateDecision {
        guard let max = limits.maxChecklists else { return .allowed }
        if current < max { return .allowed }
        return .blocked(.init(
            dimension: .checklists,
            limit: max,
            message: "Free plan is limited to \(max) checklist\(max == 1 ? "" : "s"). Upgrade for unlimited."
        ))
    }

    /// Can the user add another item to the checklist given its current item count?
    static func canAddItem(currentItemsOnChecklist: Int, limits: FeatureLimits) -> GateDecision {
        guard let max = limits.maxItemsPerChecklist else { return .allowed }
        if currentItemsOnChecklist < max { return .allowed }
        return .blocked(.init(
            dimension: .items,
            limit: max,
            message: "Free plan caps each checklist at \(max) items. Upgrade to keep adding."
        ))
    }

    /// Can the user start another live run on the checklist?
    static func canStartRun(currentLiveRunsOnChecklist: Int, limits: FeatureLimits) -> GateDecision {
        guard let max = limits.maxLiveRunsPerChecklist else { return .allowed }
        if currentLiveRunsOnChecklist < max { return .allowed }
        return .blocked(.init(
            dimension: .liveRuns,
            limit: max,
            message: "Free plan allows \(max) live run\(max == 1 ? "" : "s") per checklist. Upgrade for concurrent runs."
        ))
    }

    /// Can the user create another tag?
    static func canCreateTag(current: Int, limits: FeatureLimits) -> GateDecision {
        guard let max = limits.maxTags else { return .allowed }
        if current < max { return .allowed }
        return .blocked(.init(
            dimension: .tags,
            limit: max,
            message: "Free plan is limited to \(max) tag\(max == 1 ? "" : "s"). Upgrade for unlimited."
        ))
    }

    /// Can the user create another category?
    static func canCreateCategory(current: Int, limits: FeatureLimits) -> GateDecision {
        guard let max = limits.maxCategories else { return .allowed }
        if current < max { return .allowed }
        return .blocked(.init(
            dimension: .categories,
            limit: max,
            message: max == 0
                ? "Categories are a Plus feature."
                : "Free plan is limited to \(max) categor\(max == 1 ? "y" : "ies"). Upgrade for unlimited."
        ))
    }
}
```

- [ ] **Step 3: Run tests**

```bash
xcodebuild -project Checklist/Checklist/Checklist.xcodeproj \
  -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test -only-testing:ChecklistTests/EntitlementGateTests 2>&1 | grep -E "passed|failed" | tail -10
```

Expected: 7 tests passing.

- [ ] **Step 4: Commit**

```bash
git add Checklist/Checklist/Checklist/Purchases/EntitlementGate.swift \
        Checklist/Checklist/ChecklistTests/Purchases/EntitlementGateTests.swift
git commit -m "feat(purchases): EntitlementGate pure helpers for per-feature access decisions

Returns .allowed or .blocked(Reason) with a structured Dimension + message.
Views pattern-match the result and own the PaywallSheet presentation so
paywall copy can be feature-specific (items vs tags vs lists). Seven tests."
```

---

## Task 8.5: `PaywallSheet` (Gem visuals)

**Files:**
- Create: `Checklist/Checklist/Checklist/Sheets/PaywallSheet.swift`

- [ ] **Step 1: Write `PaywallSheet.swift`**

```swift
/// PaywallSheet.swift
/// Purpose: Presents the upgrade offer when EntitlementGate returns .blocked,
///   or when the user taps "Upgrade" from SettingsView. Feature-specific
///   headline copy comes from the Reason passed in.
/// Dependencies: SwiftUI, StoreKit, BottomSheet, PillButton, HeroGem, Theme,
///   GemIcons, EntitlementManager, StoreKitManager, GateDecision, FeatureLimits.
/// Key concepts:
///   - `reason` is optional. nil = generic "unlock everything" pitch (opened
///     from Settings); non-nil = feature-specific gate trigger.
///   - Product list pulls from StoreKitManager.products (sorted by price).
///   - "Restore purchases" calls through to StoreKitManager.restorePurchases.

import SwiftUI
import StoreKit

/// Sheet shown when an EntitlementGate returns .blocked, or from SettingsView's
/// Upgrade row. Offers the active paid plans pulled from StoreKitManager.
struct PaywallSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var storeKit: StoreKitManager
    @EnvironmentObject private var entitlementManager: EntitlementManager

    /// The reason the paywall opened (feature + cap + message). nil when the
    /// user opened Settings → Upgrade directly.
    let reason: GateDecision.Reason?

    var body: some View {
        BottomSheet {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                hero
                pitchCopy
                featureList
                productButtons
                footerRow
            }
        }
    }

    // MARK: - Hero

    private var hero: some View {
        HStack(spacing: Theme.Spacing.md) {
            HeroGem(color: Theme.amethyst, size: 56)
            VStack(alignment: .leading, spacing: 4) {
                Text("UPGRADE")
                    .font(Theme.eyebrow()).tracking(2)
                    .foregroundColor(Theme.amethyst)
                Text(headline)
                    .font(Theme.display(size: 26))
                    .foregroundColor(Theme.text)
            }
        }
    }

    /// Headline: feature-specific when `reason` is set, generic otherwise.
    private var headline: String {
        guard let reason else { return "Unlock everything." }
        switch reason.dimension {
        case .checklists:   return "Unlock more checklists."
        case .items:        return "Keep adding items."
        case .liveRuns:     return "Run many trips at once."
        case .totalRuns:    return "Keep your full history."
        case .tags:         return "Unlock more tags."
        case .categories:   return "Organize with categories."
        case .cloudKitSync: return "Sync across devices."
        }
    }

    // MARK: - Pitch

    private var pitchCopy: some View {
        Text(reason?.message ?? "Checklist Plus unlocks unlimited lists, items, runs, tags, categories, and iCloud sync across your devices.")
            .font(.system(size: 14))
            .foregroundColor(Theme.dim)
    }

    // MARK: - Feature list

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 6) {
            featureBullet("Unlimited checklists + items")
            featureBullet("Concurrent live runs")
            featureBullet("Unlimited tags + categories")
            featureBullet("iCloud sync across all your devices")
        }
    }

    private func featureBullet(_ text: String) -> some View {
        HStack(spacing: 8) {
            GemIcons.image("check")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Theme.emerald)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Theme.text)
        }
    }

    // MARK: - Product buttons

    private var productButtons: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(storeKit.products, id: \.id) { product in
                productButton(product)
            }
            if storeKit.products.isEmpty {
                Text(storeKit.isLoading ? "Loading plans…" : "Plans unavailable. Check your connection.")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.dim)
            }
        }
    }

    private func productButton(_ product: Product) -> some View {
        PillButton(
            title: productLabel(product),
            color: Theme.amethyst,
            wide: true
        ) {
            Task {
                await storeKit.purchase(product)
                if entitlementManager.isPremium { dismiss() }
            }
        }
    }

    /// Formats the product label as "DISPLAY NAME · PRICE/PERIOD".
    private func productLabel(_ product: Product) -> String {
        let period: String
        if let sub = product.subscription?.subscriptionPeriod {
            switch sub.unit {
            case .day:   period = "day"
            case .week:  period = "week"
            case .month: period = "mo"
            case .year:  period = "yr"
            @unknown default: period = ""
            }
        } else {
            period = ""
        }
        let price = product.displayPrice
        let name = product.displayName.isEmpty
            ? (PlanCatalog.plan(for: product.id)?.displayName ?? "Plus")
            : product.displayName
        return "\(name) · \(price)/\(period)"
    }

    // MARK: - Footer

    private var footerRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            PillButton(title: "Maybe later", tone: .ghost, wide: true) { dismiss() }
            PillButton(title: "Restore", tone: .ghost, wide: true) {
                Task { await storeKit.restorePurchases() }
            }
        }
        .padding(.top, Theme.Spacing.sm)
    }
}

// MARK: - Previews

#Preview("Paywall — tags reason") {
    let ent = EntitlementManager()
    let sk = StoreKitManager(entitlementManager: ent)
    return Color.gray.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            PaywallSheet(
                reason: .init(
                    dimension: .tags, limit: 3,
                    message: "Free plan is limited to 3 tags. Upgrade for unlimited."
                )
            )
            .environmentObject(ent)
            .environmentObject(sk)
        }
}

#Preview("Paywall — no reason") {
    let ent = EntitlementManager()
    let sk = StoreKitManager(entitlementManager: ent)
    return Color.gray.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            PaywallSheet(reason: nil)
                .environmentObject(ent)
                .environmentObject(sk)
        }
}
```

- [ ] **Step 2: Build**

Standard build. Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add Checklist/Checklist/Checklist/Sheets/PaywallSheet.swift
git commit -m "feat(sheets): PaywallSheet (Gem visuals, feature-specific headline)

Headline + pitch copy come from the GateDecision.Reason passed in, so the
paywall speaks to the specific feature the user hit. Pulls product list
from StoreKitManager.products; dismisses on successful purchase. Restore
purchases action wired to StoreKitManager.restorePurchases."
```

---

## Task 8.6: Gate Home's `+` checklist-create button

**Files:**
- Modify: `Checklist/Checklist/Checklist/Views/HomeView.swift`

- [ ] **Step 1: Hook up the gate + paywall presentation on HomeView**

Find the top of the `HomeView` struct, after the `@Query` declarations. Add:

```swift
    @EnvironmentObject private var entitlementManager: EntitlementManager

    /// Reason passed to PaywallSheet when triggered by a gate. nil = opened
    /// via Settings → Upgrade (no current gate trigger).
    @State private var paywallReason: GateDecision.Reason? = nil
    @State private var showPaywall = false
```

Find the topBar's right button:

```swift
            right: { IconButton(iconName: "plus", solid: true) { showCreateSheet = true } }
```

Replace with:

```swift
            right: { IconButton(iconName: "plus", solid: true) { tapCreateList() } }
```

Add below `eyebrowText`:

```swift
    /// Tapping `+` gates through EntitlementGate — blocked routes to the paywall
    /// with a feature-specific reason instead of opening the create sheet.
    private func tapCreateList() {
        let decision = EntitlementGate.canCreateChecklist(
            current: checklists.count,
            limits: entitlementManager.limits
        )
        switch decision {
        case .allowed:
            showCreateSheet = true
        case .blocked(let reason):
            paywallReason = reason
            showPaywall = true
        }
    }
```

And in the `emptyState` view, change the `PillButton(title: "+ New list", ...)` action from `showCreateSheet = true` to `tapCreateList()`:

```swift
            PillButton(title: "+ New list", color: Theme.amethyst) {
                tapCreateList()
            }
```

Finally, add the sheet modifier next to the existing `.sheet(isPresented: $showCreateSheet)`:

```swift
            .sheet(isPresented: $showPaywall) {
                PaywallSheet(reason: paywallReason)
            }
```

- [ ] **Step 2: Build**

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add Checklist/Checklist/Checklist/Views/HomeView.swift
git commit -m "feat(gate): Home + button routes through EntitlementGate → PaywallSheet

Checklist cap from the active plan's limits; blocked taps present a
feature-specific paywall instead of the create sheet. Empty-state
'+ New list' pill honours the gate too."
```

---

## Task 8.7: Gate `TagsView`'s `+` + `+ New tag`

**Files:**
- Modify: `Checklist/Checklist/Checklist/Views/TagsView.swift`

- [ ] **Step 1: Rewire the two trigger points through a gate helper**

Add at top of struct:

```swift
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @State private var paywallReason: GateDecision.Reason? = nil
    @State private var showPaywall = false
```

Replace `showNewEditor = true` in both `topBar` and `newTagRow` with `tapCreateTag()`:

```swift
    private var topBar: some View {
        TopBar(
            left: { IconButton(iconName: "back") { dismiss() } },
            right: { IconButton(iconName: "plus", solid: true) { tapCreateTag() } }
        )
    }
```

```swift
    private var newTagRow: some View {
        Button {
            tapCreateTag()
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

    /// Gate + paywall presentation for create-new-tag.
    private func tapCreateTag() {
        let decision = EntitlementGate.canCreateTag(
            current: tags.count,
            limits: entitlementManager.limits
        )
        switch decision {
        case .allowed:
            showNewEditor = true
        case .blocked(let reason):
            paywallReason = reason
            showPaywall = true
        }
    }
```

Add the paywall sheet modifier next to the existing `.sheet(...)` chain:

```swift
        .sheet(isPresented: $showPaywall) {
            PaywallSheet(reason: paywallReason)
        }
```

- [ ] **Step 2: Build + commit**

Standard build. Commit:

```bash
git add Checklist/Checklist/Checklist/Views/TagsView.swift
git commit -m "feat(gate): TagsView + buttons route through EntitlementGate → PaywallSheet

Tag cap from the active plan's limits; blocked taps present the paywall
with a tag-specific headline. Both entry points (top-bar + and '+ New tag'
dashed pill) honour the gate."
```

---

## Task 8.8: Gate `CreateChecklistSheet`'s `+ New` category chip

**Files:**
- Modify: `Checklist/Checklist/Checklist/Sheets/CreateChecklistSheet.swift`

- [ ] **Step 1: Add the gate**

In `CreateChecklistSheet`, add:

```swift
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @State private var paywallReason: GateDecision.Reason? = nil
    @State private var showPaywall = false
```

Find the `newChip` view:

```swift
    private var newChip: some View {
        Button {
            showNewCategoryInput = true
        } label: {
```

Replace with:

```swift
    private var newChip: some View {
        Button {
            tapNewCategory()
        } label: {
```

Add the helper near `commitNewCategory()`:

```swift
    /// Gate + paywall for "+ New" category chip.
    private func tapNewCategory() {
        let decision = EntitlementGate.canCreateCategory(
            current: categories.count,
            limits: entitlementManager.limits
        )
        switch decision {
        case .allowed:
            showNewCategoryInput = true
        case .blocked(let reason):
            paywallReason = reason
            showPaywall = true
        }
    }
```

Add the sheet modifier at the end of the body block (outer scope of the view, matching the existing `BottomSheet { ... }`):

```swift
        BottomSheet {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("NEW LIST")
                    .font(Theme.eyebrow())
                    .tracking(2)
                    .foregroundColor(Theme.dim)
                // ... existing children unchanged ...
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallSheet(reason: paywallReason)
        }
```

- [ ] **Step 2: Build + commit**

```bash
git add Checklist/Checklist/Checklist/Sheets/CreateChecklistSheet.swift
git commit -m "feat(gate): CreateChecklistSheet + New category chip routes through EntitlementGate

Free plan has maxCategories=0 by default, so the chip always triggers the
paywall for free users. Paywall headline is category-specific via the
GateDecision.Reason."
```

---

## Task 8.9: Gate `AddItemInline` (max items per checklist)

**Files:**
- Modify: `Checklist/Checklist/Checklist/Sheets/AddItemInline.swift`

(Read the file first to locate the commit function. The sheet is presented from `ChecklistRunView` which knows the checklist; the gate wires in the sheet's Save handler.)

- [ ] **Step 1: Read the file to see the commit flow**

```bash
cat Checklist/Checklist/Checklist/Sheets/AddItemInline.swift | head -80
```

Look for the function that inserts the new `Item` via `ChecklistStore.addItem`. The current code calls `commitAdd()` or similar on Save.

- [ ] **Step 2: Wrap the commit with a gate check**

Add to the struct:

```swift
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @State private var paywallReason: GateDecision.Reason? = nil
    @State private var showPaywall = false
```

At the top of the existing commit function (e.g. `commitAdd()`), insert:

```swift
        // Gate on max items per checklist. Block routes to the paywall and
        // leaves the sheet open so the user's typed text isn't lost.
        let decision = EntitlementGate.canAddItem(
            currentItemsOnChecklist: checklist.items?.count ?? 0,
            limits: entitlementManager.limits
        )
        if case .blocked(let reason) = decision {
            paywallReason = reason
            showPaywall = true
            return
        }
```

Add the paywall sheet modifier on the `BottomSheet { ... }`:

```swift
        .sheet(isPresented: $showPaywall) {
            PaywallSheet(reason: paywallReason)
        }
```

- [ ] **Step 3: Build + commit**

```bash
git add Checklist/Checklist/Checklist/Sheets/AddItemInline.swift
git commit -m "feat(gate): AddItemInline gates save through EntitlementGate.canAddItem

Blocks saving a new item when the checklist is at its item cap; presents
the paywall with an items-specific headline. User's typed text is
preserved so they can still add after upgrading."
```

---

## Task 8.10: Gate `StartRunSheet` (max live runs per checklist)

**Files:**
- Modify: `Checklist/Checklist/Checklist/Sheets/StartRunSheet.swift`

- [ ] **Step 1: Wrap the `RunStore.startRun` call with a gate check**

Read the file; locate the Save / Start action. Add the gate similarly to Task 8.9:

```swift
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @State private var paywallReason: GateDecision.Reason? = nil
    @State private var showPaywall = false
```

Wrap the existing `try? RunStore.startRun(...)` call:

```swift
        let decision = EntitlementGate.canStartRun(
            currentLiveRunsOnChecklist: checklist.runs?.count ?? 0,
            limits: entitlementManager.limits
        )
        if case .blocked(let reason) = decision {
            paywallReason = reason
            showPaywall = true
            return
        }
        // ... existing startRun call ...
```

Plus the sheet modifier:

```swift
        .sheet(isPresented: $showPaywall) {
            PaywallSheet(reason: paywallReason)
        }
```

- [ ] **Step 2: Build + commit**

```bash
git add Checklist/Checklist/Checklist/Sheets/StartRunSheet.swift
git commit -m "feat(gate): StartRunSheet gates through EntitlementGate.canStartRun

Blocks starting an additional live run when the checklist is at its live-run
cap; presents the paywall with a concurrent-runs headline. Preserves the
user's typed run name."
```

---

## Task 8.11: `SettingsView` — stats, nav, danger zone

**Files:**
- Create: `Checklist/Checklist/Checklist/Views/SettingsRoute.swift`
- Create: `Checklist/Checklist/Checklist/Views/SettingsView.swift`
- Create: `Checklist/Checklist/ChecklistTests/Views/SettingsViewTests.swift`

- [ ] **Step 1: `SettingsRoute.swift`**

```swift
/// SettingsRoute.swift
/// Purpose: Hashable marker for NavigationStack → SettingsView.
import Foundation

enum SettingsDestination: Hashable {
    case root
}
```

- [ ] **Step 2: `SettingsView.swift`**

```swift
/// SettingsView.swift
/// Purpose: Settings home — stats row (total lists / runs / tags), shortcut
///   rows to Categories/Tags/History, account row (active plan + manage/
///   upgrade), and a danger zone (Clear all history).
/// Dependencies: SwiftUI, SwiftData, Theme, TopBar, PillButton, GemIcons,
///   EntitlementManager, StoreKitManager, RunStore, PaywallSheet,
///   CategoriesView, TagsView, HistoryView.
/// Key concepts:
///   - @Query drives the stat counts.
///   - Nav rows are Buttons that append to `path` so each destination lives
///     at the root navigationDestination registration on HomeView.

import SwiftUI
import SwiftData

/// Settings root. Reads counts live from @Query, emits nav via `path`.
struct SettingsView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var storeKit: StoreKitManager
    @Binding var path: NavigationPath

    @Query private var checklists: [Checklist]
    @Query private var tags: [Tag]
    @Query private var categories: [ChecklistCategory]
    @Query private var completedRuns: [CompletedRun]

    @State private var showPaywall = false
    @State private var showClearHistoryConfirm = false

    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        headerBlock
                        statsCard
                        planCard
                        shortcutRows
                        dangerZone
                        Spacer(minLength: 40)
                    }
                    .padding(.top, Theme.Spacing.md)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showPaywall) {
            PaywallSheet(reason: nil)
        }
        .alert(
            "Clear all history?",
            isPresented: $showClearHistoryConfirm,
            actions: {
                Button("Clear all", role: .destructive) {
                    try? RunStore.clearAllHistory(in: ctx)
                }
                Button("Cancel", role: .cancel) {}
            },
            message: {
                Text("Permanently deletes all completed runs on every checklist. Can't be undone.")
            }
        )
    }

    private var topBar: some View {
        TopBar(
            left: { IconButton(iconName: "back") { dismiss() } },
            right: { Color.clear.frame(width: 36, height: 36) }
        )
    }

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("PREFERENCES")
                .font(Theme.eyebrow()).tracking(2)
                .foregroundColor(Theme.dim)
            Text("Settings.")
                .font(Theme.display(size: 34, weight: .bold))
                .foregroundColor(Theme.text)
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    private var statsCard: some View {
        HStack(spacing: Theme.Spacing.md) {
            stat("Lists",       "\(checklists.count)")
            stat("Runs done",   "\(completedRuns.count)")
            stat("Tags",        "\(tags.count)")
            stat("Categories",  "\(categories.count)")
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(Theme.display(size: 22))
                .foregroundColor(Theme.text)
            Text(title.uppercased())
                .font(Theme.eyebrow()).tracking(1.5)
                .foregroundColor(Theme.dim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.border, lineWidth: 1))
    }

    private var planCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("YOUR PLAN")
                .font(Theme.eyebrow()).tracking(2)
                .foregroundColor(Theme.dim)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entitlementManager.activePlan.displayName)
                        .font(Theme.display(size: 20))
                        .foregroundColor(Theme.text)
                    Text(planSubtitle)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.dim)
                }
                Spacer()
                if entitlementManager.isPremium {
                    PillButton(title: "Manage", tone: .ghost, small: true) {
                        Task { await storeKit.restorePurchases() }
                    }
                } else {
                    PillButton(title: "Upgrade", color: Theme.amethyst, small: true) {
                        showPaywall = true
                    }
                }
            }
            .padding(Theme.Spacing.md)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Theme.card))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.border, lineWidth: 1))
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    /// Subtitle below the plan name: lists "N lists · M tags · iCloud on/off".
    private var planSubtitle: String {
        let l = entitlementManager.limits
        let lists = l.checklistLimitDescription
        let tags = l.tagLimitDescription
        let sync = l.cloudKitSync ? "iCloud on" : "iCloud off"
        return "\(lists) · \(tags) · \(sync)"
    }

    private var shortcutRows: some View {
        VStack(spacing: Theme.Spacing.xs) {
            shortcut(icon: "tag", title: "Manage tags") {
                path.append(TagsDestination.root)
            }
            shortcut(icon: "history", title: "Full history") {
                path.append(HistoryScope.allLists)
            }
            shortcut(icon: "sparkle", title: "Categories") {
                path.append(CategoriesDestination.root)
            }
            shortcut(icon: "edit", title: "Restore purchases") {
                Task { await storeKit.restorePurchases() }
            }
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    private func shortcut(
        icon: String,
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                GemIcons.image(icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.dim)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.text)
                Spacer()
                GemIcons.image("right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Theme.dimmer)
            }
            .padding(.horizontal, Theme.Spacing.md).padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Theme.card))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var dangerZone: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("DANGER ZONE")
                .font(Theme.eyebrow()).tracking(2)
                .foregroundColor(Theme.ruby)
                .padding(.horizontal, Theme.Spacing.xl)

            Button {
                showClearHistoryConfirm = true
            } label: {
                HStack {
                    GemIcons.image("trash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.ruby)
                    Text("Clear all history")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.ruby)
                    Spacer()
                }
                .padding(.horizontal, Theme.Spacing.md).padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Theme.ruby.opacity(0.1)))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.ruby.opacity(0.35), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Theme.Spacing.xl)
        }
    }
}

// MARK: - Preview

#Preview("Settings — seeded") {
    let container = try! SeedStore.container(for: .historicalRuns)
    let ent = EntitlementManager()
    let sk = StoreKitManager(entitlementManager: ent)
    return NavigationStack {
        SettingsView(path: .constant(NavigationPath()))
            .environmentObject(ent)
            .environmentObject(sk)
    }
    .modelContainer(container)
}
```

Note: this preview references a new `CategoriesDestination.root` that lands in Task 8.12 — the preview will fail to compile until that task lands. Leave as-is; Task 8.12 immediately follows.

- [ ] **Step 3: Commit stub tests**

```swift
/// SettingsViewTests.swift
/// Purpose: Tests SettingsView's stats + dangerous action entry points
///   without driving SwiftUI.

import XCTest
import SwiftData
@testable import Checklist

final class SettingsViewTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Checklist.self, ChecklistCategory.self, Item.self, Tag.self,
                Run.self, Check.self, CompletedRun.self,
            configurations: makeTestConfig()
        )
        return ModelContext(container)
    }

    /// Stats card reflects @Query counts — proxy test: counts resolve correctly.
    func test_stats_counts_reflect_fetch_results() throws {
        let ctx = try makeContext()
        _ = try ChecklistStore.create(name: "A", in: ctx)
        _ = try ChecklistStore.create(name: "B", in: ctx)
        _ = try TagStore.create(name: "Beach", in: ctx)

        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Checklist>()).count, 2)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Tag>()).count, 1)
    }
}
```

Don't commit yet — Task 8.12 (Categories destination) and 8.13 (RunStore.clearAllHistory) need to land first for the build to succeed.

---

## Task 8.12: `CategoriesView` + `CategoriesRoute`

**Files:**
- Create: `Checklist/Checklist/Checklist/Views/CategoriesRoute.swift`
- Create: `Checklist/Checklist/Checklist/Views/CategoriesView.swift`
- Create: `Checklist/Checklist/ChecklistTests/Views/CategoriesViewTests.swift`

- [ ] **Step 1: Write `CategoriesRoute.swift`**

```swift
/// CategoriesRoute.swift
/// Purpose: Hashable marker routing to CategoriesView.
import Foundation
enum CategoriesDestination: Hashable { case root }
```

- [ ] **Step 2: Write `CategoriesView.swift`**

```swift
/// CategoriesView.swift
/// Purpose: CRUD screen for ChecklistCategory. Lists all categories with
///   per-category usage count ("Used by N lists"); inline rename via tap;
///   swipe-to-delete (which nullifies list.category per existing cascade rule).
/// Dependencies: SwiftUI, SwiftData, ChecklistCategory, Theme, TopBar,
///   GemIcons, PillButton, CategoryStore, EntitlementManager, EntitlementGate,
///   PaywallSheet.
/// Key concepts:
///   - @Query drives the list in sortKey order.
///   - Inline rename: tapping a row toggles a TextField; Save calls
///     CategoryStore.rename. Cancel reverts.
///   - "+ New category" dashed pill gates through EntitlementGate.canCreateCategory.

import SwiftUI
import SwiftData

/// App-wide category manager. CRUD on ChecklistCategory.
struct CategoriesView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlementManager: EntitlementManager

    @Query(sort: [SortDescriptor(\ChecklistCategory.sortKey, order: .forward)])
    private var categories: [ChecklistCategory]
    @Query private var checklists: [Checklist]

    @State private var renamingID: UUID? = nil
    @State private var renamingText: String = ""
    @State private var showAddInput = false
    @State private var newName: String = ""

    @State private var paywallReason: GateDecision.Reason? = nil
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        headerBlock
                        listBody
                        Spacer(minLength: 40)
                    }
                    .padding(.top, Theme.Spacing.md)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showPaywall) {
            PaywallSheet(reason: paywallReason)
        }
    }

    private var topBar: some View {
        TopBar(
            left: { IconButton(iconName: "back") { dismiss() } },
            right: { IconButton(iconName: "plus", solid: true) { tapAdd() } }
        )
    }

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("GROUP CHECKLISTS").font(Theme.eyebrow()).tracking(2).foregroundColor(Theme.dim)
            Text("Categories.")
                .font(Theme.display(size: 34, weight: .bold))
                .foregroundColor(Theme.text)
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    private var listBody: some View {
        VStack(spacing: Theme.Spacing.xs) {
            if categories.isEmpty && !showAddInput {
                emptyRow
            }
            ForEach(categories) { cat in
                categoryRow(cat)
            }
            if showAddInput {
                newCategoryInput
            } else {
                newCategoryPill
            }
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    private var emptyRow: some View {
        Text("No categories yet.")
            .font(.system(size: 14))
            .foregroundColor(Theme.dim)
            .frame(maxWidth: .infinity)
            .padding(.top, 40)
    }

    private func categoryRow(_ cat: ChecklistCategory) -> some View {
        HStack {
            if renamingID == cat.id {
                TextField("", text: $renamingText)
                    .foregroundColor(Theme.text)
                    .font(.system(size: 15, weight: .semibold))
                    .onSubmit { commitRename(cat) }
                Button("Save") { commitRename(cat) }
                    .buttonStyle(.plain)
                    .foregroundColor(Theme.amethyst)
                Button("Cancel") { renamingID = nil }
                    .buttonStyle(.plain)
                    .foregroundColor(Theme.dim)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(cat.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.text)
                    Text(usage(cat))
                        .font(.system(size: 12))
                        .foregroundColor(Theme.dim)
                }
                Spacer()
                Button {
                    renamingID = cat.id
                    renamingText = cat.name
                } label: {
                    GemIcons.image("edit")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.dim)
                }
                .buttonStyle(.plain)
                Button(role: .destructive) {
                    try? CategoryStore.delete(cat, in: ctx)
                } label: {
                    GemIcons.image("trash")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.ruby)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Theme.Spacing.md).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.border, lineWidth: 1))
    }

    private func usage(_ cat: ChecklistCategory) -> String {
        let n = checklists.filter { $0.category?.id == cat.id }.count
        return "Used by \(n) list\(n == 1 ? "" : "s")"
    }

    private var newCategoryPill: some View {
        Button { tapAdd() } label: {
            HStack(spacing: 6) {
                GemIcons.image("plus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Theme.dim)
                Text("New category")
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

    private var newCategoryInput: some View {
        HStack {
            TextField("New category name", text: $newName)
                .foregroundColor(Theme.text)
                .onSubmit { commitAdd() }
            Button("Add") { commitAdd() }
                .buttonStyle(.plain)
                .foregroundColor(Theme.amethyst)
                .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
            Button("Cancel") {
                newName = ""
                showAddInput = false
            }
            .buttonStyle(.plain)
            .foregroundColor(Theme.dim)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Color.white.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.border, lineWidth: 1))
    }

    // MARK: - Actions

    private func tapAdd() {
        let decision = EntitlementGate.canCreateCategory(
            current: categories.count,
            limits: entitlementManager.limits
        )
        switch decision {
        case .allowed:
            showAddInput = true
        case .blocked(let reason):
            paywallReason = reason
            showPaywall = true
        }
    }

    private func commitAdd() {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        _ = try? CategoryStore.create(name: trimmed, in: ctx)
        newName = ""
        showAddInput = false
    }

    private func commitRename(_ cat: ChecklistCategory) {
        let trimmed = renamingText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty, trimmed != cat.name {
            try? CategoryStore.rename(cat, to: trimmed, in: ctx)
        }
        renamingID = nil
    }
}

// MARK: - Preview

#Preview("Categories — seeded") {
    let container = try! SeedStore.container(for: .seededMulti)
    let ent = EntitlementManager()
    return NavigationStack {
        CategoriesView()
            .environmentObject(ent)
    }
    .modelContainer(container)
}
```

- [ ] **Step 3: Write `CategoriesViewTests.swift`**

```swift
/// CategoriesViewTests.swift
/// Purpose: Tests the CategoryStore call sites CategoriesView relies on +
///   the "Used by N lists" count logic.

import XCTest
import SwiftData
@testable import Checklist

final class CategoriesViewTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Checklist.self, ChecklistCategory.self, Item.self, Tag.self,
                Run.self, Check.self, CompletedRun.self,
            configurations: makeTestConfig()
        )
        return ModelContext(container)
    }

    /// CategoryStore.create persists and assigns sortKey.
    func test_create_persists_category() throws {
        let ctx = try makeContext()
        let travel = try CategoryStore.create(name: "Travel", in: ctx)
        XCTAssertEqual(travel.name, "Travel")
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<ChecklistCategory>()).count, 1)
    }

    /// CategoryStore.rename changes the name in place.
    func test_rename_updates_name() throws {
        let ctx = try makeContext()
        let travel = try CategoryStore.create(name: "Travel", in: ctx)
        try CategoryStore.rename(travel, to: "Trips", in: ctx)
        XCTAssertEqual(travel.name, "Trips")
    }

    /// CategoryStore.delete nullifies Checklist.category.
    func test_delete_nullifies_checklist_reference() throws {
        let ctx = try makeContext()
        let travel = try CategoryStore.create(name: "Travel", in: ctx)
        let list = try ChecklistStore.create(name: "Trip", category: travel, in: ctx)
        XCTAssertNotNil(list.category)
        try CategoryStore.delete(travel, in: ctx)
        XCTAssertNil(list.category, "Cascade rule nullifies the reference")
    }

    /// Usage count: count of checklists referencing the category.
    func test_usage_count_reflects_checklist_references() throws {
        let ctx = try makeContext()
        let travel = try CategoryStore.create(name: "Travel", in: ctx)
        _ = try ChecklistStore.create(name: "Trip A", category: travel, in: ctx)
        _ = try ChecklistStore.create(name: "Trip B", category: travel, in: ctx)
        _ = try ChecklistStore.create(name: "Home", in: ctx)

        let all = try ctx.fetch(FetchDescriptor<Checklist>())
        let usage = all.filter { $0.category?.id == travel.id }.count
        XCTAssertEqual(usage, 2)
    }
}
```

- [ ] **Step 4: Don't build yet — Task 8.13 (clearAllHistory) must land first for SettingsView to compile.**

---

## Task 8.13: `RunStore.clearHistory(for:in:)` + `clearAllHistory(in:)`

**Files:**
- Modify: `Checklist/Checklist/Checklist/Store/RunStore.swift`
- Create: `Checklist/Checklist/ChecklistTests/Store/RunStore_ClearHistoryTests.swift`

- [ ] **Step 1: Write failing tests**

```swift
/// RunStore_ClearHistoryTests.swift
/// Purpose: Tests for RunStore.clearHistory(for:in:) + RunStore.clearAllHistory(in:).
///   Clear-history permanently deletes CompletedRun records but never touches
///   live Runs or source Items/Checklists.

import XCTest
import SwiftData
@testable import Checklist

final class RunStore_ClearHistoryTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Checklist.self, ChecklistCategory.self, Item.self, Tag.self,
                Run.self, Check.self, CompletedRun.self,
            configurations: makeTestConfig()
        )
        return ModelContext(container)
    }

    /// Scoped clear: only deletes CompletedRuns for the given checklist.
    func test_clearHistory_scoped_to_checklist() throws {
        let ctx = try makeContext()
        let a = try ChecklistStore.create(name: "A", in: ctx)
        let b = try ChecklistStore.create(name: "B", in: ctx)
        for _ in 0..<3 {
            let r = try RunStore.startRun(on: a, in: ctx); try RunStore.complete(r, in: ctx)
        }
        for _ in 0..<2 {
            let r = try RunStore.startRun(on: b, in: ctx); try RunStore.complete(r, in: ctx)
        }
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<CompletedRun>()).count, 5)

        try RunStore.clearHistory(for: a, in: ctx)
        let left = try ctx.fetch(FetchDescriptor<CompletedRun>())
        XCTAssertEqual(left.count, 2, "only B's runs remain")
        XCTAssertTrue(left.allSatisfy { $0.checklist?.id == b.id })
    }

    /// Clear all: wipes every CompletedRun regardless of checklist.
    func test_clearAllHistory_wipes_all_completed_runs() throws {
        let ctx = try makeContext()
        let a = try ChecklistStore.create(name: "A", in: ctx)
        let b = try ChecklistStore.create(name: "B", in: ctx)
        for _ in 0..<2 {
            let r = try RunStore.startRun(on: a, in: ctx); try RunStore.complete(r, in: ctx)
        }
        for _ in 0..<2 {
            let r = try RunStore.startRun(on: b, in: ctx); try RunStore.complete(r, in: ctx)
        }
        try RunStore.clearAllHistory(in: ctx)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<CompletedRun>()).count, 0)
    }

    /// Clear does not delete live Runs or Items.
    func test_clearHistory_leaves_live_runs_untouched() throws {
        let ctx = try makeContext()
        let a = try ChecklistStore.create(name: "A", in: ctx)
        _ = try ChecklistStore.addItem(text: "X", to: a, in: ctx)
        _ = try RunStore.startRun(on: a, in: ctx)           // live
        let r2 = try RunStore.startRun(on: a, in: ctx); try RunStore.complete(r2, in: ctx)

        XCTAssertEqual(try ctx.fetch(FetchDescriptor<CompletedRun>()).count, 1)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Run>()).count, 1)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Item>()).count, 1)

        try RunStore.clearAllHistory(in: ctx)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<CompletedRun>()).count, 0)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Run>()).count, 1, "live runs untouched")
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Item>()).count, 1, "items untouched")
    }
}
```

- [ ] **Step 2: Implement the two methods in `RunStore.swift`**

Append inside `enum RunStore { ... }`:

```swift
    // MARK: - History management (Plan 4 §3f)

    /// Permanently deletes every CompletedRun on the given checklist.
    /// Live Runs and source Items are untouched.
    ///
    /// - Parameters:
    ///   - list: The Checklist whose history to clear.
    ///   - context: The `ModelContext` to delete from and save.
    /// - Throws: If the fetch or save fails.
    static func clearHistory(for list: Checklist, in context: ModelContext) throws {
        let listID = list.id
        let runs = try context.fetch(FetchDescriptor<CompletedRun>(
            predicate: #Predicate<CompletedRun> { $0.checklist?.id == listID }
        ))
        for run in runs { context.delete(run) }
        try context.save()
    }

    /// Permanently deletes every CompletedRun on every checklist.
    ///
    /// - Parameter context: The `ModelContext` to delete from and save.
    /// - Throws: If the fetch or save fails.
    static func clearAllHistory(in context: ModelContext) throws {
        let all = try context.fetch(FetchDescriptor<CompletedRun>())
        for run in all { context.delete(run) }
        try context.save()
    }
```

- [ ] **Step 3: Run tests**

```bash
xcodebuild -project Checklist/Checklist/Checklist.xcodeproj \
  -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test -only-testing:ChecklistTests/RunStore_ClearHistoryTests 2>&1 | grep -E "passed|failed" | tail -10
```

Expected: 3 tests passing.

- [ ] **Step 4: Commit (Tasks 8.11, 8.12, 8.13 together, now that SettingsView's dependencies exist)**

```bash
git add Checklist/Checklist/Checklist/Views/SettingsRoute.swift \
        Checklist/Checklist/Checklist/Views/SettingsView.swift \
        Checklist/Checklist/Checklist/Views/CategoriesRoute.swift \
        Checklist/Checklist/Checklist/Views/CategoriesView.swift \
        Checklist/Checklist/Checklist/Store/RunStore.swift \
        Checklist/Checklist/ChecklistTests/Views/SettingsViewTests.swift \
        Checklist/Checklist/ChecklistTests/Views/CategoriesViewTests.swift \
        Checklist/Checklist/ChecklistTests/Store/RunStore_ClearHistoryTests.swift
git commit -m "feat(views,store): SettingsView + CategoriesView + RunStore.clearHistory

- SettingsView: stats row, plan card (active plan + upgrade/manage CTA),
  shortcut rows (tags / history / categories / restore), danger zone
  (clear all history with confirm).
- CategoriesView: CRUD with inline rename, usage count, + gate.
- RunStore.clearHistory(for:in:) + .clearAllHistory(in:) + 3 tests.
- Two new nav routes: SettingsDestination, CategoriesDestination."
```

---

## Task 8.14: Register new nav destinations on `HomeView` + wire `sparkle` icon to Settings

**Files:**
- Modify: `Checklist/Checklist/Checklist/Views/HomeView.swift`

- [ ] **Step 1: Register `SettingsDestination` and `CategoriesDestination` destinations**

Find the existing chain of `.navigationDestination(for:)` modifiers. Add:

```swift
            .navigationDestination(for: SettingsDestination.self) { _ in
                SettingsView(path: $path)
                    .environmentObject(entitlementManager)
                    .environmentObject(storeKit)
            }
            .navigationDestination(for: CategoriesDestination.self) { _ in
                CategoriesView()
                    .environmentObject(entitlementManager)
            }
```

And add the environment-object declarations on HomeView itself if they aren't already present:

```swift
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var storeKit: StoreKitManager
```

(These were added to HomeView in Task 8.6 for `entitlementManager`; `storeKit` may also already be present.)

- [ ] **Step 2: Wire the `sparkle` icon to push Settings**

Find the existing topBar:

```swift
            left: { IconButton(iconName: "sparkle") {} },   // sun/theme — no-op
```

Replace with:

```swift
            left: { IconButton(iconName: "sparkle") { path.append(SettingsDestination.root) } },
```

- [ ] **Step 3: Build + full test run**

```bash
xcodebuild -project Checklist/Checklist/Checklist.xcodeproj \
  -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test 2>&1 | \
  grep -E "Test Suite 'All tests'|TEST SUCCEEDED|TEST FAILED" | tail -3
```

Expected: TEST SUCCEEDED. Total ≈ 88 (baseline) + 5 FeatureLimitsTests + 5 PlanCatalogTests + 7 EntitlementGateTests + 1 SettingsViewTests + 4 CategoriesViewTests + 3 RunStore_ClearHistoryTests = **≈113 tests**.

- [ ] **Step 4: Commit**

```bash
git add Checklist/Checklist/Checklist/Views/HomeView.swift
git commit -m "feat(nav): wire sparkle icon to SettingsView, register Settings + Categories routes

HomeView registers SettingsDestination and CategoriesDestination as
navigationDestinations. sparkle (top-left) now pushes Settings. Home's
EnvironmentObjects propagate to the new screens."
```

---

## Task 8.15: Phase 8 verification pass + visual-diff notes

**Files:** none — validation only.

- [ ] **Step 1: Full test suite**

Standard test command. Expected ≈113 passing.

- [ ] **Step 2: Smoke test in simulator**

Build + install + launch. Manually tap-through:
1. Home `sparkle` → Settings renders with stats, plan card, shortcuts, danger zone
2. Settings → Upgrade → Paywall sheet renders (empty product list in sim without local StoreKit testing)
3. Home `+` with 1+ lists (free tier) → Paywall with "Unlock more checklists" headline
4. List kebab → Manage tags → Tags → `+ New tag` at 3 tags free → Paywall with tag headline
5. Settings → Categories → `+ New category` → Paywall (free has `maxCategories: 0`)

Capture each via `xcrun simctl io booted screenshot /tmp/phase-8-<n>.png` + `sips -Z 1800`.

- [ ] **Step 3: Write Phase 8 visual-diff notes**

Create `docs/superpowers/visual-diff/phase-8/README.md`:

```markdown
# Phase 8 visual-diff report — Settings + Paywall + Gate wiring

**Tests:** 113 / 113 passing.

**Captures targeted (prototype):** 28 (Settings seeded).

**Smoke-verified states:**
- [x] Home → sparkle → Settings (stats + plan card + shortcuts + danger zone)
- [x] Settings → Upgrade → PaywallSheet (generic "Unlock everything." pitch)
- [x] Home `+` gated at maxChecklists=1 free → PaywallSheet (checklist headline)
- [x] Tags `+` gated at maxTags=3 free → PaywallSheet (tag headline)
- [x] Categories `+` gated at maxCategories=0 free → PaywallSheet (category headline)
- [x] Settings → Clear all history → confirm → wipes CompletedRuns

**Acceptable deltas:** font fallbacks, native sheet chrome, icon padding.
**Unacceptable:** wrong gate triggers, paywall without feature-specific headline, clear-history touching live runs or items.
```

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/visual-diff/phase-8/
git commit -m "docs: Phase 8 visual-diff + smoke-verification report"
```

---

# Phase 9 — Polish

## Task 9.1: Deep-link fixture seeder (`checklist://seed/<fixture>`)

**Files:**
- Create: `Checklist/Checklist/Checklist/Store/FixtureRouter.swift`
- Create: `Checklist/Checklist/ChecklistTests/Store/FixtureRouterTests.swift`
- Modify: `Checklist/Checklist/Checklist/ChecklistApp.swift` — `onOpenURL` handler
- Modify: `Checklist/Checklist/Checklist/Info.plist` — register URL scheme

- [ ] **Step 1: Write `FixtureRouter.swift`**

```swift
/// FixtureRouter.swift
/// Purpose: Parses `checklist://seed/<fixture>` URLs into a SeedStore.Fixture
///   and swaps the running app's ModelContainer to the seeded fixture.
///   Used by scripts/capture_states.sh + manual QA.
/// Dependencies: Foundation, SwiftData, SeedStore.
/// Key concepts:
///   - Pure parse function returns .some(fixture) or nil for unknown / malformed.
///   - DEBUG builds only — release builds return nil regardless (guarded at call site).

import Foundation
import SwiftData

enum FixtureRouter {

    /// Parses `checklist://seed/<fixture>` into a SeedStore.Fixture.
    /// Returns nil for URLs with a different scheme, missing path, or unknown name.
    static func fixture(from url: URL) -> SeedStore.Fixture? {
        guard url.scheme == "checklist" else { return nil }
        guard url.host == "seed" else { return nil }
        let name = url.lastPathComponent
        switch name {
        case "empty":           return .empty
        case "oneList":         return .oneList
        case "seededMulti":     return .seededMulti
        case "historicalRuns":  return .historicalRuns
        case "nearCompleteRun": return .nearCompleteRun
        default:                return nil
        }
    }
}
```

- [ ] **Step 2: Write tests**

```swift
/// FixtureRouterTests.swift
/// Purpose: Unit tests for FixtureRouter URL parsing.

import XCTest
@testable import Checklist

final class FixtureRouterTests: XCTestCase {
    func test_valid_seedMulti_url_parses() {
        let url = URL(string: "checklist://seed/seededMulti")!
        XCTAssertEqual(FixtureRouter.fixture(from: url), .seededMulti)
    }

    func test_valid_empty_url_parses() {
        let url = URL(string: "checklist://seed/empty")!
        XCTAssertEqual(FixtureRouter.fixture(from: url), .empty)
    }

    func test_wrong_scheme_returns_nil() {
        let url = URL(string: "http://seed/empty")!
        XCTAssertNil(FixtureRouter.fixture(from: url))
    }

    func test_unknown_fixture_name_returns_nil() {
        let url = URL(string: "checklist://seed/notARealFixture")!
        XCTAssertNil(FixtureRouter.fixture(from: url))
    }

    func test_wrong_host_returns_nil() {
        let url = URL(string: "checklist://somethingelse/empty")!
        XCTAssertNil(FixtureRouter.fixture(from: url))
    }
}
```

- [ ] **Step 3: Wire up `onOpenURL` in `ChecklistApp.swift`**

In `AppRoot.body`, add just after the existing `.onAppear { setupModelContainer() }`:

```swift
            .onOpenURL { url in
                #if DEBUG
                if let fixture = FixtureRouter.fixture(from: url) {
                    loadFixture(fixture)
                }
                #endif
            }
```

Add the helper at the bottom of `AppRoot`:

```swift
    /// DEBUG-only: swaps the running container for a freshly-seeded one. Called
    /// when a `checklist://seed/<name>` URL is opened.
    private func loadFixture(_ fixture: SeedStore.Fixture) {
        guard let container = try? SeedStore.container(for: fixture) else { return }
        modelContainer = container
    }
```

- [ ] **Step 4: Register the URL scheme in `Info.plist`**

Read `Checklist/Checklist/Checklist/Info.plist`. Add (or merge with existing) the URL Types array:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.themostthing.Checklist.seed</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>checklist</string>
        </array>
    </dict>
</array>
```

If `Info.plist` doesn't already have `CFBundleURLTypes`, add the whole block. If it does, merge the new entry into the existing array.

- [ ] **Step 5: Build + run**

Build. Launch simulator. In a terminal:

```bash
xcrun simctl openurl booted checklist://seed/seededMulti
```

Expected: app re-renders with the `.seededMulti` fixture (multiple checklists visible). Screenshot `/tmp/phase-9-deeplink.png` to verify.

- [ ] **Step 6: Commit**

```bash
git add Checklist/Checklist/Checklist/Store/FixtureRouter.swift \
        Checklist/Checklist/Checklist/ChecklistApp.swift \
        Checklist/Checklist/Checklist/Info.plist \
        Checklist/Checklist/ChecklistTests/Store/FixtureRouterTests.swift
git commit -m "feat(dev): deep-link fixture seeder (checklist://seed/<fixture>)

DEBUG-only URL handler swaps the running ModelContainer for a named
SeedStore fixture. Enables scripted visual-diff capture by routing the
sim to any named state with one command. Five parse tests."
```

---

## Task 9.2: Motion polish (Facet + HeroGem + sheet spring)

**Files:**
- Modify: `Checklist/Checklist/Checklist/Design/Components/Facet.swift`
- Modify: `Checklist/Checklist/Checklist/Design/Components/HeroGem.swift`

- [ ] **Step 1: Tune Facet's spring to match prototype's `cubic-bezier(.2,.9,.15,1.25)` pop**

The current Facet uses `.spring(response: 0.26, dampingFraction: 0.6)`. That's close but the prototype has slightly more bounce on check. Tune to:

```swift
        .scaleEffect(checked ? 1.0 : 0.96)
        .animation(.spring(response: 0.32, dampingFraction: 0.55), value: checked)
```

(Keeps the overshoot a shade longer — matches the prototype's "satisfying snap".)

- [ ] **Step 2: Add an appear-spring to HeroGem**

At the top of `HeroGem.body`, wrap the existing ZStack with:

```swift
    @State private var appeared = false

    var body: some View {
        ZStack { ... existing ... }
            .scaleEffect(appeared ? 1 : 0.6)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: appeared)
            .onAppear { appeared = true }
    }
```

- [ ] **Step 3: Build + commit**

```bash
git add Checklist/Checklist/Checklist/Design/Components/Facet.swift \
        Checklist/Checklist/Checklist/Design/Components/HeroGem.swift
git commit -m "polish: match prototype motion curves

Facet check animation overshoots a touch longer (response 0.32 / damping
0.55). HeroGem gets an appear-spring so CompletionSheet and
CompletedRunView's status card mint in."
```

---

## Task 9.3: Inter Tight font registration (conditional)

**Files:**
- Modify: `Checklist/Checklist/Checklist/Info.plist` (conditional)
- Modify: `Checklist/Checklist/Checklist/Design/Theme.swift` (conditional)

- [ ] **Step 1: Check for font files**

```bash
ls Checklist/Checklist/Checklist/Fonts/ 2>/dev/null
```

If no `InterTight-*.ttf` files are present, skip this task. Create a reminder:

```bash
echo "Inter Tight font registration skipped — drop InterTight-Regular.ttf and InterTight-Bold.ttf into Checklist/Checklist/Checklist/Fonts/ and re-run Task 9.3." > /tmp/phase-9-font-skip.txt
cat /tmp/phase-9-font-skip.txt
```

Proceed to Task 9.4.

- [ ] **Step 2 (only if fonts exist): Register in `Info.plist`**

Add to Info.plist:

```xml
<key>UIAppFonts</key>
<array>
    <string>InterTight-Regular.ttf</string>
    <string>InterTight-Medium.ttf</string>
    <string>InterTight-SemiBold.ttf</string>
    <string>InterTight-Bold.ttf</string>
</array>
```

- [ ] **Step 3 (only if fonts exist): Update `Theme.swift`**

Replace the three font helpers:

```swift
    static func display(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .custom("InterTight-Bold", size: size)
    }

    static func body(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("InterTight-Regular", size: size)
    }

    static func eyebrow() -> Font {
        .custom("InterTight-SemiBold", size: 11)
    }
```

(If weight mapping is needed, use `.custom(name, size:).weight(weight)`.)

- [ ] **Step 4 (conditional): Build + commit**

If fonts were added:

```bash
git add Checklist/Checklist/Checklist/Fonts/ \
        Checklist/Checklist/Checklist/Info.plist \
        Checklist/Checklist/Checklist/Design/Theme.swift
git commit -m "polish: register Inter Tight via Info.plist UIAppFonts"
```

Otherwise no-op — the SF system font continues to render.

---

## Task 9.4: `scripts/capture_states.sh` — sim-driver for visual-diff

**Files:**
- Create: `scripts/capture_states.sh`

- [ ] **Step 1: Write the script**

```bash
#!/usr/bin/env bash
# capture_states.sh — Drive the simulator through each seeded fixture state
# via the checklist://seed URL scheme, screenshot each, and assemble a diff
# folder at /tmp/checklist-diff/.
#
# Prereq: Checklist.app built + installed on the booted sim, DEBUG build.
#
# Usage: scripts/capture_states.sh

set -euo pipefail

OUT=/tmp/checklist-diff
mkdir -p "$OUT"

states=(empty oneList seededMulti historicalRuns nearCompleteRun)

for s in "${states[@]}"; do
  xcrun simctl openurl booted "checklist://seed/$s"
  sleep 2
  xcrun simctl io booted screenshot "$OUT/home-$s.png"
  sips -Z 1800 "$OUT/home-$s.png" >/dev/null
  echo "captured $s"
done

echo "Screenshots saved to $OUT"
```

Save + `chmod +x scripts/capture_states.sh`.

- [ ] **Step 2: Run it, commit**

```bash
chmod +x scripts/capture_states.sh
scripts/capture_states.sh  # optional: produces /tmp/checklist-diff
git add scripts/capture_states.sh
git commit -m "tooling: capture_states.sh — sim-driver for visual-diff captures

Iterates the seeded fixture set via the checklist://seed URL handler,
screenshots each, sips to 1800px. Used by Phase 9 visual-diff passes
and regressable going forward."
```

---

## Task 9.5: Phase 9 visual-diff report

**Files:** none — validation only.

- [ ] **Step 1: Run full test suite**

Standard test command. Expected ≈118 (113 + FixtureRouterTests 5).

- [ ] **Step 2: Capture via the script**

```bash
scripts/capture_states.sh
```

- [ ] **Step 3: Write Phase 9 diff report**

Create `docs/superpowers/visual-diff/phase-9/README.md`:

```markdown
# Phase 9 visual-diff report — Polish

**Tests:** 118 / 118 passing.

**What shipped:**
- Deep-link fixture seeder (`checklist://seed/<fixture>`)
- Facet check spring tuned (response 0.32 / damping 0.55)
- HeroGem appear-spring on all presenting surfaces
- Optional Inter Tight font registration (conditional on ttf files present; otherwise SF fallback)
- `scripts/capture_states.sh` drives the sim through all five fixtures

**Captures:** `/tmp/checklist-diff/home-<fixture>.png` (5 screenshots).

**Regression class covered:** fixture-state smoke pass can now run in <1 min without manual navigation.
```

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/visual-diff/phase-9/
git commit -m "docs: Phase 9 visual-diff report (polish + fixture driver)"
```

---

# Phase 10 — Runbook

## Task 10.1: Write the manual verification runbook

**Files:**
- Create: `docs/superpowers/runbooks/phase-10-premium-cloudkit.md`

- [ ] **Step 1: Write the runbook**

```markdown
# Phase 10 — Manual Verification Runbook

Premium + CloudKit flows can only be exercised end-to-end on real hardware or
against live Apple services. This runbook documents the manual steps.

## Prerequisites

1. Paid Apple Developer account (needed for the `com.themostthing.Checklist` bundle
   ID and real StoreKit products).
2. A sandbox tester Apple ID — create at
   <https://appstoreconnect.apple.com/access/users/sandbox>.
3. A physical iPhone running iOS 17+ signed into the sandbox tester Apple ID
   (for StoreKit) **and** a second device signed into the same user's iCloud
   account (for CloudKit cross-device verification).
4. App Store Connect product SKUs `com.checklist.premium.monthly` and
   `.annual` matching `Checklist/Checklist/Products.storekit`. Set both to
   "Ready to Submit" with pricing in Tier 1 and sandbox-testable.

## Part A — StoreKit sandbox purchase

1. Install a production-signed build on the physical device:
   ```bash
   xcodebuild -project Checklist/Checklist/Checklist.xcodeproj \
     -scheme Checklist -configuration Release \
     -destination 'generic/platform=iOS' archive \
     -archivePath /tmp/Checklist.xcarchive
   ```
   Export for Ad Hoc / Development distribution via Xcode Organizer.
2. Launch the app. Confirm free plan shows on Home and Settings.
3. Home → `+` at 1 existing list → PaywallSheet appears with
   "Unlock more checklists" headline.
4. Tap "Plus · $2.99/mo". Sandbox prompts for the tester Apple ID password.
   Approve.
5. Confirm:
   - PaywallSheet dismisses automatically.
   - Settings → Plan card now reads "Checklist Plus" with "Unlimited … · iCloud on".
   - Home `+` at 1+ lists now opens CreateChecklistSheet (not the paywall).
   - Tags + / Categories + behave the same — always allowed.
6. **Restore Purchases test:** delete + reinstall the app. Sign in still as
   sandbox tester. Settings → Restore purchases → plan should resolve back to
   Plus within a few seconds.

## Part B — CloudKit cross-device sync

1. Sign **both** devices into the same iCloud account under Settings → iCloud.
2. On Device A (already Plus from Part A): create a new Checklist "Sync Test"
   with three items. Check the first item.
3. Wait 10–30 seconds. Open Checklist on Device B.
4. Expected: "Sync Test" appears in Home grid with 1/3 progress on the first
   item.
5. On Device B: check a second item, rename the list to "Sync Test ✓".
6. Wait, return to Device A. Expected: list title updates, second item shows
   checked.
7. **Cancel sync test:** downgrade Device A back to Free (sandbox can cancel
   subscription from Settings → Apple ID → Subscriptions). Confirm that the
   CloudKit container flips to `.none` within ~5s (matches
   `ChecklistApp.onChange(of: limits.cloudKitSync)`). Local data stays; no new
   changes sync.

## Part C — Edge cases

- Purchase on Device A, then open the app on Device B that's already Free.
  Settings → Restore purchases should pull the entitlement across within seconds.
- Delete a local list on one device with sync on — verify the list disappears
  on the other. (Cascade deletes all items/runs/completedRuns — confirm.)
- Toggle airplane mode on; edit a list. Toggle off; verify the edit syncs to
  the second device.

## Known gotchas

1. **CloudKit containers must match the entitlement file + App ID.** If your
   Apple Developer team ID changed, CloudKit writes fail silently. Verify via
   Console.app logs filtered on "CKRecord".
2. **The sandbox subscription period is compressed**: 1 month = 5 minutes.
   Expect renewal/expiration notifications unexpectedly.
3. **Simulator StoreKit** uses `Products.storekit` locally — sandbox does NOT
   use that file. Keep them in sync manually.
4. **iCloud Drive vs CloudKit DB**: the app uses CloudKit private DB, not iCloud
   Drive. Documents in Files.app won't show anything.

## Verification checklist

- [ ] Sandbox purchase monthly succeeds
- [ ] Sandbox purchase annual succeeds
- [ ] Plan card shows correct displayName after purchase
- [ ] Feature gates lift after purchase (Home `+`, Tags `+`, Categories `+`, AddItemInline, StartRunSheet)
- [ ] Restore purchases rehydrates on a fresh install
- [ ] CloudKit container flips to `.automatic` within seconds of `limits.cloudKitSync = true`
- [ ] Data flows Device A → Device B within 30s
- [ ] Data flows Device B → Device A within 30s
- [ ] Downgrading back to Free stops new syncs but preserves local data
- [ ] Delete cascades correctly across synced devices

Record results in `docs/superpowers/runbooks/runs/phase-10-YYYY-MM-DD.md` with
a "pass / fail / N/A" per checkbox. File any fails as a GitHub issue tagged
`phase-10-regression`.
```

- [ ] **Step 2: Commit**

```bash
mkdir -p docs/superpowers/runbooks
git add docs/superpowers/runbooks/phase-10-premium-cloudkit.md
git commit -m "docs(runbook): Phase 10 manual verification (StoreKit + CloudKit)"
```

- [ ] **Step 3: Tag Plan 4 complete**

```bash
git tag plan-4-settings-paywall-polish-complete
```

---

## Self-review checklist (run before handoff)

- [ ] `FeatureLimits` has all 7 dimensions the user listed (checklists, items, liveRuns, totalRuns, tags, categories, cloudKitSync). ✓
- [ ] `plans.json` ships with free + two paid tiers matching `Products.storekit`. ✓
- [ ] All 5 gate call sites wired (Home +, Tags +, Category +, AddItemInline, StartRunSheet). ✓
- [ ] `ChecklistApp` reads `limits.cloudKitSync`, not `isPremium`. ✓ (Task 8.3 step 3)
- [ ] `SettingsView` + `CategoriesView` + `PaywallSheet` all created. ✓
- [ ] `RunStore.clearHistory` + `clearAllHistory` with tests. ✓
- [ ] Deep-link fixture seeder. ✓
- [ ] Phase 10 runbook created. ✓
- [ ] Every test has real assertions. ✓
- [ ] No placeholders ("TBD", "later", etc.). ✓
- [ ] Tag consistency across tasks: `SettingsDestination.root`, `CategoriesDestination.root`, `HistoryScope.allLists`, `TagsDestination.root`. ✓

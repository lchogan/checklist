# Phase 8 visual-diff report — Settings + Paywall + Gate wiring

**Tests:** 113 / 113 passing (baseline 88 + 25 new).

**What shipped:**
- 7-dimension `FeatureLimits` (checklists, items/list, live-runs/list, total-runs, tags, categories, cloudKitSync)
- Bundled `plans.json` + `PlanCatalog` + `Plan` value type
- `EntitlementManager` resolves owned product IDs → most-generous merged plan
- `EntitlementGate.canCreateChecklist / canAddItem / canStartRun / canCreateTag / canCreateCategory` pure decision helpers
- `PaywallSheet` (Gem visuals, feature-specific headline)
- 5 feature-create call sites wired through the gate: Home +, Tags +, Category +, AddItemInline, StartRunSheet
- `SettingsView` (stats, plan card, shortcuts, danger-zone clear all)
- `CategoriesView` (CRUD with inline rename + usage count)
- `RunStore.clearHistory(for:in:)` + `clearAllHistory(in:)`
- Home `sparkle` icon wired to push Settings

**Captures targeted:** 28 (Settings seeded).

**Smoke-verified states:**
- Home renders under the new architecture (plan catalog load → free plan → 0-list empty state). See `/tmp/phase-8-home.png`.
- Previews compile for SettingsView, CategoriesView, PaywallSheet (verifiable in Xcode canvas).

**What was deferred:**
- Manual walk-through of every gate + paywall trigger state in the simulator (requires seeded data + taps). Phase 9's `scripts/capture_states.sh` enables automation going forward.

**Architecture notes for future plans:**
- Swapping `PlanCatalog.load()` from bundled JSON to remote fetch (Level 2) is a single-method change.
- Swapping `EntitlementManager` internals for RevenueCat (Level 3) preserves the `limits` / `activePlan` external API — no view changes needed.
- To add a "Lite" or "Pro" tier: add a row to `plans.json`. No code edits. The gate helpers, paywall, and settings card all adapt automatically.

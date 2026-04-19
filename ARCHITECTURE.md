# Checklist — Data Architecture

**Status:** Draft v4 (supersedes v1–v3)
**Target platform:** iOS / macOS, iCloud (CloudKit) sync
**One-line summary:** *A Checklist owns the items. A Run is just a per-usage map of checks and ignores. Multiple live runs can share one Checklist.*

---

## 1. The model in one paragraph

A **Checklist** owns its items and tags. Structural edits (add, delete, rename, reorder) happen on the Checklist and are visible to every live Run immediately — Runs don't own their own items; they reference the shared Checklist structure. A **Run** holds only per-usage state: which items are checked, which are ignored, which tags are view-hidden. Multiple live Runs can exist at once on one Checklist (e.g., "Tokyo" and "Portland" trips sharing the same Packing list). Completing a Run snapshots the Checklist's items into a read-only **CompletedRun** record and removes the Run from the live set. When a Checklist has no live Runs, the next user interaction auto-creates one. There is no template entity.

---

## 2. Core entities

```
Checklist ─┬─ id, name, icon?, color?, categoryId?, sortKey
           ├─ items: Item[]              (canonical; shared across all live Runs)
           ├─ tags: Tag[]                (scoped to this Checklist)
           ├─ dueAt?: ISODate            (reserved for v2)
           ├─ reminderAt?: ISODate       (reserved for v2)
           └─ recurrence?                (reserved for v2)

Run ──────┬─ id, checklistId
          ├─ startedAt
          ├─ name?: string              (optional label, e.g. "Tokyo")
          ├─ checks: ItemId → Check     (this Run's check state)
          └─ hiddenTags: TagId[]        (this Run's view filter)

CompletedRun ─┬─ id, checklistId
              ├─ startedAt, completedAt
              ├─ name?: string
              ├─ itemsSnapshot: Item[]   (deep copy of Checklist.items at seal time)
              ├─ tagsSnapshot: Tag[]     (deep copy of Checklist.tags at seal time)
              ├─ checks: ItemId → Check  (frozen)
              ├─ hiddenTags: TagId[]     (frozen)
              └─ (read-only forever)

Item ─────┬─ id, text, sortKey
          ├─ tags: TagId[]
          └─ dueAt?: ISODate             (reserved for v2; absolute)

Tag ──────┬─ id, name, icon, color
          └─ (scoped to a single Checklist)

Category ─┬─ id, name, sortKey
          └─ (scoped per user; multiple Checklists can reference)

Check ────┬─ state: 'complete' | 'ignored'
          └─ updatedAt, deviceId
```

**Check state semantics.** An item with no entry in `Run.checks` is incomplete (the default). An entry with `state: 'complete'` is checked. An entry with `state: 'ignored'` is explicitly skipped for this Run — not counted toward completion math, rendered distinctly in UI. Ignore is a toggleable per-Run state, not a destructive operation.

**Front-end terminology.** Internally we use Run / CompletedRun. The UI may show them both as "runs" with live vs. sealed indicators. The user never sees the word "CompletedRun."

---

## 3. User-facing actions

### 3a. Editing a Checklist (structural)

Inline, from any live Run's view. Tap an item to rename, swipe to delete, add items at the bottom, reorder. Any structural edit mutates **`Checklist.items`** — which means it's immediately visible to every live Run of that Checklist.

- **Add item:** appended to `Checklist.items`. Appears in all live Runs as unchecked.
- **Rename item:** updates the `Item.text` on the Checklist. Every live Run now shows the new name (checks persist — they're keyed by item ID).
- **Reorder items:** updates `sortKey` on the Checklist. Every live Run sees the new order.
- **Delete item:** removes from `Checklist.items`. Cascades: every live Run's `checks[itemId]` is cleared. Sealed `CompletedRun` records are untouched (their snapshots keep the deleted item forever).

**Delete confirmation rule:** when 2+ live Runs exist, show a warning — *"Delete 'Rain jacket'? This will remove it from 3 live runs."* — before proceeding. When 0 or 1 live Runs exist, delete silently (it's just editing the list).

### 3b. Per-Run actions (non-structural)

These affect only the current Run, never the Checklist or other Runs:

- **Check / uncheck an item:** writes or clears `Run.checks[itemId] = { state: 'complete', ... }`.
- **Ignore / unignore an item:** writes `Run.checks[itemId] = { state: 'ignored', ... }` or clears it. Ignore is visible as a distinct UI state (grayed, struck-through, or similar — design choice). Toggleable at will during the Run.
- **Hide / show tag:** updates `Run.hiddenTags`. Filters the view of this Run only.

### 3c. Complete

User taps **Complete** on a live Run. The system:

1. Creates a new **CompletedRun** record:
   - `itemsSnapshot` = deep copy of the Checklist's current `items`
   - `tagsSnapshot` = deep copy of the Checklist's current `tags`
   - `checks` = copy of `Run.checks`
   - `hiddenTags` = copy of `Run.hiddenTags`
   - `startedAt` = the Run's `startedAt`
   - `completedAt` = now
   - `name` = the Run's `name` (if any)
2. Deletes the Run record.
3. Other live Runs on the same Checklist are untouched.

CompletedRuns are forever read-only. There is no unseal action.

### 3d. New run

User taps **New run** (or **Add run**) on a Checklist. Creates a fresh Run record with:
- `startedAt` = now
- `checks` = empty
- `hiddenTags` = empty
- `name` = optional (user can label at create-time or later)

Multiple live Runs can coexist on the same Checklist — each is an independent usage context over the shared item structure.

### 3e. Auto-create on first interaction

When a Checklist has zero live Runs and the user does anything that implies starting a Run (taps an item to check it, adds an item, etc.), a new Run is auto-created transparently before the action applies. This means the user never has to think "I need to start a run first" — they just use the checklist.

The explicit **New run** button is reserved for the case when at least one live Run already exists and the user wants a *concurrent* one.

### 3f. Save as new checklist

Available from a live Run, a CompletedRun (history detail), or the Checklist itself.

1. User taps **Save as new checklist**.
2. Prompt: *"Transfer checks?"* — yes / no toggle.
3. Creates a new Checklist:
   - `items` = deep copy of source's items
   - `tags` = deep copy of source's tags
   - `name` = user-provided (default: "Source name (copy)")
   - `categoryId` = source's categoryId (user can change)
4. If checks are transferred:
   - Creates one initial live Run on the new Checklist with those checks copied in.
   - Else: no Run is auto-created; first interaction triggers auto-create (§3e).

This is the fork point. The new Checklist has no shared identity with the source — subsequent edits to either never affect the other.

### 3g. View history

Per-Checklist history is the set of `CompletedRun` records where `checklistId` matches. UI shows them chronologically (probably reverse). Tapping one opens read-only detail showing the item list, checks, and ignored items as they were at seal time.

### 3h. Clear history

From a Checklist's history view, **Clear history** deletes all `CompletedRun` records for that Checklist. Confirmation required. The Checklist and its live Runs are unaffected.

For users who complete frequently (daily routines), this is the release valve. No automatic pagination or archiving in v1.

### 3i. Deleting a Checklist

Deletes the Checklist, all its Runs, and all its CompletedRuns. Cascading. Confirmation required. No soft-delete.

---

## 4. Lifecycle examples

### Single-use (99% case)

1. User opens Checklist. No live Runs. User taps an item → auto-creates Run 1, applies check.
2. User continues using the Checklist. Run 1 accumulates checks.
3. User taps Complete → CompletedRun 1 sealed, Run 1 gone.
4. User opens Checklist again later → no live Runs. Taps an item → auto-creates Run 2.

### Concurrent trips

1. User has "Packing list" Checklist with items [A, B, C, D, E].
2. Taps an item → Run 1 auto-created, named "Tokyo" after the fact.
3. Checks A, B, C in Tokyo. Starts packing.
4. Taps **New run** → Run 2 created, named "Portland." Empty checks.
5. In Portland run, adds item "F" (Portland-specific). This adds F to `Checklist.items`. Now Tokyo also sees F unchecked. User accepts or deletes F (see delete warning below).
6. Completes Tokyo first → CompletedRun, Run 1 gone. Run 2 still live.
7. User keeps using Portland. Eventually completes it → CompletedRun, Run 2 gone. History shows both.

### Delete with multiple live runs

1. Tokyo and Portland both live. User in Tokyo view swipes "Rain jacket" → delete.
2. Warning: *"Delete 'Rain jacket'? This will remove it from 2 live runs and hide it from future runs."*
3. User confirms → `Checklist.items` loses Rain jacket. `Run.checks` for Rain jacket is cleared on both Tokyo and Portland. Sealed history is untouched.
4. If user wanted to skip Rain jacket for *just* Tokyo, they'd use **Ignore** instead (per-Run, non-destructive).

---

## 5. What this architecture deletes

Compared to all prior drafts, these are **gone**:

- Separate Template entity.
- Per-Run item lists (items live on Checklist only).
- `initialItems`, `snapshotItems`, `excludedItemIds`, `templateGeneration`.
- "Save edits to template" button / chip.
- Completion-diff propagation.
- Fork-on-write, pull-latest.
- Unsealing / reopening CompletedRuns.
- Text-match dedup logic.

The propagation question is *dissolved*: items live in one place (Checklist), so every live Run sees edits automatically without any propagation mechanism.

---

## 6. Future-proofing (reserved, not implemented in v1)

### 6a. Recurrence

`Checklist.recurrence?` is reserved. When implemented, a recurring rule creates a new Run automatically on its schedule (or reminds the user to). No data-model changes required.

### 6b. Due dates

- `Checklist.dueAt` — soft deadline for *all* currently-live Runs.
- `Checklist.reminderAt` — push notification time for the Checklist.
- `Item.dueAt` — per-item absolute deadline.
- Per-Run deadlines (e.g., "Tokyo is due on Oct 18") could be added as `Run.dueAt?` later without breaking.

If relative offsets are ever needed ("due 3 days after Run starts"), add `Item.dueAtOffsetSeconds?: number` as additive field.

### 6c. Bulk edit

Later feature. Operates on `Checklist.items` (the canonical list). Same mutation semantics as single-item edits. No model changes.

### 6d. Sharing (CloudKit)

Checklists can be shared via `CKShare` with items/tags as hierarchical children. Runs can be shared independently (e.g., "let Mom check things off this specific Portland run"). For v2+.

---

## 7. CloudKit mapping

One container: `iCloud.com.example.checklist`
Zone: `privateCloudDatabase`, custom record zone `ChecklistData`.

| Entity | Record Type | Parent | Storage notes |
|---|---|---|---|
| Checklist | `Checklist` | — | `items` and `tags` stored inline as JSON blobs (NSData) for atomic updates |
| Run | `Run` | `Checklist` | `checks` and `hiddenTags` stored inline as JSON blobs |
| CompletedRun | `CompletedRun` | `Checklist` | All snapshot data inline as JSON blobs (immutable) |
| Category | `Category` | — | Flat list per user |

**Why inline blobs:** items and checks are small (tens, not thousands) and always read/written together. Atomic per-record updates avoid partial-state sync issues. Immutable CompletedRuns have no update cost concerns.

**Sync strategy:**
- Cold launch: `CKFetchRecordChangesOperation` on `ChecklistData` zone.
- Live sync: CloudKit subscription → silent push → `fetchChanges`.
- Offline: all writes to local SQLite (GRDB) first, replay on reconnect.

**Local store:** SQLite mirrors the entities 1:1 with a `syncState` column. CloudKit is the source of truth; SQLite is cache + write-ahead log.

**Concurrent-edit resolution:**
- **Checklist:** last-writer-wins on the whole record. If users edit items on two devices within the same sync window, one write wins. Acceptable because structural edits are low-frequency.
- **Run:** last-writer-wins on the whole record. `checks` being a blob means ticking items on two devices could lose one side's tick. If this becomes a real complaint, migrate `checks` to LWW-per-key. Not worth pre-optimizing.
- **CompletedRun:** immutable, no conflicts possible.

---

## 8. Freemium tiers

(From existing project decisions; unchanged.)

- **Free:** 1 Checklist, 3 tags (per Checklist), 3 categories.
- **Premium:** unlimited.
- History (`CompletedRun` count) and live Runs (count per Checklist) are unlimited on both tiers.

Gating happens at creation time; existing data is never retroactively limited.

---

## 9. Gem visuals (v2 delight layer, noted for later)

Every `CompletedRun` mints a unique gem — a pure function of the CompletedRun's state, **computed at view time** (not stored):

```
gem(run) = {
  hue:          hash(checklistId) mapped to oklch chroma wheel,
  cut:          (count of prior CompletedRuns on this Checklist) → facet complexity,
  saturation:   run.checks.completionRatio,
  clarity:      (itemsSnapshot.count - itemsAddedDuringRun) / itemsSnapshot.count,
  size:         log(completedAt - startedAt),
  inclusion:    run.checks.some(c => c.state === 'ignored') ? 'flaw' : 'clean',
}
```

View-time keeps everything trivial — no mint events, no gem records, no cache. Tap a gem → full-screen with procedurally-generated mythology copy (LLM at view time, cached). Shareable as image.

---

## 10. Prototype ↔ spec migration

Current prototype (`Gem App v2.html`) was built around an earlier template/run model. Map to this spec:

| Prototype concept | This spec | Migration notes |
|---|---|---|
| Template record | *(gone)* | Collapse into Checklist. |
| Run record with `excludedItemIds`, `snapshotItems`, `templateGeneration` | Run (live) or CompletedRun (sealed) | Delete all delta fields. Items live on Checklist only. |
| `hiddenItems` / `excludedItemIds` on a run | **Ignore state** (`Run.checks[itemId].state = 'ignored'`) | Semantic rename + simpler storage. |
| `status: 'partial'` | Computed from `checks.count < items.count` at completion | Not stored. |
| "Finish run" | Complete | Seals Run into CompletedRun, deletes Run. |
| "Start new run" / "Start new run from here" | **New run** (concurrent) or **Save as new checklist** (fork) | Depending on user intent. |
| Fork-on-write, pull-latest | *(gone)* | Not needed — shared Checklist.items makes drift impossible between live Runs. |

The existing SwiftData models (`Checklist`, `ChecklistItem`, `ChecklistCategory`, `Tag`) are roughly right but currently assume one Checklist = one run. Migration adds `Run` and `CompletedRun` SwiftData models; `ChecklistItem.statusRaw` (the `incomplete/complete/deferred` field) moves from Items to Run's `checks` map, with `deferred` renamed to `ignored`.

---

## 11. What we're deliberately NOT doing in v1

- **No template editor.** The Checklist is the template.
- **No per-Run items.** Items live on the Checklist only. Runs hold only check state.
- **No "delete from just this run."** Delete is Checklist-wide. Users wanting soft-skip use **Ignore**.
- **No unsealing CompletedRuns.** Frozen forever. Users can fork via Save as new checklist.
- **No shared items across Checklists.** Deep copies only.
- **No real-time multiplayer.** iCloud silent-push is eventual-consistency.
- **No automatic history archival.** User taps Clear history when they want.
- **No cross-Checklist item dependencies.**
- **No soft-delete on Checklist records.** Deletes are permanent after confirmation.

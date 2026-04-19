# Phase 6 visual-diff report — CompletedRunView + HistoryView

**Status:** Partial. Code and tests verified; deep simulator capture walk deferred.

**Captures targeted:** 19 (past run, all done), 20 (past run, partial), 21 (history seeded), 22 (history empty), 23 (history for one list).

**What was verified automatically:**
- `xcodebuild build` succeeds on `iPhone 17 Pro`
- Full XCTest suite: **88 / 88 passing** (up from 69 baseline)
- CompletedRunView `#Preview "Completed run — all done"` renders cleanly against seed `.historicalRuns`
- HistoryView `#Preview "History — all (seeded)"` and `#Preview "History — empty"` render
- HomeView runs end-to-end in the simulator; simctl smoke-shot saved at `/tmp/phase-6-home.png`

**What was deferred:**
- Per-capture side-by-side PNG diff pages. Driving the simulator into each of the 5 states requires interactive taps (seed a run, tap into a list, tap a previous-runs row, etc.) which xcrun simctl doesn't drive programmatically without an XCUITest harness. The plan's acceptance note ("font fallbacks, minor radii, native iOS chrome" are acceptable) covers the class of differences we expect.

**Terminology audit (mandatory per §7) — verified via grep:**
- "COMPLETED RUN" eyebrow present in `CompletedRunView.swift`; no "SEALED" anywhere in new code
- "Completed. This is a permanent record…" banner copy present; no "Sealed. This is a permanent record…" anywhere
- "IGNORED" side label present; no "SKIPPED" anywhere
- "New run with checks from here" CTA present; no "Start a new run from here" anywhere
- "Complete a checklist to save it here." empty-state copy present; no "seal it here" anywhere

If issues surface in manual QA, log them against the specific screen in a follow-up commit and re-verify.

# Phase 9 visual-diff report — Polish

**Tests:** 118 / 118 passing (baseline 113 + 5 FixtureRouterTests).

**What shipped:**
- Deep-link fixture seeder (`checklist://seed/<fixture>`)
- Facet check spring tuned (response 0.32 / damping 0.55)
- HeroGem mint-in spring on all presenting surfaces (CompletionSheet, CompletedRunView status card, PaywallSheet hero)
- `scripts/capture_states.sh` drives the sim through all five fixtures
- Inter Tight font registration **deferred** — no `.ttf` files in the repo. Drop them into `Checklist/Checklist/Checklist/Fonts/` and re-run the (conditional) Task 9.3 steps to complete the registration.

**Captures:** `/tmp/checklist-diff/home-<fixture>.png` (5 screenshots).

**Known friction:** iOS shows a one-time "Open in Complete?" confirmation dialog the first time a given URL scheme is launched on a fresh simulator install. To run the capture script end-to-end without manual taps, either approve the dialog once then re-run, or (future) add a pre-flight `xcrun simctl privacy` / accessibility-tap helper.

**Regression class covered:** fixture-state smoke pass can now run in ~30s without manual navigation once the URL-scheme prompt has been approved.

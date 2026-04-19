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

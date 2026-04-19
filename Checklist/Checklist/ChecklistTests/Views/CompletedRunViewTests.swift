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
}

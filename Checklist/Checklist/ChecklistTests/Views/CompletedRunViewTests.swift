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

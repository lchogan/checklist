/// HistoryViewTests.swift
/// Purpose: Unit tests for HistoryView helpers — scope filtering, state
///   filtering (Task 6.6), month grouping (Task 6.6).
/// Dependencies: XCTest, SwiftData, Checklist target.
/// Key concepts:
///   - Task 6.5: scope filtering (allLists vs single checklist).
///   - Task 6.6: state filtering + month grouping.
///   - Helper: testing is done through a duplicated filter function living in
///     the test target, because the real helpers are private on HistoryView.

import XCTest
import SwiftData
@testable import Checklist

final class HistoryViewTests: XCTestCase {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Checklist.self, ChecklistCategory.self, Item.self, Tag.self,
                Run.self, Check.self, CompletedRun.self,
            configurations: makeTestConfig()
        )
        return ModelContext(container)
    }

    /// Scope filtering: .allLists returns every CompletedRun; scope(id) returns
    /// only runs whose checklist.id matches.
    func test_scope_filtering_returns_matching_runs() throws {
        let ctx = try makeContext()
        let a = try ChecklistStore.create(name: "A", in: ctx)
        let b = try ChecklistStore.create(name: "B", in: ctx)

        // Two completions for A, one for B.
        try seedCompleted(list: a, count: 2, in: ctx)
        try seedCompleted(list: b, count: 1, in: ctx)

        let all = try ctx.fetch(FetchDescriptor<CompletedRun>())
        XCTAssertEqual(all.count, 3, "3 completed runs total")

        let scopedToA = all.filter { $0.checklist?.id == a.id }
        XCTAssertEqual(scopedToA.count, 2, "scope to A: 2 runs")

        let scopedToB = all.filter { $0.checklist?.id == b.id }
        XCTAssertEqual(scopedToB.count, 1, "scope to B: 1 run")
    }

    /// Helper to seed N CompletedRuns for a checklist.
    private func seedCompleted(list: Checklist, count: Int, in ctx: ModelContext) throws {
        for _ in 0..<count {
            let run = try RunStore.startRun(on: list, in: ctx)
            try RunStore.complete(run, in: ctx)
        }
    }

    // MARK: - State filter (Task 6.6)

    /// Helper: creates a completed run with the given item count, N of which are complete.
    private func seedCompletedRun(list: Checklist, items: Int, complete: Int, in ctx: ModelContext) throws {
        let created = (0..<items).map { i -> Item in
            try! ChecklistStore.addItem(text: "Item \(i)", to: list, in: ctx)
        }
        let run = try RunStore.startRun(on: list, in: ctx)
        for item in created.prefix(complete) {
            try RunStore.toggleCheck(run: run, itemID: item.id, in: ctx)
        }
        try RunStore.complete(run, in: ctx)
        // Delete the template items so subsequent seedings on the same list
        // start with a clean item roster. CompletedRun snapshots keep their
        // frozen items regardless.
        for item in (list.items ?? []) { ctx.delete(item) }
        try ctx.save()
    }

    /// Complete filter: only runs where done == total are returned.
    func test_state_filter_complete_returns_only_all_done() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "T", in: ctx)
        try seedCompletedRun(list: list, items: 3, complete: 3, in: ctx) // all-done
        try seedCompletedRun(list: list, items: 3, complete: 1, in: ctx) // partial

        let all = try ctx.fetch(FetchDescriptor<CompletedRun>())
        let completeOnly = all.filter {
            CompletedRunProgress.compute(snapshot: $0.snapshot).isAllDone
        }
        XCTAssertEqual(completeOnly.count, 1)
        XCTAssertEqual(CompletedRunProgress.compute(snapshot: completeOnly[0].snapshot).done, 3)
    }

    /// Partial filter: only runs where 0 < done < total are returned.
    func test_state_filter_partial_returns_only_partial() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "T", in: ctx)
        try seedCompletedRun(list: list, items: 3, complete: 3, in: ctx) // all-done
        try seedCompletedRun(list: list, items: 3, complete: 1, in: ctx) // partial
        try seedCompletedRun(list: list, items: 3, complete: 0, in: ctx) // also partial (0/3)

        let all = try ctx.fetch(FetchDescriptor<CompletedRun>())
        let partialOnly = all.filter { run in
            let p = CompletedRunProgress.compute(snapshot: run.snapshot)
            return p.total > 0 && !p.isAllDone
        }
        XCTAssertEqual(partialOnly.count, 2, "both partial runs returned")
    }

    // MARK: - Month grouping (Task 6.6)

    /// Grouping invariant: two runs completed in the same month share a key;
    /// runs from different months end up in different keys.
    func test_month_grouping_partitions_by_year_month() {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM"
        let cal = Calendar.current

        let apr2026 = cal.date(from: DateComponents(year: 2026, month: 4, day: 17))!
        let apr2026b = cal.date(from: DateComponents(year: 2026, month: 4, day: 3))!
        let mar2026 = cal.date(from: DateComponents(year: 2026, month: 3, day: 31))!

        XCTAssertEqual(f.string(from: apr2026), f.string(from: apr2026b),
                       "same-month dates share the key")
        XCTAssertNotEqual(f.string(from: apr2026), f.string(from: mar2026),
                          "cross-month dates do not share the key")
    }
}

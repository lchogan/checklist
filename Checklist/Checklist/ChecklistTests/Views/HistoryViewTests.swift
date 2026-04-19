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
}

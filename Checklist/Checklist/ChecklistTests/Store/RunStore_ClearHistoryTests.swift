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

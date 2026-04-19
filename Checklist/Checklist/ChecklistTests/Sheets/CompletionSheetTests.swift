/// CompletionSheetTests.swift
/// Purpose: Verifies the data-level behavior CompletionSheet relies on:
///   RunProgress "all done" detection, and that RunStore.complete/discard
///   both clear the Run (with or without a CompletedRun history record).
/// Dependencies: XCTest, SwiftData, Checklist (testable), ChecklistStore,
///   RunStore, RunProgress, TestHelpers.makeTestConfig.

import XCTest
import SwiftData
@testable import Checklist

/// Verifies the data-level behavior CompletionSheet relies on: RunProgress
/// "all done" detection, and that RunStore.complete/discard both clear the
/// Run.
final class CompletionSheetTests: XCTestCase {

    /// Returns an in-memory ModelContext with all required model types registered.
    ///
    /// - Returns: A fresh `ModelContext` backed by an in-memory store.
    /// - Throws: If the ModelContainer cannot be created.
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Checklist.self, ChecklistCategory.self, Item.self, Tag.self,
                Run.self, Check.self, CompletedRun.self,
            configurations: makeTestConfig()
        )
        return ModelContext(container)
    }

    /// RunProgress reports done == total when every visible item has a complete Check.
    func test_all_done_detection_all_visible_items_complete() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "T", in: ctx)
        let a = try ChecklistStore.addItem(text: "A", to: list, in: ctx)
        let b = try ChecklistStore.addItem(text: "B", to: list, in: ctx)
        let run = try RunStore.startRun(on: list, in: ctx)
        try RunStore.toggleCheck(run: run, itemID: a.id, in: ctx)
        try RunStore.toggleCheck(run: run, itemID: b.id, in: ctx)

        let progress = RunProgress.compute(
            items: list.items ?? [],
            checks: run.checks ?? [],
            hiddenTagIDs: run.hiddenTagIDs
        )
        XCTAssertEqual(progress.done, 2)
        XCTAssertEqual(progress.total, 2)
    }

    /// RunStore.complete creates a CompletedRun snapshot and removes the live Run.
    func test_complete_creates_CompletedRun_and_removes_live_run() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "T", in: ctx)
        _ = try ChecklistStore.addItem(text: "A", to: list, in: ctx)
        let run = try RunStore.startRun(on: list, name: "Tokyo", in: ctx)

        try RunStore.complete(run, in: ctx)

        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Run>()).count, 0)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<CompletedRun>()).count, 1)
    }

    /// RunStore.discard removes the Run without creating a CompletedRun in history.
    func test_discard_destroys_run_without_history() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "T", in: ctx)
        let run = try RunStore.startRun(on: list, in: ctx)

        try RunStore.discard(run, in: ctx)

        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Run>()).count, 0)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<CompletedRun>()).count, 0)
    }
}

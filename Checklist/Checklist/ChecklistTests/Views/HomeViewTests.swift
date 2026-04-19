/// HomeViewTests.swift
/// Purpose: Unit tests for HomeView helpers — specifically the RunProgress
///   computation used by the cards grid.
/// Dependencies: XCTest, SwiftData, Checklist (testable import), TestHelpers.
/// Key concepts: All tests use makeTestConfig() to disable CloudKit in-memory containers.

import XCTest
import SwiftData
@testable import Checklist

final class HomeViewTests: XCTestCase {
    /// Creates an isolated in-memory ModelContext for test isolation.
    ///
    /// - Returns: A fresh `ModelContext` backed by an in-memory container.
    /// - Throws: If the container cannot be created.
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Checklist.self, ChecklistCategory.self, Item.self, Tag.self,
                Run.self, Check.self, CompletedRun.self,
            configurations: makeTestConfig()
        )
        return ModelContext(container)
    }

    /// RunProgress with no runs returns total equal to item count and done = 0.
    func test_runProgress_with_no_runs_returns_total_eq_items() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "T", in: ctx)
        _ = try ChecklistStore.addItem(text: "A", to: list, in: ctx)
        _ = try ChecklistStore.addItem(text: "B", to: list, in: ctx)

        let progress = RunProgress.compute(items: list.items ?? [], checks: [], hiddenTagIDs: [])
        XCTAssertEqual(progress.done, 0)
        XCTAssertEqual(progress.total, 2)
    }

    /// Ignored items are excluded from both the numerator and denominator.
    func test_runProgress_ignored_items_excluded_from_both() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "T", in: ctx)
        let a = try ChecklistStore.addItem(text: "A", to: list, in: ctx)
        let b = try ChecklistStore.addItem(text: "B", to: list, in: ctx)
        let c = try ChecklistStore.addItem(text: "C", to: list, in: ctx)

        let run = try RunStore.startRun(on: list, in: ctx)
        try RunStore.toggleCheck(run: run, itemID: a.id, in: ctx)
        try RunStore.setIgnored(run: run, itemID: b.id, to: true, in: ctx)
        _ = c

        let progress = RunProgress.compute(
            items: list.items ?? [],
            checks: run.checks ?? [],
            hiddenTagIDs: run.hiddenTagIDs
        )
        XCTAssertEqual(progress.done, 1, "only A complete")
        XCTAssertEqual(progress.total, 2, "B ignored, excluded; total = A + C")
    }

    /// Items whose every tag is hidden are excluded from total and done.
    func test_runProgress_hidden_tag_filters_items_whose_all_tags_hidden() throws {
        let ctx = try makeContext()
        let beach = try TagStore.create(name: "Beach", in: ctx)
        let list = try ChecklistStore.create(name: "T", in: ctx)
        _ = try ChecklistStore.addItem(text: "Untagged", to: list, in: ctx)
        _ = try ChecklistStore.addItem(text: "BeachOnly", to: list, tags: [beach], in: ctx)

        let run = try RunStore.startRun(on: list, in: ctx)
        try RunStore.toggleHideTag(run: run, tagID: beach.id, in: ctx)

        let progress = RunProgress.compute(
            items: list.items ?? [],
            checks: run.checks ?? [],
            hiddenTagIDs: run.hiddenTagIDs
        )
        XCTAssertEqual(progress.total, 1, "BeachOnly hidden, Untagged visible")
    }
}

/// ChecklistStoreTests.swift
/// Purpose: Unit tests for ChecklistStore CRUD operations and delete cascade behaviour.
/// Dependencies: XCTest, SwiftData, Checklist (testable), TestHelpers.makeTestConfig().
/// Key concepts:
///   - Each test gets its own in-memory ModelContext so tests are fully isolated.
///   - CloudKit must be disabled via makeTestConfig() to avoid loadIssueModelContainer.

import XCTest
import SwiftData
@testable import Checklist

final class ChecklistStoreTests: XCTestCase {

    // MARK: - Helpers

    /// Returns an isolated in-memory ModelContext with all v4 models registered.
    ///
    /// - Returns: A fresh `ModelContext` backed by an in-memory store.
    /// - Throws: If `ModelContainer` fails to initialise (e.g. schema mismatch).
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Checklist.self, ChecklistCategory.self, Item.self, Tag.self,
                Run.self, Check.self, CompletedRun.self,
            configurations: makeTestConfig()
        )
        return ModelContext(container)
    }

    // MARK: - Tests

    /// Creating a checklist persists exactly one record with the given name.
    func test_create_returns_persisted_checklist() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "Daily", in: ctx)
        XCTAssertEqual(list.name, "Daily")
        let fetched = try ctx.fetch(FetchDescriptor<Checklist>())
        XCTAssertEqual(fetched.count, 1)
    }

    /// Items added sequentially get monotonically incrementing sortKeys starting at 0.
    func test_addItem_appends_with_incrementing_sortKey() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "Trip", in: ctx)
        let a = try ChecklistStore.addItem(text: "Passport", to: list, in: ctx)
        let b = try ChecklistStore.addItem(text: "Toothbrush", to: list, in: ctx)
        XCTAssertEqual(a.sortKey, 0)
        XCTAssertEqual(b.sortKey, 1)
        XCTAssertEqual(list.items?.count, 2)
    }

    /// Deleting an item removes all Check records referencing that item's ID
    /// across every live Run on the same checklist.
    func test_deleteItem_clears_matching_checks_across_all_live_runs() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "Trip", in: ctx)
        let item = try ChecklistStore.addItem(text: "Passport", to: list, in: ctx)

        // Create 2 live runs, both with a check on this item.
        let run1 = Run(checklist: list, name: "Tokyo")
        let check1 = Check(itemID: item.id)
        check1.run = run1
        ctx.insert(run1)
        ctx.insert(check1)

        let run2 = Run(checklist: list, name: "Lisbon")
        let check2 = Check(itemID: item.id)
        check2.run = run2
        ctx.insert(run2)
        ctx.insert(check2)

        try ctx.save()

        try ChecklistStore.deleteItem(item, in: ctx)

        let fetchedChecks = try ctx.fetch(FetchDescriptor<Check>())
        XCTAssertTrue(
            fetchedChecks.isEmpty,
            "deleting item should clear its checks in all live runs"
        )
    }

    /// Deleting a checklist cascade-deletes its items.
    func test_deleteChecklist_cascades() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "Trip", in: ctx)
        _ = try ChecklistStore.addItem(text: "A", to: list, in: ctx)
        try ctx.save()

        try ChecklistStore.delete(list, in: ctx)

        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Checklist>()).count, 0)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Item>()).count, 0)
    }

    /// liveRunCount returns the number of active Run records on the checklist.
    func test_liveRunCount() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "Trip", in: ctx)
        ctx.insert(Run(checklist: list, name: "One"))
        ctx.insert(Run(checklist: list, name: "Two"))
        try ctx.save()
        XCTAssertEqual(ChecklistStore.liveRunCount(for: list), 2)
    }
}

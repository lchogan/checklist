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
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Item>()).count, 0)
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

    /// Reordering items assigns sequential sortKeys matching the supplied order.
    func test_reorderItems_assigns_sequential_sortKeys() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "Trip", in: ctx)
        let a = try ChecklistStore.addItem(text: "A", to: list, in: ctx)
        let b = try ChecklistStore.addItem(text: "B", to: list, in: ctx)
        let c = try ChecklistStore.addItem(text: "C", to: list, in: ctx)

        // Reorder to [C, A, B]
        try ChecklistStore.reorderItems([c, a, b], in: ctx)

        XCTAssertEqual(c.sortKey, 0)
        XCTAssertEqual(a.sortKey, 1)
        XCTAssertEqual(b.sortKey, 2)
    }

    /// Renaming a checklist persists the new name.
    func test_rename_updates_name() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "Old", in: ctx)
        try ChecklistStore.rename(list, to: "New", in: ctx)
        XCTAssertEqual(list.name, "New")
    }

    /// setCategory assigns a category and can be cleared by passing nil.
    func test_setCategory_assigns_and_clears() throws {
        let ctx = try makeContext()
        let travel = try CategoryStore.create(name: "Travel", in: ctx)
        let list = try ChecklistStore.create(name: "Trip", in: ctx)

        try ChecklistStore.setCategory(list, to: travel, in: ctx)
        XCTAssertEqual(list.category?.id, travel.id)

        try ChecklistStore.setCategory(list, to: nil, in: ctx)
        XCTAssertNil(list.category)
    }

    /// renameItem updates the item's display text.
    func test_renameItem_updates_text() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "T", in: ctx)
        let item = try ChecklistStore.addItem(text: "Old", to: list, in: ctx)
        try ChecklistStore.renameItem(item, to: "New", in: ctx)
        XCTAssertEqual(item.text, "New")
    }

    /// setItemTags replaces the full tag set on an item, including clearing it.
    func test_setItemTags_replaces_tag_set() throws {
        let ctx = try makeContext()
        let tagA = try TagStore.create(name: "A", in: ctx)
        let tagB = try TagStore.create(name: "B", in: ctx)
        let list = try ChecklistStore.create(name: "T", in: ctx)
        let item = try ChecklistStore.addItem(text: "X", to: list, tags: [tagA], in: ctx)

        try ChecklistStore.setItemTags(item, to: [tagB], in: ctx)
        XCTAssertEqual(item.tags?.count, 1)
        XCTAssertEqual(item.tags?.first?.id, tagB.id)

        try ChecklistStore.setItemTags(item, to: [], in: ctx)
        XCTAssertEqual(item.tags?.count ?? 0, 0)
    }

    /// hasMultipleLiveRuns returns false for 0–1 runs and true for 2+.
    func test_hasMultipleLiveRuns_thresholds() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "T", in: ctx)
        XCTAssertFalse(ChecklistStore.hasMultipleLiveRuns(for: list))

        ctx.insert(Run(checklist: list))
        try ctx.save()
        XCTAssertFalse(ChecklistStore.hasMultipleLiveRuns(for: list))

        ctx.insert(Run(checklist: list))
        try ctx.save()
        XCTAssertTrue(ChecklistStore.hasMultipleLiveRuns(for: list))
    }

    /// Deleting an item that has no parent checklist deletes only that item and
    /// does not touch Check records belonging to unrelated checklists.
    func test_deleteItem_with_nil_checklist_deletes_only_item() throws {
        let ctx = try makeContext()

        // Create an unrelated checklist + run + check to ensure we don't wrongly delete it.
        let otherList = try ChecklistStore.create(name: "Other", in: ctx)
        let otherItem = try ChecklistStore.addItem(text: "Other item", to: otherList, in: ctx)
        let otherRun = Run(checklist: otherList, name: "Other run")
        let otherCheck = Check(itemID: otherItem.id)
        otherCheck.run = otherRun
        ctx.insert(otherRun); ctx.insert(otherCheck)
        try ctx.save()

        // Orphan item — inserted without a checklist.
        let orphan = Item(text: "Orphan", sortKey: 0)
        ctx.insert(orphan)
        try ctx.save()

        try ChecklistStore.deleteItem(orphan, in: ctx)

        // Orphan item is gone; the unrelated item remains.
        let items = try ctx.fetch(FetchDescriptor<Item>())
        XCTAssertEqual(items.count, 1, "only the orphan item should be deleted")
        XCTAssertEqual(items.first?.text, "Other item")

        // The other checklist's Check record is NOT deleted.
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Check>()).count, 1)
    }
}

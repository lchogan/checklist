/// TagStoreTests.swift
/// Purpose: Unit tests for TagStore CRUD operations and cross-entity cleanup behaviour.
/// Dependencies: XCTest, SwiftData, Checklist target models.
/// Key concepts:
///   - Each test gets its own in-memory ModelContext via makeTestConfig().
///   - The delete test verifies that CompletedRun snapshots are never mutated.

import XCTest
import SwiftData
@testable import Checklist

final class TagStoreTests: XCTestCase {

    /// Creates a fresh in-memory ModelContext containing all v4 model types.
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Checklist.self, ChecklistCategory.self, Item.self, Tag.self,
                Run.self, Check.self, CompletedRun.self,
            configurations: makeTestConfig()
        )
        return ModelContext(container)
    }

    // MARK: - Create

    /// Verifies that create() assigns incrementing sortKeys and persists the tags.
    func test_create_assigns_sortKey_and_persists() throws {
        let ctx = try makeContext()
        let a = try TagStore.create(name: "Beach", iconName: "sun", colorHue: 85, in: ctx)
        let b = try TagStore.create(name: "Snow", iconName: "snowflake", colorHue: 250, in: ctx)
        XCTAssertEqual(a.sortKey, 0)
        XCTAssertEqual(b.sortKey, 1)
    }

    // MARK: - Delete

    /// Verifies that delete() removes the Tag from Item.tags and Run.hiddenTagIDs.
    func test_delete_removes_from_items_tags_and_run_hiddenTagIDs() throws {
        let ctx = try makeContext()
        let beach = try TagStore.create(name: "Beach", in: ctx)

        let list = Checklist(name: "Trip"); ctx.insert(list)
        let item = Item(text: "Sandals"); item.checklist = list; item.tags = [beach]; ctx.insert(item)
        let run = Run(checklist: list); run.hiddenTagIDs = [beach.id]; ctx.insert(run)
        try ctx.save()

        try TagStore.delete(beach, in: ctx)

        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Tag>()).count, 0)
        XCTAssertEqual(item.tags?.count ?? 0, 0)
        XCTAssertEqual(run.hiddenTagIDs, [])
    }

    /// Verifies that delete() leaves CompletedRun snapshots entirely unchanged.
    func test_delete_does_not_alter_completedRun_snapshot() throws {
        let ctx = try makeContext()
        let beach = try TagStore.create(name: "Beach", in: ctx)
        let list = Checklist(name: "Trip"); ctx.insert(list)
        let completed = CompletedRun(checklist: list, name: "Tokyo")
        completed.snapshot = CompletedRunSnapshot(
            items: [],
            tags: [TagSnapshot(id: beach.id, name: "Beach", iconName: "sun", colorHue: 85)],
            checks: [:],
            hiddenTagIDs: []
        )
        ctx.insert(completed)
        try ctx.save()

        try TagStore.delete(beach, in: ctx)

        XCTAssertEqual(completed.snapshot.tags.first?.name, "Beach",
                       "CompletedRun snapshot must remain frozen even after Tag delete")
    }

    /// Verifies that delete() removes the tag from items across multiple checklists,
    /// catching any silent misses that FetchDescriptor<Item>() faulting could cause.
    func test_delete_removes_tag_from_all_items_across_checklists() throws {
        let ctx = try makeContext()
        let beach = try TagStore.create(name: "Beach", in: ctx)

        // Two checklists, each with an item tagged "beach"
        let list1 = Checklist(name: "Trip A"); ctx.insert(list1)
        let item1 = Item(text: "Sandals"); item1.checklist = list1; item1.tags = [beach]
        ctx.insert(item1)

        let list2 = Checklist(name: "Trip B"); ctx.insert(list2)
        let item2 = Item(text: "Sunscreen"); item2.checklist = list2; item2.tags = [beach]
        ctx.insert(item2)

        try ctx.save()

        try TagStore.delete(beach, in: ctx)

        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Tag>()).count, 0, "Tag deleted")
        XCTAssertEqual(item1.tags?.count ?? 0, 0, "item1 should have beach tag removed")
        XCTAssertEqual(item2.tags?.count ?? 0, 0, "item2 should have beach tag removed")
    }

    // MARK: - Update

    /// Verifies that update() patches only the fields that are provided.
    func test_update_patches_fields() throws {
        let ctx = try makeContext()
        let tag = try TagStore.create(name: "Beach", in: ctx)
        try TagStore.update(tag, name: "Tropical", iconName: "palm", colorHue: 120, in: ctx)
        XCTAssertEqual(tag.name, "Tropical")
        XCTAssertEqual(tag.iconName, "palm")
        XCTAssertEqual(tag.colorHue, 120)
    }

    // MARK: - Queries

    /// Verifies that usageCount() counts every Item referencing the tag across all Checklists.
    func test_usageCount_across_all_items() throws {
        let ctx = try makeContext()
        let beach = try TagStore.create(name: "Beach", in: ctx)
        let list = Checklist(name: "A"); ctx.insert(list)
        let a = Item(text: "a"); a.checklist = list; a.tags = [beach]; ctx.insert(a)
        let b = Item(text: "b"); b.checklist = list; b.tags = [beach]; ctx.insert(b)
        try ctx.save()
        XCTAssertEqual(TagStore.usageCount(for: beach, in: ctx), 2)
    }
}

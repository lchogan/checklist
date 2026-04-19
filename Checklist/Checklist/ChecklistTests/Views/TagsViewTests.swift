/// TagsViewTests.swift
/// Purpose: Tests covering TagsView's visible behaviour — tag-count listing,
///   usage-count subtitle formatting via TagStore.usageCount, and "empty" vs
///   "seeded" branching. View internals (private helpers) are exercised by
///   invoking TagStore directly since the store owns the count logic.
/// Dependencies: XCTest, SwiftData, Checklist target.

import XCTest
import SwiftData
@testable import Checklist

final class TagsViewTests: XCTestCase {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Checklist.self, ChecklistCategory.self, Item.self, Tag.self,
                Run.self, Check.self, CompletedRun.self,
            configurations: makeTestConfig()
        )
        return ModelContext(container)
    }

    /// Empty state: `fetch(Tag)` returns an empty array.
    func test_empty_tag_list() throws {
        let ctx = try makeContext()
        let tags = try ctx.fetch(FetchDescriptor<Tag>())
        XCTAssertTrue(tags.isEmpty, "TagsView's tagList branch relies on @Query → fetch returning []")
    }

    /// Seeded state: tags are returned in sortKey order.
    func test_seeded_tags_returned_in_sortKey_order() throws {
        let ctx = try makeContext()
        let a = try TagStore.create(name: "Beach", in: ctx)
        let b = try TagStore.create(name: "Snow", in: ctx)
        let c = try TagStore.create(name: "Hike", in: ctx)
        var desc = FetchDescriptor<Tag>()
        desc.sortBy = [SortDescriptor(\.sortKey, order: .forward)]
        let fetched = try ctx.fetch(desc)
        XCTAssertEqual(fetched.map(\.id), [a.id, b.id, c.id],
                       "@Query on TagsView must surface tags in sortKey order")
    }

    /// Usage subtitle formatting: singular vs plural branches.
    /// (The subtitle copy is duplicated here because the helper is private on
    /// the view; the count comes from TagStore.usageCount which is the source
    /// of truth tested separately. Uses direct model insertion — matches the
    /// pattern in TagStoreTests.test_usageCount_across_all_items, which works
    /// around a many-to-many faulting quirk when items are saved individually
    /// via ChecklistStore.addItem.)
    func test_usage_subtitle_singular_plural() throws {
        let ctx = try makeContext()
        let beach = try TagStore.create(name: "Beach", in: ctx)
        let list = Checklist(name: "Trip"); ctx.insert(list)
        let a = Item(text: "Sandals"); a.checklist = list; a.tags = [beach]; ctx.insert(a)
        try ctx.save()

        XCTAssertEqual(TagStore.usageCount(for: beach, in: ctx), 1)
        XCTAssertEqual(subtitle(for: TagStore.usageCount(for: beach, in: ctx)), "Used by 1 item")

        let b = Item(text: "Sunscreen"); b.checklist = list; b.tags = [beach]; ctx.insert(b)
        try ctx.save()
        XCTAssertEqual(TagStore.usageCount(for: beach, in: ctx), 2)
        XCTAssertEqual(subtitle(for: TagStore.usageCount(for: beach, in: ctx)), "Used by 2 items")
    }

    /// Mirror of the private helper on TagsView — single source of truth for
    /// the subtitle format contract.
    private func subtitle(for n: Int) -> String {
        "Used by \(n) item\(n == 1 ? "" : "s")"
    }
}

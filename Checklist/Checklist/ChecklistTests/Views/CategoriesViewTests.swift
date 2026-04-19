/// CategoriesViewTests.swift
/// Purpose: Tests the CategoryStore call sites CategoriesView relies on +
///   the "Used by N lists" count logic.

import XCTest
import SwiftData
@testable import Checklist

final class CategoriesViewTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Checklist.self, ChecklistCategory.self, Item.self, Tag.self,
                Run.self, Check.self, CompletedRun.self,
            configurations: makeTestConfig()
        )
        return ModelContext(container)
    }

    /// CategoryStore.create persists and assigns sortKey.
    func test_create_persists_category() throws {
        let ctx = try makeContext()
        let travel = try CategoryStore.create(name: "Travel", in: ctx)
        XCTAssertEqual(travel.name, "Travel")
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<ChecklistCategory>()).count, 1)
    }

    /// CategoryStore.rename changes the name in place.
    func test_rename_updates_name() throws {
        let ctx = try makeContext()
        let travel = try CategoryStore.create(name: "Travel", in: ctx)
        try CategoryStore.rename(travel, to: "Trips", in: ctx)
        XCTAssertEqual(travel.name, "Trips")
    }

    /// CategoryStore.delete nullifies Checklist.category.
    func test_delete_nullifies_checklist_reference() throws {
        let ctx = try makeContext()
        let travel = try CategoryStore.create(name: "Travel", in: ctx)
        let list = try ChecklistStore.create(name: "Trip", category: travel, in: ctx)
        XCTAssertNotNil(list.category)
        try CategoryStore.delete(travel, in: ctx)
        XCTAssertNil(list.category, "Cascade rule nullifies the reference")
    }

    /// Usage count: count of checklists referencing the category.
    func test_usage_count_reflects_checklist_references() throws {
        let ctx = try makeContext()
        let travel = try CategoryStore.create(name: "Travel", in: ctx)
        _ = try ChecklistStore.create(name: "Trip A", category: travel, in: ctx)
        _ = try ChecklistStore.create(name: "Trip B", category: travel, in: ctx)
        _ = try ChecklistStore.create(name: "Home", in: ctx)

        let all = try ctx.fetch(FetchDescriptor<Checklist>())
        let usage = all.filter { $0.category?.id == travel.id }.count
        XCTAssertEqual(usage, 2)
    }
}

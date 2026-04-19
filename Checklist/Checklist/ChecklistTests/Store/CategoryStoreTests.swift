/// CategoryStoreTests.swift
/// Purpose: Unit tests for CategoryStore CRUD operations.
/// Dependencies: XCTest, SwiftData, Checklist (testable), TestHelpers.makeTestConfig().
/// Key concepts:
///   - Each test gets its own in-memory ModelContext so tests are fully isolated.
///   - CloudKit must be disabled via makeTestConfig() to avoid loadIssueModelContainer.

import XCTest
import SwiftData
@testable import Checklist

/// Tests for CategoryStore CRUD operations.
final class CategoryStoreTests: XCTestCase {

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

    /// Creating categories assigns incrementing sortKeys starting at 0 and persists both records.
    func test_create_assigns_sortKey_and_persists() throws {
        let ctx = try makeContext()
        let a = try CategoryStore.create(name: "Travel", in: ctx)
        let b = try CategoryStore.create(name: "Daily", in: ctx)
        XCTAssertEqual(a.sortKey, 0)
        XCTAssertEqual(b.sortKey, 1)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<ChecklistCategory>()).count, 2)
    }

    /// Renaming a category persists the new name.
    func test_rename_updates_name() throws {
        let ctx = try makeContext()
        let cat = try CategoryStore.create(name: "Old", in: ctx)
        try CategoryStore.rename(cat, to: "New", in: ctx)
        XCTAssertEqual(cat.name, "New")
    }

    /// Deleting a category removes it from the store and nullifies the
    /// `category` relationship on any checklists that referenced it.
    func test_delete_removes_category_and_nullifies_checklists() throws {
        let ctx = try makeContext()
        let travel = try CategoryStore.create(name: "Travel", in: ctx)
        let list = try ChecklistStore.create(name: "Trip", category: travel, in: ctx)
        XCTAssertEqual(list.category?.id, travel.id)

        try CategoryStore.delete(travel, in: ctx)

        XCTAssertEqual(try ctx.fetch(FetchDescriptor<ChecklistCategory>()).count, 0)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Checklist>()).count, 1)
        // SwiftData with `deleteRule: .nullify` should clear the relationship.
        XCTAssertNil(list.category)
    }
}

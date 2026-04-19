/// CreateChecklistSheetTests.swift
/// Purpose: Tests the Store-layer commits that CreateChecklistSheet invokes.
///   The view itself is exercised via SwiftUI previews; this file verifies the
///   data-side contract: persisting a checklist with or without a category, and
///   the inline "+ New" category creation flow.
/// Dependencies: XCTest, SwiftData, Checklist (testable), ChecklistStore,
///   CategoryStore, TestHelpers.makeTestConfig.

import XCTest
import SwiftData
@testable import Checklist

/// Tests the Store-layer commits that CreateChecklistSheet invokes. The view
/// itself is exercised via SwiftUI previews; this file verifies the
/// data-side contract.
final class CreateChecklistSheetTests: XCTestCase {

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

    /// Creating a checklist without a category persists it with a nil category relationship.
    func test_create_without_category_persists_checklist() throws {
        let ctx = try makeContext()
        _ = try ChecklistStore.create(name: "Road Trip", category: nil, in: ctx)
        let lists = try ctx.fetch(FetchDescriptor<Checklist>())
        XCTAssertEqual(lists.count, 1)
        XCTAssertEqual(lists.first?.name, "Road Trip")
        XCTAssertNil(lists.first?.category)
    }

    /// Creating a checklist with a category assigns the relationship correctly.
    func test_create_with_category_assigns_relationship() throws {
        let ctx = try makeContext()
        let travel = try CategoryStore.create(name: "Travel", in: ctx)
        _ = try ChecklistStore.create(name: "Europe 2026", category: travel, in: ctx)
        let lists = try ctx.fetch(FetchDescriptor<Checklist>())
        XCTAssertEqual(lists.first?.category?.id, travel.id)
    }

    /// The inline "+ New" flow: creating a category then immediately using it
    /// in the same context assigns the relationship correctly.
    func test_new_category_then_use_it_in_same_context() throws {
        let ctx = try makeContext()
        // Simulates "+ New" inline flow
        let cat = try CategoryStore.create(name: "Weekend", in: ctx)
        let list = try ChecklistStore.create(name: "Beach Day", category: cat, in: ctx)
        XCTAssertEqual(list.category?.name, "Weekend")
    }
}

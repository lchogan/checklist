/// CompletedRunBuilderTests.swift
/// Purpose: Unit tests for CompletedRunBuilder.snapshot(for:checklist:).
/// Dependencies: XCTest, SwiftData, Checklist (testable import), TestHelpers.
/// Key concepts:
///   - All tests run against an in-memory ModelContainer (via makeTestConfig())
///     to avoid CloudKit entitlement conflicts.
///   - Tests verify that snapshot correctly captures items in sortKey order,
///     maps tag references, records check states, and excludes unreferenced tags.

import XCTest
import SwiftData
@testable import Checklist

final class CompletedRunBuilderTests: XCTestCase {

    // MARK: - Helpers

    /// Creates an in-memory ModelContext containing all models used by the app.
    ///
    /// Uses `makeTestConfig()` (CloudKit disabled) to avoid `loadIssueModelContainer`
    /// errors when the app target has a CloudKit entitlement.
    ///
    /// - Returns: A fresh `ModelContext` backed by an in-memory store.
    /// - Throws: If `ModelContainer` initialisation fails.
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Checklist.self, ChecklistCategory.self, Item.self, Tag.self,
                Run.self, Check.self, CompletedRun.self,
            configurations: makeTestConfig()
        )
        return ModelContext(container)
    }

    // MARK: - Tests

    /// Verifies that snapshot captures items (in sortKey order), their tag
    /// references, the check-state map, and the hidden tag ID list.
    func test_snapshot_captures_items_with_tags_and_checks() throws {
        let ctx = try makeContext()

        let list = Checklist(name: "Trip")
        ctx.insert(list)

        let beach = Tag(name: "Beach", iconName: "sun", colorHue: 85)
        ctx.insert(beach)

        // Item A (sortKey 0) — no tags, will be checked.
        let a = Item(text: "Passport", sortKey: 0)
        a.checklist = list
        ctx.insert(a)

        // Item B (sortKey 1) — tagged with beach, not checked.
        let b = Item(text: "Sandals", sortKey: 1)
        b.checklist = list
        b.tags = [beach]
        ctx.insert(b)

        let run = Run(checklist: list, name: "Tokyo")
        ctx.insert(run)

        let check = Check(itemID: a.id, state: .complete)
        check.run = run
        ctx.insert(check)

        // Hide the beach tag in this run's view.
        run.hiddenTagIDs = [beach.id]
        try ctx.save()

        let snapshot = CompletedRunBuilder.snapshot(for: run, checklist: list)

        // Items should be present in sortKey order.
        XCTAssertEqual(snapshot.items.count, 2)
        XCTAssertEqual(snapshot.items[0].text, "Passport")

        // Item B should carry the beach tag reference.
        XCTAssertEqual(snapshot.items[1].tagIDs, [beach.id])

        // Only the beach tag (referenced by an item) should be in the snapshot.
        XCTAssertEqual(snapshot.tags.count, 1)
        XCTAssertEqual(snapshot.tags[0].name, "Beach")

        // Item A's check should appear in the map.
        XCTAssertEqual(snapshot.checks[a.id], .complete)

        // Hidden tag IDs should be carried over from the run.
        XCTAssertEqual(snapshot.hiddenTagIDs, [beach.id])
    }

    /// Verifies that tags not referenced by any item are excluded from the snapshot,
    /// keeping the blob lean and preventing stale tag pollution.
    func test_snapshot_includes_only_tags_referenced_by_items() throws {
        let ctx = try makeContext()

        let list = Checklist(name: "Trip")
        ctx.insert(list)

        let used = Tag(name: "Used")
        ctx.insert(used)

        let unused = Tag(name: "Unused")
        ctx.insert(unused)

        let item = Item(text: "X")
        item.checklist = list
        item.tags = [used]   // Only `used` is attached to an item.
        ctx.insert(item)

        let run = Run(checklist: list)
        ctx.insert(run)
        try ctx.save()

        let snapshot = CompletedRunBuilder.snapshot(for: run, checklist: list)

        // `unused` must be absent — it isn't referenced by any item in this checklist.
        XCTAssertEqual(snapshot.tags.count, 1)
        XCTAssertEqual(snapshot.tags.first?.name, "Used")
    }
}

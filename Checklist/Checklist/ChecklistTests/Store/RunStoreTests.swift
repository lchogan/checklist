/// RunStoreTests.swift
/// Purpose: Unit tests for RunStore — startRun, toggleCheck, setIgnored,
///          toggleHideTag, complete, discard, and multi-run coexistence.
/// Dependencies: XCTest, SwiftData, Checklist (testable import), TestHelpers.
/// Key concepts:
///   - All tests run against an in-memory ModelContainer (via makeTestConfig())
///     to avoid CloudKit entitlement conflicts.
///   - The `seed` helper creates a Checklist + 3 Items via ChecklistStore so
///     tests share consistent initial state without duplicating setup code.

import XCTest
import SwiftData
@testable import Checklist

final class RunStoreTests: XCTestCase {

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

    /// Creates a `Checklist` named "Trip" with three items ("A", "B", "C").
    ///
    /// - Parameter ctx: The `ModelContext` to seed into.
    /// - Returns: A tuple of the new `Checklist` and its three `Item` objects.
    /// - Throws: If any `ChecklistStore` call fails.
    private func seed(_ ctx: ModelContext) throws -> (Checklist, [Item]) {
        let list = try ChecklistStore.create(name: "Trip", in: ctx)
        let items = try ["A", "B", "C"].map {
            try ChecklistStore.addItem(text: $0, to: list, in: ctx)
        }
        return (list, items)
    }

    // MARK: - Tests

    /// Verifies that startRun creates a Run linked to the correct Checklist with
    /// the correct name and an empty checks array.
    func test_startRun_creates_live_run() throws {
        let ctx = try makeContext()
        let (list, _) = try seed(ctx)

        let run = try RunStore.startRun(on: list, name: "Tokyo", in: ctx)

        XCTAssertEqual(run.checklist?.id, list.id)
        XCTAssertEqual(run.name, "Tokyo")
        XCTAssertTrue(run.checks?.isEmpty ?? false)
    }

    /// Verifies that toggleCheck cycles: no record → .complete → no record.
    func test_toggleCheck_sets_then_clears() throws {
        let ctx = try makeContext()
        let (list, items) = try seed(ctx)
        let run = try RunStore.startRun(on: list, in: ctx)

        // First toggle: creates a Check with .complete state.
        try RunStore.toggleCheck(run: run, itemID: items[0].id, in: ctx)
        XCTAssertEqual(run.checks?.count, 1)
        XCTAssertEqual(run.checks?.first?.state, .complete)

        // Second toggle: removes the Check record.
        try RunStore.toggleCheck(run: run, itemID: items[0].id, in: ctx)
        XCTAssertEqual(run.checks?.count ?? 0, 0)
    }

    /// Verifies that setIgnored(to: true) creates / updates a Check with .ignored,
    /// and setIgnored(to: false) removes the Check record.
    func test_setIgnored_adds_check_with_ignored_state() throws {
        let ctx = try makeContext()
        let (list, items) = try seed(ctx)
        let run = try RunStore.startRun(on: list, in: ctx)

        // Ignore the item — should create a Check with .ignored state.
        try RunStore.setIgnored(run: run, itemID: items[0].id, to: true, in: ctx)
        XCTAssertEqual(run.checks?.first?.state, .ignored)

        // Un-ignore the item — should remove the Check record.
        try RunStore.setIgnored(run: run, itemID: items[0].id, to: false, in: ctx)
        XCTAssertEqual(run.checks?.count ?? 0, 0)
    }

    /// Verifies that toggleHideTag appends and then removes a tag UUID from
    /// the run's hiddenTagIDs list.
    func test_toggleHideTag() throws {
        let ctx = try makeContext()
        let (list, _) = try seed(ctx)
        let run = try RunStore.startRun(on: list, in: ctx)
        let tagID = UUID()

        // First toggle: tag UUID should be hidden.
        try RunStore.toggleHideTag(run: run, tagID: tagID, in: ctx)
        XCTAssertEqual(run.hiddenTagIDs, [tagID])

        // Second toggle: tag UUID should be visible again.
        try RunStore.toggleHideTag(run: run, tagID: tagID, in: ctx)
        XCTAssertEqual(run.hiddenTagIDs, [])
    }

    /// Verifies that complete() persists a CompletedRun with the correct name and
    /// snapshot contents, and removes the live Run.
    func test_complete_creates_CompletedRun_and_removes_Run() throws {
        let ctx = try makeContext()
        let (list, items) = try seed(ctx)
        let run = try RunStore.startRun(on: list, name: "Tokyo", in: ctx)

        // Check two of the three items.
        try RunStore.toggleCheck(run: run, itemID: items[0].id, in: ctx)
        try RunStore.toggleCheck(run: run, itemID: items[1].id, in: ctx)

        try RunStore.complete(run, in: ctx)

        // Live Run should be gone.
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Run>()).count, 0)

        // Exactly one CompletedRun should exist.
        let completed = try ctx.fetch(FetchDescriptor<CompletedRun>())
        XCTAssertEqual(completed.count, 1)
        XCTAssertEqual(completed.first?.name, "Tokyo")

        // Snapshot should capture all 3 items and the 2 checks.
        XCTAssertEqual(completed.first?.snapshot.items.count, 3)
        XCTAssertEqual(completed.first?.snapshot.checks.count, 2)
    }

    /// Verifies that discard() removes the live Run without creating a CompletedRun.
    func test_discard_removes_Run_without_completing() throws {
        let ctx = try makeContext()
        let (list, _) = try seed(ctx)
        let run = try RunStore.startRun(on: list, in: ctx)

        try RunStore.discard(run, in: ctx)

        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Run>()).count, 0)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<CompletedRun>()).count, 0)
    }

    /// Verifies that multiple live Runs can coexist on a single Checklist.
    func test_multiple_live_runs_coexist() throws {
        let ctx = try makeContext()
        let (list, _) = try seed(ctx)

        _ = try RunStore.startRun(on: list, name: "Tokyo", in: ctx)
        _ = try RunStore.startRun(on: list, name: "Lisbon", in: ctx)

        XCTAssertEqual(list.runs?.count, 2)
    }
}

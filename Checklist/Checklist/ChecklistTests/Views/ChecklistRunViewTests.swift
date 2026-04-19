/// ChecklistRunViewTests.swift
/// Purpose: Unit tests for view-level behaviors of ChecklistRunView that can
///   be verified without rendering — current-run selection, auto-create logic,
///   and check toggle state transitions.
/// Dependencies: XCTest, SwiftData, Checklist (testable import), TestHelpers.
/// Key concepts: All tests use makeTestConfig() to disable CloudKit in-memory containers.

import XCTest
import SwiftData
@testable import Checklist

/// Tests for the view-level behaviors that are easy to verify without
/// rendering: current-run selection, auto-create, state derivation.
final class ChecklistRunViewTests: XCTestCase {
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

    /// Simulates the auto-create path in handleToggleCheck: when no run exists,
    /// startRun + toggleCheck should produce exactly one run and one complete check.
    func test_first_toggle_auto_creates_run() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "T", in: ctx)
        let item = try ChecklistStore.addItem(text: "A", to: list, in: ctx)

        // Simulate what ChecklistRunView.handleToggleCheck does:
        // no run exists → startRun → toggleCheck.
        XCTAssertEqual(list.runs?.count ?? 0, 0)
        let run = try RunStore.startRun(on: list, in: ctx)
        try RunStore.toggleCheck(run: run, itemID: item.id, in: ctx)

        XCTAssertEqual(list.runs?.count, 1)
        XCTAssertEqual(run.checks?.count, 1)
        XCTAssertEqual(run.checks?.first?.state, .complete)
    }

    /// A second toggle on the same item should remove the check record, leaving
    /// the run with zero checks (toggling off idempotently).
    func test_second_toggle_clears_check() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "T", in: ctx)
        let item = try ChecklistStore.addItem(text: "A", to: list, in: ctx)
        let run = try RunStore.startRun(on: list, in: ctx)

        try RunStore.toggleCheck(run: run, itemID: item.id, in: ctx)
        try RunStore.toggleCheck(run: run, itemID: item.id, in: ctx)

        XCTAssertEqual(run.checks?.count ?? 0, 0)
    }
}

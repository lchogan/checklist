/// RunStore_StartFromHistoryTests.swift
/// Purpose: Tests for RunStore.startRun(on:name:withChecksFrom:in:) — the
///   CompletedRunView fork CTA's backing store method.
/// Dependencies: XCTest, SwiftData, Checklist target, TestHelpers.
/// Key concepts:
///   - Items that exist on the checklist AND had a .complete check in the
///     snapshot get a new .complete Check on the new run.
///   - Items that were .ignored or absent from snapshot.checks yield no Check.
///   - Items in the snapshot that no longer exist on the checklist are skipped.
///   - hiddenTagIDs are copied verbatim.

import XCTest
import SwiftData
@testable import Checklist

final class RunStore_StartFromHistoryTests: XCTestCase {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Checklist.self, ChecklistCategory.self, Item.self, Tag.self,
                Run.self, Check.self, CompletedRun.self,
            configurations: makeTestConfig()
        )
        return ModelContext(container)
    }

    /// Happy path: snapshot has two complete checks + one ignored + one unchecked;
    /// the forked run inherits only the two completes.
    func test_fork_copies_only_complete_checks() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "Trip", in: ctx)
        let a = try ChecklistStore.addItem(text: "A", to: list, in: ctx)
        let b = try ChecklistStore.addItem(text: "B", to: list, in: ctx)
        let c = try ChecklistStore.addItem(text: "C", to: list, in: ctx)
        let d = try ChecklistStore.addItem(text: "D", to: list, in: ctx)

        let oldRun = try RunStore.startRun(on: list, in: ctx)
        try RunStore.toggleCheck(run: oldRun, itemID: a.id, in: ctx)
        try RunStore.toggleCheck(run: oldRun, itemID: b.id, in: ctx)
        try RunStore.setIgnored(run: oldRun, itemID: c.id, to: true, in: ctx)
        // d is left untouched (unchecked)
        try RunStore.complete(oldRun, in: ctx)

        let completed = try XCTUnwrap(try ctx.fetch(FetchDescriptor<CompletedRun>()).first)
        let newRun = try RunStore.startRun(
            on: list,
            name: "Fork",
            withChecksFrom: completed,
            in: ctx
        )

        let checks = newRun.checks ?? []
        let checkedIDs = Set(checks.filter { $0.state == .complete }.map(\.itemID))
        XCTAssertEqual(checkedIDs, [a.id, b.id],
                       "only items that were .complete in the snapshot carry over")
        XCTAssertFalse(checks.contains { $0.itemID == c.id && $0.state == .ignored },
                       "ignored state does NOT carry over — user re-evaluates each item")
        XCTAssertFalse(checks.contains { $0.itemID == d.id },
                       "unchecked items stay unchecked")
        XCTAssertEqual(newRun.name, "Fork")
    }

    /// Snapshot items whose live Item was since deleted must not fabricate
    /// orphaned Check records.
    func test_fork_skips_items_no_longer_on_checklist() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "Trip", in: ctx)
        let a = try ChecklistStore.addItem(text: "A", to: list, in: ctx)
        let b = try ChecklistStore.addItem(text: "B-to-delete", to: list, in: ctx)
        let oldRun = try RunStore.startRun(on: list, in: ctx)
        try RunStore.toggleCheck(run: oldRun, itemID: a.id, in: ctx)
        try RunStore.toggleCheck(run: oldRun, itemID: b.id, in: ctx)
        try RunStore.complete(oldRun, in: ctx)

        let completed = try XCTUnwrap(try ctx.fetch(FetchDescriptor<CompletedRun>()).first)

        // Delete item B *after* completing — simulating an edit between runs.
        try ChecklistStore.deleteItem(b, in: ctx)

        let newRun = try RunStore.startRun(on: list, withChecksFrom: completed, in: ctx)
        let ids = Set((newRun.checks ?? []).map(\.itemID))
        XCTAssertEqual(ids, [a.id], "orphaned snapshot check for deleted B is skipped")
    }

    /// hiddenTagIDs in the snapshot are copied to the new run verbatim.
    func test_fork_copies_hiddenTagIDs() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "Trip", in: ctx)
        let beach = try TagStore.create(name: "Beach", in: ctx)
        _ = try ChecklistStore.addItem(text: "A", to: list, tags: [beach], in: ctx)
        let oldRun = try RunStore.startRun(on: list, in: ctx)
        try RunStore.toggleHideTag(run: oldRun, tagID: beach.id, in: ctx)
        try RunStore.complete(oldRun, in: ctx)

        let completed = try XCTUnwrap(try ctx.fetch(FetchDescriptor<CompletedRun>()).first)
        let newRun = try RunStore.startRun(on: list, withChecksFrom: completed, in: ctx)
        XCTAssertEqual(newRun.hiddenTagIDs, [beach.id])
    }
}

/// SeedStoreTests.swift
/// Purpose: Unit tests for SeedStore fixtures — verifies each named fixture
///          produces the expected entity counts and structural relationships.
/// Dependencies: XCTest, SwiftData, Checklist (testable).
/// Key concepts:
///   - SeedStore.container(for:) already uses cloudKitDatabase: .none internally,
///     so no makeTestConfig() wrapper is needed here.
///   - Each test creates a fresh container via SeedStore so fixtures are independent.

import XCTest
import SwiftData
@testable import Checklist

final class SeedStoreTests: XCTestCase {

    /// `.empty` fixture produces a container with no Checklists and no Tags.
    func test_empty_returns_container_with_nothing() throws {
        let container = try SeedStore.container(for: .empty)
        let ctx = ModelContext(container)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Checklist>()).count, 0)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Tag>()).count, 0)
    }

    /// `.oneList` fixture produces exactly one Checklist that has at least one Item.
    func test_oneList_returns_one_checklist_with_items() throws {
        let container = try SeedStore.container(for: .oneList)
        let ctx = ModelContext(container)
        let lists = try ctx.fetch(FetchDescriptor<Checklist>())
        XCTAssertEqual(lists.count, 1)
        XCTAssertGreaterThan(lists.first?.items?.count ?? 0, 0)
    }

    /// `.seededMulti` fixture produces multiple Checklists, at least one Tag, and
    /// at least one live Run.
    func test_seededMulti_has_multiple_checklists_tags_and_live_run() throws {
        let container = try SeedStore.container(for: .seededMulti)
        let ctx = ModelContext(container)
        XCTAssertGreaterThan(try ctx.fetch(FetchDescriptor<Checklist>()).count, 1)
        XCTAssertGreaterThan(try ctx.fetch(FetchDescriptor<Tag>()).count, 0)
        XCTAssertGreaterThan(try ctx.fetch(FetchDescriptor<Run>()).count, 0)
    }

    /// `.historicalRuns` fixture produces at least one CompletedRun record.
    func test_historicalRuns_has_completedRuns() throws {
        let container = try SeedStore.container(for: .historicalRuns)
        let ctx = ModelContext(container)
        XCTAssertGreaterThan(try ctx.fetch(FetchDescriptor<CompletedRun>()).count, 0)
    }

    /// `.nearCompleteRun` fixture produces exactly one live Run whose check count
    /// equals the checklist's item count minus one (all but last item checked).
    func test_nearCompleteRun_has_one_live_run_with_all_but_one_item_checked() throws {
        let container = try SeedStore.container(for: .nearCompleteRun)
        let ctx = ModelContext(container)
        let runs = try ctx.fetch(FetchDescriptor<Run>())
        XCTAssertEqual(runs.count, 1)
        let run = runs[0]
        let itemCount = run.checklist?.items?.count ?? 0
        XCTAssertEqual(run.checks?.count, itemCount - 1)
    }
}

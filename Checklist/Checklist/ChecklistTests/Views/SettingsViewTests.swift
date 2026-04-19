/// SettingsViewTests.swift
/// Purpose: Tests SettingsView's stats + dangerous action entry points
///   without driving SwiftUI.

import XCTest
import SwiftData
@testable import Checklist

final class SettingsViewTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Checklist.self, ChecklistCategory.self, Item.self, Tag.self,
                Run.self, Check.self, CompletedRun.self,
            configurations: makeTestConfig()
        )
        return ModelContext(container)
    }

    /// Stats card reflects @Query counts — proxy test: counts resolve correctly.
    func test_stats_counts_reflect_fetch_results() throws {
        let ctx = try makeContext()
        _ = try ChecklistStore.create(name: "A", in: ctx)
        _ = try ChecklistStore.create(name: "B", in: ctx)
        _ = try TagStore.create(name: "Beach", in: ctx)

        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Checklist>()).count, 2)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Tag>()).count, 1)
    }
}

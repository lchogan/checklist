import XCTest
import SwiftData
@testable import Checklist

final class ChecklistModelTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        // cloudKitDatabase: .none is required — see TestHelpers.makeTestConfig().
        let container = try ModelContainer(
            for: Checklist.self, ChecklistCategory.self, Item.self, Tag.self,
                Run.self, Check.self, CompletedRun.self,
            configurations: makeTestConfig()
        )
        return ModelContext(container)
    }

    func test_init_defaults() throws {
        let context = try makeContext()
        let list = Checklist(name: "Packing List")
        context.insert(list)

        XCTAssertEqual(list.name, "Packing List")
        XCTAssertEqual(list.sortKey, 0)
        XCTAssertNil(list.category)
        XCTAssertEqual(list.items, [])
        XCTAssertEqual(list.runs, [])
        XCTAssertEqual(list.completedRuns, [])
    }

    func test_category_relationship_round_trip() throws {
        let context = try makeContext()
        let cat = ChecklistCategory(name: "Travel")
        let list = Checklist(name: "Packing List")
        list.category = cat
        context.insert(cat)
        context.insert(list)
        try context.save()

        XCTAssertEqual(list.category?.name, "Travel")
        XCTAssertEqual(cat.checklists?.count, 1)
        XCTAssertEqual(cat.checklists?.first?.name, "Packing List")
    }

    func test_category_nullify_on_delete() throws {
        let context = try makeContext()
        let cat = ChecklistCategory(name: "Travel")
        let list = Checklist(name: "Packing List")
        list.category = cat
        context.insert(cat)
        context.insert(list)
        try context.save()

        context.delete(cat)
        try context.save()

        XCTAssertNil(list.category)
    }
}

import XCTest
import SwiftData
@testable import Checklist

// NOTE: The plan named this type `Category`, but `Category` is ambiguous at
// the Swift compiler level because <objc/runtime.h> also exports a `Category`
// typedef. The model is therefore named `ChecklistCategory` — consistent with
// the v3 convention — to keep the compiler happy. All test semantics are
// identical to the plan.
final class CategoryTests: XCTestCase {
    private func makeInMemoryContext() throws -> ModelContext {
        // cloudKitDatabase: .none is required — see TestHelpers.makeTestConfig().
        let container = try ModelContainer(
            for: ChecklistCategory.self,
            configurations: makeTestConfig()
        )
        return ModelContext(container)
    }

    func test_init_with_name_stores_defaults() throws {
        let context = try makeInMemoryContext()
        let cat = ChecklistCategory(name: "Travel")
        context.insert(cat)

        XCTAssertEqual(cat.name, "Travel")
        XCTAssertEqual(cat.sortKey, 0)
        XCTAssertNotNil(cat.id)
        XCTAssertNotNil(cat.createdAt)
        XCTAssertEqual(cat.checklists, [])
    }

    func test_sortKey_can_be_set_at_init() throws {
        let context = try makeInMemoryContext()
        let cat = ChecklistCategory(name: "Daily", sortKey: 7)
        context.insert(cat)
        XCTAssertEqual(cat.sortKey, 7)
    }

    func test_persists_and_fetches() throws {
        let context = try makeInMemoryContext()
        let cat = ChecklistCategory(name: "Home")
        context.insert(cat)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<ChecklistCategory>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "Home")
    }
}

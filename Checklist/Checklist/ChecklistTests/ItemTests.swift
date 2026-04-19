import XCTest
import SwiftData
@testable import Checklist

final class ItemTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        // cloudKitDatabase: .none is required — see TestHelpers.makeTestConfig().
        let container = try ModelContainer(
            for: Checklist.self, Item.self, Tag.self,
            configurations: makeTestConfig()
        )
        return ModelContext(container)
    }

    func test_init_defaults() throws {
        let context = try makeContext()
        let item = Item(text: "Toothbrush")
        context.insert(item)

        XCTAssertEqual(item.text, "Toothbrush")
        XCTAssertEqual(item.sortKey, 0)
        XCTAssertNil(item.checklist)
        XCTAssertEqual(item.tags, [])
    }

    func test_checklist_items_cascade_delete() throws {
        let context = try makeContext()
        let list = Checklist(name: "Trip")
        let item = Item(text: "Passport")
        item.checklist = list
        context.insert(list)
        context.insert(item)
        try context.save()

        context.delete(list)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Item>())
        XCTAssertTrue(fetched.isEmpty, "item should be cascade-deleted with its checklist")
    }

    func test_tags_many_to_many() throws {
        let context = try makeContext()
        let beach = Tag(name: "Beach")
        let snow = Tag(name: "Snow")
        let item = Item(text: "Boots")
        item.tags = [beach, snow]
        context.insert(beach)
        context.insert(snow)
        context.insert(item)
        try context.save()

        XCTAssertEqual(item.tags?.count, 2)
    }
}

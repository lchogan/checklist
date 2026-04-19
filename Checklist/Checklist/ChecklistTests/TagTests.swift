import XCTest
import SwiftData
@testable import Checklist

final class TagTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        // cloudKitDatabase: .none is required — see TestHelpers.makeTestConfig().
        let container = try ModelContainer(
            for: Tag.self,
            configurations: makeTestConfig()
        )
        return ModelContext(container)
    }

    func test_init_defaults() throws {
        let context = try makeContext()
        let tag = Tag(name: "Beach")
        context.insert(tag)

        XCTAssertEqual(tag.name, "Beach")
        XCTAssertEqual(tag.iconName, "tag")
        XCTAssertEqual(tag.colorHue, 300)
        XCTAssertEqual(tag.sortKey, 0)
        XCTAssertNotNil(tag.id)
    }

    func test_init_with_icon_and_color() throws {
        let context = try makeContext()
        let tag = Tag(name: "Snow", iconName: "snowflake", colorHue: 250)
        context.insert(tag)
        XCTAssertEqual(tag.iconName, "snowflake")
        XCTAssertEqual(tag.colorHue, 250)
    }
}

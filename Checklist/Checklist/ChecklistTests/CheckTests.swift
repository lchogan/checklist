import XCTest
import SwiftData
@testable import Checklist

final class CheckTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        // cloudKitDatabase: .none is required — see TestHelpers.makeTestConfig().
        let container = try ModelContainer(
            for: Check.self, Run.self, Checklist.self,
            configurations: makeTestConfig()
        )
        return ModelContext(container)
    }

    func test_init_defaults_to_complete() throws {
        let context = try makeContext()
        let itemID = UUID()
        let check = Check(itemID: itemID)
        context.insert(check)

        XCTAssertEqual(check.itemID, itemID)
        XCTAssertEqual(check.state, .complete)
    }

    func test_state_setter_updates_timestamp() throws {
        let context = try makeContext()
        let check = Check(itemID: UUID())
        context.insert(check)
        let before = check.updatedAt

        check.state = .ignored
        XCTAssertEqual(check.state, .ignored)
        XCTAssertGreaterThanOrEqual(check.updatedAt, before)
    }

    func test_checkstate_codable_roundtrip() throws {
        let value: CheckState = .ignored
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(CheckState.self, from: data)
        XCTAssertEqual(decoded, .ignored)
    }
}

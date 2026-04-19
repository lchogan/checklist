import XCTest
import SwiftData
@testable import Checklist

final class RunTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        // cloudKitDatabase: .none is required — see TestHelpers.makeTestConfig().
        let container = try ModelContainer(
            for: Checklist.self, Run.self, Check.self,
            configurations: makeTestConfig()
        )
        return ModelContext(container)
    }

    func test_init_defaults() throws {
        let context = try makeContext()
        let list = Checklist(name: "Daily")
        let run = Run(checklist: list)
        context.insert(list)
        context.insert(run)

        XCTAssertEqual(run.checklist?.name, "Daily")
        XCTAssertNil(run.name)
        XCTAssertNotNil(run.startedAt)
        XCTAssertEqual(run.hiddenTagIDs, [])
        XCTAssertEqual(run.checks, [])
    }

    func test_init_with_name() throws {
        let context = try makeContext()
        let list = Checklist(name: "Packing")
        let run = Run(checklist: list, name: "Tokyo")
        context.insert(list)
        context.insert(run)
        XCTAssertEqual(run.name, "Tokyo")
    }
}

import XCTest
import SwiftData
@testable import Checklist

final class CompletedRunTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        // cloudKitDatabase: .none is required — see TestHelpers.makeTestConfig().
        let container = try ModelContainer(
            for: CompletedRun.self, Checklist.self,
            configurations: makeTestConfig()
        )
        return ModelContext(container)
    }

    func test_init_defaults_empty_snapshot() throws {
        let context = try makeContext()
        let list = Checklist(name: "Daily")
        let completed = CompletedRun(checklist: list)
        context.insert(list)
        context.insert(completed)

        XCTAssertEqual(completed.snapshot.items.count, 0)
        XCTAssertEqual(completed.snapshot.tags.count, 0)
        XCTAssertEqual(completed.snapshot.checks.count, 0)
        XCTAssertEqual(completed.snapshot.hiddenTagIDs.count, 0)
    }

    func test_snapshot_round_trip() throws {
        let context = try makeContext()
        let list = Checklist(name: "Trip")
        let completed = CompletedRun(checklist: list)
        context.insert(list)
        context.insert(completed)

        let itemID = UUID()
        let tagID = UUID()
        let snapshot = CompletedRunSnapshot(
            items: [ItemSnapshot(id: itemID, text: "Passport", tagIDs: [tagID], sortKey: 0)],
            tags: [TagSnapshot(id: tagID, name: "Intl", iconName: "plane", colorHue: 300)],
            checks: [itemID: .complete],
            hiddenTagIDs: []
        )
        completed.snapshot = snapshot
        try context.save()

        XCTAssertEqual(completed.snapshot.items.first?.text, "Passport")
        XCTAssertEqual(completed.snapshot.tags.first?.name, "Intl")
        XCTAssertEqual(completed.snapshot.checks[itemID], .complete)
    }

    func test_cascade_from_checklist() throws {
        let context = try makeContext()
        let list = Checklist(name: "Trip")
        let completed = CompletedRun(checklist: list)
        context.insert(list)
        context.insert(completed)
        try context.save()

        context.delete(list)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<CompletedRun>())
        XCTAssertTrue(fetched.isEmpty, "CompletedRun should cascade-delete with its Checklist")
    }
}

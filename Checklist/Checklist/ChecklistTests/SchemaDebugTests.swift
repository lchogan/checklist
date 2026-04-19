/// SchemaDebugTests.swift
/// Purpose: Temporary diagnostic tests that confirmed the root cause of
/// loadIssueModelContainer: CloudKit entitlement + isStoredInMemoryOnly requires
/// cloudKitDatabase: .none. Now fixed via makeTestConfig(). This file can be
/// deleted once all tasks pass, but is kept for reference.
import XCTest
import SwiftData
@testable import Checklist

final class SchemaDebugTests: XCTestCase {

    func test_tag_alone_in_memory_with_cloudkit_none() throws {
        // This test documents the fix: cloudKitDatabase: .none is required.
        let container = try ModelContainer(
            for: Tag.self,
            configurations: makeTestConfig()
        )
        let ctx = ModelContext(container)
        let tag = Tag(name: "Test")
        ctx.insert(tag)
        XCTAssertEqual(tag.name, "Test")
    }
}

/// TestHelpers.swift
/// Purpose: Shared utilities for ChecklistTests.
/// Key concept: When the app has a CloudKit entitlement, ModelContainer with
/// isStoredInMemoryOnly: true throws loadIssueModelContainer unless
/// cloudKitDatabase: .none is explicitly set. All test contexts must use
/// makeTestConfig() to avoid this bug.
///
/// Reference: https://developer.apple.com/forums/thread/746507

import Foundation
import SwiftData

/// Returns an in-memory ModelConfiguration with CloudKit disabled.
///
/// IMPORTANT: Always use this instead of `ModelConfiguration(isStoredInMemoryOnly: true)`
/// in tests. The CloudKit entitlement on the app target causes `ModelContainer` to throw
/// `loadIssueModelContainer` with an in-memory store unless CloudKit is explicitly
/// disabled in the configuration.
///
/// - Returns: A `ModelConfiguration` suitable for in-memory XCTest contexts.
func makeTestConfig() -> ModelConfiguration {
    ModelConfiguration(
        isStoredInMemoryOnly: true,
        cloudKitDatabase: .none
    )
}

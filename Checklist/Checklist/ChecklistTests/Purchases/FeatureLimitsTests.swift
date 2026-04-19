/// FeatureLimitsTests.swift
/// Purpose: Tests for the expanded FeatureLimits value type — merging, Codable
///   round-trip, and the per-dimension canAdd helpers.
/// Dependencies: XCTest, Checklist target.

import XCTest
@testable import Checklist

final class FeatureLimitsTests: XCTestCase {

    /// Merge: nil (unlimited) beats a numeric cap on a single Int? field.
    func test_merge_nil_beats_numeric() {
        let a = FeatureLimits(maxChecklists: 3, maxItemsPerChecklist: nil,
                              maxLiveRunsPerChecklist: nil, maxTotalRuns: nil,
                              maxTags: 3, maxCategories: 0, cloudKitSync: false)
        let b = FeatureLimits(maxChecklists: nil, maxItemsPerChecklist: nil,
                              maxLiveRunsPerChecklist: nil, maxTotalRuns: nil,
                              maxTags: nil, maxCategories: nil, cloudKitSync: true)
        let merged = a.merged(with: b)
        XCTAssertNil(merged.maxChecklists, "nil unlimited wins over 3")
        XCTAssertNil(merged.maxTags, "nil unlimited wins over 3")
        XCTAssertNil(merged.maxCategories, "nil wins over 0")
        XCTAssertTrue(merged.cloudKitSync, "true OR false = true")
    }

    /// Merge: the larger numeric cap wins when neither side is nil.
    func test_merge_larger_numeric_wins() {
        let a = FeatureLimits(maxChecklists: 3, maxItemsPerChecklist: 50,
                              maxLiveRunsPerChecklist: 2, maxTotalRuns: nil,
                              maxTags: 3, maxCategories: 1, cloudKitSync: false)
        let b = FeatureLimits(maxChecklists: 10, maxItemsPerChecklist: 20,
                              maxLiveRunsPerChecklist: 5, maxTotalRuns: nil,
                              maxTags: 10, maxCategories: 0, cloudKitSync: false)
        let merged = a.merged(with: b)
        XCTAssertEqual(merged.maxChecklists, 10)
        XCTAssertEqual(merged.maxItemsPerChecklist, 50)
        XCTAssertEqual(merged.maxLiveRunsPerChecklist, 5)
        XCTAssertEqual(merged.maxTags, 10)
        XCTAssertEqual(merged.maxCategories, 1)
        XCTAssertFalse(merged.cloudKitSync)
    }

    /// canAddChecklist: nil cap means always allowed; numeric cap honoured.
    func test_canAdd_checklist() {
        let free = FeatureLimits(maxChecklists: 1, maxItemsPerChecklist: nil,
                                 maxLiveRunsPerChecklist: nil, maxTotalRuns: nil,
                                 maxTags: 3, maxCategories: 0, cloudKitSync: false)
        XCTAssertTrue(free.canAddChecklist(current: 0))
        XCTAssertFalse(free.canAddChecklist(current: 1))
        let unlimited = FeatureLimits.unlimited
        XCTAssertTrue(unlimited.canAddChecklist(current: 99_999))
    }

    /// canAddItem / canStartRun: nil = unlimited; numeric cap honoured.
    func test_canAdd_items_and_runs() {
        let free = FeatureLimits(maxChecklists: 1, maxItemsPerChecklist: 10,
                                 maxLiveRunsPerChecklist: 1, maxTotalRuns: nil,
                                 maxTags: 3, maxCategories: 0, cloudKitSync: false)
        XCTAssertTrue(free.canAddItem(currentItemsOnChecklist: 9))
        XCTAssertFalse(free.canAddItem(currentItemsOnChecklist: 10))
        XCTAssertTrue(free.canStartRun(currentLiveRunsOnChecklist: 0))
        XCTAssertFalse(free.canStartRun(currentLiveRunsOnChecklist: 1))
    }

    /// Codable round-trip: JSON encode + decode = original.
    func test_codable_round_trip() throws {
        let original = FeatureLimits(
            maxChecklists: 3, maxItemsPerChecklist: 25,
            maxLiveRunsPerChecklist: 2, maxTotalRuns: nil,
            maxTags: 5, maxCategories: 0, cloudKitSync: true
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FeatureLimits.self, from: data)
        XCTAssertEqual(original, decoded)
    }
}

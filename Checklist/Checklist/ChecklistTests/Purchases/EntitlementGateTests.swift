/// EntitlementGateTests.swift
/// Purpose: Tests that the pure EntitlementGate helpers return .allowed or
///   .blocked with the expected reason given a FeatureLimits + a current
///   count. Tests the decision only; the view-side presentation of
///   PaywallSheet is verified manually.
/// Dependencies: XCTest, Checklist target.

import XCTest
@testable import Checklist

final class EntitlementGateTests: XCTestCase {

    private let free = FeatureLimits(
        maxChecklists: 1, maxItemsPerChecklist: 25,
        maxLiveRunsPerChecklist: 1, maxTotalRuns: nil,
        maxTags: 3, maxCategories: 0, cloudKitSync: false
    )

    func test_canCreateChecklist_allowed_when_under_cap() {
        XCTAssertEqual(EntitlementGate.canCreateChecklist(current: 0, limits: free),
                       .allowed)
    }

    func test_canCreateChecklist_blocked_when_at_cap() {
        let result = EntitlementGate.canCreateChecklist(current: 1, limits: free)
        if case .blocked(let reason) = result {
            XCTAssertEqual(reason.dimension, .checklists)
            XCTAssertEqual(reason.limit, 1)
        } else {
            XCTFail("expected .blocked, got \(result)")
        }
    }

    func test_canAddTag_blocked_at_3_with_plural_copy() {
        let result = EntitlementGate.canCreateTag(current: 3, limits: free)
        if case .blocked(let reason) = result {
            XCTAssertTrue(reason.message.contains("3"), "message must include the cap")
        } else { XCTFail("expected .blocked") }
    }

    func test_canAddCategory_blocked_when_cap_is_zero() {
        let result = EntitlementGate.canCreateCategory(current: 0, limits: free)
        // cap of 0 means "not allowed at all" — always blocked
        if case .blocked = result {} else { XCTFail("cap of 0 must always block") }
    }

    func test_canAddItem_uses_per_checklist_cap() {
        XCTAssertEqual(EntitlementGate.canAddItem(
            currentItemsOnChecklist: 24, limits: free
        ), .allowed)
        let blocked = EntitlementGate.canAddItem(currentItemsOnChecklist: 25, limits: free)
        if case .blocked = blocked {} else { XCTFail("at 25 items must block") }
    }

    func test_canStartRun_uses_live_runs_cap() {
        XCTAssertEqual(EntitlementGate.canStartRun(
            currentLiveRunsOnChecklist: 0, limits: free
        ), .allowed)
        let blocked = EntitlementGate.canStartRun(
            currentLiveRunsOnChecklist: 1, limits: free
        )
        if case .blocked = blocked {} else { XCTFail("at 1 live run free must block") }
    }

    func test_allowed_when_limits_unlimited() {
        let u = FeatureLimits.unlimited
        XCTAssertEqual(EntitlementGate.canCreateChecklist(current: 10_000, limits: u), .allowed)
        XCTAssertEqual(EntitlementGate.canCreateTag(current: 10_000, limits: u), .allowed)
        XCTAssertEqual(EntitlementGate.canCreateCategory(current: 10_000, limits: u), .allowed)
    }
}

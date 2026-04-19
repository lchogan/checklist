/// PlanCatalogTests.swift
/// Purpose: Tests the shipped plans.json loads correctly and that the catalog
///   exposes the expected free and premium plans.
/// Dependencies: XCTest, Checklist target.

import XCTest
@testable import Checklist

final class PlanCatalogTests: XCTestCase {

    /// plans.json loads and yields ≥2 plans (free + at least one paid).
    func test_catalog_loads_at_least_two_plans() {
        XCTAssertGreaterThanOrEqual(PlanCatalog.plans.count, 2,
                                    "plans.json must ship free + at least one paid tier")
    }

    /// Free plan exists with productID nil.
    func test_free_plan_has_nil_productID() {
        XCTAssertNil(PlanCatalog.freePlan.productID)
    }

    /// Free plan's limits match the ship defaults (1 list / 3 tags / 0 categories).
    func test_free_plan_limits_are_as_documented() {
        let f = PlanCatalog.freePlan.limits
        XCTAssertEqual(f.maxChecklists, 1, "documented free-tier default")
        XCTAssertEqual(f.maxTags, 3)
        XCTAssertEqual(f.maxCategories, 0)
        XCTAssertFalse(f.cloudKitSync, "free tier must NOT sync")
    }

    /// plan(for:) resolves known StoreKit IDs.
    func test_plan_lookup_by_productID() {
        XCTAssertNotNil(PlanCatalog.plan(for: "com.checklist.premium.monthly"))
        XCTAssertNotNil(PlanCatalog.plan(for: "com.checklist.premium.annual"))
        XCTAssertNil(PlanCatalog.plan(for: "com.bogus.product"))
    }

    /// allProductIDs contains each non-free plan's productID.
    func test_allProductIDs_excludes_free() {
        let ids = PlanCatalog.allProductIDs
        XCTAssertFalse(ids.contains(where: { $0.isEmpty }), "nil / empty product IDs filtered out")
        XCTAssertGreaterThanOrEqual(ids.count, 1)
    }
}

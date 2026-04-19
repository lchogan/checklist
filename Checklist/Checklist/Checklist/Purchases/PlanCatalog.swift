/// PlanCatalog.swift
/// Purpose: Source of truth for all Plans. Loads from bundled plans.json once
///   at first access; falls back to a hardcoded safe default if the JSON is
///   missing or malformed.
/// Dependencies: Foundation, Plan, FeatureLimits.
/// Key concepts:
///   - Sync loader (JSON is in the app bundle — always available at first read).
///   - Design accommodates a future remote override: swap `load()` to async
///     fetch + cache without touching callers.
///   - The free plan is the first plan with `productID == nil`.
///   - `plan(for productID:)` resolves an owned StoreKit productID to its Plan,
///     or returns `nil` when the productID isn't in the catalog.

import Foundation

/// Source of truth for Plans. Loads bundled `plans.json` lazily; safe default
/// fallback keeps the app usable even if the JSON is missing.
enum PlanCatalog {

    // MARK: - Public API

    /// All plans in the catalog, in declaration order from plans.json.
    static var plans: [Plan] { cache.plans }

    /// The free plan — first entry with `productID == nil`. If no free plan is
    /// declared, a safe hardcoded default is returned (which should never
    /// happen in a shipping build, but we defend against it).
    static var freePlan: Plan {
        plans.first(where: { $0.productID == nil }) ?? defaultFreePlan
    }

    /// All StoreKit product IDs declared across non-free plans.
    static var allProductIDs: [String] {
        plans.compactMap(\.productID)
    }

    /// Returns the plan owning the given productID, if any.
    static func plan(for productID: String) -> Plan? {
        plans.first(where: { $0.productID == productID })
    }

    // MARK: - Private cache

    private static let cache: (plans: [Plan], error: Error?) = load()

    private static func load() -> (plans: [Plan], error: Error?) {
        guard let url = Bundle.main.url(forResource: "plans", withExtension: "json") else {
            return ([defaultFreePlan], CatalogError.resourceNotFound)
        }
        do {
            let data = try Data(contentsOf: url)
            let wrapper = try JSONDecoder().decode(Wrapper.self, from: data)
            return (wrapper.plans, nil)
        } catch {
            return ([defaultFreePlan], error)
        }
    }

    private struct Wrapper: Codable { let plans: [Plan] }

    private enum CatalogError: Error { case resourceNotFound }

    /// Hard-coded fallback so the app doesn't crash if plans.json is missing.
    /// Free tier with cap-all-at-zero — the user can still read existing data
    /// but can't create anything. This is deliberately conservative; a missing
    /// plans.json is a build-config bug that should be caught in tests.
    private static let defaultFreePlan = Plan(
        id: "_fallback_free",
        displayName: "Free",
        productID: nil,
        limits: .restrictive
    )
}

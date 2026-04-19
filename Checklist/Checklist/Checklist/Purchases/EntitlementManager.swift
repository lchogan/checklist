/// EntitlementManager.swift
/// Purpose: Single source of truth for the user's current entitlements.
///   Resolves the set of owned StoreKit product IDs to an effective Plan
///   (most-generous merge when multiple are owned) via PlanCatalog.
/// Dependencies: Foundation, Combine, PlanCatalog, Plan, FeatureLimits.
/// Key concepts:
///   - `activePlan` is the Plan currently effective; changes when StoreKitManager
///     updates the owned-product-ID set.
///   - `limits` is `activePlan.limits` — this is what view gates read.
///   - `isPremium` kept for back-compat: true when activePlan != free plan.

import Foundation
import Combine

/// Exposes the user's currently-effective Plan + its merged FeatureLimits.
/// StoreKitManager drives the input via `updateOwnedProducts(_:)`.
@MainActor
final class EntitlementManager: ObservableObject {
    /// The plan in effect. Publishes when StoreKitManager reports a change.
    @Published private(set) var activePlan: Plan = PlanCatalog.freePlan

    /// Back-compat: true when a paid plan is active.
    var isPremium: Bool { activePlan.productID != nil }

    /// The merged limits for the active plan. View gates read this.
    var limits: FeatureLimits { activePlan.limits }

    /// Called by StoreKitManager when the set of owned product IDs changes.
    /// Resolves to the most-generous merge of all owned plans.
    func updateOwnedProducts(_ productIDs: Set<String>) {
        activePlan = Self.resolvePlan(for: productIDs)
    }

    /// Pure function: pick plans matching `productIDs`, merge their limits,
    /// return a synthetic Plan carrying the merged limits. Falls back to the
    /// free plan when no matches.
    static func resolvePlan(for productIDs: Set<String>) -> Plan {
        let owned = PlanCatalog.plans.filter {
            guard let pid = $0.productID else { return false }
            return productIDs.contains(pid)
        }
        if owned.isEmpty { return PlanCatalog.freePlan }

        // Merge starting from `restrictive` so Int fields open monotonically.
        let mergedLimits = owned.reduce(FeatureLimits.restrictive) {
            $0.merged(with: $1.limits)
        }
        // Attribute the effective plan to the first owned plan's name/id for
        // display purposes — a merge of two plans is conceptually still "one
        // active subscription" from the user's perspective.
        let primary = owned[0]
        return Plan(
            id: primary.id,
            displayName: primary.displayName,
            productID: primary.productID,
            limits: mergedLimits
        )
    }
}

/// EntitlementGate.swift
/// Purpose: Pure gating decisions for feature access. Returns .allowed or
///   .blocked(reason); views pattern-match on the result and present the
///   paywall when blocked.
/// Dependencies: FeatureLimits.
/// Key concepts:
///   - Intent-first: one method per user-facing feature, not one per tier.
///   - Blocked carries a structured Reason so the paywall can show feature-
///     specific copy ("Unlock more checklists" vs "Unlock tags").
///   - Pure — no singletons, no state. Views pass `entitlementManager.limits`.

import Foundation

/// Outcome of a gate decision.
enum GateDecision: Equatable {
    case allowed
    case blocked(Reason)

    /// Structured blocked reason carried to the paywall for feature-specific copy.
    struct Reason: Equatable {
        let dimension: Dimension
        /// Cap value hit (or nil when semantics are "not available at all").
        let limit: Int?
        /// Human-readable message shown on the paywall banner.
        let message: String
    }

    /// Feature categories the gate reasons about.
    enum Dimension: String, Equatable {
        case checklists
        case items
        case liveRuns
        case totalRuns
        case tags
        case categories
        case cloudKitSync
    }
}

/// Pure gating helpers. Views call these; views own the paywall presentation.
enum EntitlementGate {

    /// Can the user create another checklist given the current count?
    static func canCreateChecklist(current: Int, limits: FeatureLimits) -> GateDecision {
        guard let max = limits.maxChecklists else { return .allowed }
        if current < max { return .allowed }
        return .blocked(.init(
            dimension: .checklists,
            limit: max,
            message: "Free plan is limited to \(max) checklist\(max == 1 ? "" : "s"). Upgrade for unlimited."
        ))
    }

    /// Can the user add another item to the checklist given its current item count?
    static func canAddItem(currentItemsOnChecklist: Int, limits: FeatureLimits) -> GateDecision {
        guard let max = limits.maxItemsPerChecklist else { return .allowed }
        if currentItemsOnChecklist < max { return .allowed }
        return .blocked(.init(
            dimension: .items,
            limit: max,
            message: "Free plan caps each checklist at \(max) items. Upgrade to keep adding."
        ))
    }

    /// Can the user start another live run on the checklist?
    static func canStartRun(currentLiveRunsOnChecklist: Int, limits: FeatureLimits) -> GateDecision {
        guard let max = limits.maxLiveRunsPerChecklist else { return .allowed }
        if currentLiveRunsOnChecklist < max { return .allowed }
        return .blocked(.init(
            dimension: .liveRuns,
            limit: max,
            message: "Free plan allows \(max) live run\(max == 1 ? "" : "s") per checklist. Upgrade for concurrent runs."
        ))
    }

    /// Can the user create another tag?
    static func canCreateTag(current: Int, limits: FeatureLimits) -> GateDecision {
        guard let max = limits.maxTags else { return .allowed }
        if current < max { return .allowed }
        return .blocked(.init(
            dimension: .tags,
            limit: max,
            message: "Free plan is limited to \(max) tag\(max == 1 ? "" : "s"). Upgrade for unlimited."
        ))
    }

    /// Can the user create another category?
    static func canCreateCategory(current: Int, limits: FeatureLimits) -> GateDecision {
        guard let max = limits.maxCategories else { return .allowed }
        if current < max { return .allowed }
        return .blocked(.init(
            dimension: .categories,
            limit: max,
            message: max == 0
                ? "Categories are a Plus feature."
                : "Free plan is limited to \(max) categor\(max == 1 ? "y" : "ies"). Upgrade for unlimited."
        ))
    }
}

/// FeatureLimits.swift
/// Purpose: Value-type numeric + boolean caps for one plan. Hydrated from
///   bundled plans.json via PlanCatalog; merged across multiple active plans
///   by EntitlementManager.
/// Dependencies: Foundation (Codable).
/// Key concepts:
///   - Nullable Int: nil means unlimited.
///   - merged(with:) takes the more generous value per field (nil > number,
///     larger number wins, true wins on Bool).
///   - Static constants: only `unlimited` and `restrictive` exist here — named
///     tiers (free / plus / pro) live in plans.json and flow through PlanCatalog.

import Foundation

/// Per-feature limits for a single plan. All numeric fields are nullable to
/// express "unlimited"; the `cloudKitSync` bool gates iCloud sync independently.
///
/// Merge semantics (`merged(with:)`):
/// - Int? fields: `nil` (unlimited) wins; otherwise the larger number wins.
/// - Bool fields: `true` wins (OR).
///
/// This lets EntitlementManager combine multiple owned plans into a single
/// most-generous effective limits set without branching per dimension.
struct FeatureLimits: Codable, Equatable {
    var maxChecklists: Int?
    var maxItemsPerChecklist: Int?
    var maxLiveRunsPerChecklist: Int?
    var maxTotalRuns: Int?
    var maxTags: Int?
    var maxCategories: Int?
    var cloudKitSync: Bool

    // MARK: - Standard instances

    /// All dimensions unlimited, cloudKitSync on. Used as the final fallback
    /// if plans.json fails to load and as the right-hand identity in merges.
    static let unlimited = FeatureLimits(
        maxChecklists: nil,
        maxItemsPerChecklist: nil,
        maxLiveRunsPerChecklist: nil,
        maxTotalRuns: nil,
        maxTags: nil,
        maxCategories: nil,
        cloudKitSync: true
    )

    /// All dimensions zero, cloudKitSync off. Used as the starting value when
    /// merging up from a set of plans (so the merge monotonically opens access).
    static let restrictive = FeatureLimits(
        maxChecklists: 0,
        maxItemsPerChecklist: 0,
        maxLiveRunsPerChecklist: 0,
        maxTotalRuns: 0,
        maxTags: 0,
        maxCategories: 0,
        cloudKitSync: false
    )

    // MARK: - Merge

    /// Returns the most-generous per-field merge of `self` and `other`.
    func merged(with other: FeatureLimits) -> FeatureLimits {
        FeatureLimits(
            maxChecklists: mergedMax(self.maxChecklists, other.maxChecklists),
            maxItemsPerChecklist: mergedMax(self.maxItemsPerChecklist, other.maxItemsPerChecklist),
            maxLiveRunsPerChecklist: mergedMax(self.maxLiveRunsPerChecklist, other.maxLiveRunsPerChecklist),
            maxTotalRuns: mergedMax(self.maxTotalRuns, other.maxTotalRuns),
            maxTags: mergedMax(self.maxTags, other.maxTags),
            maxCategories: mergedMax(self.maxCategories, other.maxCategories),
            cloudKitSync: self.cloudKitSync || other.cloudKitSync
        )
    }

    /// nil (unlimited) wins; else the larger value wins.
    private func mergedMax(_ a: Int?, _ b: Int?) -> Int? {
        if a == nil || b == nil { return nil }
        return max(a!, b!)
    }

    // MARK: - Per-dimension guard helpers

    /// True iff `current` is below the checklist cap (or no cap).
    func canAddChecklist(current: Int) -> Bool {
        guard let max = maxChecklists else { return true }
        return current < max
    }

    /// True iff the current item count on a checklist is below the per-list cap.
    func canAddItem(currentItemsOnChecklist: Int) -> Bool {
        guard let max = maxItemsPerChecklist else { return true }
        return currentItemsOnChecklist < max
    }

    /// True iff the current live-run count on a checklist is below the per-list cap.
    func canStartRun(currentLiveRunsOnChecklist: Int) -> Bool {
        guard let max = maxLiveRunsPerChecklist else { return true }
        return currentLiveRunsOnChecklist < max
    }

    /// True iff `current` is below the total-runs (live + completed) cap.
    func canCompleteRun(currentTotalRuns: Int) -> Bool {
        guard let max = maxTotalRuns else { return true }
        return currentTotalRuns < max
    }

    /// True iff `current` is below the tag cap.
    func canAddTag(current: Int) -> Bool {
        guard let max = maxTags else { return true }
        return current < max
    }

    /// True iff `current` is below the category cap.
    func canAddCategory(current: Int) -> Bool {
        guard let max = maxCategories else { return true }
        return current < max
    }

    // MARK: - Display helpers (used by PaywallSheet and SettingsView)

    var checklistLimitDescription: String {
        guard let max = maxChecklists else { return "Unlimited checklists" }
        return "\(max) checklist\(max == 1 ? "" : "s")"
    }

    var tagLimitDescription: String {
        guard let max = maxTags else { return "Unlimited tags" }
        return "\(max) tag\(max == 1 ? "" : "s")"
    }

    var categoryLimitDescription: String {
        guard let max = maxCategories else { return "Unlimited categories" }
        if max == 0 { return "No categories" }
        return "\(max) categor\(max == 1 ? "y" : "ies")"
    }
}

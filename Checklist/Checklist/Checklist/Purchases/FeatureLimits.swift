import Foundation

/// Defines the capability limits for each tier.
/// Set any value to `nil` to indicate unlimited.
/// To adjust the freemium model, only change the `free` static instance.
struct FeatureLimits {
    var maxChecklists: Int?
    var maxTags: Int?
    var maxCategories: Int?

    // MARK: - Tiers

    static let free = FeatureLimits(
        maxChecklists: 1,
        maxTags: 3,
        maxCategories: 0
    )

    static let premium = FeatureLimits(
        maxChecklists: nil,
        maxTags: nil,
        maxCategories: nil
    )

    // MARK: - Guard helpers

    func canAdd(checklists currentCount: Int) -> Bool {
        guard let max = maxChecklists else { return true }
        return currentCount < max
    }

    func canAdd(tags currentCount: Int) -> Bool {
        guard let max = maxTags else { return true }
        return currentCount < max
    }

    func canAdd(categories currentCount: Int) -> Bool {
        guard let max = maxCategories else { return true }
        return currentCount < max
    }

    // MARK: - Display helpers

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

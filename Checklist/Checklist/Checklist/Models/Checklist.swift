import Foundation
import SwiftData

@Model
final class Checklist {
    var name: String
    var category: ChecklistCategory?
    var createdAt: Date = Date()
    
    // Display settings
    var showProgressBar: Bool = true
    var showTagsOnItems: Bool = true

    @Relationship(deleteRule: .cascade, inverse: \ChecklistItem.checklist)
    var items: [ChecklistItem] = []

    init(name: String) {
        self.name = name
    }

    // MARK: - Computed helpers

    var sortedItems: [ChecklistItem] {
        items.sorted { $0.order < $1.order }
    }

    /// All unique tags used across this checklist's items, sorted by name.
    var usedTags: [Tag] {
        var seen: Set<PersistentIdentifier> = []
        var result: [Tag] = []
        for item in items {
            for tag in item.tags {
                if seen.insert(tag.persistentModelID).inserted {
                    result.append(tag)
                }
            }
        }
        return result.sorted { $0.name < $1.name }
    }

    // MARK: - Completion calculations

    /// Used by the run view. Excludes deferred items and tag-hidden items from both numerator and denominator.
    func completionInfo(hiddenTagIDs: Set<PersistentIdentifier> = []) -> (completed: Int, total: Int) {
        let relevant = items.filter { item in
            let isDeferred = item.status == .deferred
            let isTagHidden = !hiddenTagIDs.isEmpty &&
                item.tags.contains { hiddenTagIDs.contains($0.persistentModelID) }
            return !isDeferred && !isTagHidden
        }
        let completed = relevant.filter { $0.status == .complete }.count
        return (completed, relevant.count)
    }

    /// Used by the list view. Simple: completed / total (all items, no filtering).
    var listViewCompletionInfo: (completed: Int, total: Int) {
        let completed = items.filter { $0.status == .complete }.count
        return (completed, items.count)
    }

    /// True when every item is either complete or deferred (nothing left to do).
    var isEffectivelyComplete: Bool {
        !items.isEmpty && items.allSatisfy { $0.status != .incomplete }
    }
}

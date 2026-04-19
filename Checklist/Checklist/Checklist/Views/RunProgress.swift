/// RunProgress.swift
/// Purpose: Computed progress snapshot for a Run. Not persisted — derived from
///   the Run's current checks and the Checklist's current items, with hidden-tag
///   filtering applied.
/// Dependencies: Foundation, Item, Check models.
/// Key concepts:
///   - `total` = items whose tags are NOT all in `hiddenTagIDs`, excluding items
///     with Check.state == .ignored (ignored items are hidden from both numerator
///     and denominator, matching ARCHITECTURE §3b semantics).
///   - `done` = of those visible items, the count with Check.state == .complete.

import Foundation

/// Computed progress snapshot for a Run. Not persisted — derived from the
/// Run's current checks and the Checklist's current items, with hidden-tag
/// filtering applied.
///
/// Rules:
/// - `total` = items whose tags are NOT all in `run.hiddenTagIDs`, excluding
///   items with `Check.state == .ignored` (ignored items are hidden from both
///   numerator and denominator, matching ARCHITECTURE §3b semantics).
/// - `done` = of those visible items, the count with `Check.state == .complete`.
struct RunProgress {
    let done: Int
    let total: Int
    var percent: Double { total == 0 ? 0 : Double(done) / Double(total) }

    /// Computes a progress snapshot given a list of items, checks, and hidden tag IDs.
    ///
    /// - Parameters:
    ///   - items: All items belonging to the checklist.
    ///   - checks: The check records from the live Run.
    ///   - hiddenTagIDs: Tag UUIDs that are currently hidden in this run's view.
    /// - Returns: A `RunProgress` with `done` and `total` counts after filtering.
    static func compute(items: [Item], checks: [Check], hiddenTagIDs: [UUID]) -> RunProgress {
        let ignored = Set(checks.filter { $0.state == .ignored }.map(\.itemID))
        let visible = items.filter { item in
            if ignored.contains(item.id) { return false }
            // Hidden if EVERY tag on the item is in hiddenTagIDs (an untagged
            // item can never be hidden).
            guard let tags = item.tags, !tags.isEmpty else { return true }
            let itemTagIDs = Set(tags.map(\.id))
            let hidden = Set(hiddenTagIDs)
            return !itemTagIDs.isSubset(of: hidden)
        }
        let visibleIDs = Set(visible.map(\.id))
        let done = checks.filter { visibleIDs.contains($0.itemID) && $0.state == .complete }.count
        return RunProgress(done: done, total: visible.count)
    }
}

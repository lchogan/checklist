/// CompletedRunProgress.swift
/// Purpose: Snapshot-derived completion counters for a frozen CompletedRun.
/// Dependencies: CompletedRunSnapshot, CheckState.
/// Key concepts:
///   - Total is `snapshot.items.count` — ignored items are INCLUDED in total (they
///     represent actual items that existed during the run; the "partial"/"complete"
///     badge reads the same way it did at run time).
///   - Done is the count of `.complete` entries in `snapshot.checks`.
///   - `isAllDone` is true when every item has a `.complete` check (total == done).

import Foundation

/// Read-only progress snapshot for a `CompletedRunSnapshot`.
///
/// Computed at view time per spec §3 decision 5 — partial/complete status is
/// never persisted.
struct CompletedRunProgress {
    let done: Int
    let total: Int

    var isAllDone: Bool { total > 0 && done == total }

    /// Builds progress directly from a frozen snapshot.
    ///
    /// - Parameter snapshot: The `CompletedRunSnapshot` to summarise.
    /// - Returns: A `CompletedRunProgress` with `done` = count of `.complete`
    ///   checks, `total` = count of items in the snapshot.
    static func compute(snapshot: CompletedRunSnapshot) -> CompletedRunProgress {
        let done = snapshot.checks.values.filter { $0 == .complete }.count
        return CompletedRunProgress(done: done, total: snapshot.items.count)
    }
}

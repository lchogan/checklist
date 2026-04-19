/// CompletedRunSnapshot.swift
/// Purpose: Frozen value-type snapshots embedded in CompletedRun as a JSON blob.
/// Dependencies: Foundation (Codable), CheckState.
/// Key concepts:
///   - All snapshot types are value types (structs) — they're never mutated
///     after the CompletedRun is created.
///   - Stored as a single Data blob on CompletedRun so the completed record is
///     self-contained even if source Checklist/Tag is later edited or deleted.
///   - Dictionary<UUID, CheckState> encodes to JSON cleanly because UUID
///     adopts CustomStringConvertible (keys become strings).

import Foundation

/// Frozen snapshot of a Run's state at the moment of completion. Embedded in
/// CompletedRun as JSON, so the completed record is self-contained even if the
/// source Checklist or Tag is later edited or deleted.
struct CompletedRunSnapshot: Codable {
    /// Ordered list of item snapshots from the run.
    var items: [ItemSnapshot]

    /// All tags referenced by items in this snapshot.
    var tags: [TagSnapshot]

    /// Map of item UUID → check state. Items absent from this map were
    /// incomplete (not checked) when the run was completed.
    var checks: [UUID: CheckState]

    /// Tag UUIDs that were hidden from view during this run.
    var hiddenTagIDs: [UUID]

    /// An empty snapshot used as the default value before a real snapshot is
    /// set, and as a safe fallback if JSON decoding fails.
    static let empty = CompletedRunSnapshot(items: [], tags: [], checks: [:], hiddenTagIDs: [])
}

/// Immutable snapshot of a single Item's state at run-completion time.
struct ItemSnapshot: Codable, Identifiable, Hashable {
    let id: UUID
    let text: String
    let tagIDs: [UUID]
    let sortKey: Int
}

/// Immutable snapshot of a single Tag's display properties at run-completion time.
struct TagSnapshot: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let iconName: String
    let colorHue: Double
}

/// Checklist.swift
/// Purpose: SwiftData model for a reusable checklist. Owns items directly;
///          Run/CompletedRun records reference this shape by relationship.
/// Dependencies: SwiftData, ChecklistCategory (optional), Item, Run, CompletedRun.
/// Key concepts:
///   - Structural edits (add/rename/reorder/delete item) mutate this record
///     and are immediately visible to every live Run.
///   - Category deletion nullifies this record's category pointer (user's
///     checklists are preserved).

import Foundation
import SwiftData

/// A reusable checklist. Owns its items directly; Run/CompletedRun records
/// reference this shape.
///
/// Dependencies: ChecklistCategory (optional), Item/Run/CompletedRun (cascade).
/// Key concepts: structural edits (add/rename/reorder/delete item) mutate
/// this record and are immediately visible to every live Run.
@Model
final class Checklist {
    // MARK: - Persistent properties

    /// Stable unique identifier assigned at creation.
    var id: UUID = UUID()

    /// Display name shown in the UI.
    var name: String = ""

    /// Determines display order within the checklist list. Lower = first.
    var sortKey: Int = 0

    /// Timestamp recorded when the model is first initialised.
    var createdAt: Date = Date()

    // MARK: - Relationships

    /// Optional category grouping. Nullified (not cascade-deleted) when the
    /// ChecklistCategory is deleted so the checklist itself is preserved.
    @Relationship(deleteRule: .nullify) var category: ChecklistCategory?

    /// Items belonging to this checklist. Cascade-deleted when the checklist
    /// is deleted.
    @Relationship(deleteRule: .cascade, inverse: \Item.checklist) var items: [Item]? = []

    /// Active runs of this checklist. Cascade-deleted when the checklist is
    /// deleted.
    @Relationship(deleteRule: .cascade, inverse: \Run.checklist) var runs: [Run]? = []

    /// Completed run history for this checklist. Cascade-deleted when the
    /// checklist is deleted.
    @Relationship(deleteRule: .cascade, inverse: \CompletedRun.checklist) var completedRuns: [CompletedRun]? = []

    // MARK: - Init

    /// Creates a new Checklist with the given display name.
    /// - Parameter name: The checklist label shown to the user.
    init(name: String) {
        self.name = name
    }
}

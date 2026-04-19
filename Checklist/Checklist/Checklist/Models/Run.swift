/// Run.swift
/// Purpose: SwiftData model for a live usage of a Checklist. Holds per-usage
///          state: which items are checked/ignored, which tags are hidden.
/// Dependencies: SwiftData, Checklist (parent), Check (cascade).
/// Key concepts:
///   - Multiple live Runs can exist per Checklist (e.g., concurrent trips on
///     one Packing List).
///   - Completing a Run creates a CompletedRun snapshot and deletes this record
///     (see RunStore.complete).
///   - hiddenTagIDs stores tag UUIDs filtered out of the run's view.

import Foundation
import SwiftData

/// A live usage of a Checklist. Holds per-usage state: which items are
/// checked/ignored, which tags are hidden from view. Multiple live Runs can
/// exist per Checklist (e.g., concurrent trips on one Packing List).
///
/// Key concept: completing a Run creates a CompletedRun snapshot and deletes
/// the Run record (see RunStore.complete).
@Model
final class Run {
    // MARK: - Persistent properties

    /// Stable unique identifier assigned at creation.
    var id: UUID = UUID()

    /// Optional user-given label for this particular usage (e.g., "Tokyo Trip").
    var name: String? = nil

    /// When this run was started.
    var startedAt: Date = Date()

    /// UUIDs of tags whose items are hidden from this run's view.
    var hiddenTagIDs: [UUID] = []

    // MARK: - Relationships

    /// The Checklist being run. Nullified (not cascade-deleted) so a Run can
    /// survive temporary Checklist absence (though in practice RunStore always
    /// deletes orphaned Runs).
    @Relationship(deleteRule: .nullify) var checklist: Checklist?

    /// Check records for this run. Cascade-deleted when the Run is deleted.
    @Relationship(deleteRule: .cascade, inverse: \Check.run) var checks: [Check]? = []

    // MARK: - Init

    /// Creates a new Run for the given Checklist.
    /// - Parameters:
    ///   - checklist: The Checklist being run.
    ///   - name: Optional user label; defaults to nil.
    init(checklist: Checklist, name: String? = nil) {
        self.checklist = checklist
        self.name = name
    }
}

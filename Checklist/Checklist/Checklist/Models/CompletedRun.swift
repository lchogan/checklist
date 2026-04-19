/// CompletedRun.swift
/// Purpose: SwiftData model for a completed record of a finished Run.
/// Dependencies: SwiftData, Checklist (parent), CompletedRunSnapshot (blob).
/// Key concepts:
///   - Read-only after creation — never mutated.
///   - Stores the entire run snapshot as a single Codable blob with
///     `.externalStorage` for atomic immutability and CloudKit-friendly size.
///   - Once created, editing the source Checklist or Tag does NOT affect past
///     CompletedRuns because all data is frozen in the snapshot.

import Foundation
import SwiftData

/// Completed record of a finished Run. Read-only forever. Stores items, tags,
/// checks, and hidden-tag IDs as a single Codable blob (`.externalStorage`)
/// for atomic immutability + CloudKit-friendly size.
///
/// Key concept: once created, this never changes. Editing the source Checklist
/// or Tag does NOT affect past CompletedRuns.
@Model
final class CompletedRun {
    // MARK: - Persistent properties

    /// Stable unique identifier assigned at creation.
    var id: UUID = UUID()

    /// Optional user-given label copied from the originating Run.
    var name: String? = nil

    /// When the originating Run was started.
    var startedAt: Date = Date()

    /// When the Run was completed and this record was created.
    var completedAt: Date = Date()

    // MARK: - Relationships

    /// The Checklist this run was for. Nullified (not cascade-deleted) from
    /// this side; cascade deletion is handled from Checklist's side.
    @Relationship(deleteRule: .nullify) var checklist: Checklist?

    // MARK: - Snapshot blob

    /// Raw JSON encoding of a `CompletedRunSnapshot`. Stored externally so
    /// CloudKit treats it as a CKAsset rather than a record field, keeping
    /// record size predictable.
    @Attribute(.externalStorage)
    var snapshotData: Data = Data()

    /// Decoded snapshot. Getting decodes `snapshotData`; setting JSON-encodes
    /// the new value back into `snapshotData`. Falls back to `.empty` if
    /// decoding fails so the model is never in an invalid state.
    var snapshot: CompletedRunSnapshot {
        get {
            (try? JSONDecoder().decode(CompletedRunSnapshot.self, from: snapshotData))
                ?? .empty
        }
        set {
            snapshotData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    // MARK: - Init

    /// Creates a new CompletedRun.
    /// - Parameters:
    ///   - checklist: The Checklist that was run.
    ///   - name: Optional user label copied from the originating Run.
    ///   - startedAt: When the run started; defaults to now.
    ///   - completedAt: When the run was completed; defaults to now.
    init(
        checklist: Checklist,
        name: String? = nil,
        startedAt: Date = Date(),
        completedAt: Date = Date()
    ) {
        self.checklist = checklist
        self.name = name
        self.startedAt = startedAt
        self.completedAt = completedAt
    }
}

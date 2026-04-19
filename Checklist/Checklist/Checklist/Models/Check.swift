/// Check.swift
/// Purpose: SwiftData model for one entry in a Run's check map.
/// Dependencies: SwiftData, Run (parent), CheckState.
/// Key concepts:
///   - `itemID` is a UUID (not a relationship) so Item deletion doesn't leave a
///     phantom — RunStore.clearChecks(forItemID:) handles cleanup explicitly.
///   - `state` is a computed property backed by `stateRaw: String` for SwiftData
///     compatibility (enums aren't natively stored by SwiftData).
///   - Setting `state` automatically updates `updatedAt`.

import Foundation
import SwiftData

/// One entry in a Run's check map: Item X has state Y as of time T.
///
/// `itemID` is a UUID (not a relationship) so Item deletion doesn't leave a
/// phantom — RunStore.clearChecks(forItemID:) handles cleanup explicitly.
@Model
final class Check {
    // MARK: - Persistent properties

    /// Stable unique identifier assigned at creation.
    var id: UUID = UUID()

    /// The ID of the Item this check refers to. Stored as UUID (not a
    /// relationship) so deleting the Item doesn't leave a phantom Check.
    var itemID: UUID = UUID()

    /// Raw storage for `state`. String so SwiftData can persist it.
    var stateRaw: String = CheckState.complete.rawValue

    /// When this check's state was last set.
    var updatedAt: Date = Date()

    // MARK: - Relationships

    /// The Run this check belongs to. Nullified (not cascade-deleted) from this
    /// side; cascade deletion is handled from Run's side.
    @Relationship(deleteRule: .nullify) var run: Run?

    // MARK: - Computed

    /// The check's state. Getting decodes `stateRaw`; setting encodes to
    /// `stateRaw` and bumps `updatedAt` atomically.
    var state: CheckState {
        get { CheckState(rawValue: stateRaw) ?? .complete }
        set {
            stateRaw = newValue.rawValue
            updatedAt = Date()
        }
    }

    // MARK: - Init

    /// Creates a new Check.
    /// - Parameters:
    ///   - itemID: The UUID of the Item being checked.
    ///   - state: Initial state; defaults to `.complete`.
    init(itemID: UUID, state: CheckState = .complete) {
        self.itemID = itemID
        self.stateRaw = state.rawValue
    }
}

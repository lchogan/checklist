/// Item.swift
/// Purpose: SwiftData model for a single checklist item. Many-to-many with Tag.
/// Dependencies: SwiftData, Checklist (parent), Tag (many-to-many).
/// Key concepts:
///   - An Item has no status field — check state lives in Run.checks, keyed by itemID.
///   - `sortKey` determines display order within a Checklist.
///   - Tag relationship is many-to-many with no deleteRule so Tag deletion does
///     not cascade to Items.

import Foundation
import SwiftData

/// A single checklist item. Many-to-many with Tag. Ordered within a Checklist
/// via `sortKey`.
///
/// Key concept: an Item has no status field — check state lives in Run.checks,
/// keyed by itemID.
@Model
final class Item {
    // MARK: - Persistent properties

    /// Stable unique identifier assigned at creation.
    var id: UUID = UUID()

    /// The text label shown in the UI.
    var text: String = ""

    /// Determines display order within the owning Checklist. Lower = first.
    var sortKey: Int = 0

    // MARK: - Relationships

    /// The Checklist this item belongs to. Nullified (not cascade-deleted) so
    /// that deletion of an isolated item does not affect its parent checklist.
    /// The parent's deleteRule: .cascade handles cleanup from the other side.
    @Relationship(deleteRule: .nullify) var checklist: Checklist?

    /// Tags applied to this item. Many-to-many; no cascade so deleting a Tag
    /// does not delete Items.
    @Relationship var tags: [Tag]? = []

    // MARK: - Init

    /// Creates a new Item.
    /// - Parameters:
    ///   - text: Display text.
    ///   - sortKey: Integer ordering within the parent checklist; defaults to 0.
    init(text: String, sortKey: Int = 0) {
        self.text = text
        self.sortKey = sortKey
    }
}

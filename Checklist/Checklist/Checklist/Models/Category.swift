/// Category.swift
/// Purpose: SwiftData model representing a top-level grouping for checklists.
/// Dependencies: SwiftData, ChecklistItem (inverse relationship — Task 1.3).
/// Key concepts: @Model macro, PersistentModel, nullify delete-rule.
///
/// NOTE: Named `ChecklistCategory` (not `Category`) to avoid ambiguity with the
/// ObjC `Category` typedef in <objc/runtime.h>, which the Swift compiler imports
/// and cannot disambiguate when both names are in scope.

import Foundation
import SwiftData

/// A top-level grouping for checklists. App-wide scope.
///
/// - Note: `checklists` uses `.nullify` so deleting a ChecklistCategory does not
///   cascade-delete its Checklists — the user's data is preserved.
@Model
final class ChecklistCategory {
    // MARK: - Persistent properties

    /// Stable unique identifier assigned at creation.
    var id: UUID = UUID()

    /// Display name shown in the UI.
    var name: String = ""

    /// Determines display order within the category list. Lower = first.
    var sortKey: Int = 0

    /// Timestamp recorded when the model is first initialised.
    var createdAt: Date = Date()

    /// Checklists that belong to this category.
    ///
    /// `inverse: \Checklist.category` keeps both sides of the relationship
    /// consistent without manual book-keeping.
    @Relationship(deleteRule: .nullify, inverse: \Checklist.category)
    var checklists: [Checklist]? = []

    // MARK: - Init

    /// Creates a new ChecklistCategory with a given display name and optional sort position.
    /// - Parameters:
    ///   - name: The category label shown to the user.
    ///   - sortKey: Integer used for deterministic ordering; defaults to 0.
    init(name: String, sortKey: Int = 0) {
        self.name = name
        self.sortKey = sortKey
    }
}

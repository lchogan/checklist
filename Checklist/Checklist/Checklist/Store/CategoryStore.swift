/// CategoryStore.swift
/// Purpose: Stateless CRUD operations for ChecklistCategory.
///          Every function takes a ModelContext explicitly — no hidden singletons.
///          Views call these directly; no view-model layer required.
/// Dependencies: Foundation, SwiftData, ChecklistCategory model.
/// Key concepts:
///   - Named ChecklistCategory (not Category) to avoid ObjC runtime conflict.
///   - sortKey assignment uses the current maximum + 1 strategy (same as other stores).
///   - Deleting a ChecklistCategory nullifies its checklists (preserves user data).

import Foundation
import SwiftData

/// Stateless CRUD namespace for `ChecklistCategory`.
///
/// Handles sort-key assignment on create and delegates relationship cleanup to
/// SwiftData's `.nullify` delete rule on `ChecklistCategory.checklists`.
enum CategoryStore {

    // MARK: - Create

    /// Creates and persists a new ChecklistCategory with an auto-assigned sortKey.
    ///
    /// The sortKey is set to one greater than the current maximum, so new
    /// categories appear at the end of the list.
    ///
    /// - Parameters:
    ///   - name: Display name for the category.
    ///   - context: The `ModelContext` in which to insert and save.
    /// - Returns: The newly created and persisted `ChecklistCategory`.
    /// - Throws: If the sortKey fetch or the save fails.
    @discardableResult
    static func create(name: String, in context: ModelContext) throws -> ChecklistCategory {
        let cat = ChecklistCategory(name: name, sortKey: try nextSortKey(in: context))
        context.insert(cat)
        try context.save()
        return cat
    }

    // MARK: - Update

    /// Renames an existing ChecklistCategory and persists the change.
    ///
    /// - Parameters:
    ///   - category: The `ChecklistCategory` to rename.
    ///   - name: The new display name.
    ///   - context: The `ModelContext` to save into.
    /// - Throws: If the save fails.
    static func rename(_ category: ChecklistCategory, to name: String, in context: ModelContext) throws {
        category.name = name
        try context.save()
    }

    // MARK: - Delete

    /// Deletes a ChecklistCategory and persists the change.
    ///
    /// Checklists that referenced this category have their `category` relationship
    /// nullified by SwiftData's `.nullify` delete rule — user checklists are preserved.
    ///
    /// - Parameters:
    ///   - category: The `ChecklistCategory` to delete.
    ///   - context: The `ModelContext` to delete from and save.
    /// - Throws: If the save fails.
    static func delete(_ category: ChecklistCategory, in context: ModelContext) throws {
        // Checklists with this category nullify (relationship deleteRule: .nullify)
        context.delete(category)
        try context.save()
    }

    // MARK: - Private

    /// Computes the next sortKey for a new ChecklistCategory by reading the highest
    /// existing sortKey and incrementing it.
    ///
    /// - Parameter context: The `ModelContext` to fetch from.
    /// - Returns: One greater than the current maximum sortKey, or 0 if no categories exist.
    /// - Throws: If the fetch fails.
    private static func nextSortKey(in context: ModelContext) throws -> Int {
        let descriptor = FetchDescriptor<ChecklistCategory>(sortBy: [SortDescriptor(\.sortKey, order: .reverse)])
        return ((try context.fetch(descriptor)).first?.sortKey ?? -1) + 1
    }
}

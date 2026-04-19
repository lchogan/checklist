/// ChecklistStore.swift
/// Purpose: Stateless CRUD operations for Checklist, Item, and ChecklistCategory.
///          Every function takes a ModelContext explicitly — no hidden singletons.
///          Views call these directly; no view-model layer required.
/// Dependencies: Foundation, SwiftData, Checklist, Item, ChecklistCategory,
///               Run, Check models.
/// Key concepts:
///   - Structural edits (add/rename/reorder/delete item) mutate Checklist and are
///     immediately visible to every live Run because items live on Checklist (v4 arch).
///   - deleteItem explicitly cleans up Check records keyed by itemID across all
///     live Runs — SwiftData cannot cascade across a UUID reference, so we do it here.

import Foundation
import SwiftData

/// Stateless CRUD namespace for `Checklist`, `Item`, and `ChecklistCategory`.
enum ChecklistStore {

    // MARK: - Checklist CRUD

    /// Creates and persists a new Checklist with the given name and optional category.
    ///
    /// - Parameters:
    ///   - name: Display name for the new checklist.
    ///   - category: Optional `ChecklistCategory` grouping; defaults to nil.
    ///   - context: The `ModelContext` in which to insert and save.
    /// - Returns: The newly created and persisted `Checklist`.
    /// - Throws: If the fetch for the next sort key or the save fails.
    @discardableResult
    static func create(
        name: String,
        category: ChecklistCategory? = nil,
        in context: ModelContext
    ) throws -> Checklist {
        let list = Checklist(name: name)
        list.category = category
        list.sortKey = try nextChecklistSortKey(in: context)
        context.insert(list)
        try context.save()
        return list
    }

    /// Renames an existing Checklist and persists the change.
    ///
    /// - Parameters:
    ///   - list: The `Checklist` to rename.
    ///   - name: The new display name.
    ///   - context: The `ModelContext` to save into.
    /// - Throws: If the save fails.
    static func rename(_ list: Checklist, to name: String, in context: ModelContext) throws {
        list.name = name
        try context.save()
    }

    /// Assigns a ChecklistCategory to a Checklist (or clears it by passing nil).
    ///
    /// - Parameters:
    ///   - list: The `Checklist` to update.
    ///   - category: The new `ChecklistCategory`, or nil to clear.
    ///   - context: The `ModelContext` to save into.
    /// - Throws: If the save fails.
    static func setCategory(
        _ list: Checklist,
        to category: ChecklistCategory?,
        in context: ModelContext
    ) throws {
        list.category = category
        try context.save()
    }

    /// Deletes a Checklist (and cascade-deletes its items, runs, and completed runs).
    ///
    /// - Parameters:
    ///   - list: The `Checklist` to delete.
    ///   - context: The `ModelContext` to delete from and save.
    /// - Throws: If the save fails.
    static func delete(_ list: Checklist, in context: ModelContext) throws {
        context.delete(list)
        try context.save()
    }

    // MARK: - Items

    /// Appends a new Item to the given Checklist with the next available sortKey.
    ///
    /// - Parameters:
    ///   - text: Display text for the item.
    ///   - list: The `Checklist` that owns this item.
    ///   - tags: Tags to associate with the item; defaults to empty.
    ///   - context: The `ModelContext` to insert and save into.
    /// - Returns: The newly created and persisted `Item`.
    /// - Throws: If the save fails.
    @discardableResult
    static func addItem(
        text: String,
        to list: Checklist,
        tags: [Tag] = [],
        in context: ModelContext
    ) throws -> Item {
        // Next sortKey is one past the current maximum, or 0 if there are no items.
        let nextSort = (list.items?.map(\.sortKey).max() ?? -1) + 1
        let item = Item(text: text, sortKey: nextSort)
        item.checklist = list
        item.tags = tags
        context.insert(item)
        try context.save()
        return item
    }

    /// Renames an Item and persists the change.
    ///
    /// - Parameters:
    ///   - item: The `Item` to rename.
    ///   - text: The new display text.
    ///   - context: The `ModelContext` to save into.
    /// - Throws: If the save fails.
    static func renameItem(_ item: Item, to text: String, in context: ModelContext) throws {
        item.text = text
        try context.save()
    }

    /// Replaces the tag set on an Item and persists the change.
    ///
    /// - Parameters:
    ///   - item: The `Item` to update.
    ///   - tags: The new set of tags.
    ///   - context: The `ModelContext` to save into.
    /// - Throws: If the save fails.
    static func setItemTags(_ item: Item, to tags: [Tag], in context: ModelContext) throws {
        item.tags = tags
        try context.save()
    }

    /// Deletes an Item and removes any Check records referencing it across all live Runs.
    ///
    /// SwiftData cannot cascade across a UUID reference (`Check.itemID`), so orphan
    /// cleanup is done explicitly here before saving.
    ///
    /// - Parameters:
    ///   - item: The `Item` to delete.
    ///   - context: The `ModelContext` to delete from and save.
    /// - Throws: If the fetch or save fails.
    static func deleteItem(_ item: Item, in context: ModelContext) throws {
        let itemID = item.id
        guard let checklistID = item.checklist?.id else {
            // No parent checklist means no Check records can legitimately be scoped to
            // this item, so just delete and return.
            context.delete(item)
            try context.save()
            return
        }
        context.delete(item)

        // Clean up Check records referencing this item in all live Runs on the same
        // checklist. Check.itemID is a UUID (not a relationship), so SwiftData won't
        // cascade — we must delete orphans manually.
        // The checklist guard cannot be pushed into #Predicate because optional-chained
        // relationship traversals (check.run?.checklist?.id) aren't supported by the
        // macro. Filter in-memory on the already-small itemID slice instead.
        let descriptor = FetchDescriptor<Check>(
            predicate: #Predicate<Check> { $0.itemID == itemID }
        )
        let orphans = try context.fetch(descriptor)
        for check in orphans where check.run?.checklist?.id == checklistID {
            context.delete(check)
        }
        try context.save()
    }

    /// Applies a new sort order to a list of Items by updating each item's sortKey.
    ///
    /// - Parameters:
    ///   - ordered: Items in the desired display order.
    ///   - context: The `ModelContext` to save into.
    /// - Throws: If the save fails.
    static func reorderItems(_ ordered: [Item], in context: ModelContext) throws {
        for (index, item) in ordered.enumerated() {
            item.sortKey = index
        }
        try context.save()
    }

    // MARK: - Queries

    /// Returns the number of live (not yet completed) Runs for a Checklist.
    ///
    /// - Parameter list: The `Checklist` to query.
    /// - Returns: Count of `Run` objects attached to the checklist.
    static func liveRunCount(for list: Checklist) -> Int {
        list.runs?.count ?? 0
    }

    /// Returns true when two or more live Runs exist for the Checklist.
    ///
    /// Used by the UI to determine whether to show a run-disambiguation picker.
    ///
    /// - Parameter list: The `Checklist` to query.
    /// - Returns: `true` if `liveRunCount >= 2`.
    static func hasMultipleLiveRuns(for list: Checklist) -> Bool {
        liveRunCount(for: list) >= 2
    }

    // MARK: - Private

    /// Computes the next available sortKey for a new Checklist by reading the
    /// highest existing sortKey and incrementing it.
    ///
    /// - Parameter context: The `ModelContext` to fetch from.
    /// - Returns: An integer one greater than the current maximum sortKey, or 0 if
    ///   no checklists exist yet.
    /// - Throws: If the fetch fails.
    private static func nextChecklistSortKey(in context: ModelContext) throws -> Int {
        var descriptor = FetchDescriptor<Checklist>(
            sortBy: [SortDescriptor(\.sortKey, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return ((try context.fetch(descriptor)).first?.sortKey ?? -1) + 1
    }
}

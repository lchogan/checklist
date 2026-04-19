/// TagStore.swift
/// Purpose: Stateless CRUD operations for app-wide Tags.
///          Every function takes a ModelContext explicitly — no hidden singletons.
///          Views call these directly; no view-model layer required.
/// Dependencies: Foundation, SwiftData, Tag, Item, Run, CompletedRun models.
/// Key concepts:
///   - Tags are app-wide — a single Tag may be referenced by Items across many Checklists.
///   - On delete, orphan cleanup runs across live entities (Item.tags, Run.hiddenTagIDs).
///   - CompletedRun snapshots are intentionally frozen and are never modified by this store.
///   - sortKey assignment uses the current maximum + 1 strategy (same as ChecklistStore).

import Foundation
import SwiftData

/// Stateless CRUD namespace for `Tag`.
///
/// Handles cross-entity cleanup on delete. CompletedRun snapshots are frozen
/// and are never touched — that invariant is enforced by design.
enum TagStore {

    // MARK: - Create

    /// Creates and persists a new Tag with an auto-assigned sortKey.
    ///
    /// The sortKey is set to one greater than the current maximum, so new tags
    /// appear at the end of the list.
    ///
    /// - Parameters:
    ///   - name: Display name for the tag.
    ///   - iconName: Design-token key for the icon; defaults to `"tag"`.
    ///   - colorHue: OKLCH hue angle (0–360); defaults to 300 (magenta-ish).
    ///   - context: The `ModelContext` in which to insert and save.
    /// - Returns: The newly created and persisted `Tag`.
    /// - Throws: If the sortKey fetch or the save fails.
    @discardableResult
    static func create(
        name: String,
        iconName: String = "tag",
        colorHue: Double = 300,
        in context: ModelContext
    ) throws -> Tag {
        let tag = Tag(
            name: name,
            iconName: iconName,
            colorHue: colorHue,
            sortKey: try nextSortKey(in: context)
        )
        context.insert(tag)
        try context.save()
        return tag
    }

    // MARK: - Update

    /// Patches one or more fields on a Tag and persists the change.
    ///
    /// Only non-nil arguments are applied, so callers can update a single field
    /// without passing the others.
    ///
    /// - Parameters:
    ///   - tag: The `Tag` to update.
    ///   - name: New display name, or nil to leave unchanged.
    ///   - iconName: New icon design-token key, or nil to leave unchanged.
    ///   - colorHue: New OKLCH hue angle, or nil to leave unchanged.
    ///   - context: The `ModelContext` to save into.
    /// - Throws: If the save fails.
    static func update(
        _ tag: Tag,
        name: String? = nil,
        iconName: String? = nil,
        colorHue: Double? = nil,
        in context: ModelContext
    ) throws {
        if let name { tag.name = name }
        if let iconName { tag.iconName = iconName }
        if let colorHue { tag.colorHue = colorHue }
        try context.save()
    }

    // MARK: - Delete

    /// Deletes a Tag and removes all references to it from live entities.
    ///
    /// Cleanup order:
    ///   1. Remove tag from every `Item.tags` array.
    ///   2. Remove the tag's UUID from every `Run.hiddenTagIDs` array.
    ///   3. Delete the `Tag` record itself.
    ///
    /// CompletedRun snapshots are intentionally left untouched — they are frozen
    /// historical records and must not be mutated by structural edits.
    ///
    /// SwiftData cannot cascade across UUID references, so orphan cleanup is
    /// done explicitly here before saving.
    ///
    /// - Parameters:
    ///   - tag: The `Tag` to delete.
    ///   - context: The `ModelContext` to delete from and save.
    /// - Throws: If the fetch or save fails.
    static func delete(_ tag: Tag, in context: ModelContext) throws {
        let tagID = tag.id

        // Remove from all Items' tag arrays.
        let items = try context.fetch(FetchDescriptor<Item>())
        for item in items {
            if item.tags?.contains(where: { $0.id == tagID }) == true {
                item.tags?.removeAll { $0.id == tagID }
            }
        }

        // Remove from all live Runs' hiddenTagIDs arrays.
        let runs = try context.fetch(FetchDescriptor<Run>())
        for run in runs where run.hiddenTagIDs.contains(tagID) {
            run.hiddenTagIDs.removeAll { $0 == tagID }
        }

        // CompletedRun snapshots are frozen — do NOT touch.
        context.delete(tag)
        try context.save()
    }

    // MARK: - Queries

    /// Returns the number of Items across all Checklists that reference this Tag.
    ///
    /// Useful for showing a usage badge in tag management UI and for confirming
    /// deletion impact to the user before they proceed.
    ///
    /// - Parameters:
    ///   - tag: The `Tag` to count usage for.
    ///   - context: The `ModelContext` to query.
    /// - Returns: The count of `Item` objects whose `tags` array contains `tag`.
    static func usageCount(for tag: Tag, in context: ModelContext) -> Int {
        // Traverse via Checklist → items to avoid in-memory faulting issues on
        // the many-to-many Item.tags relationship (which has no explicit inverse).
        // All Checklists are fetched; their items relationships are already tracked
        // in the context identity map, so tag membership reads correctly.
        //
        // Items with checklist == nil are excluded from the count. In normal operation
        // this is safe: Checklist.items uses a cascade delete rule, so any Item without
        // a Checklist is already an orphan awaiting GC and will never appear in the UI.
        let tagID = tag.id
        let lists = (try? context.fetch(FetchDescriptor<Checklist>())) ?? []
        return lists.reduce(0) { count, list in
            let matching = list.items?.filter { item in
                item.tags?.contains(where: { $0.id == tagID }) == true
            } ?? []
            return count + matching.count
        }
    }

    // MARK: - Private

    /// Computes the next sortKey for a new Tag by reading the highest existing
    /// sortKey and incrementing it.
    ///
    /// - Parameter context: The `ModelContext` to fetch from.
    /// - Returns: One greater than the current maximum sortKey, or 0 if no tags exist.
    /// - Throws: If the fetch fails.
    private static func nextSortKey(in context: ModelContext) throws -> Int {
        var descriptor = FetchDescriptor<Tag>(
            sortBy: [SortDescriptor(\.sortKey, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return ((try context.fetch(descriptor)).first?.sortKey ?? -1) + 1
    }
}

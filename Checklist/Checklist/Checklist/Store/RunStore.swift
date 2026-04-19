/// RunStore.swift
/// Purpose: Stateless operations on live Run objects — start, rename, toggle
///          check state, toggle ignore, hide/show tags, complete (→ CompletedRun),
///          and discard. Every function takes a ModelContext explicitly.
/// Dependencies: Foundation, SwiftData, Run, Check, CompletedRun,
///               CompletedRunBuilder, StoreError.
/// Key concepts:
///   - Multiple live Runs can coexist per Checklist (e.g., two concurrent trips).
///   - toggleCheck cycles: no check → .complete → no check.
///     setIgnored handles .ignored state separately, without cycling through complete.
///   - complete() delegates snapshot creation to CompletedRunBuilder, inserts a
///     CompletedRun, then deletes the live Run atomically in one save.
///   - StoreError.orphanedRun is thrown by complete() when the Run has no checklist,
///     which should never happen in practice but is guarded defensively.

import Foundation
import SwiftData

/// Stateless namespace for operations on live `Run` objects.
///
/// All methods take a `ModelContext` explicitly — no hidden singletons or
/// shared state. Views call these directly; no view-model layer required.
enum RunStore {

    // MARK: - Lifecycle

    /// Creates a new live `Run` attached to the given `Checklist` and persists it.
    ///
    /// - Parameters:
    ///   - list: The `Checklist` to run.
    ///   - name: Optional user label for this particular usage (e.g., "Tokyo Trip").
    ///   - context: The `ModelContext` to insert and save into.
    /// - Returns: The newly created and persisted `Run`.
    /// - Throws: If the save fails.
    @discardableResult
    static func startRun(on list: Checklist, name: String? = nil, in context: ModelContext) throws -> Run {
        let run = Run(checklist: list, name: name)
        context.insert(run)
        try context.save()
        return run
    }

    /// Renames a live `Run` and persists the change.
    ///
    /// Passing an empty string is treated as clearing the name (sets it to nil).
    ///
    /// - Parameters:
    ///   - run: The `Run` to rename.
    ///   - name: New label, or nil / empty string to clear.
    ///   - context: The `ModelContext` to save into.
    /// - Throws: If the save fails.
    static func rename(_ run: Run, to name: String?, in context: ModelContext) throws {
        run.name = name?.isEmpty == true ? nil : name
        try context.save()
    }

    /// Deletes a live `Run` without creating a `CompletedRun` record.
    ///
    /// Use this when the user explicitly abandons a run in progress. Cascade
    /// deletion on `Run.checks` removes all associated `Check` records.
    ///
    /// - Parameters:
    ///   - run: The `Run` to discard.
    ///   - context: The `ModelContext` to delete from and save.
    /// - Throws: If the save fails.
    static func discard(_ run: Run, in context: ModelContext) throws {
        context.delete(run)
        try context.save()
    }

    /// Completes a live `Run`: creates a frozen `CompletedRun` snapshot, then
    /// deletes the live `Run`. Both changes are committed in a single save.
    ///
    /// - Parameters:
    ///   - run: The `Run` to complete. Must have a non-nil `checklist`.
    ///   - context: The `ModelContext` to insert/delete from and save.
    /// - Throws: `StoreError.orphanedRun` if `run.checklist` is nil.
    ///           Also throws if the save fails.
    static func complete(_ run: Run, in context: ModelContext) throws {
        guard let list = run.checklist else {
            // Guard is defensive — RunStore should never be called with an orphaned
            // Run, but we throw rather than silently lose data.
            throw StoreError.orphanedRun
        }
        let snapshot = CompletedRunBuilder.snapshot(for: run, checklist: list)
        let completed = CompletedRun(
            checklist: list,
            name: run.name,
            startedAt: run.startedAt,
            completedAt: Date()
        )
        completed.snapshot = snapshot
        context.insert(completed)
        context.delete(run)
        try context.save()
    }

    // MARK: - Per-item check state

    /// Toggles the check state for one item within a run.
    ///
    /// Cycle: no `Check` record → `.complete` → (record deleted, back to no record).
    /// If the existing record has state `.ignored`, it is switched to `.complete`
    /// (use `setIgnored` to clear ignored state instead).
    ///
    /// - Parameters:
    ///   - run: The `Run` to update.
    ///   - itemID: The `UUID` of the `Item` to toggle.
    ///   - context: The `ModelContext` to insert/delete from and save.
    /// - Throws: If the save fails.
    static func toggleCheck(run: Run, itemID: UUID, in context: ModelContext) throws {
        if let existing = run.checks?.first(where: { $0.itemID == itemID }) {
            if existing.state == .complete {
                // Already complete — cycle back to unchecked by removing the record.
                context.delete(existing)
            } else {
                // Any other state (e.g., ignored) transitions to complete on tap.
                existing.state = .complete
            }
        } else {
            // No existing check — create a new one in the complete state.
            let check = Check(itemID: itemID, state: .complete)
            check.run = run
            context.insert(check)
        }
        try context.save()
    }

    /// Explicitly sets or clears the `.ignored` state for one item within a run.
    ///
    /// Unlike `toggleCheck`, this does not cycle through `.complete`. Passing
    /// `ignored: false` removes the `Check` record entirely (same as unchecked).
    ///
    /// - Parameters:
    ///   - run: The `Run` to update.
    ///   - itemID: The `UUID` of the `Item` to set ignored on.
    ///   - ignored: `true` to set the item's state to `.ignored`; `false` to clear it.
    ///   - context: The `ModelContext` to insert/delete from and save.
    /// - Throws: If the save fails.
    static func setIgnored(run: Run, itemID: UUID, to ignored: Bool, in context: ModelContext) throws {
        if ignored {
            if let existing = run.checks?.first(where: { $0.itemID == itemID }) {
                // Reuse the existing Check record rather than inserting a duplicate.
                existing.state = .ignored
            } else {
                let check = Check(itemID: itemID, state: .ignored)
                check.run = run
                context.insert(check)
            }
        } else if let existing = run.checks?.first(where: { $0.itemID == itemID }) {
            // Clear ignored → unchecked by removing the Check record.
            context.delete(existing)
        }
        try context.save()
    }

    // MARK: - View-only filters

    /// Toggles a tag's hidden/visible state within a run's view.
    ///
    /// If the tag UUID is already in `run.hiddenTagIDs` it is removed (tag
    /// becomes visible); otherwise it is appended (tag is hidden).
    ///
    /// - Parameters:
    ///   - run: The `Run` to update.
    ///   - tagID: The `UUID` of the `Tag` to toggle.
    ///   - context: The `ModelContext` to save into.
    /// - Throws: If the save fails.
    static func toggleHideTag(run: Run, tagID: UUID, in context: ModelContext) throws {
        if run.hiddenTagIDs.contains(tagID) {
            run.hiddenTagIDs.removeAll { $0 == tagID }
        } else {
            run.hiddenTagIDs.append(tagID)
        }
        try context.save()
    }
}

// MARK: - Errors

/// Errors that `RunStore` operations can throw.
enum StoreError: Error {
    /// Thrown when `complete(_:in:)` is called on a `Run` whose `checklist`
    /// relationship is nil. This should not happen in normal app flow.
    case orphanedRun
}

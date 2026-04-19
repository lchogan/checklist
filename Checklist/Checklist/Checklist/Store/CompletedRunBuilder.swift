/// CompletedRunBuilder.swift
/// Purpose: Converts a live Run + its Checklist into a frozen CompletedRunSnapshot.
/// Dependencies: Foundation, Run, Checklist, CompletedRunSnapshot, ItemSnapshot,
///               TagSnapshot, CheckState.
/// Key concepts:
///   - Pure function — no SwiftData side effects, no context required.
///   - Items are sorted by sortKey so snapshot preserves display order.
///   - Only tags actually referenced by items are included in the snapshot,
///     keeping the blob lean and preventing stale tag pollution.
///   - Called exclusively by RunStore.complete before deleting the live Run.

import Foundation

/// Builds a `CompletedRunSnapshot` from a live `Run` and its owning `Checklist`.
///
/// All methods are pure: they read from model objects but never insert, delete,
/// or save via a `ModelContext`. Callers are responsible for persisting the
/// resulting snapshot on a `CompletedRun`.
enum CompletedRunBuilder {

    /// Produces a frozen snapshot of the given run's state at the moment of call.
    ///
    /// - Parameters:
    ///   - run: The live `Run` being completed. Provides check records and hidden
    ///     tag IDs.
    ///   - checklist: The `Checklist` owning the run. Provides items and their tags.
    /// - Returns: A `CompletedRunSnapshot` containing ordered item snapshots,
    ///   deduplicated tag snapshots, a check-state map, and the hidden tag ID list.
    static func snapshot(for run: Run, checklist: Checklist) -> CompletedRunSnapshot {
        // Sort items by sortKey so the snapshot preserves the same display order
        // the user saw during the run.
        let items = (checklist.items ?? []).sorted { $0.sortKey < $1.sortKey }

        let itemSnapshots: [ItemSnapshot] = items.map { item in
            ItemSnapshot(
                id: item.id,
                text: item.text,
                tagIDs: (item.tags ?? []).map(\.id),
                sortKey: item.sortKey
            )
        }

        // Collect only the tag UUIDs actually referenced by items so the snapshot
        // stays lean; globally-defined tags not used on this checklist are excluded.
        let referencedTagIDs = Set(itemSnapshots.flatMap(\.tagIDs))

        // Deduplicate tags by id using a dictionary, then sort by name for stable
        // ordering independent of insertion order.
        let tagSnapshots: [TagSnapshot] = items
            .flatMap { $0.tags ?? [] }
            .reduce(into: [UUID: TagSnapshot]()) { dict, tag in
                guard referencedTagIDs.contains(tag.id), dict[tag.id] == nil else { return }
                dict[tag.id] = TagSnapshot(
                    id: tag.id,
                    name: tag.name,
                    iconName: tag.iconName,
                    colorHue: tag.colorHue
                )
            }
            .values
            .sorted { $0.name < $1.name }

        // Build the check-state map: itemID → state. Items absent from the map
        // were incomplete when the run was completed.
        let checks: [UUID: CheckState] = (run.checks ?? []).reduce(into: [:]) { dict, check in
            dict[check.itemID] = check.state
        }

        return CompletedRunSnapshot(
            items: itemSnapshots,
            tags: tagSnapshots,
            checks: checks,
            hiddenTagIDs: run.hiddenTagIDs
        )
    }
}

/// HistoryRoute.swift
/// Purpose: Hashable value types that NavigationStack uses to route to
///   HistoryView. `HistoryScope` carries an optional Checklist UUID —
///   `.allLists` for the global feed, `.checklist(id)` for per-list.
/// Dependencies: Foundation.
/// Key concepts:
///   - Declaring `scope` as a Hashable struct (not a raw UUID?) lets us add
///     future filter dimensions (e.g. date range) without changing the
///     navigationDestination signature.

import Foundation

/// Navigation value pushed onto the root NavigationPath to open `HistoryView`.
struct HistoryScope: Hashable {
    /// When non-nil, the history feed is scoped to that Checklist only. Nil
    /// means the global feed ("All runs").
    let checklistID: UUID?

    static let allLists = HistoryScope(checklistID: nil)
}

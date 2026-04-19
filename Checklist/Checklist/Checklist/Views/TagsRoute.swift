/// TagsRoute.swift
/// Purpose: Hashable marker used by NavigationStack to route to TagsView.
/// Dependencies: Foundation.
/// Key concepts:
///   - A single-case enum keeps the route identity stable across pushes so
///     `path.append(TagsDestination.root)` twice collapses to one.

import Foundation

/// Navigation value pushed onto the root NavigationPath to open `TagsView`.
enum TagsDestination: Hashable {
    case root
}

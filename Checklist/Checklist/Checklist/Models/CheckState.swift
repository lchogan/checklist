/// CheckState.swift
/// Purpose: Enum representing the state of a Check in a Run.
/// Dependencies: Foundation (Codable).
/// Key concepts:
///   - Items with no Check are "incomplete" by omission.
///   - `.complete` means the item has been checked in this run.
///   - `.ignored` is a per-run skip that doesn't count toward completion math.

import Foundation

/// The state of a Check in a Run. Items with no Check are "incomplete" by
/// omission; a Check with `.complete` is checked; `.ignored` is a per-run
/// skip that doesn't count toward completion math.
enum CheckState: String, Codable, Equatable {
    case complete
    case ignored
}

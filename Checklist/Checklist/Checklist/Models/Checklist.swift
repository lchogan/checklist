/// Checklist.swift
/// Purpose: Minimal stub so that `ChecklistCategory.checklists` inverse relationship compiles.
/// Dependencies: SwiftData, ChecklistCategory.
/// Key concepts: Forward declaration stub — full implementation arrives in Task 1.3.
///
/// [VERIFY] Replace the entire body in Task 1.3 with the complete Checklist model.

import Foundation
import SwiftData

// Stub — full implementation in Task 1.3. Kept minimal so `ChecklistCategory.checklists`
// inverse-relationship compiles.
@Model
final class Checklist {
    var id: UUID = UUID()
    var name: String = ""

    /// Back-pointer to the containing ChecklistCategory.
    ///
    /// `deleteRule: .nullify` means deleting the Checklist does not cascade
    /// to the ChecklistCategory.
    @Relationship(deleteRule: .nullify) var category: ChecklistCategory?

    init(name: String) {
        self.name = name
    }
}

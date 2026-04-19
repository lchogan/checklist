/// Item.swift
/// Purpose: Minimal stub so that Checklist.items inverse relationship compiles.
/// Dependencies: SwiftData, Checklist.
/// Key concepts: Forward declaration stub — full implementation arrives in Task 1.4.
///
/// [VERIFY] Replace the entire body in Task 1.4 with the complete Item model.

import Foundation
import SwiftData

@Model
final class Item {
    var id: UUID = UUID()
    var text: String = ""

    @Relationship(deleteRule: .nullify) var checklist: Checklist?

    init(text: String) { self.text = text }
}

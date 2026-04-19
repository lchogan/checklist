/// Check.swift
/// Purpose: Minimal stub so that Run.checks inverse relationship compiles.
/// Dependencies: SwiftData, Run.
/// Key concepts: Forward declaration stub — full implementation arrives in Task 1.6.
///
/// [VERIFY] Replace the entire body in Task 1.6 with the complete Check model.

import Foundation
import SwiftData

@Model
final class Check {
    var id: UUID = UUID()
    var itemID: UUID = UUID()

    @Relationship(deleteRule: .nullify) var run: Run?

    init(itemID: UUID) { self.itemID = itemID }
}

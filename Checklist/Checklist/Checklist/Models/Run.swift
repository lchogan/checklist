/// Run.swift
/// Purpose: Minimal stub so that Checklist.runs inverse relationship compiles.
/// Dependencies: SwiftData, Checklist.
/// Key concepts: Forward declaration stub — full implementation arrives in Task 1.5.
///
/// [VERIFY] Replace the entire body in Task 1.5 with the complete Run model.

import Foundation
import SwiftData

@Model
final class Run {
    var id: UUID = UUID()
    var startedAt: Date = Date()

    @Relationship(deleteRule: .nullify) var checklist: Checklist?

    init(checklist: Checklist) { self.checklist = checklist }
}

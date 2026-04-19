/// CompletedRun.swift
/// Purpose: Minimal stub so that Checklist.completedRuns inverse relationship compiles.
/// Dependencies: SwiftData, Checklist.
/// Key concepts: Forward declaration stub — full implementation arrives in Task 1.7.
///
/// [VERIFY] Replace the entire body in Task 1.7 with the complete CompletedRun model.

import Foundation
import SwiftData

@Model
final class CompletedRun {
    var id: UUID = UUID()
    var completedAt: Date = Date()

    @Relationship(deleteRule: .nullify) var checklist: Checklist?

    init(checklist: Checklist) { self.checklist = checklist }
}

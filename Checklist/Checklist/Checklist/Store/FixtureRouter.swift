/// FixtureRouter.swift
/// Purpose: Parses `checklist://seed/<fixture>` URLs into a SeedStore.Fixture
///   and swaps the running app's ModelContainer to the seeded fixture.
///   Used by scripts/capture_states.sh + manual QA.
/// Dependencies: Foundation, SwiftData, SeedStore.
/// Key concepts:
///   - Pure parse function returns .some(fixture) or nil for unknown / malformed.
///   - DEBUG builds only — release builds return nil regardless (guarded at call site).

import Foundation
import SwiftData

enum FixtureRouter {

    /// Parses `checklist://seed/<fixture>` into a SeedStore.Fixture.
    /// Returns nil for URLs with a different scheme, missing path, or unknown name.
    static func fixture(from url: URL) -> SeedStore.Fixture? {
        guard url.scheme == "checklist" else { return nil }
        guard url.host == "seed" else { return nil }
        let name = url.lastPathComponent
        switch name {
        case "empty":           return .empty
        case "oneList":         return .oneList
        case "seededMulti":     return .seededMulti
        case "historicalRuns":  return .historicalRuns
        case "nearCompleteRun": return .nearCompleteRun
        default:                return nil
        }
    }
}

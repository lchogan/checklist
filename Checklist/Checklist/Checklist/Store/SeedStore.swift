/// SeedStore.swift
/// Purpose: Builds in-memory ModelContainers pre-populated with named fixtures.
///          Used by both unit tests and SwiftUI previews so any prototype-captured
///          state can be reproduced on demand.
/// Dependencies: Foundation, SwiftData, CategoryStore, TagStore, ChecklistStore,
///               RunStore, CompletedRunBuilder, all v4 models.
/// Key concepts:
///   - Each container is in-memory and CloudKit-disabled (cloudKitDatabase: .none)
///     to prevent the loadIssueModelContainer crash that occurs when the app has a
///     CloudKit entitlement but no CloudKit database is configured at test/preview time.
///   - One `Fixture` case per distinct UI state; cases align with prototype captures
///     in docs/superpowers/prototype-captures/index.md.
///   - `seedMulti` is shared between `.seededMulti`, `.historicalRuns`, and
///     `.nearCompleteRun` to keep fixture data consistent.

import Foundation
import SwiftData

/// Builds in-memory ModelContainers pre-populated with named fixtures. Used by
/// both unit tests and SwiftUI previews. One case per state in
/// docs/superpowers/prototype-captures/index.md so the visual-diff loop can
/// reproduce any captured state.
enum SeedStore {

    // MARK: - Fixture cases

    /// Distinct app states that can be seeded into an in-memory container.
    enum Fixture {
        /// No data at all — blank slate.
        case empty
        /// A single checklist with a few items; good for basic layout previews.
        case oneList
        /// Multiple checklists, tags, categories, and one live run.
        case seededMulti
        /// Everything in `.seededMulti` plus five historical `CompletedRun` records.
        case historicalRuns
        /// One checklist with a live run where all but the last item are checked.
        case nearCompleteRun
    }

    // MARK: - Schema

    /// All persistent model types used by the v4 schema.
    ///
    /// Must stay in sync with the app's actual schema. Order does not matter for
    /// `Schema`, but keeping it alphabetical aids future diffs.
    static let allModels: [any PersistentModel.Type] = [
        ChecklistCategory.self, Tag.self, Checklist.self, Item.self,
        Run.self, Check.self, CompletedRun.self,
    ]

    // MARK: - Public API

    /// Creates an in-memory `ModelContainer` pre-populated with the given fixture.
    ///
    /// The container uses `cloudKitDatabase: .none` to avoid the
    /// `loadIssueModelContainer` crash that occurs when a CloudKit entitlement is
    /// present but no CloudKit database is available (simulator / test environment).
    ///
    /// - Parameter fixture: The named fixture to seed into the container.
    /// - Returns: A populated `ModelContainer` ready for use in previews or tests.
    /// - Throws: If the container cannot be created or if any store operation fails.
    static func container(for fixture: Fixture) throws -> ModelContainer {
        let schema = Schema(allModels)
        let container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
        )
        let ctx = ModelContext(container)
        try populate(ctx, with: fixture)
        try ctx.save()
        return container
    }

    // MARK: - Private population

    /// Dispatches to the appropriate seeding logic for each fixture case.
    ///
    /// - Parameters:
    ///   - ctx: The `ModelContext` to populate.
    ///   - fixture: Which fixture to seed.
    /// - Throws: If any store operation or save fails.
    private static func populate(_ ctx: ModelContext, with fixture: Fixture) throws {
        switch fixture {
        case .empty:
            return

        case .oneList:
            let travel = try CategoryStore.create(name: "Travel", in: ctx)
            let trip = try ChecklistStore.create(name: "Road Trip", category: travel, in: ctx)
            try ["Charger", "Sunglasses", "Snacks"].forEach { _ = try ChecklistStore.addItem(text: $0, to: trip, in: ctx) }

        case .seededMulti:
            try seedMulti(ctx)

        case .historicalRuns:
            try seedMulti(ctx)
            let lists = try ctx.fetch(FetchDescriptor<Checklist>())
            if let morning = lists.first(where: { $0.name == "Morning Routine" }) {
                // Seed 5 completed historical runs, each one day further in the past.
                for i in 1...5 {
                    let started = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
                    let completed = CompletedRun(checklist: morning, name: nil, startedAt: started, completedAt: started)
                    // NOTE: Throwaway Run has no checks, so the resulting snapshot.checks is empty.
                    // Sufficient for fixtures that only need CompletedRun count; if future tests
                    // assert on historical check state, seed the temp Run with checks first.
                    completed.snapshot = CompletedRunBuilder.snapshot(
                        for: Run(checklist: morning), checklist: morning
                    )
                    ctx.insert(completed)
                }
            }

        case .nearCompleteRun:
            try seedMulti(ctx)
            // Delete ALL live runs seeded by seedMulti (including the Packing List run)
            // so the fixture has exactly one run — the near-complete gym one.
            let allRuns = try ctx.fetch(FetchDescriptor<Run>())
            for run in allRuns { ctx.delete(run) }
            try ctx.save()
            let lists = try ctx.fetch(FetchDescriptor<Checklist>())
            if let gym = lists.first(where: { $0.name == "Gym Bag" }) {
                let run = try RunStore.startRun(on: gym, in: ctx)
                // Check all items except the last one (sorted by sortKey ascending).
                let items = (gym.items ?? []).sorted { $0.sortKey < $1.sortKey }
                for item in items.dropLast() {
                    try RunStore.toggleCheck(run: run, itemID: item.id, in: ctx)
                }
            }
        }
    }

    /// Seeds the shared multi-checklist scenario used by `.seededMulti`,
    /// `.historicalRuns`, and `.nearCompleteRun`.
    ///
    /// Creates three categories, three tags, and four checklists — including one
    /// live run on "Packing List". `.nearCompleteRun` deletes all runs after calling
    /// this before starting a fresh gym run.
    ///
    /// - Parameter ctx: The `ModelContext` to insert into.
    /// - Throws: If any store operation fails.
    private static func seedMulti(_ ctx: ModelContext) throws {
        // Categories
        let travel = try CategoryStore.create(name: "Travel", in: ctx)
        let daily = try CategoryStore.create(name: "Daily", in: ctx)
        let home = try CategoryStore.create(name: "Home", in: ctx)

        // Tags
        let beach = try TagStore.create(name: "Beach", iconName: "sun", colorHue: 85, in: ctx)
        let snow = try TagStore.create(name: "Snow", iconName: "snow", colorHue: 250, in: ctx)
        let intl = try TagStore.create(name: "Intl", iconName: "plane", colorHue: 300, in: ctx)

        // Packing List — a travel checklist with tag-filtered items
        let packing = try ChecklistStore.create(name: "Packing List", category: travel, in: ctx)
        _ = try ChecklistStore.addItem(text: "Toothbrush", to: packing, in: ctx)
        _ = try ChecklistStore.addItem(text: "Passport", to: packing, tags: [intl], in: ctx)
        _ = try ChecklistStore.addItem(text: "Sandals", to: packing, tags: [beach], in: ctx)
        _ = try ChecklistStore.addItem(text: "Thermal layers", to: packing, tags: [snow], in: ctx)

        // Live run on Packing List so the run screen can be previewed.
        _ = try RunStore.startRun(on: packing, name: "Tokyo", in: ctx)

        // Morning Routine — a daily checklist with no live run (for history fixture).
        let morning = try ChecklistStore.create(name: "Morning Routine", category: daily, in: ctx)
        for item in ["Water first", "Stretch 5 min", "Make bed", "Journal"] {
            _ = try ChecklistStore.addItem(text: item, to: morning, in: ctx)
        }

        // Weekly Groceries — a home checklist.
        let groceries = try ChecklistStore.create(name: "Weekly Groceries", category: home, in: ctx)
        for item in ["Eggs", "Milk", "Coffee", "Pasta"] {
            _ = try ChecklistStore.addItem(text: item, to: groceries, in: ctx)
        }

        // Gym Bag — daily checklist. No live run seeded here; `.nearCompleteRun`
        // deletes all runs from seedMulti before starting its own.
        let gym = try ChecklistStore.create(name: "Gym Bag", category: daily, in: ctx)
        for item in ["Shoes", "Shorts", "Water bottle", "Headphones"] {
            _ = try ChecklistStore.addItem(text: item, to: gym, in: ctx)
        }
    }
}

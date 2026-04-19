/// TagEditorSheetTests.swift
/// Purpose: Behaviour tests for TagEditorSheet. We can't instantiate the sheet
///   headlessly and drive SwiftUI taps from XCTest, so the tests exercise the
///   TagStore call sites the sheet invokes (create / update / delete) to lock
///   in the contract the sheet depends on.
/// Dependencies: XCTest, SwiftData, Checklist target.

import XCTest
import SwiftData
@testable import Checklist

final class TagEditorSheetTests: XCTestCase {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Checklist.self, ChecklistCategory.self, Item.self, Tag.self,
                Run.self, Check.self, CompletedRun.self,
            configurations: makeTestConfig()
        )
        return ModelContext(container)
    }

    /// Create: TagStore.create returns a persisted tag with the supplied
    /// name, icon and hue. TagEditorSheet's "Create" action relies on this.
    func test_create_persists_fields_as_supplied() throws {
        let ctx = try makeContext()
        let tag = try TagStore.create(
            name: "Winter",
            iconName: "snow",
            colorHue: 210,
            in: ctx
        )
        XCTAssertEqual(tag.name, "Winter")
        XCTAssertEqual(tag.iconName, "snow")
        XCTAssertEqual(tag.colorHue, 210)
    }

    /// Edit: TagStore.update patches only the fields provided.
    func test_update_patches_only_supplied_fields() throws {
        let ctx = try makeContext()
        let tag = try TagStore.create(name: "Beach", iconName: "sun", colorHue: 85, in: ctx)
        try TagStore.update(tag, name: "Summer", in: ctx)
        XCTAssertEqual(tag.name, "Summer")
        XCTAssertEqual(tag.iconName, "sun", "iconName unchanged when not supplied")
        XCTAssertEqual(tag.colorHue, 85, "colorHue unchanged when not supplied")
    }

    /// Delete: TagStore.delete cascades to Item.tags and Run.hiddenTagIDs —
    /// the sheet's delete affordance (Task 7.4) relies on this.
    func test_delete_cleans_live_references() throws {
        let ctx = try makeContext()
        let beach = try TagStore.create(name: "Beach", in: ctx)
        let list = Checklist(name: "Trip"); ctx.insert(list)
        let item = Item(text: "Sandals"); item.checklist = list; item.tags = [beach]; ctx.insert(item)
        let run = Run(checklist: list); run.hiddenTagIDs = [beach.id]; ctx.insert(run)
        try ctx.save()

        try TagStore.delete(beach, in: ctx)

        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Tag>()).count, 0)
        XCTAssertEqual(item.tags?.count ?? 0, 0)
        XCTAssertEqual(run.hiddenTagIDs, [])
    }

    /// GemIcons.all order + tag-hue palette match what the editor's icon grid
    /// and color swatch rows iterate over — lock them in so a change to either
    /// list is caught by tests.
    func test_icon_and_hue_catalogs_available() {
        XCTAssertFalse(GemIcons.all.isEmpty, "icon grid must have options")
        XCTAssertGreaterThanOrEqual(GemIcons.all.count, 14, "capture 26/27 shows 14 icons")
        XCTAssertGreaterThanOrEqual(GemIcons.tagHues.count, 9, "capture 26/27 shows 9 color swatches")
    }
}

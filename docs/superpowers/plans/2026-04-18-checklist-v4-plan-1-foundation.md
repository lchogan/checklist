# Checklist v4 — Plan 1: Foundation (Phases 0–3)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reset the v3 codebase and establish the v4 foundation — all SwiftData models, the stateless Store layer, design tokens, and reusable UI components — so Plans 2 and 3 can build screens on top.

**Architecture:** Reset-in-place. Keep the Xcode project shell + `Purchases/` subsystem + assets + StoreKit config. Delete all v3 models and views. Build v4 models with `@Model`, business logic as stateless `Store` functions taking `ModelContext`, design tokens in `Theme.swift`, reusable views in `Design/Components/`. No view models, no screens yet (placeholder `ContentView` shows "Foundation complete").

**Tech Stack:** Swift 5.9+, SwiftUI, SwiftData (iOS 17+), XCTest, Xcode 15+.

**Spec:** `docs/superpowers/specs/2026-04-18-checklist-v4-redesign.md`
**Architecture:** `ARCHITECTURE.md` (v4)
**Visual refs:** `docs/superpowers/prototype-captures/`, `gem-screenshots/`

---

## Repo paths used throughout

- Repo root: `/Users/lukehogan/Library/Mobile Documents/com~apple~CloudDocs/Code/checklist` — every path below is relative to this.
- Xcode project: `Checklist/Checklist.xcodeproj`
- App sources: `Checklist/Checklist/`
- Tests target (to be created if missing): `Checklist/ChecklistTests/`

All `xcodebuild` commands assume PWD = repo root and use:
```
-scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

---

## Phase 0 — Reset

### Task 0.1: Archive stale v3 docs

**Files:**
- Move: `Checklist/Checklist/NAVIGATION_FLOW.md` → `docs/v3-archive/NAVIGATION_FLOW.md`
- Move: `Checklist/Checklist/PROFILE_FEATURES_README.md` → `docs/v3-archive/PROFILE_FEATURES_README.md`
- Move: `Checklist/Checklist/QUICK_START.md` → `docs/v3-archive/QUICK_START.md`

- [ ] **Step 1: Create archive dir and move docs**

```bash
mkdir -p docs/v3-archive
git mv "Checklist/Checklist/NAVIGATION_FLOW.md" docs/v3-archive/
git mv "Checklist/Checklist/PROFILE_FEATURES_README.md" docs/v3-archive/
git mv "Checklist/Checklist/QUICK_START.md" docs/v3-archive/
```

- [ ] **Step 2: Verify moves**

Run: `ls docs/v3-archive/`
Expected: 3 files listed.

- [ ] **Step 3: Commit**

```bash
git commit -m "chore: archive v3 docs to docs/v3-archive"
```

---

### Task 0.2: Delete v3 model and view files

**Files deleted:**
- `Checklist/Checklist/Models/Checklist.swift`
- `Checklist/Checklist/Models/ChecklistCategory.swift`
- `Checklist/Checklist/Models/ChecklistItem.swift`
- `Checklist/Checklist/Models/ItemStatus.swift`
- `Checklist/Checklist/Models/Tag.swift`
- `Checklist/Checklist/Views/*.swift` (all 11 files)

- [ ] **Step 1: Delete v3 model files**

```bash
git rm "Checklist/Checklist/Models/Checklist.swift"
git rm "Checklist/Checklist/Models/ChecklistCategory.swift"
git rm "Checklist/Checklist/Models/ChecklistItem.swift"
git rm "Checklist/Checklist/Models/ItemStatus.swift"
git rm "Checklist/Checklist/Models/Tag.swift"
```

- [ ] **Step 2: Delete v3 view files**

```bash
git rm "Checklist/Checklist/Views/AboutView.swift"
git rm "Checklist/Checklist/Views/CategoryManagementSheet.swift"
git rm "Checklist/Checklist/Views/ChecklistEditView.swift"
git rm "Checklist/Checklist/Views/ChecklistListView.swift"
git rm "Checklist/Checklist/Views/ChecklistRunView.swift"
git rm "Checklist/Checklist/Views/HelpView.swift"
git rm "Checklist/Checklist/Views/PaywallView.swift"
git rm "Checklist/Checklist/Views/PlanView.swift"
git rm "Checklist/Checklist/Views/ProfileView.swift"
git rm "Checklist/Checklist/Views/TagPickerSheet.swift"
git rm "Checklist/Checklist/Views/TutorialView.swift"
```

- [ ] **Step 3: Verify directories now empty**

Run: `ls Checklist/Checklist/Models/ Checklist/Checklist/Views/ 2>/dev/null; echo ok`
Expected: both directories empty (or gone); `ok` printed.

- [ ] **Step 4: Remove empty dirs from Xcode project reference**

Xcode project files reference individual source files, not folders. Deletion via `git rm` also updates the .pbxproj if the files weren't referenced as "group references". Verify with:

Run: `grep -E "(ChecklistCategory|ChecklistItem|ItemStatus|AboutView|TutorialView)" "Checklist/Checklist.xcodeproj/project.pbxproj" | wc -l`
Expected: 0. If non-zero, open Xcode and manually "Remove References" for the dangling entries; or edit the pbxproj with care.

**Note:** If pbxproj still references deleted files, the build will fail. Fix before committing.

---

### Task 0.3: Rewrite ChecklistApp.swift with minimal placeholder

**Files:**
- Modify: `Checklist/Checklist/ChecklistApp.swift` (replace schema array contents, inject placeholder view)

- [ ] **Step 1: Replace schema with empty placeholder + wire ContentView**

Write `Checklist/Checklist/ChecklistApp.swift`:

```swift
import SwiftUI
import SwiftData

@main
struct ChecklistApp: App {
    /// EntitlementManager is created first so StoreKitManager can reference it.
    @StateObject private var entitlementManager = EntitlementManager()

    var body: some Scene {
        WindowGroup {
            AppRoot(entitlementManager: entitlementManager)
        }
    }
}

/// Wires StoreKitManager to EntitlementManager and boots the SwiftData container.
private struct AppRoot: View {
    let entitlementManager: EntitlementManager
    @StateObject private var storeKit: StoreKitManager
    @State private var modelContainer: ModelContainer?

    init(entitlementManager: EntitlementManager) {
        self.entitlementManager = entitlementManager
        _storeKit = StateObject(
            wrappedValue: StoreKitManager(entitlementManager: entitlementManager)
        )
    }

    var body: some View {
        Group {
            if let container = modelContainer {
                ContentView()
                    .environmentObject(entitlementManager)
                    .environmentObject(storeKit)
                    .modelContainer(container)
            } else {
                ProgressView("Loading…")
            }
        }
        .onAppear { setupModelContainer() }
        .onChange(of: entitlementManager.isPremium) { _, _ in setupModelContainer() }
    }

    private func setupModelContainer() {
        do {
            // Phase 1 will add real models. For Phase 0 the schema is empty.
            let schema = Schema([])
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                cloudKitDatabase: entitlementManager.isPremium ? .automatic : .none
            )
            modelContainer = try ModelContainer(for: schema, configurations: configuration)
        } catch {
            print("Failed to create ModelContainer: \(error)")
        }
    }
}

/// Temporary placeholder until Phase 4 adds HomeView.
private struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Checklist")
                .font(.largeTitle.bold())
            Text("Foundation phase — UI coming in Plan 2.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Launch in simulator to verify placeholder renders**

```bash
xcrun simctl boot "iPhone 16 Pro" 2>/dev/null || true
APP_PATH=$(find .build -name "Checklist.app" -type d | head -1)
xcrun simctl install booted "$APP_PATH"
xcrun simctl launch booted com.lchogan.Checklist
sleep 2
xcrun simctl io booted screenshot /tmp/phase-0-placeholder.png
```

Expected: Screenshot shows "Checklist" + "Foundation phase — UI coming in Plan 2."

- [ ] **Step 4: Commit**

```bash
git add Checklist/Checklist/ChecklistApp.swift
git commit -m "refactor: reset ChecklistApp to minimal placeholder for v4 rebuild"
```

---

## Phase 1 — Data model (7 `@Model` classes + 1 enum + 2 snapshot structs)

### Prerequisite: ensure test target exists

- [ ] **Step 1: Check for existing test target**

Run: `ls Checklist/ChecklistTests/ 2>/dev/null || echo "no test target"`

- If "no test target" — create the unit test target in Xcode:
  1. Open `Checklist/Checklist.xcodeproj` in Xcode.
  2. File → New → Target → iOS → Unit Testing Bundle.
  3. Name: `ChecklistTests`. Project: Checklist. Target to be tested: Checklist.
  4. Save; close Xcode.
  5. Verify: `ls Checklist/ChecklistTests/` shows `ChecklistTests.swift`.

- [ ] **Step 2: Add a sanity test to confirm harness works**

Write `Checklist/ChecklistTests/ChecklistTests.swift` (replace generated contents):

```swift
import XCTest
@testable import Checklist

final class ChecklistTests: XCTestCase {
    func test_sanity() {
        XCTAssertEqual(1 + 1, 2)
    }
}
```

- [ ] **Step 3: Run tests**

```bash
xcodebuild test -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build 2>&1 | tail -10
```

Expected: `** TEST SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add Checklist/ChecklistTests/
git commit -m "test: add ChecklistTests target with sanity test"
```

---

### Task 1.1: Category model

**Files:**
- Create: `Checklist/Checklist/Models/Category.swift`
- Create: `Checklist/ChecklistTests/Models/CategoryTests.swift`

- [ ] **Step 1: Write the failing test**

Write `Checklist/ChecklistTests/Models/CategoryTests.swift`:

```swift
import XCTest
import SwiftData
@testable import Checklist

final class CategoryTests: XCTestCase {
    private func makeInMemoryContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Category.self, configurations: config)
        return ModelContext(container)
    }

    func test_init_with_name_stores_defaults() throws {
        let context = try makeInMemoryContext()
        let cat = Category(name: "Travel")
        context.insert(cat)

        XCTAssertEqual(cat.name, "Travel")
        XCTAssertEqual(cat.sortKey, 0)
        XCTAssertNotNil(cat.id)
        XCTAssertNotNil(cat.createdAt)
        XCTAssertEqual(cat.checklists, [])
    }

    func test_sortKey_can_be_set_at_init() throws {
        let context = try makeInMemoryContext()
        let cat = Category(name: "Daily", sortKey: 7)
        context.insert(cat)
        XCTAssertEqual(cat.sortKey, 7)
    }

    func test_persists_and_fetches() throws {
        let context = try makeInMemoryContext()
        let cat = Category(name: "Home")
        context.insert(cat)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Category>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "Home")
    }
}
```

- [ ] **Step 2: Run the test — confirm it fails (Category undefined)**

```bash
xcodebuild test -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build -only-testing:ChecklistTests/CategoryTests 2>&1 | tail -15
```

Expected: compile error "cannot find type 'Category' in scope".

- [ ] **Step 3: Implement Category**

Write `Checklist/Checklist/Models/Category.swift`:

```swift
import Foundation
import SwiftData

/// A top-level grouping for checklists. App-wide scope.
///
/// Dependencies: `Checklist` (inverse relationship).
@Model
final class Category {
    var id: UUID = UUID()
    var name: String = ""
    var sortKey: Int = 0
    var createdAt: Date = Date()

    @Relationship(deleteRule: .nullify, inverse: \Checklist.category)
    var checklists: [Checklist]? = []

    init(name: String, sortKey: Int = 0) {
        self.name = name
        self.sortKey = sortKey
    }
}
```

**Note:** This file references `Checklist` (the @Model), which doesn't exist yet. The build will fail until Task 1.3 lands. This is expected — SwiftData inverse relationships require forward declaration. We'll stub `Checklist` as a placeholder in Step 4 to make Phase 1 compile incrementally.

- [ ] **Step 4: Add forward-declaration stub for Checklist**

Write `Checklist/Checklist/Models/Checklist.swift` (will be fully implemented in Task 1.3):

```swift
import Foundation
import SwiftData

// Stub — full implementation in Task 1.3. Kept minimal so `Category.checklists`
// inverse-relationship compiles.
@Model
final class Checklist {
    var id: UUID = UUID()
    var name: String = ""

    @Relationship(deleteRule: .nullify) var category: Category?

    init(name: String) {
        self.name = name
    }
}
```

- [ ] **Step 5: Run tests — confirm pass**

```bash
xcodebuild test -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build -only-testing:ChecklistTests/CategoryTests 2>&1 | tail -10
```

Expected: `** TEST SUCCEEDED **`, 3 tests passed.

- [ ] **Step 6: Commit**

```bash
git add Checklist/Checklist/Models/Category.swift Checklist/Checklist/Models/Checklist.swift Checklist/ChecklistTests/Models/CategoryTests.swift
git commit -m "feat(model): add Category @Model with tests (stub Checklist forward-decl)"
```

---

### Task 1.2: Tag model

**Files:**
- Create: `Checklist/Checklist/Models/Tag.swift`
- Create: `Checklist/ChecklistTests/Models/TagTests.swift`

- [ ] **Step 1: Write the failing test**

Write `Checklist/ChecklistTests/Models/TagTests.swift`:

```swift
import XCTest
import SwiftData
@testable import Checklist

final class TagTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Tag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    func test_init_defaults() throws {
        let context = try makeContext()
        let tag = Tag(name: "Beach")
        context.insert(tag)

        XCTAssertEqual(tag.name, "Beach")
        XCTAssertEqual(tag.iconName, "tag")
        XCTAssertEqual(tag.colorHue, 300)
        XCTAssertEqual(tag.sortKey, 0)
        XCTAssertNotNil(tag.id)
    }

    func test_init_with_icon_and_color() throws {
        let context = try makeContext()
        let tag = Tag(name: "Snow", iconName: "snowflake", colorHue: 250)
        context.insert(tag)
        XCTAssertEqual(tag.iconName, "snowflake")
        XCTAssertEqual(tag.colorHue, 250)
    }
}
```

- [ ] **Step 2: Run — confirm it fails**

```bash
xcodebuild test -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build -only-testing:ChecklistTests/TagTests 2>&1 | tail -10
```

Expected: compile error "cannot find type 'Tag'".

- [ ] **Step 3: Implement Tag**

Write `Checklist/Checklist/Models/Tag.swift`:

```swift
import Foundation
import SwiftData

/// A filter label applied to items. App-wide scope — a tag can be referenced
/// by items across any checklist.
///
/// Key concepts:
/// - `colorHue` is an OKLCH hue angle (0–360). Chroma and lightness are applied
///   by Theme at render time so all tags have visually consistent saturation.
/// - `iconName` is a design-token key; see `Design/GemIcons.swift` for the map
///   to SF Symbols / custom glyphs.
@Model
final class Tag {
    var id: UUID = UUID()
    var name: String = ""
    var iconName: String = "tag"
    var colorHue: Double = 300
    var sortKey: Int = 0

    init(name: String, iconName: String = "tag", colorHue: Double = 300, sortKey: Int = 0) {
        self.name = name
        self.iconName = iconName
        self.colorHue = colorHue
        self.sortKey = sortKey
    }
}
```

- [ ] **Step 4: Run — confirm pass**

```bash
xcodebuild test -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build -only-testing:ChecklistTests/TagTests 2>&1 | tail -10
```

Expected: 2 tests passed.

- [ ] **Step 5: Commit**

```bash
git add Checklist/Checklist/Models/Tag.swift Checklist/ChecklistTests/Models/TagTests.swift
git commit -m "feat(model): add Tag @Model (app-wide scope) with tests"
```

---

### Task 1.3: Checklist model (replace stub with full implementation)

**Files:**
- Modify: `Checklist/Checklist/Models/Checklist.swift` (replace stub)
- Create: `Checklist/ChecklistTests/Models/ChecklistTests.swift`

- [ ] **Step 1: Write the failing test**

Write `Checklist/ChecklistTests/Models/ChecklistTests.swift`:

```swift
import XCTest
import SwiftData
@testable import Checklist

final class ChecklistModelTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Checklist.self, Category.self, Item.self, Run.self, CompletedRun.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    func test_init_defaults() throws {
        let context = try makeContext()
        let list = Checklist(name: "Packing List")
        context.insert(list)

        XCTAssertEqual(list.name, "Packing List")
        XCTAssertEqual(list.sortKey, 0)
        XCTAssertNil(list.category)
        XCTAssertEqual(list.items, [])
        XCTAssertEqual(list.runs, [])
        XCTAssertEqual(list.completedRuns, [])
    }

    func test_category_relationship_round_trip() throws {
        let context = try makeContext()
        let cat = Category(name: "Travel")
        let list = Checklist(name: "Packing List")
        list.category = cat
        context.insert(cat)
        context.insert(list)
        try context.save()

        XCTAssertEqual(list.category?.name, "Travel")
        XCTAssertEqual(cat.checklists?.count, 1)
        XCTAssertEqual(cat.checklists?.first?.name, "Packing List")
    }

    func test_category_nullify_on_delete() throws {
        let context = try makeContext()
        let cat = Category(name: "Travel")
        let list = Checklist(name: "Packing List")
        list.category = cat
        context.insert(cat)
        context.insert(list)
        try context.save()

        context.delete(cat)
        try context.save()

        XCTAssertNil(list.category)
    }
}
```

- [ ] **Step 2: Run — confirm it fails (Item, Run, CompletedRun undefined)**

```bash
xcodebuild test -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build -only-testing:ChecklistTests/ChecklistModelTests 2>&1 | tail -10
```

Expected: compile error — missing types.

- [ ] **Step 3: Add stubs for Item, Run, CompletedRun**

(Full implementations come in Tasks 1.4–1.7. Stubs make the inverse relationships in this task compile.)

Write `Checklist/Checklist/Models/Item.swift`:

```swift
import Foundation
import SwiftData

@Model
final class Item {
    var id: UUID = UUID()
    var text: String = ""

    @Relationship(deleteRule: .nullify) var checklist: Checklist?

    init(text: String) { self.text = text }
}
```

Write `Checklist/Checklist/Models/Run.swift`:

```swift
import Foundation
import SwiftData

@Model
final class Run {
    var id: UUID = UUID()
    var startedAt: Date = Date()

    @Relationship(deleteRule: .nullify) var checklist: Checklist?

    init(checklist: Checklist) { self.checklist = checklist }
}
```

Write `Checklist/Checklist/Models/CompletedRun.swift`:

```swift
import Foundation
import SwiftData

@Model
final class CompletedRun {
    var id: UUID = UUID()
    var completedAt: Date = Date()

    @Relationship(deleteRule: .nullify) var checklist: Checklist?

    init(checklist: Checklist) { self.checklist = checklist }
}
```

- [ ] **Step 4: Replace Checklist stub with full implementation**

Overwrite `Checklist/Checklist/Models/Checklist.swift`:

```swift
import Foundation
import SwiftData

/// A reusable checklist. Owns its items directly; Run/CompletedRun records
/// reference this shape.
///
/// Dependencies: Category (optional), Item/Run/CompletedRun (cascade).
/// Key concepts: structural edits (add/rename/reorder/delete item) mutate
/// this record and are immediately visible to every live Run.
@Model
final class Checklist {
    var id: UUID = UUID()
    var name: String = ""
    var sortKey: Int = 0
    var createdAt: Date = Date()

    @Relationship(deleteRule: .nullify) var category: Category?
    @Relationship(deleteRule: .cascade, inverse: \Item.checklist) var items: [Item]? = []
    @Relationship(deleteRule: .cascade, inverse: \Run.checklist) var runs: [Run]? = []
    @Relationship(deleteRule: .cascade, inverse: \CompletedRun.checklist) var completedRuns: [CompletedRun]? = []

    init(name: String) {
        self.name = name
    }
}
```

- [ ] **Step 5: Run — confirm pass**

```bash
xcodebuild test -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build -only-testing:ChecklistTests/ChecklistModelTests 2>&1 | tail -10
```

Expected: 3 tests passed.

- [ ] **Step 6: Commit**

```bash
git add Checklist/Checklist/Models/Checklist.swift Checklist/Checklist/Models/Item.swift Checklist/Checklist/Models/Run.swift Checklist/Checklist/Models/CompletedRun.swift Checklist/ChecklistTests/Models/ChecklistTests.swift
git commit -m "feat(model): add Checklist with full relationships (Item/Run/CompletedRun stubs)"
```

---

### Task 1.4: Item model (replace stub)

**Files:**
- Modify: `Checklist/Checklist/Models/Item.swift`
- Create: `Checklist/ChecklistTests/Models/ItemTests.swift`

- [ ] **Step 1: Write the failing test**

Write `Checklist/ChecklistTests/Models/ItemTests.swift`:

```swift
import XCTest
import SwiftData
@testable import Checklist

final class ItemTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Checklist.self, Item.self, Tag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    func test_init_defaults() throws {
        let context = try makeContext()
        let item = Item(text: "Toothbrush")
        context.insert(item)

        XCTAssertEqual(item.text, "Toothbrush")
        XCTAssertEqual(item.sortKey, 0)
        XCTAssertNil(item.checklist)
        XCTAssertEqual(item.tags, [])
    }

    func test_checklist_items_cascade_delete() throws {
        let context = try makeContext()
        let list = Checklist(name: "Trip")
        let item = Item(text: "Passport")
        item.checklist = list
        context.insert(list)
        context.insert(item)
        try context.save()

        context.delete(list)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Item>())
        XCTAssertTrue(fetched.isEmpty, "item should be cascade-deleted with its checklist")
    }

    func test_tags_many_to_many() throws {
        let context = try makeContext()
        let beach = Tag(name: "Beach")
        let snow = Tag(name: "Snow")
        let item = Item(text: "Boots")
        item.tags = [beach, snow]
        context.insert(beach)
        context.insert(snow)
        context.insert(item)
        try context.save()

        XCTAssertEqual(item.tags?.count, 2)
    }
}
```

- [ ] **Step 2: Run — confirm it fails (sortKey, tags not defined yet)**

```bash
xcodebuild test -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build -only-testing:ChecklistTests/ItemTests 2>&1 | tail -10
```

Expected: compile errors on `sortKey`, `tags`.

- [ ] **Step 3: Full Item implementation**

Overwrite `Checklist/Checklist/Models/Item.swift`:

```swift
import Foundation
import SwiftData

/// A single checklist item. Many-to-many with Tag. Ordered within a Checklist
/// via `sortKey`.
///
/// Key concept: an Item has no status field — check state lives in Run.checks,
/// keyed by itemID.
@Model
final class Item {
    var id: UUID = UUID()
    var text: String = ""
    var sortKey: Int = 0

    @Relationship(deleteRule: .nullify) var checklist: Checklist?
    @Relationship var tags: [Tag]? = []

    init(text: String, sortKey: Int = 0) {
        self.text = text
        self.sortKey = sortKey
    }
}
```

- [ ] **Step 4: Run — confirm pass**

```bash
xcodebuild test -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build -only-testing:ChecklistTests/ItemTests 2>&1 | tail -10
```

Expected: 3 tests passed.

- [ ] **Step 5: Commit**

```bash
git add Checklist/Checklist/Models/Item.swift Checklist/ChecklistTests/Models/ItemTests.swift
git commit -m "feat(model): add Item @Model with tag many-to-many"
```

---

### Task 1.5: Run model (replace stub)

**Files:**
- Modify: `Checklist/Checklist/Models/Run.swift`
- Create: `Checklist/ChecklistTests/Models/RunTests.swift`

- [ ] **Step 1: Write the failing test**

Write `Checklist/ChecklistTests/Models/RunTests.swift`:

```swift
import XCTest
import SwiftData
@testable import Checklist

final class RunTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Checklist.self, Run.self, Check.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    func test_init_defaults() throws {
        let context = try makeContext()
        let list = Checklist(name: "Daily")
        let run = Run(checklist: list)
        context.insert(list)
        context.insert(run)

        XCTAssertEqual(run.checklist?.name, "Daily")
        XCTAssertNil(run.name)
        XCTAssertNotNil(run.startedAt)
        XCTAssertEqual(run.hiddenTagIDs, [])
        XCTAssertEqual(run.checks, [])
    }

    func test_init_with_name() throws {
        let context = try makeContext()
        let list = Checklist(name: "Packing")
        let run = Run(checklist: list, name: "Tokyo")
        context.insert(list)
        context.insert(run)
        XCTAssertEqual(run.name, "Tokyo")
    }
}
```

- [ ] **Step 2: Run — confirm fail (Check missing + missing properties)**

```bash
xcodebuild test -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build -only-testing:ChecklistTests/RunTests 2>&1 | tail -10
```

- [ ] **Step 3: Stub Check so Run's inverse compiles**

Write `Checklist/Checklist/Models/Check.swift` (placeholder; full impl in Task 1.6):

```swift
import Foundation
import SwiftData

@Model
final class Check {
    var id: UUID = UUID()
    var itemID: UUID = UUID()

    @Relationship(deleteRule: .nullify) var run: Run?

    init(itemID: UUID) { self.itemID = itemID }
}
```

- [ ] **Step 4: Full Run implementation**

Overwrite `Checklist/Checklist/Models/Run.swift`:

```swift
import Foundation
import SwiftData

/// A live usage of a Checklist. Holds per-usage state: which items are
/// checked/ignored, which tags are hidden from view. Multiple live Runs can
/// exist per Checklist (e.g., concurrent trips on one Packing List).
///
/// Key concept: completing a Run creates a CompletedRun snapshot and deletes
/// the Run record (see RunStore.complete).
@Model
final class Run {
    var id: UUID = UUID()
    var name: String? = nil
    var startedAt: Date = Date()
    var hiddenTagIDs: [UUID] = []

    @Relationship(deleteRule: .nullify) var checklist: Checklist?
    @Relationship(deleteRule: .cascade, inverse: \Check.run) var checks: [Check]? = []

    init(checklist: Checklist, name: String? = nil) {
        self.checklist = checklist
        self.name = name
    }
}
```

- [ ] **Step 5: Run — confirm pass**

```bash
xcodebuild test -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build -only-testing:ChecklistTests/RunTests 2>&1 | tail -10
```

Expected: 2 tests passed.

- [ ] **Step 6: Commit**

```bash
git add Checklist/Checklist/Models/Run.swift Checklist/Checklist/Models/Check.swift Checklist/ChecklistTests/Models/RunTests.swift
git commit -m "feat(model): add Run with hiddenTagIDs and Check relationship (Check stub)"
```

---

### Task 1.6: Check model + CheckState enum (replace stub)

**Files:**
- Modify: `Checklist/Checklist/Models/Check.swift`
- Create: `Checklist/Checklist/Models/CheckState.swift`
- Create: `Checklist/ChecklistTests/Models/CheckTests.swift`

- [ ] **Step 1: Write the failing test**

Write `Checklist/ChecklistTests/Models/CheckTests.swift`:

```swift
import XCTest
import SwiftData
@testable import Checklist

final class CheckTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Check.self, Run.self, Checklist.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    func test_init_defaults_to_complete() throws {
        let context = try makeContext()
        let itemID = UUID()
        let check = Check(itemID: itemID)
        context.insert(check)

        XCTAssertEqual(check.itemID, itemID)
        XCTAssertEqual(check.state, .complete)
    }

    func test_state_setter_updates_timestamp() throws {
        let context = try makeContext()
        let check = Check(itemID: UUID())
        context.insert(check)
        let before = check.updatedAt

        // Flip to ignored
        check.state = .ignored
        XCTAssertEqual(check.state, .ignored)
        XCTAssertGreaterThanOrEqual(check.updatedAt, before)
    }

    func test_checkstate_codable_roundtrip() throws {
        let value: CheckState = .ignored
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(CheckState.self, from: data)
        XCTAssertEqual(decoded, .ignored)
    }
}
```

- [ ] **Step 2: Run — confirm fail (state, updatedAt not on stub; CheckState missing)**

```bash
xcodebuild test -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build -only-testing:ChecklistTests/CheckTests 2>&1 | tail -10
```

- [ ] **Step 3: Implement CheckState**

Write `Checklist/Checklist/Models/CheckState.swift`:

```swift
import Foundation

/// The state of a Check in a Run. Items with no Check are "incomplete" by
/// omission; a Check with `.complete` is checked; `.ignored` is a per-run
/// skip that doesn't count toward completion math.
enum CheckState: String, Codable {
    case complete
    case ignored
}
```

- [ ] **Step 4: Full Check implementation**

Overwrite `Checklist/Checklist/Models/Check.swift`:

```swift
import Foundation
import SwiftData

/// One entry in a Run's check map: Item X has state Y as of time T.
///
/// `itemID` is a UUID (not a relationship) so Item deletion doesn't leave a
/// phantom — RunStore.clearChecks(forItemID:) handles cleanup explicitly.
@Model
final class Check {
    var id: UUID = UUID()
    var itemID: UUID = UUID()
    var stateRaw: String = CheckState.complete.rawValue
    var updatedAt: Date = Date()

    @Relationship(deleteRule: .nullify) var run: Run?

    var state: CheckState {
        get { CheckState(rawValue: stateRaw) ?? .complete }
        set {
            stateRaw = newValue.rawValue
            updatedAt = Date()
        }
    }

    init(itemID: UUID, state: CheckState = .complete) {
        self.itemID = itemID
        self.stateRaw = state.rawValue
    }
}
```

- [ ] **Step 5: Run — confirm pass**

```bash
xcodebuild test -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build -only-testing:ChecklistTests/CheckTests 2>&1 | tail -10
```

Expected: 3 tests passed.

- [ ] **Step 6: Commit**

```bash
git add Checklist/Checklist/Models/Check.swift Checklist/Checklist/Models/CheckState.swift Checklist/ChecklistTests/Models/CheckTests.swift
git commit -m "feat(model): add Check and CheckState with state+updatedAt accessor"
```

---

### Task 1.7: CompletedRun + snapshot structs (replace stub)

**Files:**
- Modify: `Checklist/Checklist/Models/CompletedRun.swift`
- Create: `Checklist/Checklist/Models/CompletedRunSnapshot.swift`
- Create: `Checklist/ChecklistTests/Models/CompletedRunTests.swift`

- [ ] **Step 1: Write the failing test**

Write `Checklist/ChecklistTests/Models/CompletedRunTests.swift`:

```swift
import XCTest
import SwiftData
@testable import Checklist

final class CompletedRunTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: CompletedRun.self, Checklist.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    func test_init_defaults_empty_snapshot() throws {
        let context = try makeContext()
        let list = Checklist(name: "Daily")
        let completed = CompletedRun(checklist: list)
        context.insert(list)
        context.insert(completed)

        XCTAssertEqual(completed.snapshot.items.count, 0)
        XCTAssertEqual(completed.snapshot.tags.count, 0)
        XCTAssertEqual(completed.snapshot.checks.count, 0)
        XCTAssertEqual(completed.snapshot.hiddenTagIDs.count, 0)
    }

    func test_snapshot_round_trip() throws {
        let context = try makeContext()
        let list = Checklist(name: "Trip")
        let completed = CompletedRun(checklist: list)
        context.insert(list)
        context.insert(completed)

        let itemID = UUID()
        let tagID = UUID()
        let snapshot = CompletedRunSnapshot(
            items: [ItemSnapshot(id: itemID, text: "Passport", tagIDs: [tagID], sortKey: 0)],
            tags: [TagSnapshot(id: tagID, name: "Intl", iconName: "plane", colorHue: 300)],
            checks: [itemID: .complete],
            hiddenTagIDs: []
        )
        completed.snapshot = snapshot
        try context.save()

        XCTAssertEqual(completed.snapshot.items.first?.text, "Passport")
        XCTAssertEqual(completed.snapshot.tags.first?.name, "Intl")
        XCTAssertEqual(completed.snapshot.checks[itemID], .complete)
    }

    func test_cascade_from_checklist() throws {
        let context = try makeContext()
        let list = Checklist(name: "Trip")
        let completed = CompletedRun(checklist: list)
        context.insert(list)
        context.insert(completed)
        try context.save()

        context.delete(list)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<CompletedRun>())
        XCTAssertTrue(fetched.isEmpty, "CompletedRun should cascade-delete with its Checklist")
    }
}
```

- [ ] **Step 2: Run — confirm fail**

```bash
xcodebuild test -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build -only-testing:ChecklistTests/CompletedRunTests 2>&1 | tail -10
```

- [ ] **Step 3: Implement snapshot structs**

Write `Checklist/Checklist/Models/CompletedRunSnapshot.swift`:

```swift
import Foundation

/// Frozen snapshot of a Run's state at the moment of completion. Embedded in
/// CompletedRun as JSON, so the completed record is self-contained even if the
/// source Checklist or Tag is later edited or deleted.
struct CompletedRunSnapshot: Codable {
    var items: [ItemSnapshot]
    var tags: [TagSnapshot]
    var checks: [UUID: CheckState]
    var hiddenTagIDs: [UUID]

    static let empty = CompletedRunSnapshot(items: [], tags: [], checks: [:], hiddenTagIDs: [])
}

struct ItemSnapshot: Codable, Identifiable, Hashable {
    let id: UUID
    let text: String
    let tagIDs: [UUID]
    let sortKey: Int
}

struct TagSnapshot: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let iconName: String
    let colorHue: Double
}
```

- [ ] **Step 4: Full CompletedRun implementation**

Overwrite `Checklist/Checklist/Models/CompletedRun.swift`:

```swift
import Foundation
import SwiftData

/// Sealed record of a completed Run. Read-only forever. Stores items, tags,
/// checks, and hidden-tag IDs as a single Codable blob (`.externalStorage`)
/// for atomic immutability + CloudKit-friendly size.
///
/// Key concept: once created, this never changes. Editing the source Checklist
/// or Tag does NOT affect past CompletedRuns.
@Model
final class CompletedRun {
    var id: UUID = UUID()
    var name: String? = nil
    var startedAt: Date = Date()
    var completedAt: Date = Date()

    @Relationship(deleteRule: .nullify) var checklist: Checklist?

    @Attribute(.externalStorage)
    var snapshotData: Data = Data()

    var snapshot: CompletedRunSnapshot {
        get {
            (try? JSONDecoder().decode(CompletedRunSnapshot.self, from: snapshotData))
                ?? .empty
        }
        set {
            snapshotData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    init(checklist: Checklist, name: String? = nil, startedAt: Date = Date(), completedAt: Date = Date()) {
        self.checklist = checklist
        self.name = name
        self.startedAt = startedAt
        self.completedAt = completedAt
    }
}
```

- [ ] **Step 5: Run — confirm pass**

```bash
xcodebuild test -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build -only-testing:ChecklistTests/CompletedRunTests 2>&1 | tail -10
```

Expected: 3 tests passed.

- [ ] **Step 6: Commit**

```bash
git add Checklist/Checklist/Models/CompletedRun.swift Checklist/Checklist/Models/CompletedRunSnapshot.swift Checklist/ChecklistTests/Models/CompletedRunTests.swift
git commit -m "feat(model): add CompletedRun with Codable snapshot blob"
```

---

### Task 1.8: Wire schema into ChecklistApp

**Files:**
- Modify: `Checklist/Checklist/ChecklistApp.swift`

- [ ] **Step 1: Add full schema**

Edit `Checklist/Checklist/ChecklistApp.swift`'s `setupModelContainer()`:

```swift
private func setupModelContainer() {
    do {
        let schema = Schema([
            Category.self,
            Tag.self,
            Checklist.self,
            Item.self,
            Run.self,
            Check.self,
            CompletedRun.self,
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: entitlementManager.isPremium ? .automatic : .none
        )
        modelContainer = try ModelContainer(for: schema, configurations: configuration)
    } catch {
        print("Failed to create ModelContainer: \(error)")
    }
}
```

- [ ] **Step 2: Build + launch**

```bash
xcodebuild -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build build 2>&1 | tail -10
APP_PATH=$(find .build -name "Checklist.app" -type d | head -1)
xcrun simctl install booted "$APP_PATH"
xcrun simctl launch booted com.lchogan.Checklist
sleep 2
xcrun simctl io booted screenshot /tmp/phase-1-placeholder.png
```

Expected: BUILD SUCCEEDED, app launches, no crashes, placeholder screen still visible.

- [ ] **Step 3: Run ALL model tests**

```bash
xcodebuild test -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build 2>&1 | tail -15
```

Expected: all model tests pass (Category, Tag, ChecklistModel, Item, Run, Check, CompletedRun).

- [ ] **Step 4: Commit**

```bash
git add Checklist/Checklist/ChecklistApp.swift
git commit -m "feat: wire full v4 schema into ChecklistApp model container"
```

---

## Phase 2 — Store layer (stateless functions taking `ModelContext`)

### Task 2.1: ChecklistStore

**Files:**
- Create: `Checklist/Checklist/Store/ChecklistStore.swift`
- Create: `Checklist/ChecklistTests/Store/ChecklistStoreTests.swift`

- [ ] **Step 1: Write the failing test**

Write `Checklist/ChecklistTests/Store/ChecklistStoreTests.swift`:

```swift
import XCTest
import SwiftData
@testable import Checklist

final class ChecklistStoreTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Checklist.self, Category.self, Item.self, Tag.self,
                Run.self, Check.self, CompletedRun.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    func test_create_returns_persisted_checklist() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "Daily", in: ctx)
        XCTAssertEqual(list.name, "Daily")
        let fetched = try ctx.fetch(FetchDescriptor<Checklist>())
        XCTAssertEqual(fetched.count, 1)
    }

    func test_addItem_appends_with_incrementing_sortKey() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "Trip", in: ctx)
        let a = try ChecklistStore.addItem(text: "Passport", to: list, in: ctx)
        let b = try ChecklistStore.addItem(text: "Toothbrush", to: list, in: ctx)
        XCTAssertEqual(a.sortKey, 0)
        XCTAssertEqual(b.sortKey, 1)
        XCTAssertEqual(list.items?.count, 2)
    }

    func test_deleteItem_clears_matching_checks_across_all_live_runs() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "Trip", in: ctx)
        let item = try ChecklistStore.addItem(text: "Passport", to: list, in: ctx)

        // Create 2 live runs, both with a check on this item
        let run1 = Run(checklist: list, name: "Tokyo")
        let check1 = Check(itemID: item.id)
        check1.run = run1
        ctx.insert(run1); ctx.insert(check1)

        let run2 = Run(checklist: list, name: "Lisbon")
        let check2 = Check(itemID: item.id)
        check2.run = run2
        ctx.insert(run2); ctx.insert(check2)

        try ctx.save()

        try ChecklistStore.deleteItem(item, in: ctx)

        let fetchedChecks = try ctx.fetch(FetchDescriptor<Check>())
        XCTAssertTrue(fetchedChecks.isEmpty, "deleting item should clear its checks in all live runs")
    }

    func test_deleteChecklist_cascades() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "Trip", in: ctx)
        _ = try ChecklistStore.addItem(text: "A", to: list, in: ctx)
        try ctx.save()

        try ChecklistStore.delete(list, in: ctx)

        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Checklist>()).count, 0)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Item>()).count, 0)
    }

    func test_liveRunCount() throws {
        let ctx = try makeContext()
        let list = try ChecklistStore.create(name: "Trip", in: ctx)
        ctx.insert(Run(checklist: list, name: "One"))
        ctx.insert(Run(checklist: list, name: "Two"))
        try ctx.save()
        XCTAssertEqual(ChecklistStore.liveRunCount(for: list), 2)
    }
}
```

- [ ] **Step 2: Run — confirm fail (ChecklistStore missing)**

```bash
xcodebuild test -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build -only-testing:ChecklistTests/ChecklistStoreTests 2>&1 | tail -10
```

- [ ] **Step 3: Implement ChecklistStore**

Write `Checklist/Checklist/Store/ChecklistStore.swift`:

```swift
import Foundation
import SwiftData

/// Stateless operations on Checklist, Item, Category. Every function takes a
/// ModelContext explicitly — no hidden singletons. Views call these directly.
///
/// Dependencies: Checklist, Item, Category, Run, Check models.
/// Key concepts: structural edits (add/rename/reorder/delete) propagate
/// automatically to live Runs because items live on Checklist, per v4.
enum ChecklistStore {

    // MARK: - Checklist CRUD

    @discardableResult
    static func create(name: String, category: Category? = nil, in context: ModelContext) throws -> Checklist {
        let list = Checklist(name: name)
        list.category = category
        list.sortKey = try nextChecklistSortKey(in: context)
        context.insert(list)
        try context.save()
        return list
    }

    static func rename(_ list: Checklist, to name: String, in context: ModelContext) throws {
        list.name = name
        try context.save()
    }

    static func setCategory(_ list: Checklist, to category: Category?, in context: ModelContext) throws {
        list.category = category
        try context.save()
    }

    static func delete(_ list: Checklist, in context: ModelContext) throws {
        context.delete(list)
        try context.save()
    }

    // MARK: - Items

    @discardableResult
    static func addItem(text: String, to list: Checklist, tags: [Tag] = [], in context: ModelContext) throws -> Item {
        let nextSort = (list.items?.map(\.sortKey).max() ?? -1) + 1
        let item = Item(text: text, sortKey: nextSort)
        item.checklist = list
        item.tags = tags
        context.insert(item)
        try context.save()
        return item
    }

    static func renameItem(_ item: Item, to text: String, in context: ModelContext) throws {
        item.text = text
        try context.save()
    }

    static func setItemTags(_ item: Item, to tags: [Tag], in context: ModelContext) throws {
        item.tags = tags
        try context.save()
    }

    static func deleteItem(_ item: Item, in context: ModelContext) throws {
        let itemID = item.id
        let checklistID = item.checklist?.id
        context.delete(item)

        // Clean up checks referencing this item across all live runs on the same checklist.
        let descriptor = FetchDescriptor<Check>(predicate: #Predicate<Check> { $0.itemID == itemID })
        let orphans = try context.fetch(descriptor)
        for check in orphans where check.run?.checklist?.id == checklistID {
            context.delete(check)
        }
        try context.save()
    }

    static func reorderItems(_ ordered: [Item], in context: ModelContext) throws {
        for (index, item) in ordered.enumerated() {
            item.sortKey = index
        }
        try context.save()
    }

    // MARK: - Queries

    static func liveRunCount(for list: Checklist) -> Int {
        list.runs?.count ?? 0
    }

    static func hasMultipleLiveRuns(for list: Checklist) -> Bool {
        liveRunCount(for: list) >= 2
    }

    // MARK: - Private

    private static func nextChecklistSortKey(in context: ModelContext) throws -> Int {
        let descriptor = FetchDescriptor<Checklist>(sortBy: [SortDescriptor(\.sortKey, order: .reverse)])
        return ((try? context.fetch(descriptor).first?.sortKey) ?? -1) + 1
    }
}
```

- [ ] **Step 4: Run — confirm pass**

```bash
xcodebuild test -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build -only-testing:ChecklistTests/ChecklistStoreTests 2>&1 | tail -10
```

Expected: 5 tests passed.

- [ ] **Step 5: Commit**

```bash
git add Checklist/Checklist/Store/ChecklistStore.swift Checklist/ChecklistTests/Store/ChecklistStoreTests.swift
git commit -m "feat(store): add ChecklistStore with CRUD + item delete cascade to checks"
```

---

### Task 2.2: RunStore (startRun, toggleCheck, ignore, hideTag, complete, discard)

**Files:**
- Create: `Checklist/Checklist/Store/RunStore.swift`
- Create: `Checklist/ChecklistTests/Store/RunStoreTests.swift`

- [ ] **Step 1: Write the failing test**

Write `Checklist/ChecklistTests/Store/RunStoreTests.swift`:

```swift
import XCTest
import SwiftData
@testable import Checklist

final class RunStoreTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Checklist.self, Category.self, Item.self, Tag.self,
                Run.self, Check.self, CompletedRun.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    private func seed(_ ctx: ModelContext) throws -> (Checklist, [Item]) {
        let list = try ChecklistStore.create(name: "Trip", in: ctx)
        let items = try ["A", "B", "C"].map {
            try ChecklistStore.addItem(text: $0, to: list, in: ctx)
        }
        return (list, items)
    }

    func test_startRun_creates_live_run() throws {
        let ctx = try makeContext()
        let (list, _) = try seed(ctx)
        let run = try RunStore.startRun(on: list, name: "Tokyo", in: ctx)
        XCTAssertEqual(run.checklist?.id, list.id)
        XCTAssertEqual(run.name, "Tokyo")
        XCTAssertTrue(run.checks?.isEmpty ?? false)
    }

    func test_toggleCheck_sets_then_clears() throws {
        let ctx = try makeContext()
        let (list, items) = try seed(ctx)
        let run = try RunStore.startRun(on: list, in: ctx)

        try RunStore.toggleCheck(run: run, itemID: items[0].id, in: ctx)
        XCTAssertEqual(run.checks?.count, 1)
        XCTAssertEqual(run.checks?.first?.state, .complete)

        try RunStore.toggleCheck(run: run, itemID: items[0].id, in: ctx)
        XCTAssertEqual(run.checks?.count ?? 0, 0)
    }

    func test_setIgnored_adds_check_with_ignored_state() throws {
        let ctx = try makeContext()
        let (list, items) = try seed(ctx)
        let run = try RunStore.startRun(on: list, in: ctx)

        try RunStore.setIgnored(run: run, itemID: items[0].id, to: true, in: ctx)
        XCTAssertEqual(run.checks?.first?.state, .ignored)

        try RunStore.setIgnored(run: run, itemID: items[0].id, to: false, in: ctx)
        XCTAssertEqual(run.checks?.count ?? 0, 0)
    }

    func test_toggleHideTag() throws {
        let ctx = try makeContext()
        let (list, _) = try seed(ctx)
        let run = try RunStore.startRun(on: list, in: ctx)
        let tagID = UUID()

        try RunStore.toggleHideTag(run: run, tagID: tagID, in: ctx)
        XCTAssertEqual(run.hiddenTagIDs, [tagID])

        try RunStore.toggleHideTag(run: run, tagID: tagID, in: ctx)
        XCTAssertEqual(run.hiddenTagIDs, [])
    }

    func test_complete_creates_CompletedRun_and_removes_Run() throws {
        let ctx = try makeContext()
        let (list, items) = try seed(ctx)
        let run = try RunStore.startRun(on: list, name: "Tokyo", in: ctx)
        try RunStore.toggleCheck(run: run, itemID: items[0].id, in: ctx)
        try RunStore.toggleCheck(run: run, itemID: items[1].id, in: ctx)

        try RunStore.complete(run, in: ctx)

        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Run>()).count, 0)
        let completed = try ctx.fetch(FetchDescriptor<CompletedRun>())
        XCTAssertEqual(completed.count, 1)
        XCTAssertEqual(completed.first?.name, "Tokyo")
        XCTAssertEqual(completed.first?.snapshot.items.count, 3)
        XCTAssertEqual(completed.first?.snapshot.checks.count, 2)
    }

    func test_discard_removes_Run_without_completing() throws {
        let ctx = try makeContext()
        let (list, _) = try seed(ctx)
        let run = try RunStore.startRun(on: list, in: ctx)
        try RunStore.discard(run, in: ctx)

        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Run>()).count, 0)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<CompletedRun>()).count, 0)
    }

    func test_multiple_live_runs_coexist() throws {
        let ctx = try makeContext()
        let (list, _) = try seed(ctx)
        _ = try RunStore.startRun(on: list, name: "Tokyo", in: ctx)
        _ = try RunStore.startRun(on: list, name: "Lisbon", in: ctx)
        XCTAssertEqual(list.runs?.count, 2)
    }
}
```

- [ ] **Step 2: Run — confirm fail**

```bash
xcodebuild test -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build -only-testing:ChecklistTests/RunStoreTests 2>&1 | tail -10
```

- [ ] **Step 3: Implement RunStore**

Write `Checklist/Checklist/Store/RunStore.swift`:

```swift
import Foundation
import SwiftData

/// Operations on live Runs: start, toggle check, toggle ignore, hide tag,
/// complete (→ CompletedRun), discard.
enum RunStore {

    // MARK: - Lifecycle

    @discardableResult
    static func startRun(on list: Checklist, name: String? = nil, in context: ModelContext) throws -> Run {
        let run = Run(checklist: list, name: name)
        context.insert(run)
        try context.save()
        return run
    }

    static func rename(_ run: Run, to name: String?, in context: ModelContext) throws {
        run.name = name?.isEmpty == true ? nil : name
        try context.save()
    }

    static func discard(_ run: Run, in context: ModelContext) throws {
        context.delete(run)
        try context.save()
    }

    static func complete(_ run: Run, in context: ModelContext) throws {
        guard let list = run.checklist else {
            throw StoreError.orphanedRun
        }
        let snapshot = CompletedRunBuilder.snapshot(for: run, checklist: list)
        let completed = CompletedRun(
            checklist: list,
            name: run.name,
            startedAt: run.startedAt,
            completedAt: Date()
        )
        completed.snapshot = snapshot
        context.insert(completed)
        context.delete(run)
        try context.save()
    }

    // MARK: - Per-item check state

    /// Toggle: no check → complete → no check. (Ignored is handled separately.)
    static func toggleCheck(run: Run, itemID: UUID, in context: ModelContext) throws {
        if let existing = run.checks?.first(where: { $0.itemID == itemID }) {
            if existing.state == .complete {
                context.delete(existing)
            } else {
                existing.state = .complete
            }
        } else {
            let check = Check(itemID: itemID, state: .complete)
            check.run = run
            context.insert(check)
        }
        try context.save()
    }

    /// Explicit ignore on/off (doesn't cycle through complete).
    static func setIgnored(run: Run, itemID: UUID, to ignored: Bool, in context: ModelContext) throws {
        if ignored {
            if let existing = run.checks?.first(where: { $0.itemID == itemID }) {
                existing.state = .ignored
            } else {
                let check = Check(itemID: itemID, state: .ignored)
                check.run = run
                context.insert(check)
            }
        } else if let existing = run.checks?.first(where: { $0.itemID == itemID }) {
            context.delete(existing)
        }
        try context.save()
    }

    // MARK: - View-only filters

    static func toggleHideTag(run: Run, tagID: UUID, in context: ModelContext) throws {
        if run.hiddenTagIDs.contains(tagID) {
            run.hiddenTagIDs.removeAll { $0 == tagID }
        } else {
            run.hiddenTagIDs.append(tagID)
        }
        try context.save()
    }
}

enum StoreError: Error {
    case orphanedRun
}
```

- [ ] **Step 4: Run — confirm fail (CompletedRunBuilder missing)**

Expected: compile error referencing `CompletedRunBuilder`. That's Task 2.3.

- [ ] **Step 5: Commit stub + note**

Commit the current state — the RunStore tests will pass after Task 2.3:

```bash
git add Checklist/Checklist/Store/RunStore.swift Checklist/ChecklistTests/Store/RunStoreTests.swift
git commit -m "feat(store): add RunStore (builds on CompletedRunBuilder, next task)"
```

---

### Task 2.3: CompletedRunBuilder

**Files:**
- Create: `Checklist/Checklist/Store/CompletedRunBuilder.swift`
- Create: `Checklist/ChecklistTests/Store/CompletedRunBuilderTests.swift`

- [ ] **Step 1: Write the failing test**

Write `Checklist/ChecklistTests/Store/CompletedRunBuilderTests.swift`:

```swift
import XCTest
import SwiftData
@testable import Checklist

final class CompletedRunBuilderTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Checklist.self, Item.self, Tag.self, Run.self, Check.self, CompletedRun.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    func test_snapshot_captures_items_with_tags_and_checks() throws {
        let ctx = try makeContext()
        let list = Checklist(name: "Trip")
        ctx.insert(list)

        let beach = Tag(name: "Beach", iconName: "sun", colorHue: 85)
        ctx.insert(beach)

        let a = Item(text: "Passport", sortKey: 0); a.checklist = list; ctx.insert(a)
        let b = Item(text: "Sandals", sortKey: 1); b.checklist = list; b.tags = [beach]; ctx.insert(b)

        let run = Run(checklist: list, name: "Tokyo"); ctx.insert(run)
        let check = Check(itemID: a.id, state: .complete); check.run = run; ctx.insert(check)
        run.hiddenTagIDs = [beach.id]
        try ctx.save()

        let snapshot = CompletedRunBuilder.snapshot(for: run, checklist: list)

        XCTAssertEqual(snapshot.items.count, 2)
        XCTAssertEqual(snapshot.items[0].text, "Passport")
        XCTAssertEqual(snapshot.items[1].tagIDs, [beach.id])
        XCTAssertEqual(snapshot.tags.count, 1)
        XCTAssertEqual(snapshot.tags[0].name, "Beach")
        XCTAssertEqual(snapshot.checks[a.id], .complete)
        XCTAssertEqual(snapshot.hiddenTagIDs, [beach.id])
    }

    func test_snapshot_includes_only_tags_referenced_by_items() throws {
        let ctx = try makeContext()
        let list = Checklist(name: "Trip"); ctx.insert(list)
        let used = Tag(name: "Used"); ctx.insert(used)
        let unused = Tag(name: "Unused"); ctx.insert(unused)
        let item = Item(text: "X"); item.checklist = list; item.tags = [used]; ctx.insert(item)
        let run = Run(checklist: list); ctx.insert(run)
        try ctx.save()

        let snapshot = CompletedRunBuilder.snapshot(for: run, checklist: list)
        XCTAssertEqual(snapshot.tags.count, 1)
        XCTAssertEqual(snapshot.tags.first?.name, "Used")
    }
}
```

- [ ] **Step 2: Run — confirm fail**

```bash
xcodebuild test -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build -only-testing:ChecklistTests/CompletedRunBuilderTests 2>&1 | tail -10
```

- [ ] **Step 3: Implement CompletedRunBuilder**

Write `Checklist/Checklist/Store/CompletedRunBuilder.swift`:

```swift
import Foundation

/// Builds a CompletedRunSnapshot from a live Run + its Checklist. Pure
/// function; no SwiftData side effects.
enum CompletedRunBuilder {

    static func snapshot(for run: Run, checklist: Checklist) -> CompletedRunSnapshot {
        let items = (checklist.items ?? []).sorted { $0.sortKey < $1.sortKey }

        let itemSnapshots = items.map {
            ItemSnapshot(
                id: $0.id,
                text: $0.text,
                tagIDs: ($0.tags ?? []).map(\.id),
                sortKey: $0.sortKey
            )
        }

        let referencedTagIDs = Set(itemSnapshots.flatMap(\.tagIDs))
        let tagSnapshots: [TagSnapshot] = items.flatMap({ $0.tags ?? [] })
            .reduce(into: [UUID: TagSnapshot]()) { dict, tag in
                guard referencedTagIDs.contains(tag.id), dict[tag.id] == nil else { return }
                dict[tag.id] = TagSnapshot(
                    id: tag.id,
                    name: tag.name,
                    iconName: tag.iconName,
                    colorHue: tag.colorHue
                )
            }
            .values
            .sorted { $0.name < $1.name }

        let checks: [UUID: CheckState] = (run.checks ?? []).reduce(into: [:]) { dict, c in
            dict[c.itemID] = c.state
        }

        return CompletedRunSnapshot(
            items: itemSnapshots,
            tags: tagSnapshots,
            checks: checks,
            hiddenTagIDs: run.hiddenTagIDs
        )
    }
}
```

- [ ] **Step 4: Run — confirm ALL Phase 2 tests pass**

```bash
xcodebuild test -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build -only-testing:ChecklistTests/RunStoreTests -only-testing:ChecklistTests/CompletedRunBuilderTests 2>&1 | tail -15
```

Expected: RunStore (7 tests) + CompletedRunBuilder (2 tests) all pass.

- [ ] **Step 5: Commit**

```bash
git add Checklist/Checklist/Store/CompletedRunBuilder.swift Checklist/ChecklistTests/Store/CompletedRunBuilderTests.swift
git commit -m "feat(store): add CompletedRunBuilder; RunStore tests now pass"
```

---

### Task 2.4: TagStore

**Files:**
- Create: `Checklist/Checklist/Store/TagStore.swift`
- Create: `Checklist/ChecklistTests/Store/TagStoreTests.swift`

- [ ] **Step 1: Write the failing test**

Write `Checklist/ChecklistTests/Store/TagStoreTests.swift`:

```swift
import XCTest
import SwiftData
@testable import Checklist

final class TagStoreTests: XCTestCase {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Checklist.self, Item.self, Tag.self, Run.self, Check.self, CompletedRun.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    func test_create_assigns_sortKey_and_persists() throws {
        let ctx = try makeContext()
        let a = try TagStore.create(name: "Beach", iconName: "sun", colorHue: 85, in: ctx)
        let b = try TagStore.create(name: "Snow", iconName: "snowflake", colorHue: 250, in: ctx)
        XCTAssertEqual(a.sortKey, 0)
        XCTAssertEqual(b.sortKey, 1)
    }

    func test_delete_removes_from_items_tags_and_run_hiddenTagIDs() throws {
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

    func test_delete_does_not_alter_completedRun_snapshot() throws {
        let ctx = try makeContext()
        let beach = try TagStore.create(name: "Beach", in: ctx)
        let list = Checklist(name: "Trip"); ctx.insert(list)
        let completed = CompletedRun(checklist: list, name: "Tokyo")
        completed.snapshot = CompletedRunSnapshot(
            items: [],
            tags: [TagSnapshot(id: beach.id, name: "Beach", iconName: "sun", colorHue: 85)],
            checks: [:],
            hiddenTagIDs: []
        )
        ctx.insert(completed)
        try ctx.save()

        try TagStore.delete(beach, in: ctx)

        XCTAssertEqual(completed.snapshot.tags.first?.name, "Beach",
                       "CompletedRun snapshot must remain frozen even after Tag delete")
    }

    func test_update_patches_fields() throws {
        let ctx = try makeContext()
        let tag = try TagStore.create(name: "Beach", in: ctx)
        try TagStore.update(tag, name: "Tropical", iconName: "palm", colorHue: 120, in: ctx)
        XCTAssertEqual(tag.name, "Tropical")
        XCTAssertEqual(tag.iconName, "palm")
        XCTAssertEqual(tag.colorHue, 120)
    }

    func test_usageCount_across_all_items() throws {
        let ctx = try makeContext()
        let beach = try TagStore.create(name: "Beach", in: ctx)
        let list = Checklist(name: "A"); ctx.insert(list)
        let a = Item(text: "a"); a.checklist = list; a.tags = [beach]; ctx.insert(a)
        let b = Item(text: "b"); b.checklist = list; b.tags = [beach]; ctx.insert(b)
        try ctx.save()
        XCTAssertEqual(TagStore.usageCount(for: beach, in: ctx), 2)
    }
}
```

- [ ] **Step 2: Run — confirm fail**

```bash
xcodebuild test -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build -only-testing:ChecklistTests/TagStoreTests 2>&1 | tail -10
```

- [ ] **Step 3: Implement TagStore**

Write `Checklist/Checklist/Store/TagStore.swift`:

```swift
import Foundation
import SwiftData

/// Operations on app-wide Tags. Handles cleanup across live entities on delete;
/// CompletedRun snapshots are frozen and untouched.
enum TagStore {

    @discardableResult
    static func create(name: String, iconName: String = "tag", colorHue: Double = 300, in context: ModelContext) throws -> Tag {
        let tag = Tag(
            name: name,
            iconName: iconName,
            colorHue: colorHue,
            sortKey: try nextSortKey(in: context)
        )
        context.insert(tag)
        try context.save()
        return tag
    }

    static func update(_ tag: Tag, name: String? = nil, iconName: String? = nil, colorHue: Double? = nil, in context: ModelContext) throws {
        if let name { tag.name = name }
        if let iconName { tag.iconName = iconName }
        if let colorHue { tag.colorHue = colorHue }
        try context.save()
    }

    static func delete(_ tag: Tag, in context: ModelContext) throws {
        let tagID = tag.id

        // Remove from all items
        let items = try context.fetch(FetchDescriptor<Item>())
        for item in items {
            if item.tags?.contains(where: { $0.id == tagID }) == true {
                item.tags?.removeAll { $0.id == tagID }
            }
        }

        // Remove from all live runs' hiddenTagIDs
        let runs = try context.fetch(FetchDescriptor<Run>())
        for run in runs where run.hiddenTagIDs.contains(tagID) {
            run.hiddenTagIDs.removeAll { $0 == tagID }
        }

        // CompletedRun snapshots are frozen — do NOT touch.
        context.delete(tag)
        try context.save()
    }

    static func usageCount(for tag: Tag, in context: ModelContext) -> Int {
        let tagID = tag.id
        let items = (try? context.fetch(FetchDescriptor<Item>())) ?? []
        return items.filter { $0.tags?.contains(where: { $0.id == tagID }) == true }.count
    }

    private static func nextSortKey(in context: ModelContext) throws -> Int {
        let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.sortKey, order: .reverse)])
        return ((try? context.fetch(descriptor).first?.sortKey) ?? -1) + 1
    }
}
```

- [ ] **Step 4: Run — confirm pass**

```bash
xcodebuild test -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build -only-testing:ChecklistTests/TagStoreTests 2>&1 | tail -10
```

Expected: 5 tests passed.

- [ ] **Step 5: Commit**

```bash
git add Checklist/Checklist/Store/TagStore.swift Checklist/ChecklistTests/Store/TagStoreTests.swift
git commit -m "feat(store): add TagStore with cross-entity cleanup on delete"
```

---

### Task 2.5: SeedStore

**Files:**
- Create: `Checklist/Checklist/Store/SeedStore.swift`
- Create: `Checklist/ChecklistTests/Store/SeedStoreTests.swift`

- [ ] **Step 1: Write the failing test**

Write `Checklist/ChecklistTests/Store/SeedStoreTests.swift`:

```swift
import XCTest
import SwiftData
@testable import Checklist

final class SeedStoreTests: XCTestCase {
    func test_empty_returns_container_with_nothing() throws {
        let container = try SeedStore.container(for: .empty)
        let ctx = ModelContext(container)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Checklist>()).count, 0)
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Tag>()).count, 0)
    }

    func test_oneList_returns_one_checklist_with_items() throws {
        let container = try SeedStore.container(for: .oneList)
        let ctx = ModelContext(container)
        let lists = try ctx.fetch(FetchDescriptor<Checklist>())
        XCTAssertEqual(lists.count, 1)
        XCTAssertGreaterThan(lists.first?.items?.count ?? 0, 0)
    }

    func test_seededMulti_has_multiple_checklists_tags_and_live_run() throws {
        let container = try SeedStore.container(for: .seededMulti)
        let ctx = ModelContext(container)
        XCTAssertGreaterThan(try ctx.fetch(FetchDescriptor<Checklist>()).count, 1)
        XCTAssertGreaterThan(try ctx.fetch(FetchDescriptor<Tag>()).count, 0)
        XCTAssertGreaterThan(try ctx.fetch(FetchDescriptor<Run>()).count, 0)
    }

    func test_historicalRuns_has_completedRuns() throws {
        let container = try SeedStore.container(for: .historicalRuns)
        let ctx = ModelContext(container)
        XCTAssertGreaterThan(try ctx.fetch(FetchDescriptor<CompletedRun>()).count, 0)
    }

    func test_nearCompleteRun_has_one_live_run_with_all_but_one_item_checked() throws {
        let container = try SeedStore.container(for: .nearCompleteRun)
        let ctx = ModelContext(container)
        let runs = try ctx.fetch(FetchDescriptor<Run>())
        XCTAssertEqual(runs.count, 1)
        let run = runs[0]
        let itemCount = run.checklist?.items?.count ?? 0
        XCTAssertEqual(run.checks?.count, itemCount - 1)
    }
}
```

- [ ] **Step 2: Run — confirm fail**

```bash
xcodebuild test -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build -only-testing:ChecklistTests/SeedStoreTests 2>&1 | tail -10
```

- [ ] **Step 3: Implement SeedStore**

Write `Checklist/Checklist/Store/SeedStore.swift`:

```swift
import Foundation
import SwiftData

/// Builds in-memory ModelContainers pre-populated with named fixtures. Used by
/// both unit tests and SwiftUI previews. One case per state in
/// docs/superpowers/prototype-captures/index.md so the visual-diff loop can
/// reproduce any captured state.
enum SeedStore {

    enum Fixture {
        case empty
        case oneList
        case seededMulti
        case historicalRuns
        case nearCompleteRun
    }

    static let allModels: [any PersistentModel.Type] = [
        Category.self, Tag.self, Checklist.self, Item.self,
        Run.self, Check.self, CompletedRun.self,
    ]

    static func container(for fixture: Fixture) throws -> ModelContainer {
        let schema = Schema(allModels)
        let container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        )
        let ctx = ModelContext(container)
        try populate(ctx, with: fixture)
        try ctx.save()
        return container
    }

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
                // Seed 5 completed historical runs
                for i in 1...5 {
                    let started = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
                    let completed = CompletedRun(checklist: morning, name: nil, startedAt: started, completedAt: started)
                    completed.snapshot = CompletedRunBuilder.snapshot(
                        for: Run(checklist: morning), checklist: morning
                    )
                    ctx.insert(completed)
                }
            }

        case .nearCompleteRun:
            try seedMulti(ctx)
            let lists = try ctx.fetch(FetchDescriptor<Checklist>())
            if let gym = lists.first(where: { $0.name == "Gym Bag" }) {
                // Delete any existing runs to start clean
                for run in (gym.runs ?? []) { ctx.delete(run) }
                let run = try RunStore.startRun(on: gym, in: ctx)
                let items = (gym.items ?? []).sorted { $0.sortKey < $1.sortKey }
                for item in items.dropLast() {
                    try RunStore.toggleCheck(run: run, itemID: item.id, in: ctx)
                }
            }
        }
    }

    private static func seedMulti(_ ctx: ModelContext) throws {
        // Categories
        let travel = try CategoryStore.create(name: "Travel", in: ctx)
        let daily = try CategoryStore.create(name: "Daily", in: ctx)
        let home = try CategoryStore.create(name: "Home", in: ctx)

        // Tags
        let beach = try TagStore.create(name: "Beach", iconName: "sun", colorHue: 85, in: ctx)
        let snow = try TagStore.create(name: "Snow", iconName: "snowflake", colorHue: 250, in: ctx)
        let intl = try TagStore.create(name: "Intl", iconName: "plane", colorHue: 300, in: ctx)

        // Packing List
        let packing = try ChecklistStore.create(name: "Packing List", category: travel, in: ctx)
        _ = try ChecklistStore.addItem(text: "Toothbrush", to: packing, in: ctx)
        _ = try ChecklistStore.addItem(text: "Passport", to: packing, tags: [intl], in: ctx)
        _ = try ChecklistStore.addItem(text: "Sandals", to: packing, tags: [beach], in: ctx)
        _ = try ChecklistStore.addItem(text: "Thermal layers", to: packing, tags: [snow], in: ctx)

        // Live run on Packing List
        _ = try RunStore.startRun(on: packing, name: "Tokyo", in: ctx)

        // Morning Routine
        let morning = try ChecklistStore.create(name: "Morning Routine", category: daily, in: ctx)
        for item in ["Water first", "Stretch 5 min", "Make bed", "Journal"] {
            _ = try ChecklistStore.addItem(text: item, to: morning, in: ctx)
        }

        // Weekly Groceries
        let groceries = try ChecklistStore.create(name: "Weekly Groceries", category: home, in: ctx)
        for item in ["Eggs", "Milk", "Coffee", "Pasta"] {
            _ = try ChecklistStore.addItem(text: item, to: groceries, in: ctx)
        }

        // Gym Bag
        let gym = try ChecklistStore.create(name: "Gym Bag", category: daily, in: ctx)
        for item in ["Shoes", "Shorts", "Water bottle", "Headphones"] {
            _ = try ChecklistStore.addItem(text: item, to: gym, in: ctx)
        }
    }
}
```

- [ ] **Step 4: Create CategoryStore** (referenced by SeedStore — add as a small helper)

Write `Checklist/Checklist/Store/CategoryStore.swift`:

```swift
import Foundation
import SwiftData

enum CategoryStore {
    @discardableResult
    static func create(name: String, in context: ModelContext) throws -> Category {
        let cat = Category(name: name, sortKey: try nextSortKey(in: context))
        context.insert(cat)
        try context.save()
        return cat
    }

    static func rename(_ category: Category, to name: String, in context: ModelContext) throws {
        category.name = name
        try context.save()
    }

    static func delete(_ category: Category, in context: ModelContext) throws {
        // Checklists with this category nullify (relationship deleteRule: .nullify)
        context.delete(category)
        try context.save()
    }

    private static func nextSortKey(in context: ModelContext) throws -> Int {
        let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.sortKey, order: .reverse)])
        return ((try? context.fetch(descriptor).first?.sortKey) ?? -1) + 1
    }
}
```

- [ ] **Step 5: Run — confirm all Store tests pass**

```bash
xcodebuild test -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build 2>&1 | tail -20
```

Expected: all tests pass. All Phase 1 model tests + all Phase 2 store tests green.

- [ ] **Step 6: Commit**

```bash
git add Checklist/Checklist/Store/SeedStore.swift Checklist/Checklist/Store/CategoryStore.swift Checklist/ChecklistTests/Store/SeedStoreTests.swift
git commit -m "feat(store): add SeedStore fixtures and CategoryStore helper"
```

---

## Phase 3 — Design tokens + primitive components

### Task 3.1: Theme.swift (palette + typography + spacing)

**Files:**
- Create: `Checklist/Checklist/Design/Theme.swift`

- [ ] **Step 1: Implement Theme**

Write `Checklist/Checklist/Design/Theme.swift`:

```swift
import SwiftUI

/// Design tokens for the Gem visual direction. Values mined from
/// `gem-app/shared.jsx` (the prototype's palette object) and
/// `Gem App v2.html` CSS. Do not introduce ad-hoc colors/sizes elsewhere —
/// consumers always read from Theme.
enum Theme {

    // MARK: - Palette (OKLCH → Color)
    // Gem palette: fixed chroma/lightness, varying hue. Rendered via Color(hue:,saturation:,brightness:)
    // as an approximation of OKLCH since SwiftUI has no native OKLCH. Use `gemColor(hue:)`
    // for tag colors; named colors are convenience aliases.

    static let bg        = Color(red: 0.047, green: 0.028, blue: 0.078)   // #0c0820
    static let bg2       = Color(red: 0.102, green: 0.059, blue: 0.208)   // #1a0f35
    static let bg3       = Color(red: 0.020, green: 0.012, blue: 0.059)   // #05030f

    static let card      = Color.white.opacity(0.04)
    static let cardHi    = Color.white.opacity(0.065)
    static let border    = Color.white.opacity(0.08)
    static let borderHi  = Color.white.opacity(0.14)

    static let text      = Color(red: 0.957, green: 0.933, blue: 0.988)   // #f4eefc
    static let dim       = Color(red: 0.957, green: 0.933, blue: 0.988).opacity(0.6)
    static let dimmer    = Color(red: 0.957, green: 0.933, blue: 0.988).opacity(0.32)
    static let dimmest   = Color(red: 0.957, green: 0.933, blue: 0.988).opacity(0.14)

    /// Gem colors by hue, using fixed chroma and lightness.
    /// `hue` is an OKLCH hue angle 0–360.
    static func gemColor(hue: Double) -> Color {
        // Approximate OKLCH(0.62 / 0.22) with HSB-based conversion.
        // Hue mapping: OKLCH hue 300 ≈ purple, 250 ≈ blue, 160 ≈ green, 85 ≈ yellow, 20 ≈ red.
        let normalizedHue = (hue.truncatingRemainder(dividingBy: 360)) / 360.0
        return Color(hue: normalizedHue, saturation: 0.75, brightness: 0.82)
    }

    // Named gem hues — match prototype palette exactly
    static let amethyst = gemColor(hue: 300)
    static let emerald  = gemColor(hue: 160)
    static let citrine  = gemColor(hue: 85)
    static let ruby     = gemColor(hue: 20)
    static let sapphire = gemColor(hue: 250)
    static let peridot  = gemColor(hue: 135)
    static let rose     = gemColor(hue: 350)
    static let aqua     = gemColor(hue: 210)

    // MARK: - Gradients

    static var backgroundGradient: RadialGradient {
        RadialGradient(
            colors: [bg2, bg],
            center: .init(x: 0.5, y: 1.1),
            startRadius: 0,
            endRadius: 600
        )
    }

    // MARK: - Typography
    // Inter Tight via system fallback. App's Info.plist should register
    // InterTight-Regular.ttf through Bold at Phase 4 setup; until then system
    // fonts are fine.

    static func display(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func body(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func eyebrow() -> Font {
        .system(size: 11, weight: .semibold, design: .default)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 28
    }

    // MARK: - Radii

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 14
        static let lg: CGFloat = 18
        static let xl: CGFloat = 22
        static let pill: CGFloat = 999
    }

    // MARK: - Shadows (glow)

    static func glow(_ color: Color, radius: CGFloat = 14) -> some View {
        color.opacity(0.33).blur(radius: radius)
    }
}
```

- [ ] **Step 2: Build to confirm compile**

```bash
xcodebuild -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build build 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add Checklist/Checklist/Design/Theme.swift
git commit -m "feat(design): add Theme tokens (palette, gradients, spacing, radii, typography)"
```

---

### Task 3.2: GemIcons (icon-name → SF Symbol map)

**Files:**
- Create: `Checklist/Checklist/Design/GemIcons.swift`

- [ ] **Step 1: Implement GemIcons**

Write `Checklist/Checklist/Design/GemIcons.swift`:

```swift
import SwiftUI

/// Maps the prototype's icon-name tokens (from `gem-app/tags.jsx` TAG_ICONS)
/// to SF Symbol names. Centralized so tag/icon choices stay consistent across
/// the app. Missing mappings fall back to `questionmark.circle`.
enum GemIcons {

    /// Every icon name the prototype uses, in menu order.
    static let all: [String] = [
        "sun", "snow", "leaf", "plane", "case", "laptop",
        "home-icon", "cart", "dumbbell", "flame", "moon",
        "globe", "sparkle", "tag",
    ]

    /// Every tag hue the prototype offers, in palette order. Each value is an
    /// OKLCH hue angle (0–360).
    static let tagHues: [Double] = [300, 250, 210, 170, 135, 85, 45, 20, 350]

    static func sfSymbol(for name: String) -> String {
        switch name {
        case "sun":        return "sun.max.fill"
        case "snow":       return "snowflake"
        case "leaf":       return "leaf.fill"
        case "plane":      return "airplane"
        case "case":       return "briefcase.fill"
        case "laptop":     return "laptopcomputer"
        case "home-icon":  return "house.fill"
        case "cart":       return "cart.fill"
        case "dumbbell":   return "dumbbell.fill"
        case "flame":      return "flame.fill"
        case "moon":       return "moon.fill"
        case "globe":      return "globe"
        case "sparkle":    return "sparkle"
        case "tag":        return "tag.fill"
        // App chrome icons — not in the tag picker, but used by other screens
        case "more":       return "ellipsis"
        case "back":       return "chevron.left"
        case "right":      return "chevron.right"
        case "down":       return "chevron.down"
        case "check":      return "checkmark"
        case "plus":       return "plus"
        case "trash":      return "trash.fill"
        case "edit":       return "pencil"
        case "history":    return "clock.arrow.circlepath"
        case "archive":    return "archivebox.fill"
        case "stack":      return "square.stack.3d.up.fill"
        case "eye-off":    return "eye.slash.fill"
        default:           return "questionmark.circle"
        }
    }

    static func image(_ name: String) -> Image {
        Image(systemName: sfSymbol(for: name))
    }
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build build 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
git add Checklist/Checklist/Design/GemIcons.swift
git commit -m "feat(design): add GemIcons SF Symbol map with prototype icon names"
```

---

### Task 3.3: Facet (gem checkbox with check animation)

**Files:**
- Create: `Checklist/Checklist/Design/Components/Facet.swift`

- [ ] **Step 1: Implement Facet**

Write `Checklist/Checklist/Design/Components/Facet.swift`:

```swift
import SwiftUI

/// The signature gem-faceted checkbox. Unchecked = outlined hexagon; checked =
/// filled gradient with white checkmark and a soft glow. Springy scale on toggle.
struct Facet: View {
    let color: Color
    let checked: Bool
    var size: CGFloat = 26

    var body: some View {
        ZStack {
            // Background shape
            FacetShape()
                .fill(
                    checked
                        ? LinearGradient(
                            colors: [color.opacity(0.95), color.opacity(0.55)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(colors: [.clear, .clear], startPoint: .top, endPoint: .bottom)
                )
                .overlay(
                    FacetShape()
                        .stroke(
                            checked ? color.opacity(0.7) : Theme.dimmer,
                            lineWidth: 1.5
                        )
                )
                .shadow(color: checked ? color.opacity(0.45) : .clear, radius: 6, x: 0, y: 0)

            // Checkmark
            if checked {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundColor(.white)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(checked ? 1.0 : 0.96)
        .animation(.spring(response: 0.26, dampingFraction: 0.6), value: checked)
    }
}

/// A squircle-ish hexagonal facet. Close to the prototype's rounded hex shape.
private struct FacetShape: Shape {
    func path(in rect: CGRect) -> Path {
        let r = min(rect.width, rect.height) * 0.3
        return Path(roundedRect: rect, cornerSize: CGSize(width: r, height: r))
    }
}

#Preview("Facet states") {
    HStack(spacing: 16) {
        Facet(color: Theme.amethyst, checked: false)
        Facet(color: Theme.amethyst, checked: true)
        Facet(color: Theme.citrine, checked: true)
        Facet(color: Theme.emerald, checked: true, size: 36)
    }
    .padding()
    .background(Theme.bg)
}
```

- [ ] **Step 2: Verify preview renders**

In Xcode, open `Facet.swift`, use the canvas. The preview should show 4 facet states on a dark background.

- [ ] **Step 3: Build**

```bash
xcodebuild -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build build 2>&1 | tail -5
```

- [ ] **Step 4: Commit**

```bash
git add Checklist/Checklist/Design/Components/Facet.swift
git commit -m "feat(design): add Facet checkbox component with spring toggle animation"
```

---

### Task 3.4: PillButton

**Files:**
- Create: `Checklist/Checklist/Design/Components/PillButton.swift`

- [ ] **Step 1: Implement PillButton**

Write `Checklist/Checklist/Design/Components/PillButton.swift`:

```swift
import SwiftUI

/// Primary CTA button in the Gem style: gradient fill with a subtle glow, or a
/// ghost variant with a hairline border. `tone: .solid | .ghost`.
struct PillButton: View {
    enum Tone { case solid, ghost }

    let title: String
    var color: Color = Theme.amethyst
    var tone: Tone = .solid
    var wide: Bool = false
    var small: Bool = false
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: small ? 13 : 14.5, weight: .semibold, design: .default))
                .foregroundColor(tone == .solid ? .white : Theme.text)
                .padding(.horizontal, small ? 16 : 22)
                .padding(.vertical, small ? 9 : 12)
                .frame(maxWidth: wide ? .infinity : nil)
                .background(backgroundFill)
                .overlay(border)
                .shadow(color: tone == .solid ? color.opacity(0.33) : .clear, radius: 10, x: 0, y: 0)
                .opacity(disabled ? 0.4 : 1)
        }
        .disabled(disabled)
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var backgroundFill: some View {
        switch tone {
        case .solid:
            LinearGradient(
                colors: [color, color.opacity(0.72)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(Capsule())
        case .ghost:
            Color.white.opacity(0.05).clipShape(Capsule())
        }
    }

    @ViewBuilder
    private var border: some View {
        if tone == .ghost {
            Capsule().stroke(Theme.borderHi, lineWidth: 1)
        }
    }
}

#Preview("PillButton variants") {
    VStack(spacing: 12) {
        PillButton(title: "Complete", color: Theme.amethyst) {}
        PillButton(title: "Complete", color: Theme.emerald, wide: true) {}
        PillButton(title: "Complete", color: Theme.citrine, wide: true) {}
        PillButton(title: "Not yet", tone: .ghost, wide: true) {}
        PillButton(title: "Discard", color: Theme.ruby, small: true) {}
        PillButton(title: "Disabled", disabled: true) {}
    }
    .padding()
    .background(Theme.bg)
}
```

- [ ] **Step 2: Build + preview**

```bash
xcodebuild -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build build 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
git add Checklist/Checklist/Design/Components/PillButton.swift
git commit -m "feat(design): add PillButton with solid/ghost tones"
```

---

### Task 3.5: TagChip + TagHideChip

**Files:**
- Create: `Checklist/Checklist/Design/Components/TagChip.swift`

- [ ] **Step 1: Implement both chip variants**

Write `Checklist/Checklist/Design/Components/TagChip.swift`:

```swift
import SwiftUI

/// A compact tag badge shown inside item rows. Muted variant used when the
/// parent item is completed.
struct TagChip: View {
    let name: String
    let iconName: String
    let colorHue: Double
    var muted: Bool = false
    var small: Bool = false

    var body: some View {
        HStack(spacing: small ? 3 : 4) {
            GemIcons.image(iconName)
                .font(.system(size: small ? 9 : 10, weight: .bold))
            Text(name.uppercased())
                .font(.system(size: small ? 9 : 10, weight: .bold))
                .tracking(0.6)
        }
        .foregroundColor(muted ? Theme.dim : Theme.gemColor(hue: colorHue))
        .padding(.horizontal, small ? 7 : 8)
        .padding(.vertical, small ? 3 : 3)
        .background(
            Capsule().fill(Theme.gemColor(hue: colorHue).opacity(muted ? 0.08 : 0.15))
        )
        .overlay(
            Capsule().stroke(Theme.gemColor(hue: colorHue).opacity(muted ? 0.12 : 0.35), lineWidth: 1)
        )
    }
}

/// Tag filter chip at the top of ChecklistRunView. Tap to toggle "hide items
/// with this tag" for the current run.
struct TagHideChip: View {
    let name: String
    let iconName: String
    let colorHue: Double
    let hidden: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 5) {
                GemIcons.image(hidden ? "eye-off" : iconName)
                    .font(.system(size: 11, weight: .bold))
                Text(name)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(hidden ? Theme.dim : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Group {
                    if hidden {
                        Capsule().fill(Color.white.opacity(0.04))
                    } else {
                        Capsule().fill(
                            LinearGradient(
                                colors: [
                                    Theme.gemColor(hue: colorHue),
                                    Theme.gemColor(hue: colorHue).opacity(0.7),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    }
                }
            )
            .overlay(
                Capsule().stroke(
                    hidden ? Theme.border : Theme.gemColor(hue: colorHue).opacity(0.5),
                    lineWidth: 1
                )
            )
            .opacity(hidden ? 0.72 : 1)
        }
        .buttonStyle(.plain)
    }
}

#Preview("Tag chips") {
    VStack(spacing: 12) {
        HStack(spacing: 6) {
            TagChip(name: "Beach", iconName: "sun", colorHue: 85)
            TagChip(name: "Snow", iconName: "snow", colorHue: 250)
            TagChip(name: "Hike", iconName: "leaf", colorHue: 160, muted: true)
        }
        HStack(spacing: 6) {
            TagHideChip(name: "Beach", iconName: "sun", colorHue: 85, hidden: false) {}
            TagHideChip(name: "Snow", iconName: "snow", colorHue: 250, hidden: true) {}
            TagHideChip(name: "Hike", iconName: "leaf", colorHue: 160, hidden: false) {}
        }
    }
    .padding()
    .background(Theme.bg)
}
```

- [ ] **Step 2: Build + preview**

```bash
xcodebuild -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build build 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
git add Checklist/Checklist/Design/Components/TagChip.swift
git commit -m "feat(design): add TagChip and TagHideChip components"
```

---

### Task 3.6: GemBar (segmented progress bar)

**Files:**
- Create: `Checklist/Checklist/Design/Components/GemBar.swift`

- [ ] **Step 1: Implement GemBar**

Write `Checklist/Checklist/Design/Components/GemBar.swift`:

```swift
import SwiftUI

/// Segmented progress bar — each "segment" is a tiny gem, colored in palette
/// rotation. Lit segments glow; unlit are dim. Staggered animation as percent
/// advances.
struct GemBar: View {
    let progress: Double    // 0.0 ... 1.0
    var segments: Int = 14

    private let palette: [Color] = [
        Theme.amethyst, Theme.sapphire, Theme.emerald, Theme.citrine, Theme.ruby, Theme.peridot,
    ]

    var body: some View {
        HStack(spacing: 2.5) {
            ForEach(0..<segments, id: \.self) { i in
                let lit = Double(i) < progress * Double(segments)
                let color = palette[i % palette.count]
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(
                        lit
                            ? LinearGradient(
                                colors: [color.opacity(0.95), color],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            : LinearGradient(colors: [Color.white.opacity(0.06), Color.white.opacity(0.06)], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 8, height: 16)
                    .shadow(color: lit ? color.opacity(0.53) : .clear, radius: 3, x: 0, y: 0)
                    .animation(
                        .spring(response: 0.32, dampingFraction: 0.6).delay(Double(i) * 0.018),
                        value: progress
                    )
            }
        }
    }
}

#Preview("GemBar progression") {
    VStack(spacing: 16) {
        GemBar(progress: 0.0)
        GemBar(progress: 0.25)
        GemBar(progress: 0.5)
        GemBar(progress: 0.75)
        GemBar(progress: 1.0)
    }
    .padding()
    .background(Theme.bg)
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build build 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
git add Checklist/Checklist/Design/Components/GemBar.swift
git commit -m "feat(design): add GemBar segmented progress component"
```

---

### Task 3.7: HeroGem

**Files:**
- Create: `Checklist/Checklist/Design/Components/HeroGem.swift`

- [ ] **Step 1: Implement HeroGem**

Write `Checklist/Checklist/Design/Components/HeroGem.swift`:

```swift
import SwiftUI

/// Large celebratory gem rendered at the top of completion sheets. Visual
/// stand-in for the richer gem-minting in the v2 delight layer.
struct HeroGem: View {
    let color: Color
    var progress: Double = 1.0
    var size: CGFloat = 62

    var body: some View {
        ZStack {
            // Backdrop glow
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: size * 1.4, height: size * 1.4)
                .blur(radius: size * 0.35)

            // Gem body
            RoundedRectangle(cornerRadius: size * 0.25)
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .rotationEffect(.degrees(45))
                .frame(width: size * 0.72, height: size * 0.72)
                .overlay(
                    // Facet highlight
                    RoundedRectangle(cornerRadius: size * 0.25)
                        .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                        .rotationEffect(.degrees(45))
                        .frame(width: size * 0.72, height: size * 0.72)
                        .opacity(progress)
                )
        }
        .frame(width: size * 1.4, height: size * 1.4)
    }
}

#Preview("HeroGem") {
    HStack(spacing: 20) {
        HeroGem(color: Theme.emerald, progress: 1.0)
        HeroGem(color: Theme.citrine, progress: 0.6)
        HeroGem(color: Theme.amethyst, progress: 0.3, size: 80)
    }
    .padding()
    .background(Theme.bg)
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build build 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
git add Checklist/Checklist/Design/Components/HeroGem.swift
git commit -m "feat(design): add HeroGem celebration component"
```

---

### Task 3.8: BottomSheet (reusable sheet container)

**Files:**
- Create: `Checklist/Checklist/Design/Components/BottomSheet.swift`

- [ ] **Step 1: Implement BottomSheet**

Write `Checklist/Checklist/Design/Components/BottomSheet.swift`:

```swift
import SwiftUI

/// Shared bottom sheet wrapper. All prototype sheets share this chrome:
/// dimmed overlay, rounded top corners, drag-handle pill, ivory text on
/// violet background. Use as a `.sheet(isPresented:)` content wrapper.
struct BottomSheet<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Theme.border)
                .frame(width: 42, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 4)

            content()
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.bottom, Theme.Spacing.xxl)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            LinearGradient(
                colors: [Theme.bg2, Theme.bg],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedCornerShape(radius: 28, corners: [.topLeft, .topRight]))
        .overlay(
            RoundedCornerShape(radius: 28, corners: [.topLeft, .topRight])
                .stroke(Theme.borderHi, lineWidth: 1)
        )
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.clear)
    }
}

/// Corner-specific rounded rectangle helper.
private struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        ).cgPath)
    }
}

#Preview("BottomSheet") {
    Color.gray.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            BottomSheet {
                VStack(alignment: .leading, spacing: 12) {
                    Text("NEW LIST")
                        .font(Theme.eyebrow())
                        .foregroundColor(Theme.dim)
                        .tracking(2)
                    Text("Name your checklist.")
                        .font(Theme.display(size: 26))
                        .foregroundColor(Theme.text)
                    PillButton(title: "Create", wide: true) {}
                }
            }
        }
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build build 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
git add Checklist/Checklist/Design/Components/BottomSheet.swift
git commit -m "feat(design): add BottomSheet shared sheet container"
```

---

### Task 3.9: TopBar + IconButton

**Files:**
- Create: `Checklist/Checklist/Design/Components/TopBar.swift`

- [ ] **Step 1: Implement TopBar and IconButton**

Write `Checklist/Checklist/Design/Components/TopBar.swift`:

```swift
import SwiftUI

/// Consistent top-of-screen bar with optional left/right icon button slots.
struct TopBar<Left: View, Right: View>: View {
    @ViewBuilder let left: () -> Left
    @ViewBuilder let right: () -> Right

    var body: some View {
        HStack {
            left()
            Spacer()
            right()
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.sm)
        .frame(minHeight: 40)
    }
}

/// Circular icon button. `solid: true` fills with a gem-color gradient + glow
/// (used for the home `+` add button). `solid: false` is a hairline circle.
struct IconButton: View {
    let iconName: String
    var size: CGFloat = 36
    var solid: Bool = false
    var color: Color = Theme.amethyst
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if solid {
                    GemIcons.image(iconName)
                        .font(.system(size: size * 0.4, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    GemIcons.image(iconName)
                        .font(.system(size: size * 0.4, weight: .semibold))
                        .foregroundColor(Theme.dim)
                }
            }
            .frame(width: size, height: size)
            .background(
                Group {
                    if solid {
                        Circle().fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    } else {
                        Circle().fill(Color.white.opacity(0.05))
                    }
                }
            )
            .overlay(
                solid
                    ? nil
                    : Circle().stroke(Theme.border, lineWidth: 1)
            )
            .shadow(color: solid ? color.opacity(0.4) : .clear, radius: 10)
        }
        .buttonStyle(.plain)
    }
}

#Preview("TopBar") {
    VStack {
        TopBar(
            left: { IconButton(iconName: "back") {} },
            right: { IconButton(iconName: "more") {} }
        )
        TopBar(
            left: { IconButton(iconName: "sun") {} },
            right: { IconButton(iconName: "plus", solid: true) {} }
        )
        Spacer()
    }
    .background(Theme.bg)
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build build 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
git add Checklist/Checklist/Design/Components/TopBar.swift
git commit -m "feat(design): add TopBar and IconButton components"
```

---

### Task 3.10: ChecklistCard (home grid card)

**Files:**
- Create: `Checklist/Checklist/Design/Components/ChecklistCard.swift`

- [ ] **Step 1: Implement ChecklistCard**

Write `Checklist/Checklist/Design/Components/ChecklistCard.swift`:

```swift
import SwiftUI

/// Home-screen grid card. Shows category eyebrow (+ optional run label), the
/// checklist name, progress fraction, GemBar, and an optional "N RUNS" badge
/// when multiple live runs exist.
struct ChecklistCard: View {
    let categoryName: String?
    let primaryRunLabel: String?
    let name: String
    let progress: (done: Int, total: Int)
    let liveRunCount: Int
    let onTap: () -> Void

    private var pct: Double {
        guard progress.total > 0 else { return 0 }
        return Double(progress.done) / Double(progress.total)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    eyebrow
                    Spacer()
                    fraction
                }

                Text(name)
                    .font(Theme.display(size: 22))
                    .foregroundColor(Theme.text)

                GemBar(progress: pct, segments: 16)
                    .padding(.top, 2)
            }
            .padding(Theme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.xl)
                    .fill(Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.xl)
                    .stroke(Theme.border, lineWidth: 1)
            )
            .overlay(alignment: .topTrailing) {
                if liveRunCount >= 2 {
                    Text("\(liveRunCount) RUNS")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.6)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(
                                LinearGradient(
                                    colors: [Theme.amethyst, Theme.amethyst.opacity(0.72)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        )
                        .padding(Theme.Spacing.md)
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var eyebrow: some View {
        HStack(spacing: 6) {
            if let categoryName {
                Text(categoryName.uppercased())
                    .foregroundColor(Theme.dim)
            }
            if let label = primaryRunLabel {
                Text("·")
                    .foregroundColor(Theme.dimmer)
                Text(label.uppercased())
                    .foregroundColor(Theme.citrine)
            }
        }
        .font(Theme.eyebrow())
        .tracking(2)
    }

    private var fraction: some View {
        Text("\(progress.done)/\(progress.total)")
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(Theme.dim)
    }
}

#Preview("ChecklistCard") {
    VStack(spacing: 10) {
        ChecklistCard(
            categoryName: "Travel",
            primaryRunLabel: "Tokyo",
            name: "Packing List",
            progress: (done: 4, total: 18),
            liveRunCount: 2
        ) {}
        ChecklistCard(
            categoryName: "Daily",
            primaryRunLabel: nil,
            name: "Morning Routine",
            progress: (done: 3, total: 8),
            liveRunCount: 1
        ) {}
        ChecklistCard(
            categoryName: "Home",
            primaryRunLabel: nil,
            name: "Weekly Groceries",
            progress: (done: 0, total: 12),
            liveRunCount: 0
        ) {}
    }
    .padding()
    .background(Theme.bg)
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build build 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
git add Checklist/Checklist/Design/Components/ChecklistCard.swift
git commit -m "feat(design): add ChecklistCard home grid component"
```

---

### Task 3.11: SectionLabel

**Files:**
- Create: `Checklist/Checklist/Design/Components/SectionLabel.swift`

- [ ] **Step 1: Implement SectionLabel**

Write `Checklist/Checklist/Design/Components/SectionLabel.swift`:

```swift
import SwiftUI

/// Uppercase eyebrow caption used throughout the app (e.g. "YOUR CATEGORIES",
/// "PREVIOUS RUNS", "DANGER ZONE"). Optional right-aligned hint.
struct SectionLabel: View {
    let text: String
    var hint: String? = nil

    var body: some View {
        HStack {
            Text(text.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(2)
                .foregroundColor(Theme.dim)
            Spacer()
            if let hint {
                Text(hint.uppercased())
                    .font(.system(size: 11, weight: .regular))
                    .tracking(0.5)
                    .foregroundColor(Theme.dimmer)
            }
        }
    }
}

#Preview("SectionLabel") {
    VStack(alignment: .leading, spacing: 18) {
        SectionLabel(text: "Your categories")
        SectionLabel(text: "Previous runs", hint: "3")
        SectionLabel(text: "Danger zone")
    }
    .padding()
    .background(Theme.bg)
    .foregroundColor(Theme.text)
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build build 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
git add Checklist/Checklist/Design/Components/SectionLabel.swift
git commit -m "feat(design): add SectionLabel caption component"
```

---

### Task 3.12: Final Phase 3 verification

- [ ] **Step 1: Run full test suite**

```bash
xcodebuild test -scheme Checklist -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -derivedDataPath .build 2>&1 | tail -15
```

Expected: all model + store tests pass.

- [ ] **Step 2: Launch app to confirm placeholder still renders**

```bash
APP_PATH=$(find .build -name "Checklist.app" -type d | head -1)
xcrun simctl install booted "$APP_PATH"
xcrun simctl launch booted com.lchogan.Checklist
sleep 2
xcrun simctl io booted screenshot /tmp/phase-3-placeholder.png
```

Expected: placeholder screen renders; no crashes.

- [ ] **Step 3: Verify every component preview renders in Xcode**

Open Xcode, select each file under `Design/Components/`, confirm the `#Preview` canvas renders without errors:

- `Facet.swift`
- `PillButton.swift`
- `TagChip.swift`
- `GemBar.swift`
- `HeroGem.swift`
- `BottomSheet.swift`
- `TopBar.swift`
- `ChecklistCard.swift`
- `SectionLabel.swift`

- [ ] **Step 4: Archive-tag the foundation**

```bash
git tag plan-1-foundation-complete
```

---

## Self-review checklist (run before handoff)

- [ ] Every phase/task from the spec's §5 table for Phases 0–3 has a corresponding task in this plan.
- [ ] Every `@Model` class, Store function, and Design component is defined with full code (no placeholders).
- [ ] Type names used in later tasks match earlier definitions (e.g., `CheckState`, `CompletedRunSnapshot`, `ChecklistStore.create`).
- [ ] Every test shows actual assertions, not "add tests here."
- [ ] Every build/test command has an `Expected:` line.
- [ ] Every step is committable as a standalone unit (tests pass, builds succeed).
- [ ] No references to files not yet defined at the point they're referenced.

---

## Handoff

Plan 1 produces:
- 7 SwiftData `@Model` classes with cascade relationships
- 5 stateless Store namespaces with ≥85% coverage
- Theme + GemIcons + 9 reusable Design components with previews
- A buildable, launch-able app showing a placeholder screen
- Tag `plan-1-foundation-complete` on the last commit

Next plan (Plan 2, Home + ChecklistRunView) will consume the Design components + SeedStore fixtures from this plan.

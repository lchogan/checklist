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
                HomeView()
                    .environmentObject(entitlementManager)
                    .environmentObject(storeKit)
                    .modelContainer(container)
            } else {
                ProgressView("Loading…")
            }
        }
        .onAppear { setupModelContainer() }
        .onChange(of: entitlementManager.limits.cloudKitSync) { _, _ in setupModelContainer() }
        .onOpenURL { url in
            #if DEBUG
            if let fixture = FixtureRouter.fixture(from: url) {
                loadFixture(fixture)
            }
            #endif
        }
    }

    /// DEBUG-only: swaps the running container for a freshly-seeded one. Called
    /// when a `checklist://seed/<name>` URL is opened.
    private func loadFixture(_ fixture: SeedStore.Fixture) {
        guard let container = try? SeedStore.container(for: fixture) else { return }
        modelContainer = container
    }

    private func setupModelContainer() {
        do {
            // Phase 1 complete schema (Task 1.8). All 7 @Model types listed so
            // the app container matches the binary — prevents loadIssueModelContainer
            // in unit tests (CloudKit entitlement requires cloudKitDatabase: .none
            // for in-memory containers; see TestHelpers.makeTestConfig()).
            let schema = Schema([
                ChecklistCategory.self,
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
                cloudKitDatabase: entitlementManager.limits.cloudKitSync ? .automatic : .none
            )
            modelContainer = try ModelContainer(for: schema, configurations: configuration)
        } catch {
            print("Failed to create ModelContainer: \(error)")
        }
    }
}

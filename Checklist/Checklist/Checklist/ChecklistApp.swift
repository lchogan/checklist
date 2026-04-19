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

import SwiftUI
import SwiftData

@main
struct ChecklistApp: App {
    /// EntitlementManager is created first so StoreKitManager can reference it.
    @StateObject private var entitlementManager = EntitlementManager()
    
    var body: some Scene {
        WindowGroup {
            // AppRoot wires StoreKitManager to EntitlementManager and injects both
            // into the environment before any view that might need them.
            AppRoot(entitlementManager: entitlementManager)
        }
    }
}

/// Thin wrapper that creates StoreKitManager (which needs EntitlementManager)
/// and provides both as environment objects.
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
                ChecklistListView()
                    .environmentObject(entitlementManager)
                    .environmentObject(storeKit)
                    .modelContainer(container)
            } else {
                ProgressView("Loading...")
            }
        }
        .onAppear {
            setupModelContainer()
        }
        .onChange(of: entitlementManager.isPremium) { oldValue, newValue in
            // When premium status changes, reconfigure the container
            if oldValue != newValue {
                setupModelContainer()
            }
        }
    }
    
    private func setupModelContainer() {
        do {
            let schema = Schema([
                Checklist.self,
                ChecklistItem.self,
                Tag.self,
                ChecklistCategory.self
            ])
            
            let configuration: ModelConfiguration
            
            if entitlementManager.isPremium {
                // Premium: Use CloudKit sync
                configuration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    allowsSave: true,
                    cloudKitDatabase: .automatic
                )
            } else {
                // Free: Local storage only
                configuration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    allowsSave: true,
                    cloudKitDatabase: .none
                )
            }
            
            modelContainer = try ModelContainer(
                for: schema,
                configurations: configuration
            )
        } catch {
            print("Failed to create ModelContainer: \(error)")
        }
    }
}

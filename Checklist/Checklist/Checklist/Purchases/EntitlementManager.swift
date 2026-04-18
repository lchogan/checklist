import Foundation
import Combine

/// Single source of truth for the user's current entitlement.
/// Views read `limits` to gate feature access.
@MainActor
final class EntitlementManager: ObservableObject {
    @Published private(set) var isPremium: Bool = false

    var limits: FeatureLimits {
        isPremium ? .premium : .free
    }

    /// Called by StoreKitManager when subscription state changes.
    func updatePremiumStatus(_ premium: Bool) {
        isPremium = premium
    }
}

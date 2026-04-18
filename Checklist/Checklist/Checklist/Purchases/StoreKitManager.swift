import Foundation
import StoreKit
import Combine

/// Manages StoreKit 2 product loading, purchasing, and entitlement verification.
@MainActor
final class StoreKitManager: ObservableObject {

    // MARK: - Product IDs
    // Update these to match your App Store Connect configuration.
    static let monthlyProductID = "com.checklist.premium.monthly"
    static let annualProductID  = "com.checklist.premium.annual"

    // MARK: - Published state
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Private
    private weak var entitlementManager: EntitlementManager?
    private var transactionListenerTask: Task<Void, Error>?

    // MARK: - Init / deinit

    init(entitlementManager: EntitlementManager) {
        self.entitlementManager = entitlementManager
        transactionListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    // MARK: - Computed

    var monthlyProduct: Product? {
        products.first { $0.id == Self.monthlyProductID }
    }

    var annualProduct: Product? {
        products.first { $0.id == Self.annualProductID }
    }

    // MARK: - Actions

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(
                for: [Self.monthlyProductID, Self.annualProductID]
            ).sorted { $0.price < $1.price }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func purchase(_ product: Product) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlements()
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Private helpers

    func refreshEntitlements() async {
        var hasPremium = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productType == .autoRenewable,
               transaction.revocationDate == nil {
                hasPremium = true
            }
        }
        entitlementManager?.updatePremiumStatus(hasPremium)
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.refreshEntitlements()
                }
            }
        }
    }
}

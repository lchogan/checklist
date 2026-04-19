/// StoreKitManager.swift
/// Purpose: Manages StoreKit 2 product loading, purchasing, and entitlement
///   verification. Product IDs come from PlanCatalog (bundled plans.json),
///   not hardcoded constants.
/// Dependencies: Foundation, StoreKit, Combine, PlanCatalog, EntitlementManager.
/// Key concepts:
///   - `products` is filtered to the IDs declared in PlanCatalog.
///   - `refreshEntitlements` gathers verified, non-revoked, auto-renewable
///     transactions, pulls their productIDs, and notifies EntitlementManager.

import Foundation
import StoreKit
import Combine

/// Loads products matching PlanCatalog.allProductIDs; listens for transactions
/// and forwards the owned-product-ID set to EntitlementManager.
@MainActor
final class StoreKitManager: ObservableObject {

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

    // MARK: - Computed convenience (used by paywall)

    /// The cheapest monthly-period product, if any. Used by PaywallSheet
    /// when it wants to show a primary "Monthly" CTA.
    var monthlyProduct: Product? {
        products.first { $0.subscription?.subscriptionPeriod.unit == .month }
    }

    /// The cheapest yearly product, if any.
    var annualProduct: Product? {
        products.first { $0.subscription?.subscriptionPeriod.unit == .year }
    }

    // MARK: - Public actions

    /// Fetches all product info for the IDs declared in PlanCatalog.
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let ids = PlanCatalog.allProductIDs
            guard !ids.isEmpty else { products = []; return }
            products = try await Product.products(for: ids)
                .sorted { $0.price < $1.price }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Initiates a purchase. On success, finalizes the transaction and
    /// refreshes entitlements.
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

    /// Re-syncs entitlements with the App Store (for Restore Purchases).
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

    /// Gathers the set of currently-owned, verified, non-revoked, auto-renewable
    /// product IDs and forwards them to EntitlementManager.
    func refreshEntitlements() async {
        var owned: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productType == .autoRenewable,
               transaction.revocationDate == nil {
                owned.insert(transaction.productID)
            }
        }
        entitlementManager?.updateOwnedProducts(owned)
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

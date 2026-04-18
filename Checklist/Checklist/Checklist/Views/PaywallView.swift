import SwiftUI
import StoreKit

// MARK: - Paywall reason

enum PaywallReason: Identifiable {
    case checklistLimit(Int)
    case tagLimit(Int)
    case categoryLimit(Int)

    var id: String {
        switch self {
        case .checklistLimit: return "checklist"
        case .tagLimit:       return "tag"
        case .categoryLimit:  return "category"
        }
    }

    var message: String {
        switch self {
        case .checklistLimit(let n):
            return "The free plan includes \(n) checklist. Upgrade for unlimited checklists."
        case .tagLimit(let n):
            return "The free plan includes \(n) tags. Upgrade for unlimited tags."
        case .categoryLimit(let n):
            if n == 0 {
                return "Categories are a Premium feature. Upgrade for unlimited categories."
            }
            let word = n == 1 ? "category" : "categories"
            return "The free plan includes \(n) \(word). Upgrade for unlimited categories."
        }
    }
}

// MARK: - Paywall view

/// Present as: `.sheet(item: $paywallReason) { PaywallView(reason: $0) }`
/// Requires `.environmentObject(entitlementManager)` and `.environmentObject(storeKit)`.
struct PaywallView: View {
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var storeKit: StoreKitManager
    @Environment(\.dismiss) private var dismiss

    let reason: PaywallReason

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.accentColor)
                            .padding(.top, 8)

                        Text("Checklist Premium")
                            .font(.title.bold())

                        Text(reason.message)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Feature bullets
                    VStack(alignment: .leading, spacing: 14) {
                        FeatureBullet(icon: "checklist.unchecked", text: "Unlimited checklists")
                        FeatureBullet(icon: "tag.fill",            text: "Unlimited tags")
                        FeatureBullet(icon: "folder.fill",         text: "Unlimited categories")
                        FeatureBullet(icon: "icloud.fill",         text: "iCloud sync across devices")
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // Purchase options
                    if storeKit.isLoading {
                        ProgressView()
                            .padding()
                    } else {
                        VStack(spacing: 12) {
                            if let annual = storeKit.annualProduct {
                                PurchaseOptionButton(product: annual, badge: "Best Value") {
                                    Task { await storeKit.purchase(annual) }
                                }
                            }
                            if let monthly = storeKit.monthlyProduct {
                                PurchaseOptionButton(product: monthly, badge: nil) {
                                    Task { await storeKit.purchase(monthly) }
                                }
                            }
                            if storeKit.annualProduct == nil && storeKit.monthlyProduct == nil {
                                Text("Products not found. Check your App Store Connect setup.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.horizontal)
                    }

                    Button {
                        Task { await storeKit.restorePurchases() }
                    } label: {
                        Text("Restore Purchases")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text("Subscriptions renew automatically. Cancel any time in iOS Settings.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not Now") { dismiss() }
                }
            }
            .alert("Error", isPresented: .init(
                get: { storeKit.errorMessage != nil },
                set: { if !$0 { storeKit.errorMessage = nil } }
            )) {
                Button("OK") { storeKit.errorMessage = nil }
            } message: {
                Text(storeKit.errorMessage ?? "")
            }
            .onChange(of: entitlementManager.isPremium) { _, isPremium in
                if isPremium { dismiss() }
            }
        }
    }
}

// MARK: - Subviews

private struct FeatureBullet: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
            Spacer()
            Image(systemName: "checkmark")
                .font(.subheadline.bold())
                .foregroundStyle(.green)
        }
    }
}

private struct PurchaseOptionButton: View {
    let product: Product
    let badge: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.displayName)
                        .font(.headline)
                    Text(product.description)
                        .font(.caption)
                        .opacity(0.85)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(product.displayPrice)
                        .font(.headline)
                    if let badge {
                        Text(badge)
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.white.opacity(0.25), in: Capsule())
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }
}

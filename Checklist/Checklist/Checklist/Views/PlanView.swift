import SwiftUI
import StoreKit

/// Plan management screen showing subscription options
struct PlanView: View {
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var storeKit: StoreKitManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Current Plan Status
                    VStack(spacing: 16) {
                        Image(systemName: entitlementManager.isPremium ? "checkmark.seal.fill" : "seal.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(entitlementManager.isPremium ? .green : .secondary)
                            .padding(.top, 8)
                        
                        Text(entitlementManager.isPremium ? "Premium Plan" : "Free Plan")
                            .font(.title.bold())
                        
                        if entitlementManager.isPremium {
                            Text("You have access to all premium features")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        } else {
                            Text("Upgrade to unlock unlimited features")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Feature Comparison
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What's Included")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            PlanFeatureRow(
                                icon: "checklist.unchecked",
                                feature: "Checklists",
                                freeValue: "\(entitlementManager.limits.maxChecklists ?? 1)",
                                premiumValue: "Unlimited"
                            )
                            Divider().padding(.leading, 56)
                            
                            PlanFeatureRow(
                                icon: "tag.fill",
                                feature: "Tags",
                                freeValue: "\(entitlementManager.limits.maxTags ?? 3)",
                                premiumValue: "Unlimited"
                            )
                            Divider().padding(.leading, 56)
                            
                            PlanFeatureRow(
                                icon: "folder.fill",
                                feature: "Categories",
                                freeValue: entitlementManager.limits.maxCategories == 0 ? "None" : "\(entitlementManager.limits.maxCategories ?? 0)",
                                premiumValue: "Unlimited"
                            )
                            Divider().padding(.leading, 56)
                            
                            PlanFeatureRow(
                                icon: "icloud.fill",
                                feature: "iCloud Sync",
                                freeValue: "—",
                                premiumValue: "✓"
                            )
                        }
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }
                    
                    // Purchase Options (if not premium)
                    if !entitlementManager.isPremium {
                        VStack(spacing: 12) {
                            Text("Choose Your Plan")
                                .font(.headline)
                            
                            if storeKit.isLoading {
                                ProgressView()
                                    .padding()
                            } else {
                                VStack(spacing: 12) {
                                    if let annual = storeKit.annualProduct {
                                        PremiumPurchaseButton(product: annual, badge: "Best Value") {
                                            Task { await storeKit.purchase(annual) }
                                        }
                                    }
                                    if let monthly = storeKit.monthlyProduct {
                                        PremiumPurchaseButton(product: monthly, badge: nil) {
                                            Task { await storeKit.purchase(monthly) }
                                        }
                                    }
                                    if storeKit.annualProduct == nil && storeKit.monthlyProduct == nil {
                                        Text("Products not available. Please try again later.")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        Button {
                            Task { await storeKit.restorePurchases() }
                        } label: {
                            Text("Restore Purchases")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Text("Subscriptions renew automatically. Cancel anytime in iOS Settings.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    } else {
                        // Manage Subscription (if premium)
                        VStack(spacing: 16) {
                            Button {
                                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                    openURL(url)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "gearshape.fill")
                                    Text("Manage Subscription")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(.white)
                            }
                            .padding(.horizontal)
                            
                            Text("Manage or cancel your subscription in the App Store.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
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
        }
    }
}

// MARK: - Plan Feature Row

private struct PlanFeatureRow: View {
    let icon: String
    let feature: String
    let freeValue: String
    let premiumValue: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 32)
            
            Text(feature)
                .font(.subheadline)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("Free: \(freeValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Premium: \(premiumValue)")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

// MARK: - Premium Purchase Button

private struct PremiumPurchaseButton: View {
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

#Preview {
    let em = EntitlementManager()
    PlanView()
        .environmentObject(em)
        .environmentObject(StoreKitManager(entitlementManager: em))
}

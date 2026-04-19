/// PaywallSheet.swift
/// Purpose: Presents the upgrade offer when EntitlementGate returns .blocked,
///   or when the user taps "Upgrade" from SettingsView. Feature-specific
///   headline copy comes from the Reason passed in.
/// Dependencies: SwiftUI, StoreKit, BottomSheet, PillButton, HeroGem, Theme,
///   GemIcons, EntitlementManager, StoreKitManager, GateDecision, FeatureLimits.
/// Key concepts:
///   - `reason` is optional. nil = generic "unlock everything" pitch (opened
///     from Settings); non-nil = feature-specific gate trigger.
///   - Product list pulls from StoreKitManager.products (sorted by price).
///   - "Restore purchases" calls through to StoreKitManager.restorePurchases.

import SwiftUI
import StoreKit

/// Sheet shown when an EntitlementGate returns .blocked, or from SettingsView's
/// Upgrade row. Offers the active paid plans pulled from StoreKitManager.
struct PaywallSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var storeKit: StoreKitManager
    @EnvironmentObject private var entitlementManager: EntitlementManager

    /// The reason the paywall opened (feature + cap + message). nil when the
    /// user opened Settings → Upgrade directly.
    let reason: GateDecision.Reason?

    var body: some View {
        BottomSheet {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                hero
                pitchCopy
                featureList
                productButtons
                footerRow
            }
        }
    }

    // MARK: - Hero

    private var hero: some View {
        HStack(spacing: Theme.Spacing.md) {
            HeroGem(color: Theme.amethyst, size: 56)
            VStack(alignment: .leading, spacing: 4) {
                Text("UPGRADE")
                    .font(Theme.eyebrow()).tracking(2)
                    .foregroundColor(Theme.amethyst)
                Text(headline)
                    .font(Theme.display(size: 26))
                    .foregroundColor(Theme.text)
            }
        }
    }

    /// Headline: feature-specific when `reason` is set, generic otherwise.
    private var headline: String {
        guard let reason else { return "Unlock everything." }
        switch reason.dimension {
        case .checklists:   return "Unlock more checklists."
        case .items:        return "Keep adding items."
        case .liveRuns:     return "Run many trips at once."
        case .totalRuns:    return "Keep your full history."
        case .tags:         return "Unlock more tags."
        case .categories:   return "Organize with categories."
        case .cloudKitSync: return "Sync across devices."
        }
    }

    // MARK: - Pitch

    private var pitchCopy: some View {
        Text(reason?.message ?? "Checklist Plus unlocks unlimited lists, items, runs, tags, categories, and iCloud sync across your devices.")
            .font(.system(size: 14))
            .foregroundColor(Theme.dim)
    }

    // MARK: - Feature list

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 6) {
            featureBullet("Unlimited checklists + items")
            featureBullet("Concurrent live runs")
            featureBullet("Unlimited tags + categories")
            featureBullet("iCloud sync across all your devices")
        }
    }

    private func featureBullet(_ text: String) -> some View {
        HStack(spacing: 8) {
            GemIcons.image("check")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Theme.emerald)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Theme.text)
        }
    }

    // MARK: - Product buttons

    private var productButtons: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(storeKit.products, id: \.id) { product in
                productButton(product)
            }
            if storeKit.products.isEmpty {
                Text(storeKit.isLoading ? "Loading plans…" : "Plans unavailable. Check your connection.")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.dim)
            }
        }
    }

    private func productButton(_ product: Product) -> some View {
        PillButton(
            title: productLabel(product),
            color: Theme.amethyst,
            wide: true
        ) {
            Task {
                await storeKit.purchase(product)
                if entitlementManager.isPremium { dismiss() }
            }
        }
    }

    /// Formats the product label as "DISPLAY NAME · PRICE/PERIOD".
    private func productLabel(_ product: Product) -> String {
        let period: String
        if let sub = product.subscription?.subscriptionPeriod {
            switch sub.unit {
            case .day:   period = "day"
            case .week:  period = "week"
            case .month: period = "mo"
            case .year:  period = "yr"
            @unknown default: period = ""
            }
        } else {
            period = ""
        }
        let price = product.displayPrice
        let name = product.displayName.isEmpty
            ? (PlanCatalog.plan(for: product.id)?.displayName ?? "Plus")
            : product.displayName
        return "\(name) · \(price)/\(period)"
    }

    // MARK: - Footer

    private var footerRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            PillButton(title: "Maybe later", tone: .ghost, wide: true) { dismiss() }
            PillButton(title: "Restore", tone: .ghost, wide: true) {
                Task { await storeKit.restorePurchases() }
            }
        }
        .padding(.top, Theme.Spacing.sm)
    }
}

// MARK: - Previews

#Preview("Paywall — tags reason") {
    let ent = EntitlementManager()
    let sk = StoreKitManager(entitlementManager: ent)
    return Color.gray.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            PaywallSheet(
                reason: .init(
                    dimension: .tags, limit: 3,
                    message: "Free plan is limited to 3 tags. Upgrade for unlimited."
                )
            )
            .environmentObject(ent)
            .environmentObject(sk)
        }
}

#Preview("Paywall — no reason") {
    let ent = EntitlementManager()
    let sk = StoreKitManager(entitlementManager: ent)
    return Color.gray.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            PaywallSheet(reason: nil)
                .environmentObject(ent)
                .environmentObject(sk)
        }
}

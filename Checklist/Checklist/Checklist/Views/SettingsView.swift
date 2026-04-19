/// SettingsView.swift
/// Purpose: Settings home — stats row (total lists / runs / tags), shortcut
///   rows to Categories/Tags/History, account row (active plan + manage/
///   upgrade), and a danger zone (Clear all history).
/// Dependencies: SwiftUI, SwiftData, Theme, TopBar, PillButton, GemIcons,
///   EntitlementManager, StoreKitManager, RunStore, PaywallSheet,
///   CategoriesView, TagsView, HistoryView.
/// Key concepts:
///   - @Query drives the stat counts.
///   - Nav rows are Buttons that append to `path` so each destination lives
///     at the root navigationDestination registration on HomeView.

import SwiftUI
import SwiftData

/// Settings root. Reads counts live from @Query, emits nav via `path`.
struct SettingsView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var storeKit: StoreKitManager
    @Binding var path: NavigationPath

    @Query private var checklists: [Checklist]
    @Query private var tags: [Tag]
    @Query private var categories: [ChecklistCategory]
    @Query private var completedRuns: [CompletedRun]

    @State private var showPaywall = false
    @State private var showClearHistoryConfirm = false

    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        headerBlock
                        statsCard
                        planCard
                        shortcutRows
                        dangerZone
                        Spacer(minLength: 40)
                    }
                    .padding(.top, Theme.Spacing.md)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showPaywall) {
            PaywallSheet(reason: nil)
        }
        .alert(
            "Clear all history?",
            isPresented: $showClearHistoryConfirm,
            actions: {
                Button("Clear all", role: .destructive) {
                    try? RunStore.clearAllHistory(in: ctx)
                }
                Button("Cancel", role: .cancel) {}
            },
            message: {
                Text("Permanently deletes all completed runs on every checklist. Can't be undone.")
            }
        )
    }

    private var topBar: some View {
        TopBar(
            left: { IconButton(iconName: "back") { dismiss() } },
            right: { Color.clear.frame(width: 36, height: 36) }
        )
    }

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("PREFERENCES")
                .font(Theme.eyebrow()).tracking(2)
                .foregroundColor(Theme.dim)
            Text("Settings.")
                .font(Theme.display(size: 34, weight: .bold))
                .foregroundColor(Theme.text)
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    private var statsCard: some View {
        HStack(spacing: Theme.Spacing.md) {
            stat("Lists",       "\(checklists.count)")
            stat("Runs done",   "\(completedRuns.count)")
            stat("Tags",        "\(tags.count)")
            stat("Categories",  "\(categories.count)")
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(Theme.display(size: 22))
                .foregroundColor(Theme.text)
            Text(title.uppercased())
                .font(Theme.eyebrow()).tracking(1.5)
                .foregroundColor(Theme.dim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.border, lineWidth: 1))
    }

    private var planCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("YOUR PLAN")
                .font(Theme.eyebrow()).tracking(2)
                .foregroundColor(Theme.dim)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entitlementManager.activePlan.displayName)
                        .font(Theme.display(size: 20))
                        .foregroundColor(Theme.text)
                    Text(planSubtitle)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.dim)
                }
                Spacer()
                if entitlementManager.isPremium {
                    PillButton(title: "Manage", tone: .ghost, small: true) {
                        Task { await storeKit.restorePurchases() }
                    }
                } else {
                    PillButton(title: "Upgrade", color: Theme.amethyst, small: true) {
                        showPaywall = true
                    }
                }
            }
            .padding(Theme.Spacing.md)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Theme.card))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.border, lineWidth: 1))
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    /// Subtitle below the plan name: lists "N lists · M tags · iCloud on/off".
    private var planSubtitle: String {
        let l = entitlementManager.limits
        let lists = l.checklistLimitDescription
        let tags = l.tagLimitDescription
        let sync = l.cloudKitSync ? "iCloud on" : "iCloud off"
        return "\(lists) · \(tags) · \(sync)"
    }

    private var shortcutRows: some View {
        VStack(spacing: Theme.Spacing.xs) {
            shortcut(icon: "tag", title: "Manage tags") {
                path.append(TagsDestination.root)
            }
            shortcut(icon: "history", title: "Full history") {
                path.append(HistoryScope.allLists)
            }
            shortcut(icon: "sparkle", title: "Categories") {
                path.append(CategoriesDestination.root)
            }
            shortcut(icon: "edit", title: "Restore purchases") {
                Task { await storeKit.restorePurchases() }
            }
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    private func shortcut(
        icon: String,
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                GemIcons.image(icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.dim)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.text)
                Spacer()
                GemIcons.image("right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Theme.dimmer)
            }
            .padding(.horizontal, Theme.Spacing.md).padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Theme.card))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var dangerZone: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("DANGER ZONE")
                .font(Theme.eyebrow()).tracking(2)
                .foregroundColor(Theme.ruby)
                .padding(.horizontal, Theme.Spacing.xl)

            Button {
                showClearHistoryConfirm = true
            } label: {
                HStack {
                    GemIcons.image("trash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.ruby)
                    Text("Clear all history")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.ruby)
                    Spacer()
                }
                .padding(.horizontal, Theme.Spacing.md).padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Theme.ruby.opacity(0.1)))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.ruby.opacity(0.35), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Theme.Spacing.xl)
        }
    }
}

// MARK: - Preview

#Preview("Settings — seeded") {
    let container = try! SeedStore.container(for: .historicalRuns)
    let ent = EntitlementManager()
    let sk = StoreKitManager(entitlementManager: ent)
    return NavigationStack {
        SettingsView(path: .constant(NavigationPath()))
            .environmentObject(ent)
            .environmentObject(sk)
    }
    .modelContainer(container)
}

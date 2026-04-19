/// CategoriesView.swift
/// Purpose: CRUD screen for ChecklistCategory. Lists all categories with
///   per-category usage count ("Used by N lists"); inline rename via tap;
///   swipe-to-delete (which nullifies list.category per existing cascade rule).
/// Dependencies: SwiftUI, SwiftData, ChecklistCategory, Theme, TopBar,
///   GemIcons, PillButton, CategoryStore, EntitlementManager, EntitlementGate,
///   PaywallSheet.
/// Key concepts:
///   - @Query drives the list in sortKey order.
///   - Inline rename: tapping a row toggles a TextField; Save calls
///     CategoryStore.rename. Cancel reverts.
///   - "+ New category" dashed pill gates through EntitlementGate.canCreateCategory.

import SwiftUI
import SwiftData

/// App-wide category manager. CRUD on ChecklistCategory.
struct CategoriesView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlementManager: EntitlementManager

    @Query(sort: [SortDescriptor(\ChecklistCategory.sortKey, order: .forward)])
    private var categories: [ChecklistCategory]
    @Query private var checklists: [Checklist]

    @State private var renamingID: UUID? = nil
    @State private var renamingText: String = ""
    @State private var showAddInput = false
    @State private var newName: String = ""

    @State private var paywallReason: GateDecision.Reason? = nil
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        headerBlock
                        listBody
                        Spacer(minLength: 40)
                    }
                    .padding(.top, Theme.Spacing.md)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showPaywall) {
            PaywallSheet(reason: paywallReason)
        }
    }

    private var topBar: some View {
        TopBar(
            left: { IconButton(iconName: "back") { dismiss() } },
            right: { IconButton(iconName: "plus", solid: true) { tapAdd() } }
        )
    }

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("GROUP CHECKLISTS").font(Theme.eyebrow()).tracking(2).foregroundColor(Theme.dim)
            Text("Categories.")
                .font(Theme.display(size: 34, weight: .bold))
                .foregroundColor(Theme.text)
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    private var listBody: some View {
        VStack(spacing: Theme.Spacing.xs) {
            if categories.isEmpty && !showAddInput {
                emptyRow
            }
            ForEach(categories) { cat in
                categoryRow(cat)
            }
            if showAddInput {
                newCategoryInput
            } else {
                newCategoryPill
            }
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    private var emptyRow: some View {
        Text("No categories yet.")
            .font(.system(size: 14))
            .foregroundColor(Theme.dim)
            .frame(maxWidth: .infinity)
            .padding(.top, 40)
    }

    private func categoryRow(_ cat: ChecklistCategory) -> some View {
        HStack {
            if renamingID == cat.id {
                TextField("", text: $renamingText)
                    .foregroundColor(Theme.text)
                    .font(.system(size: 15, weight: .semibold))
                    .onSubmit { commitRename(cat) }
                Button("Save") { commitRename(cat) }
                    .buttonStyle(.plain)
                    .foregroundColor(Theme.amethyst)
                Button("Cancel") { renamingID = nil }
                    .buttonStyle(.plain)
                    .foregroundColor(Theme.dim)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(cat.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.text)
                    Text(usage(cat))
                        .font(.system(size: 12))
                        .foregroundColor(Theme.dim)
                }
                Spacer()
                Button {
                    renamingID = cat.id
                    renamingText = cat.name
                } label: {
                    GemIcons.image("edit")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.dim)
                }
                .buttonStyle(.plain)
                Button(role: .destructive) {
                    try? CategoryStore.delete(cat, in: ctx)
                } label: {
                    GemIcons.image("trash")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.ruby)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Theme.Spacing.md).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.border, lineWidth: 1))
    }

    private func usage(_ cat: ChecklistCategory) -> String {
        let n = checklists.filter { $0.category?.id == cat.id }.count
        return "Used by \(n) list\(n == 1 ? "" : "s")"
    }

    private var newCategoryPill: some View {
        Button { tapAdd() } label: {
            HStack(spacing: 6) {
                GemIcons.image("plus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Theme.dim)
                Text("New category")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.dim)
                Spacer()
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .stroke(Theme.border, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            )
        }
        .buttonStyle(.plain)
    }

    private var newCategoryInput: some View {
        HStack {
            TextField("New category name", text: $newName)
                .foregroundColor(Theme.text)
                .onSubmit { commitAdd() }
            Button("Add") { commitAdd() }
                .buttonStyle(.plain)
                .foregroundColor(Theme.amethyst)
                .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
            Button("Cancel") {
                newName = ""
                showAddInput = false
            }
            .buttonStyle(.plain)
            .foregroundColor(Theme.dim)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Color.white.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.border, lineWidth: 1))
    }

    // MARK: - Actions

    private func tapAdd() {
        let decision = EntitlementGate.canCreateCategory(
            current: categories.count,
            limits: entitlementManager.limits
        )
        switch decision {
        case .allowed:
            showAddInput = true
        case .blocked(let reason):
            paywallReason = reason
            showPaywall = true
        }
    }

    private func commitAdd() {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        _ = try? CategoryStore.create(name: trimmed, in: ctx)
        newName = ""
        showAddInput = false
    }

    private func commitRename(_ cat: ChecklistCategory) {
        let trimmed = renamingText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty, trimmed != cat.name {
            try? CategoryStore.rename(cat, to: trimmed, in: ctx)
        }
        renamingID = nil
    }
}

// MARK: - Preview

#Preview("Categories — seeded") {
    let container = try! SeedStore.container(for: .seededMulti)
    let ent = EntitlementManager()
    return NavigationStack {
        CategoriesView()
            .environmentObject(ent)
    }
    .modelContainer(container)
}

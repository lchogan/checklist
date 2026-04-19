/// CreateChecklistSheet.swift
/// Purpose: Sheet presented from HomeView's "+" button. Collects a checklist name
///   and optional category selection (with inline "+ New" category creation).
///   Commits the new checklist via ChecklistStore.create and dismisses on success.
/// Dependencies: SwiftUI, SwiftData, BottomSheet (Design/Components), PillButton,
///   Theme, ChecklistStore, CategoryStore, ChecklistCategory model.
/// Key concepts:
///   - @Query drives the category chips row; chips toggle selectedCategoryID.
///   - "+ New" expands an inline text row in the same sheet (no nested sheet).
///   - commitNewCategory calls CategoryStore.create immediately and selects the result.
///   - Create button is disabled when name is empty.

import SwiftUI
import SwiftData

/// Sheet presented from HomeView's "+" button. Collects name + category
/// selection (with inline + New category). Commits via ChecklistStore.create
/// and dismisses.
struct CreateChecklistSheet: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\ChecklistCategory.sortKey, order: .forward)])
    private var categories: [ChecklistCategory]

    @State private var name: String = ""
    @State private var selectedCategoryID: UUID? = nil
    @State private var showNewCategoryInput = false
    @State private var newCategoryName: String = ""

    var body: some View {
        BottomSheet {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("NEW LIST")
                    .font(Theme.eyebrow())
                    .tracking(2)
                    .foregroundColor(Theme.dim)

                Text("Name your checklist.")
                    .font(Theme.display(size: 26))
                    .foregroundColor(Theme.text)

                nameField

                Text("CATEGORY")
                    .font(Theme.eyebrow())
                    .tracking(2)
                    .foregroundColor(Theme.dim)
                    .padding(.top, Theme.Spacing.sm)

                categoryChips

                if showNewCategoryInput {
                    newCategoryField
                }

                actionRow
            }
        }
    }

    // MARK: - Subviews

    /// Text field for the new checklist name.
    private var nameField: some View {
        TextField("e.g. Road Trip", text: $name)
            .foregroundColor(Theme.text)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Color.white.opacity(0.06)))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.border, lineWidth: 1))
            .submitLabel(.done)
    }

    /// Horizontal scroll of existing category chips ending with a "+ New" dashed pill.
    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(categories) { cat in
                    chip(title: cat.name, isSelected: selectedCategoryID == cat.id) {
                        selectedCategoryID = (selectedCategoryID == cat.id) ? nil : cat.id
                    }
                }
                newChip
            }
        }
    }

    /// Dashed "+ New" pill that reveals the inline category name input.
    private var newChip: some View {
        Button {
            showNewCategoryInput = true
        } label: {
            Text("+ New")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.dim)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Capsule().fill(Color.clear))
                .overlay(
                    Capsule().stroke(Theme.border, style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                )
        }
        .buttonStyle(.plain)
    }

    /// A single selectable category chip.
    ///
    /// - Parameters:
    ///   - title: Display label for the category.
    ///   - isSelected: Whether this chip is the currently selected category.
    ///   - action: Closure executed when the chip is tapped.
    /// - Returns: A styled capsule button view.
    private func chip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? .white : Theme.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Group {
                        if isSelected {
                            Capsule().fill(
                                LinearGradient(
                                    colors: [Theme.amethyst, Theme.sapphire.opacity(0.85)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        } else {
                            Capsule().fill(Color.white.opacity(0.05))
                        }
                    }
                )
                .overlay(
                    Capsule().stroke(isSelected ? Color.clear : Theme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    /// Inline text row for naming a new category. Visible only when `showNewCategoryInput` is true.
    private var newCategoryField: some View {
        HStack {
            TextField("New category name", text: $newCategoryName)
                .foregroundColor(Theme.text)
            Button("Add") {
                commitNewCategory()
            }
            .disabled(newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
            .buttonStyle(.plain)
            .foregroundColor(Theme.amethyst)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Color.white.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.border, lineWidth: 1))
    }

    /// Cancel + Create buttons row. Create is disabled while the name field is empty.
    private var actionRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            PillButton(title: "Cancel", tone: .ghost, wide: true) {
                dismiss()
            }
            PillButton(
                title: "Create",
                color: Theme.amethyst,
                wide: true,
                disabled: trimmedName.isEmpty
            ) {
                commitCreate()
            }
        }
        .padding(.top, Theme.Spacing.md)
    }

    // MARK: - Helpers

    /// The name field value with whitespace stripped.
    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    /// Creates a new category from `newCategoryName`, selects it, and hides the input row.
    ///
    /// Calls `CategoryStore.create` immediately — the new category is live in @Query before
    /// the user taps Create. Non-fatal errors are swallowed; a future error banner can surface them.
    private func commitNewCategory() {
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        do {
            let cat = try CategoryStore.create(name: trimmed, in: ctx)
            selectedCategoryID = cat.id
            newCategoryName = ""
            showNewCategoryInput = false
        } catch {
            // Non-fatal — surface later via an error banner; for now swallow.
        }
    }

    /// Commits the new checklist to SwiftData via ChecklistStore and dismisses the sheet.
    ///
    /// No-ops when the name is blank (guarded by the disabled Create button).
    private func commitCreate() {
        let trimmed = trimmedName
        guard !trimmed.isEmpty else { return }
        let category = categories.first(where: { $0.id == selectedCategoryID })
        _ = try? ChecklistStore.create(name: trimmed, category: category, in: ctx)
        dismiss()
    }
}

// MARK: - Previews

#Preview("Empty") {
    let container = try! SeedStore.container(for: .seededMulti)
    return Color.gray.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            CreateChecklistSheet()
                .modelContainer(container)
        }
}

/// ChecklistMenuSheet.swift
/// Purpose: Sheet presented by the kebab button on ChecklistRunView. Provides
///   four internally-switched variants: default menu (capture 14), name-run
///   (capture 16), rename-list + category (capture 15), and delete-confirm
///   (capture 17).
/// Dependencies: SwiftUI, SwiftData, Checklist, Run, ChecklistCategory models,
///   BottomSheet, PillButton, GemIcons, Theme, ChecklistStore, RunStore,
///   CategoryStore.
/// Key concepts:
///   - The sheet is self-contained: all four variants are nested inside the
///     same BottomSheet and controlled by the `variant` state var.
///   - "Manage tags" and "Full history for this list" are placeholder no-ops
///     in this plan — they dismiss the sheet. Those screens arrive in a later plan.
///   - Delete commits via ChecklistStore.delete(_:in:), which cascades runs and
///     completedRuns. The sheet dismisses after deleting; SwiftData's natural
///     unmount handles the RunView pop-back.
///   - Per spec §7: Set due date, Set repeat schedule, Archive list are cut from
///     the v4 menu.

import SwiftUI
import SwiftData

/// Sheet presented by the kebab on ChecklistRunView. Has four variants:
/// default menu, rename-run, rename-list (+ category), delete confirm.
///
/// Cut from prototype per spec §2: Set due date, Set repeat schedule,
/// Archive list.
struct ChecklistMenuSheet: View {
    // MARK: - Variant

    /// The four internally-switched screens within this sheet.
    enum Variant {
        case menu
        case nameRun
        case renameList
        case deleteConfirm
    }

    // MARK: - Environment / inputs

    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    /// The checklist being operated on.
    let checklist: Checklist

    /// The currently-active live Run. Nil when no run is in progress.
    let currentRun: Run?

    // MARK: - State

    /// Controls which screen is displayed inside the sheet.
    @State var variant: Variant = .menu

    /// Editable text for the run name field (seeded from `currentRun.name`).
    @State private var runNameInput = ""

    /// Editable text for the checklist name field (seeded from `checklist.name`).
    @State private var listNameInput = ""

    /// Selected category UUID. Nil means "no category".
    @State private var selectedCategoryID: UUID? = nil

    // MARK: - Query

    @Query(sort: [SortDescriptor(\ChecklistCategory.sortKey, order: .forward)])
    private var categories: [ChecklistCategory]

    // MARK: - Body

    var body: some View {
        BottomSheet {
            switch variant {
            case .menu:          menuContent
            case .nameRun:       nameRunContent
            case .renameList:    renameListContent
            case .deleteConfirm: deleteConfirmContent
            }
        }
        .onAppear(perform: seedInputs)
    }

    // MARK: - Seed

    /// Populates the editable fields from the live model values on first appear.
    private func seedInputs() {
        runNameInput = currentRun?.name ?? ""
        listNameInput = checklist.name
        selectedCategoryID = checklist.category?.id
    }

    // MARK: - Default menu (capture 14)

    /// Default menu showing five rows: rename run, rename list, manage tags,
    /// full history, and (danger) delete list.
    private var menuContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(checklist.name.uppercased())
                .font(Theme.eyebrow())
                .tracking(2)
                .foregroundColor(Theme.dim)
                .padding(.bottom, Theme.Spacing.sm)

            menuRow(icon: "edit", title: "Rename this run", tone: .normal) {
                variant = .nameRun
            }
            .disabled(currentRun == nil)

            menuRow(icon: "edit", title: "Rename list", tone: .normal) {
                variant = .renameList
            }

            menuRow(icon: "tag", title: "Manage tags", tone: .normal) {
                // TagsView arrives in a later plan. Placeholder: dismiss.
                dismiss()
            }

            menuRow(icon: "history", title: "Full history for this list", tone: .normal) {
                // HistoryView arrives in a later plan. Placeholder: dismiss.
                dismiss()
            }

            Divider()
                .background(Theme.border)
                .padding(.vertical, Theme.Spacing.sm)

            menuRow(icon: "trash", title: "Delete list", tone: .danger) {
                variant = .deleteConfirm
            }
        }
    }

    /// Tone applied to a menu row's icon and label colours.
    private enum RowTone { case normal, danger }

    /// Renders a single tappable menu row with a leading icon, title, and trailing chevron.
    ///
    /// - Parameters:
    ///   - icon: GemIcons name for the leading icon.
    ///   - title: Display label for the row.
    ///   - tone: `.normal` for standard text colour, `.danger` for ruby red.
    ///   - action: Closure called on tap.
    /// - Returns: A plain-style button row.
    private func menuRow(
        icon: String,
        title: String,
        tone: RowTone,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                GemIcons.image(icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(tone == .danger ? Theme.ruby : Theme.dim)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(tone == .danger ? Theme.ruby : Theme.text)
                Spacer()
                GemIcons.image("right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Theme.dimmer)
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Name run (capture 16)

    /// Variant that lets the user label the current run with a short string
    /// (e.g. "Tokyo", "Week 14").
    private var nameRunContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("NAME THIS RUN")
                .font(Theme.eyebrow())
                .tracking(2)
                .foregroundColor(Theme.dim)

            Text("A short label (e.g. \"Tokyo\", \"Week 14\"). Appears everywhere this run is referenced.")
                .font(.system(size: 13))
                .foregroundColor(Theme.dim)

            TextField("", text: $runNameInput)
                .foregroundColor(Theme.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.md)
                        .fill(Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.md)
                        .stroke(Theme.border, lineWidth: 1)
                )

            HStack(spacing: Theme.Spacing.sm) {
                PillButton(title: "Cancel", tone: .ghost, wide: true) { variant = .menu }
                PillButton(title: "Save", color: Theme.amethyst, wide: true) { commitRenameRun() }
            }
        }
    }

    /// Persists the new run name via `RunStore.rename` and dismisses the sheet.
    private func commitRenameRun() {
        guard let run = currentRun else { dismiss(); return }
        try? RunStore.rename(run, to: runNameInput, in: ctx)
        dismiss()
    }

    // MARK: - Rename list + category (capture 15)

    /// Variant that lets the user rename the checklist and re-assign its category.
    private var renameListContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("RENAME LIST")
                .font(Theme.eyebrow())
                .tracking(2)
                .foregroundColor(Theme.dim)

            Text("Rename your checklist.")
                .font(Theme.display(size: 26))
                .foregroundColor(Theme.text)

            TextField("", text: $listNameInput)
                .foregroundColor(Theme.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.md)
                        .fill(Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.md)
                        .stroke(Theme.border, lineWidth: 1)
                )

            Text("CATEGORY")
                .font(Theme.eyebrow())
                .tracking(2)
                .foregroundColor(Theme.dim)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.xs) {
                    ForEach(categories) { cat in
                        categoryChip(cat)
                    }
                }
            }

            HStack(spacing: Theme.Spacing.sm) {
                PillButton(title: "Cancel", tone: .ghost, wide: true) { variant = .menu }
                PillButton(
                    title: "Save",
                    color: Theme.amethyst,
                    wide: true,
                    disabled: listNameInput.trimmingCharacters(in: .whitespaces).isEmpty
                ) { commitRenameList() }
            }
        }
    }

    /// Renders a single category selection chip. Tapping toggles selection; tapping
    /// the already-selected chip deselects (sets category to nil).
    ///
    /// - Parameter cat: The `ChecklistCategory` this chip represents.
    /// - Returns: A styled capsule button.
    private func categoryChip(_ cat: ChecklistCategory) -> some View {
        let selected = selectedCategoryID == cat.id
        return Button {
            selectedCategoryID = (selected ? nil : cat.id)
        } label: {
            Text(cat.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(selected ? .white : Theme.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Group {
                        if selected {
                            Capsule().fill(LinearGradient(
                                colors: [Theme.amethyst, Theme.sapphire.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                        } else {
                            Capsule().fill(Color.white.opacity(0.05))
                        }
                    }
                )
                .overlay(
                    Capsule().stroke(selected ? Color.clear : Theme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    /// Persists the renamed checklist name and/or new category assignment, then dismisses.
    ///
    /// Only calls `ChecklistStore.rename` when the trimmed name differs from the current
    /// name. Only calls `ChecklistStore.setCategory` when the category selection has changed.
    private func commitRenameList() {
        let trimmed = listNameInput.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty, trimmed != checklist.name {
            try? ChecklistStore.rename(checklist, to: trimmed, in: ctx)
        }
        let newCat = categories.first(where: { $0.id == selectedCategoryID })
        if newCat?.id != checklist.category?.id {
            try? ChecklistStore.setCategory(checklist, to: newCat, in: ctx)
        }
        dismiss()
    }

    // MARK: - Delete confirm (capture 17)

    /// Variant that warns the user before permanently deleting the checklist,
    /// showing counts of past and live runs that will also be removed.
    private var deleteConfirmContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("DELETE LIST")
                .font(Theme.eyebrow())
                .tracking(2)
                .foregroundColor(Theme.ruby)

            Text("Delete \(checklist.name) forever.")
                .font(Theme.display(size: 24))
                .foregroundColor(Theme.text)

            Text(deleteBodyText)
                .font(.system(size: 13))
                .foregroundColor(Theme.dim)

            PillButton(title: "Delete forever", color: Theme.ruby, wide: true) { commitDelete() }
            PillButton(title: "Cancel", tone: .ghost, wide: true) { variant = .menu }
        }
    }

    /// Builds the body copy for the delete-confirm screen, incorporating counts of
    /// completed runs and live runs that will be removed alongside the checklist.
    private var deleteBodyText: String {
        let past = checklist.completedRuns?.count ?? 0
        let live = checklist.runs?.count ?? 0
        var bits: [String] = []
        if past > 0 { bits.append("\(past) past \(past == 1 ? "run" : "runs")") }
        if live > 0 { bits.append("\(live) live \(live == 1 ? "run" : "runs")") }
        if bits.isEmpty { return "This can't be undone." }
        return "This also removes \(bits.joined(separator: " + ")) from history. This can't be undone."
    }

    /// Permanently deletes the checklist (cascading runs + completedRuns) via
    /// `ChecklistStore.delete`, then dismisses. SwiftData's natural unmount will
    /// pop the RunView back to Home.
    private func commitDelete() {
        try? ChecklistStore.delete(checklist, in: ctx)
        dismiss()
    }
}

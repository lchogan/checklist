/// ItemEditInline.swift
/// Purpose: Sheet for editing an existing item. Supports rename, tag reassignment,
///   and per-run ignore toggle. Invoked when the user taps an ItemRow's body.
/// Dependencies: SwiftUI, SwiftData, BottomSheet, PillButton, TagChip, Theme,
///   ChecklistStore, RunStore, Item model, Run model, Tag model.
/// Key concepts:
///   - Presented via .sheet(item: $editingItem) — Item is Identifiable via SwiftData @Model.
///   - currentRun is optional; the "Ignore for this run" toggle is only shown when non-nil.
///   - onAppear pre-fills text, selectedTagIDs, and ignored from the item's current state.
///   - commit() only writes fields that actually changed, to avoid unnecessary saves.

import SwiftUI
import SwiftData

/// Sheet for editing an existing item. Supports rename, tag reassignment,
/// and per-run ignore toggle. Invoked from ItemRow's body tap.
struct ItemEditInline: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    let item: Item
    let currentRun: Run?

    @Query(sort: [SortDescriptor(\Tag.sortKey, order: .forward)]) private var allTags: [Tag]

    @State private var text: String = ""
    @State private var selectedTagIDs: Set<UUID> = []
    @State private var ignored: Bool = false

    var body: some View {
        BottomSheet {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("EDIT ITEM")
                    .font(Theme.eyebrow())
                    .tracking(2)
                    .foregroundColor(Theme.dim)

                TextField("Item", text: $text)
                    .foregroundColor(Theme.text)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Color.white.opacity(0.06)))
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.border, lineWidth: 1))

                if !allTags.isEmpty {
                    Text("TAGS")
                        .font(Theme.eyebrow()).tracking(2).foregroundColor(Theme.dim)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Theme.Spacing.xs) {
                            ForEach(allTags) { tag in
                                let selected = selectedTagIDs.contains(tag.id)
                                Button {
                                    if selected { selectedTagIDs.remove(tag.id) }
                                    else        { selectedTagIDs.insert(tag.id) }
                                } label: {
                                    TagChip(
                                        name: tag.name, iconName: tag.iconName,
                                        colorHue: tag.colorHue,
                                        muted: !selected, small: false
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                if currentRun != nil {
                    Toggle("Ignore for this run", isOn: $ignored)
                        .foregroundColor(Theme.text)
                        .tint(Theme.citrine)
                }

                HStack(spacing: Theme.Spacing.sm) {
                    PillButton(title: "Cancel", tone: .ghost, wide: true) { dismiss() }
                    PillButton(title: "Save", color: Theme.amethyst, wide: true) { commit() }
                }
                .padding(.top, Theme.Spacing.sm)
            }
        }
        .onAppear {
            text = item.text
            selectedTagIDs = Set((item.tags ?? []).map(\.id))
            if let run = currentRun,
               let check = (run.checks ?? []).first(where: { $0.itemID == item.id }),
               check.state == .ignored {
                ignored = true
            }
        }
    }

    /// Commits only the fields that changed: rename, tag reassignment, and ignore toggle.
    ///
    /// Each mutation is guarded so that unchanged fields do not trigger unnecessary
    /// SwiftData writes. Dismisses the sheet regardless of which mutations ran.
    private func commit() {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty, trimmed != item.text {
            try? ChecklistStore.renameItem(item, to: trimmed, in: ctx)
        }
        let newTags = allTags.filter { selectedTagIDs.contains($0.id) }
        let existingTagIDs = Set((item.tags ?? []).map(\.id))
        if existingTagIDs != selectedTagIDs {
            try? ChecklistStore.setItemTags(item, to: newTags, in: ctx)
        }
        if let run = currentRun {
            let currentlyIgnored = (run.checks ?? []).first(where: { $0.itemID == item.id })?.state == .ignored
            if ignored != currentlyIgnored {
                try? RunStore.setIgnored(run: run, itemID: item.id, to: ignored, in: ctx)
            }
        }
        dismiss()
    }
}

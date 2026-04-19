/// AddItemInline.swift
/// Purpose: Sheet for adding a new item to a checklist. Collects text and optional
///   tag assignments. Commits via ChecklistStore.addItem and dismisses.
/// Dependencies: SwiftUI, SwiftData, BottomSheet, PillButton, TagChip, Theme,
///   ChecklistStore, Checklist model, Tag model.
/// Key concepts:
///   - Presented as a .sheet(isPresented:) with .medium detent from ChecklistRunView.
///   - @Query drives the tag chip row; chips toggle selectedTagIDs.
///   - Add button is disabled while the text field is empty or whitespace-only.
///   - "Adds to: future only" chip from prototype is removed per §7 rules (always
///     adds to all live runs via ChecklistStore.addItem).

import SwiftUI
import SwiftData

/// Sheet for adding a new item to a checklist. Collects text + optional tags.
/// Invokes ChecklistStore.addItem on save.
///
/// Note: presented as a sheet rather than an inline-expand row because
/// SwiftUI Lists don't tolerate inline expansion cleanly. Visual match to
/// capture 13 is close-enough given the sheet chrome.
struct AddItemInline: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlementManager: EntitlementManager
    let checklist: Checklist
    @Query(sort: [SortDescriptor(\Tag.sortKey, order: .forward)]) private var allTags: [Tag]

    @State private var text: String = ""
    @State private var selectedTagIDs: Set<UUID> = []

    @State private var paywallReason: GateDecision.Reason? = nil
    @State private var showPaywall = false

    var body: some View {
        BottomSheet {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("NEW ITEM")
                    .font(Theme.eyebrow())
                    .tracking(2)
                    .foregroundColor(Theme.dim)

                TextField("Item", text: $text)
                    .foregroundColor(Theme.text)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Color.white.opacity(0.06)))
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.border, lineWidth: 1))
                    .submitLabel(.done)

                if !allTags.isEmpty {
                    Text("TAGS")
                        .font(Theme.eyebrow())
                        .tracking(2)
                        .foregroundColor(Theme.dim)

                    tagSelectRow
                }

                HStack(spacing: Theme.Spacing.sm) {
                    PillButton(title: "Cancel", tone: .ghost, wide: true) { dismiss() }
                    PillButton(
                        title: "Add",
                        color: Theme.amethyst,
                        wide: true,
                        disabled: trimmed.isEmpty
                    ) { commit() }
                }
                .padding(.top, Theme.Spacing.sm)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallSheet(reason: paywallReason)
        }
    }

    /// The text field value with whitespace stripped.
    private var trimmed: String { text.trimmingCharacters(in: .whitespaces) }

    /// Horizontal scrolling row of tag chips that toggle selection.
    private var tagSelectRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(allTags) { tag in
                    tagChip(tag)
                }
            }
        }
    }

    /// A single selectable tag chip button.
    ///
    /// - Parameter tag: The tag to represent.
    /// - Returns: A button wrapping a `TagChip` that toggles selection on tap.
    private func tagChip(_ tag: Tag) -> some View {
        let selected = selectedTagIDs.contains(tag.id)
        return Button {
            if selected {
                selectedTagIDs.remove(tag.id)
            } else {
                selectedTagIDs.insert(tag.id)
            }
        } label: {
            TagChip(
                name: tag.name,
                iconName: tag.iconName,
                colorHue: tag.colorHue,
                muted: !selected,
                small: false
            )
        }
        .buttonStyle(.plain)
    }

    /// Validates and commits the new item to SwiftData, then dismisses the sheet.
    ///
    /// No-ops when the text is blank (guarded by the disabled Add button).
    /// Tags selected in `selectedTagIDs` are resolved from `allTags` and passed
    /// to `ChecklistStore.addItem`.
    private func commit() {
        guard !trimmed.isEmpty else { return }
        // Gate on max items per checklist. Block routes to the paywall and
        // leaves the sheet open so the user's typed text isn't lost.
        let decision = EntitlementGate.canAddItem(
            currentItemsOnChecklist: checklist.items?.count ?? 0,
            limits: entitlementManager.limits
        )
        if case .blocked(let reason) = decision {
            paywallReason = reason
            showPaywall = true
            return
        }
        let tags = allTags.filter { selectedTagIDs.contains($0.id) }
        _ = try? ChecklistStore.addItem(text: trimmed, to: checklist, tags: tags, in: ctx)
        dismiss()
    }
}

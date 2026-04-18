import SwiftUI
import SwiftData

/// Shown from an item row in ChecklistEditView.
/// Lets the user select/deselect global tags for that item,
/// add new tags, and delete tags (with a warning if in use).
struct TagPickerSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlementManager: EntitlementManager

    @Query(sort: \Tag.name) private var allTags: [Tag]
    @Binding var selectedTags: [Tag]

    @State private var newTagName = ""
    @State private var newTagIcon = "tag"
    @State private var hasCustomIcon = false
    @State private var showIconPicker = false
    @State private var tagToDelete: Tag?
    @State private var showDeleteConfirmation = false
    @State private var paywallReason: PaywallReason?
    @State private var recentlyAddedTagID: PersistentIdentifier?
    @FocusState private var newTagFocused: Bool

    var body: some View {
        NavigationStack {
            List {
                // Existing tags with selection checkmarks
                Section {
                    if allTags.isEmpty {
                        Text("No tags yet. Add one below.")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(allTags) { tag in
                            TagRow(
                                tag: tag,
                                isSelected: isSelected(tag),
                                isNew: tag.persistentModelID == recentlyAddedTagID,
                                onToggle: { toggleTag(tag) }
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    tagToDelete = tag
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }

                // Add new tag
                Section("New Tag") {
                    HStack(spacing: 8) {
                        // Icon button — .buttonStyle(.plain) prevents tap area bleeding into Add
                        Button {
                            showIconPicker = true
                        } label: {
                            Image(systemName: hasCustomIcon ? newTagIcon : "circle.dashed")
                                .font(.title3)
                                .foregroundColor(hasCustomIcon ? .accentColor : .secondary)
                                .frame(width: 30, height: 30)
                                .background(
                                    hasCustomIcon
                                        ? Color.accentColor.opacity(0.1)
                                        : Color(.systemFill)
                                )
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle().size(CGSize(width: 44, height: 44)))

                        TextField("Tag name", text: $newTagName)
                            .focused($newTagFocused)
                            .submitLabel(.done)
                            .onSubmit { addTag() }

                        if !newTagName.trimmingCharacters(in: .whitespaces).isEmpty {
                            Button("Add") { addTag() }
                                .foregroundColor(.accentColor)
                                .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showIconPicker, onDismiss: {
                // Mark as custom if a non-default icon was selected
                if newTagIcon != "tag" {
                    hasCustomIcon = true
                }
            }) {
                IconPickerSheet(
                    title: "Tag Icon",
                    selectedIcon: $newTagIcon
                )
            }
            .confirmationDialog(
                deleteTitle,
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Tag", role: .destructive) {
                    if let tag = tagToDelete { performDelete(tag) }
                }
                Button("Cancel", role: .cancel) { tagToDelete = nil }
            } message: {
                Text(deleteMessage)
            }
            .sheet(item: $paywallReason) { reason in
                PaywallView(reason: reason)
            }
        }
    }

    // MARK: - Helpers

    private func isSelected(_ tag: Tag) -> Bool {
        selectedTags.contains { $0.persistentModelID == tag.persistentModelID }
    }

    private func toggleTag(_ tag: Tag) {
        if let index = selectedTags.firstIndex(where: { $0.persistentModelID == tag.persistentModelID }) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }

    private func addTag() {
        let trimmed = newTagName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        guard entitlementManager.limits.canAdd(tags: allTags.count) else {
            paywallReason = .tagLimit(entitlementManager.limits.maxTags ?? 3)
            return
        }

        guard !allTags.contains(where: { $0.name.lowercased() == trimmed.lowercased() }) else {
            newTagName = ""
            return
        }

        let tag = Tag(name: trimmed, iconName: hasCustomIcon ? newTagIcon : "tag")
        context.insert(tag)
        try? context.save()
        newTagName = ""
        newTagIcon = "tag"
        hasCustomIcon = false

        // Trigger highlight animation on the new row
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            recentlyAddedTagID = tag.persistentModelID
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                recentlyAddedTagID = nil
            }
        }
    }

    private func performDelete(_ tag: Tag) {
        selectedTags.removeAll { $0.persistentModelID == tag.persistentModelID }
        context.delete(tag)
        try? context.save()
        tagToDelete = nil
    }

    private var deleteTitle: String {
        guard let tag = tagToDelete else { return "Delete Tag?" }
        return "Delete \"\(tag.name)\"?"
    }

    private var deleteMessage: String {
        guard let tag = tagToDelete else { return "" }
        let count = tag.checklistCount
        if count > 0 {
            return "This tag is in use by \(count) \(count == 1 ? "list" : "lists"). Do you want to delete this tag?"
        }
        return "This tag will be permanently deleted."
    }
}

// MARK: - Tag row

private struct TagRow: View {
    @Bindable var tag: Tag
    let isSelected: Bool
    let isNew: Bool
    let onToggle: () -> Void

    @State private var highlightBackground = false
    @State private var showIconPicker = false
    @Environment(\.modelContext) private var context

    var body: some View {
        HStack(spacing: 0) {
            // Icon button
            Button {
                showIconPicker = true
            } label: {
                Image(systemName: tag.iconName)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .frame(width: 30, height: 30)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 12)

            TextField("Tag name", text: $tag.name)
                .submitLabel(.done)
                .onChange(of: tag.name) {
                    try? context.save()
                }
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                onToggle()
            } label: {
                HStack(spacing: 0) {
                    Image(systemName: "checkmark")
                        .foregroundColor(isSelected ? .accentColor : Color(.tertiaryLabel))
                        .fontWeight(isSelected ? .semibold : .regular)
                        .frame(width: 24, height: 44)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.leading, 12)
        }
        .listRowBackground(
            highlightBackground
                ? Color.accentColor.opacity(0.12)
                : Color(.secondarySystemGroupedBackground)
        )
        .sheet(isPresented: $showIconPicker) {
            IconPickerSheet(
                title: "Tag Icon",
                selectedIcon: $tag.iconName
            )
            .onChange(of: tag.iconName) {
                try? context.save()
            }
        }
        .onChange(of: isNew) { _, newValue in
            if newValue {
                withAnimation(.easeIn(duration: 0.15)) {
                    highlightBackground = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.easeOut(duration: 0.9)) {
                        highlightBackground = false
                    }
                }
            }
        }
    }
}

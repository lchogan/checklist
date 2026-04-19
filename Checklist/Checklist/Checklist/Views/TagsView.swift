/// TagsView.swift
/// Purpose: App-wide tag manager. Lists all Tags sorted by sortKey with usage
///   counts; tapping a row or its pencil opens TagEditorSheet in edit mode,
///   tapping "+ New tag" or the top-right + button opens it in create mode.
/// Dependencies: SwiftUI, SwiftData, Tag model, TagStore, Theme, TopBar,
///   GemIcons, TagEditorSheet (Task 7.3).
/// Key concepts:
///   - @Query drives the list; @State drives editor presentation.
///   - `editingTag == nil` presents the sheet in "new" mode;
///     a non-nil value presents it in "edit" mode.
///   - Row body tap and trailing pencil both invoke the same edit flow.

import SwiftUI
import SwiftData

/// App-wide tag manager. Lists every Tag with its usage count; taps open
/// `TagEditorSheet` in create or edit mode.
struct TagsView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\Tag.sortKey, order: .forward)]) private var tags: [Tag]

    /// Nil = editor presented in create mode. Non-nil = editor in edit mode
    /// for that tag.
    @State private var editingTag: Tag? = nil

    /// Flips to true when the user taps the top-right + or the "+ New tag"
    /// dashed row. Presentation uses `.sheet(item:)` when editing an existing
    /// tag and `.sheet(isPresented:)` for new, so both entry points coexist
    /// cleanly.
    @State private var showNewEditor = false

    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        headerBlock
                        if tags.isEmpty {
                            emptyState
                        } else {
                            tagList
                        }
                        Spacer(minLength: 40)
                    }
                    .padding(.top, Theme.Spacing.md)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(item: $editingTag) { tag in
            TagEditorSheet(mode: .edit(tag))
        }
        .sheet(isPresented: $showNewEditor) {
            TagEditorSheet(mode: .new)
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        TopBar(
            left: { IconButton(iconName: "back") { dismiss() } },
            right: { IconButton(iconName: "plus", solid: true) { showNewEditor = true } }
        )
    }

    // MARK: - Header

    /// "FILTERS FOR ITEMS ACROSS ALL LISTS" eyebrow + large "Tags." title.
    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("FILTERS FOR ITEMS ACROSS ALL LISTS")
                .font(Theme.eyebrow()).tracking(2)
                .foregroundColor(Theme.dim)
            Text("Tags.")
                .font(Theme.display(size: 34, weight: .bold))
                .foregroundColor(Theme.text)
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    // MARK: - List + empty state

    /// Rows for each tag + a trailing "+ New tag" dashed pill that opens the
    /// editor in create mode.
    private var tagList: some View {
        VStack(spacing: Theme.Spacing.xs) {
            ForEach(tags) { tag in
                tagRow(tag)
            }
            newTagRow
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    /// Empty state: shows only the "+ New tag" dashed pill.
    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.xs) {
            newTagRow
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    /// Single tag row: icon chip + name + "Used by N item(s)" subtitle +
    /// trailing pencil edit affordance.
    private func tagRow(_ tag: Tag) -> some View {
        Button {
            editingTag = tag
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                tagSwatch(tag)
                VStack(alignment: .leading, spacing: 2) {
                    Text(tag.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.text)
                    Text(usageSubtitle(for: tag))
                        .font(.system(size: 12))
                        .foregroundColor(Theme.dim)
                }
                Spacer()
                GemIcons.image("edit")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.dim)
            }
            .padding(.horizontal, Theme.Spacing.md).padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Theme.card))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    /// Rounded-square preview swatch: tag's color as background with its icon
    /// centered in white.
    private func tagSwatch(_ tag: Tag) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(
                LinearGradient(
                    colors: [
                        Theme.gemColor(hue: tag.colorHue),
                        Theme.gemColor(hue: tag.colorHue).opacity(0.7),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 36, height: 36)
            .overlay(
                GemIcons.image(tag.iconName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
            )
    }

    /// Subtitle: "Used by N item(s)" per capture 24.
    private func usageSubtitle(for tag: Tag) -> String {
        let n = TagStore.usageCount(for: tag, in: ctx)
        return "Used by \(n) item\(n == 1 ? "" : "s")"
    }

    /// Dashed "+ New tag" pill that opens the create-mode editor.
    private var newTagRow: some View {
        Button {
            showNewEditor = true
        } label: {
            HStack(spacing: 6) {
                GemIcons.image("plus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Theme.dim)
                Text("New tag")
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
}

// MARK: - Previews

#Preview("Tags — seeded") {
    let container = try! SeedStore.container(for: .seededMulti)
    return NavigationStack {
        TagsView()
    }
    .modelContainer(container)
}

#Preview("Tags — empty") {
    let container = try! SeedStore.container(for: .empty)
    return NavigationStack {
        TagsView()
    }
    .modelContainer(container)
}

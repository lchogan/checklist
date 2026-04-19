/// TagEditorSheet.swift
/// Purpose: Sheet for creating (Task 7.3) or editing (Task 7.4) a Tag. Two
///   modes: `.new` and `.edit(Tag)`. Layout matches prototype captures 26+27:
///   preview card, name field, 14-icon grid, 9-swatch color row, action row
///   (Cancel/Create for new; Delete/Cancel/Save for edit).
/// Dependencies: SwiftUI, SwiftData, Tag, TagStore, BottomSheet, PillButton,
///   GemIcons, Theme.
/// Key concepts:
///   - Mode is an enum; `@State selection` mirrors the preview card, so the
///     swatch and icon grid taps update the card live.
///   - Create disables the Create button when the name is empty; Save enables
///     only when something changed (name/icon/hue diff from the tag's current
///     values).

import SwiftUI
import SwiftData

/// Sheet for creating or editing a Tag. Two modes: `.new` and `.edit(Tag)`.
struct TagEditorSheet: View {
    /// Which variant to render.
    enum Mode {
        case new
        case edit(Tag)
    }

    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    let mode: Mode

    /// Editable fields — initialised from the tag in edit mode, or sensible
    /// defaults in create mode.
    @State private var name: String = ""
    @State private var iconName: String = "tag"
    @State private var colorHue: Double = 300

    /// Delete-confirmation stage for edit mode. Ignored in new mode.
    @State private var showDeleteConfirm: Bool = false

    var body: some View {
        BottomSheet {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                eyebrow
                previewCard
                nameBlock
                iconGrid
                colorRow
                actionRow
            }
        }
        .onAppear(perform: seedFromMode)
        .alert(
            "Delete tag?",
            isPresented: $showDeleteConfirm,
            actions: {
                Button("Delete", role: .destructive) { commitDelete() }
                Button("Cancel", role: .cancel) {}
            },
            message: {
                Text("Removes this tag from every item and run. Completed runs keep their frozen tag reference.")
            }
        )
    }

    // MARK: - Eyebrow

    /// "NEW TAG" for create mode; "EDIT TAG" for edit mode.
    private var eyebrow: some View {
        Text(isEditMode ? "EDIT TAG" : "NEW TAG")
            .font(Theme.eyebrow()).tracking(2)
            .foregroundColor(Theme.dim)
    }

    // MARK: - Preview card

    /// Live preview of the in-progress tag: swatch + name + "PREVIEW" label.
    private var previewCard: some View {
        HStack(spacing: Theme.Spacing.md) {
            previewSwatch
            VStack(alignment: .leading, spacing: 2) {
                Text(name.isEmpty ? "Tag name" : name)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Theme.text)
                Text("PREVIEW")
                    .font(Theme.eyebrow()).tracking(2)
                    .foregroundColor(Theme.dimmer)
            }
            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .fill(Theme.gemColor(hue: colorHue).opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .stroke(Theme.gemColor(hue: colorHue).opacity(0.35), lineWidth: 1)
        )
    }

    /// Preview swatch: gem-colored rounded square with the icon centered.
    private var previewSwatch: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(
                LinearGradient(
                    colors: [
                        Theme.gemColor(hue: colorHue),
                        Theme.gemColor(hue: colorHue).opacity(0.7),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 42, height: 42)
            .overlay(
                GemIcons.image(iconName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            )
    }

    // MARK: - Name

    /// "NAME" eyebrow + text field.
    private var nameBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("NAME").font(Theme.eyebrow()).tracking(2).foregroundColor(Theme.dim)
            TextField("e.g. Winter", text: $name)
                .foregroundColor(Theme.text)
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Color.white.opacity(0.06)))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).stroke(Theme.border, lineWidth: 1))
        }
    }

    // MARK: - Icon grid

    /// "ICON" eyebrow + 14-icon grid in two rows of seven. Selection is
    /// indicated by a gem-colored ring.
    private var iconGrid: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ICON").font(Theme.eyebrow()).tracking(2).foregroundColor(Theme.dim)
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7),
                spacing: 8
            ) {
                ForEach(GemIcons.all, id: \.self) { icon in
                    iconCell(icon)
                }
            }
        }
    }

    /// Single icon cell inside the grid.
    private func iconCell(_ icon: String) -> some View {
        Button {
            iconName = icon
        } label: {
            GemIcons.image(icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(iconName == icon ? .white : Theme.dim)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(iconName == icon ? Theme.gemColor(hue: colorHue).opacity(0.25) : Color.white.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            iconName == icon ? Theme.gemColor(hue: colorHue) : Theme.border,
                            lineWidth: iconName == icon ? 1.5 : 1
                        )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Color row

    /// "COLOR" eyebrow + 9 hue swatches in a horizontal row.
    private var colorRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("COLOR").font(Theme.eyebrow()).tracking(2).foregroundColor(Theme.dim)
            HStack(spacing: 8) {
                ForEach(GemIcons.tagHues, id: \.self) { hue in
                    swatchDot(hue)
                }
            }
        }
    }

    /// A single circular hue swatch.
    private func swatchDot(_ hue: Double) -> some View {
        Button {
            colorHue = hue
        } label: {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Theme.gemColor(hue: hue), Theme.gemColor(hue: hue).opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 26, height: 26)
                .overlay(
                    Circle()
                        .stroke(colorHue == hue ? Color.white : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Action row

    /// Bottom buttons: Cancel + Create in new mode; Delete + Cancel + Save in
    /// edit mode.
    @ViewBuilder
    private var actionRow: some View {
        switch mode {
        case .new:
            HStack(spacing: Theme.Spacing.sm) {
                PillButton(title: "Cancel", tone: .ghost, wide: true) { dismiss() }
                PillButton(
                    title: "Create",
                    color: Theme.amethyst,
                    wide: true,
                    disabled: trimmedName.isEmpty
                ) { commitCreate() }
            }
            .padding(.top, Theme.Spacing.sm)

        case .edit:
            HStack(spacing: Theme.Spacing.sm) {
                IconButton(iconName: "trash") { showDeleteConfirm = true }
                PillButton(title: "Cancel", tone: .ghost, wide: true) { dismiss() }
                PillButton(
                    title: "Save",
                    color: Theme.amethyst,
                    wide: true,
                    disabled: trimmedName.isEmpty
                ) { commitUpdate() }
            }
            .padding(.top, Theme.Spacing.sm)
        }
    }

    // MARK: - Helpers

    private var isEditMode: Bool {
        if case .edit = mode { return true } else { return false }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    /// Populates editable fields from the tag (edit mode) or defaults (new).
    private func seedFromMode() {
        if case let .edit(tag) = mode {
            name = tag.name
            iconName = tag.iconName
            colorHue = tag.colorHue
        } else {
            name = ""
            iconName = "tag"
            colorHue = GemIcons.tagHues.first ?? 300
        }
    }

    // MARK: - Commit paths

    /// Creates a new Tag via TagStore.create and dismisses.
    private func commitCreate() {
        let trimmed = trimmedName
        guard !trimmed.isEmpty else { return }
        _ = try? TagStore.create(
            name: trimmed,
            iconName: iconName,
            colorHue: colorHue,
            in: ctx
        )
        dismiss()
    }

    /// Applies the edited fields via TagStore.update and dismisses (edit mode).
    private func commitUpdate() {
        guard case let .edit(tag) = mode else { dismiss(); return }
        let trimmed = trimmedName
        let nameChanged = !trimmed.isEmpty && trimmed != tag.name
        let iconChanged = iconName != tag.iconName
        let hueChanged  = colorHue != tag.colorHue
        guard nameChanged || iconChanged || hueChanged else { dismiss(); return }
        try? TagStore.update(
            tag,
            name: nameChanged ? trimmed : nil,
            iconName: iconChanged ? iconName : nil,
            colorHue: hueChanged ? colorHue : nil,
            in: ctx
        )
        dismiss()
    }

    /// Deletes the tag (edit mode only) via TagStore.delete and dismisses.
    private func commitDelete() {
        guard case let .edit(tag) = mode else { dismiss(); return }
        try? TagStore.delete(tag, in: ctx)
        dismiss()
    }
}

// MARK: - Previews

#Preview("New tag") {
    let container = try! SeedStore.container(for: .seededMulti)
    return Color.gray.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            TagEditorSheet(mode: .new)
                .modelContainer(container)
        }
}

#Preview("Edit tag") {
    let container = try! SeedStore.container(for: .seededMulti)
    let ctx = ModelContext(container)
    let tag = try! ctx.fetch(FetchDescriptor<Tag>()).first!
    return Color.gray.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            TagEditorSheet(mode: .edit(tag))
                .modelContainer(container)
        }
}

/// ItemRow.swift
/// Purpose: A single row in ChecklistRunView. Displays the Facet checkbox,
///   item text (struck-through when complete), and any tag chips. State
///   (complete / ignored / neither) is passed in by the parent; this view
///   does not read from SwiftData directly.
/// Dependencies: SwiftUI, Facet, TagChip, GemIcons, Theme.
/// Key concepts:
///   - `Display` enum drives visual state (text color, strikethrough, opacity).
///   - Facet color is derived from the first tag's colorHue, defaulting to amethyst.
///   - The `ignored` state dims the entire row to 45 % opacity (per spec §3b).
///   - Tapping the Facet invokes `onToggleCheck`; tapping the row body invokes
///     `onTapBody` (opens ItemEditInline in Task 5.9).

import SwiftUI

/// A single row in ChecklistRunView. Displays the Facet checkbox, item text,
/// and any tag chips. State (complete / ignored / neither) is passed in by
/// the parent; this view does not read from SwiftData.
///
/// Interactions: tapping the facet invokes onToggleCheck; tapping the row
/// body invokes onTapBody (typically opens ItemEditInline).
struct ItemRow: View {

    // MARK: - Display state

    /// The visual state the row should render in.
    enum Display { case incomplete, complete, ignored }

    // MARK: - Inputs

    /// The item's display text.
    let text: String
    /// Tags to render as chips, mapped from SwiftData `Tag` relationships by
    /// the parent view (see `ChecklistRunView.tagTuples(for:)`).
    let tags: [(name: String, iconName: String, colorHue: Double)]
    /// Current check / ignore state for this item in the active run.
    let display: Display
    /// Called when the user taps the Facet checkbox. Toggle logic lives in parent.
    let onToggleCheck: () -> Void
    /// Called when the user taps the row body (to open edit inline). Opens ItemEditInline in Task 5.9.
    let onTapBody: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Button(action: onToggleCheck) {
                Facet(
                    color: facetColor,
                    checked: display == .complete,
                    size: 24
                )
            }
            .buttonStyle(.plain)

            Button(action: onTapBody) {
                HStack {
                    Text(text)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(textColor)
                        .strikethrough(display == .complete, color: Theme.dim)
                    Spacer()
                    tagChips
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .fill(Theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .stroke(Theme.border, lineWidth: 1)
        )
        // Ignored rows are dimmed to 45 % per ARCHITECTURE §3b semantics.
        .opacity(display == .ignored ? 0.45 : 1)
    }

    // MARK: - Private helpers

    /// The Facet's tint color: first tag's hue-derived gem color, else amethyst.
    private var facetColor: Color {
        if let hue = tags.first?.colorHue { return Theme.gemColor(hue: hue) }
        return Theme.amethyst
    }

    /// Text color varies by display state per the Gem design language.
    private var textColor: Color {
        switch display {
        case .incomplete: return Theme.text
        case .complete:   return Theme.dim
        case .ignored:    return Theme.dimmer
        }
    }

    /// Renders zero or more TagChip badges on the trailing side of the row.
    private var tagChips: some View {
        HStack(spacing: 4) {
            ForEach(tags.indices, id: \.self) { i in
                let t = tags[i]
                TagChip(
                    name: t.name,
                    iconName: t.iconName,
                    colorHue: t.colorHue,
                    muted: display != .incomplete,
                    small: true
                )
            }
        }
    }
}

// MARK: - Preview

#Preview("ItemRow states") {
    VStack(spacing: 10) {
        ItemRow(
            text: "Toothbrush",
            tags: [],
            display: .complete,
            onToggleCheck: {}, onTapBody: {}
        )
        ItemRow(
            text: "Sandals",
            tags: [(name: "Beach", iconName: "sun", colorHue: 85)],
            display: .incomplete,
            onToggleCheck: {}, onTapBody: {}
        )
        ItemRow(
            text: "Skis",
            tags: [(name: "Snow", iconName: "snow", colorHue: 250)],
            display: .ignored,
            onToggleCheck: {}, onTapBody: {}
        )
    }
    .padding()
    .background(Theme.bg)
}

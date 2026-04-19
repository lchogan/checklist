/// TagHideChipBar.swift
/// Purpose: Horizontal scrolling chip row for tag visibility toggling on the
///   run view. One chip per tag used by at least one item on the checklist.
/// Dependencies: SwiftUI, TagHideChip (Design/Components/TagChip.swift), Theme.
/// Key concepts: Tags are passed in as plain SwiftData objects; the onToggle
///   closure routes mutations back to RunStore via ChecklistRunView. Tapping a
///   chip calls onToggle(tagID), which updates run.hiddenTagIDs.

import SwiftUI

/// Horizontal scrolling chip row. One chip per tag used by at least one item
/// on the checklist. Tapping toggles whether that tag is hidden on the
/// current run (the chip's visual muted/filled state reflects this).
struct TagHideChipBar: View {
    /// The ordered list of tags to display as chips.
    let tags: [Tag]
    /// The IDs of tags currently hidden on the active run.
    let hiddenTagIDs: [UUID]
    /// Called with the tag's ID when the user taps a chip.
    let onToggle: (UUID) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(tags) { tag in
                    TagHideChip(
                        name: tag.name,
                        iconName: tag.iconName,
                        colorHue: tag.colorHue,
                        hidden: hiddenTagIDs.contains(tag.id)
                    ) {
                        onToggle(tag.id)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
        }
    }
}

/// TagEditorSheet.swift
/// Purpose: Sheet for creating or editing a Tag. Full implementation lands in
///   Task 7.3. This stub exists so TagsView (Task 7.1) compiles.

import SwiftUI

/// Placeholder — replaced by the full implementation in Task 7.3.
struct TagEditorSheet: View {
    enum Mode { case new; case edit(Tag) }

    let mode: Mode

    var body: some View {
        BottomSheet {
            Text("Tag editor stub — landed in Task 7.3")
                .foregroundColor(Theme.dim)
        }
    }
}

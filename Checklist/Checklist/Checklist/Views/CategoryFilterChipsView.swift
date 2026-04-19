/// CategoryFilterChipsView.swift
/// Purpose: Horizontal scrolling row of category filter chips for HomeView.
///   The selected chip uses the gem gradient fill; others are ghost capsules.
///   An "All" chip (selectedCategoryID == nil) is always first.
/// Dependencies: SwiftUI, ChecklistCategory model, Theme.
/// Key concepts:
///   - Binding to selectedCategoryID allows HomeView to react to chip taps.
///   - "All" chip sets selectedCategoryID to nil, showing all checklists.

import SwiftUI

/// Horizontal scrolling row of category filter chips. The selected chip uses
/// the gem gradient fill; others are ghost capsules. An "All" chip
/// (selectedCategoryID == nil) is always first.
struct CategoryFilterChipsView: View {
    /// The list of categories to render as chips (in order).
    let categories: [ChecklistCategory]

    /// Binding to the currently selected category ID. `nil` means "All".
    @Binding var selectedCategoryID: UUID?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.xs) {
                chip(title: "All", isSelected: selectedCategoryID == nil) {
                    selectedCategoryID = nil
                }
                ForEach(categories) { cat in
                    chip(title: cat.name, isSelected: selectedCategoryID == cat.id) {
                        selectedCategoryID = cat.id
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
        }
    }

    /// Renders a single filter chip.
    ///
    /// - Parameters:
    ///   - title: Label to display inside the chip.
    ///   - isSelected: Whether this chip is currently active (uses gradient fill).
    ///   - action: Called when the user taps the chip.
    /// - Returns: A styled `Button` capsule.
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
                    Capsule().stroke(
                        isSelected ? Color.clear : Theme.border,
                        lineWidth: 1
                    )
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview("Category filter chips") {
    struct Wrapper: View {
        @State var selected: UUID? = nil
        var body: some View {
            CategoryFilterChipsView(
                categories: [],
                selectedCategoryID: $selected
            )
            .padding(.vertical)
            .background(Theme.bg)
        }
    }
    return Wrapper()
}

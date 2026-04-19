/// ChecklistRunView.swift
/// Purpose: PLACEHOLDER (Task 4.6). Full implementation lands in Phase 5.
///   Renders the checklist name, category eyebrow, and item count so that
///   HomeView's NavigationStack push can be verified end-to-end before Phase 5.
/// Dependencies: SwiftUI, SwiftData, Checklist model, Theme.
/// Key concepts:
///   - Receives a Checklist via a let property from the navigation destination.
///   - Uses Theme.bg as the background to match the app's dark violet design language.
///   - The toolbar item is a no-op placeholder; the system NavigationStack supplies
///     the back chevron automatically.

import SwiftUI
import SwiftData

/// PLACEHOLDER (Task 4.6). Full implementation lands in Phase 5. For now the
/// view just renders the checklist's name and an item count so Home's
/// navigation push is verifiable end-to-end.
struct ChecklistRunView: View {
    /// The checklist being displayed. Passed in from the NavigationStack destination.
    let checklist: Checklist

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 16) {
                Text(checklist.category?.name.uppercased() ?? "")
                    .font(Theme.eyebrow())
                    .tracking(2)
                    .foregroundColor(Theme.dim)
                Text(checklist.name)
                    .font(Theme.display(size: 28))
                    .foregroundColor(Theme.text)
                Text("\(checklist.items?.count ?? 0) items · Phase-5 UI coming")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.dim)
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                // System nav bar will supply the back chevron; nothing extra needed here.
                EmptyView()
            }
        }
    }
}

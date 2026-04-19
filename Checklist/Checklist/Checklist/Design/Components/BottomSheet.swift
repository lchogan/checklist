import SwiftUI
import UIKit

/// Shared bottom sheet wrapper. All prototype sheets share this chrome:
/// dimmed overlay, rounded top corners, drag-handle pill, ivory text on
/// violet background. Use as a `.sheet(isPresented:)` content wrapper.
struct BottomSheet<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Theme.border)
                .frame(width: 42, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 4)

            content()
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.bottom, Theme.Spacing.xxl)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            LinearGradient(
                colors: [Theme.bg2, Theme.bg],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedCornerShape(radius: 28, corners: [.topLeft, .topRight]))
        .overlay(
            RoundedCornerShape(radius: 28, corners: [.topLeft, .topRight])
                .stroke(Theme.borderHi, lineWidth: 1)
        )
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.clear)
    }
}

/// Corner-specific rounded rectangle helper.
private struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        ).cgPath)
    }
}

#Preview("BottomSheet") {
    Color.gray.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            BottomSheet {
                VStack(alignment: .leading, spacing: 12) {
                    Text("NEW LIST")
                        .font(Theme.eyebrow())
                        .foregroundColor(Theme.dim)
                        .tracking(2)
                    Text("Name your checklist.")
                        .font(Theme.display(size: 26))
                        .foregroundColor(Theme.text)
                    PillButton(title: "Create", wide: true) {}
                }
            }
        }
}

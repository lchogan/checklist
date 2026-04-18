import SwiftUI

/// Interactive tutorial showing how to use the app
struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    
    private let pages: [TutorialPage] = [
        TutorialPage(
            icon: "plus.circle.fill",
            title: "Create Checklists",
            description: "Tap the + button to create a new checklist",
            color: .blue,
            animation: AnyView(CreateChecklistAnimation())
        ),
        TutorialPage(
            icon: "checkmark.circle.fill",
            title: "Check Off Items",
            description: "Tap the circle to mark items complete",
            color: .green,
            animation: AnyView(CheckmarkAnimation())
        ),
        TutorialPage(
            icon: "hand.tap.fill",
            title: "Tap to Edit",
            description: "Tap any item to edit its text",
            color: .blue,
            animation: AnyView(TapToEditAnimation())
        ),
        TutorialPage(
            icon: "tag.fill",
            title: "Add Tags",
            description: "Tap an item, then tap the tag icon to organize",
            color: .purple,
            animation: AnyView(TapToAddTagsAnimation())
        ),
        TutorialPage(
            icon: "arrow.left.arrow.right",
            title: "Swipe Actions",
            description: "Swipe right to duplicate, left to delete",
            color: .orange,
            animation: AnyView(SwipeActionsAnimation())
        ),
        TutorialPage(
            icon: "arrow.up.arrow.down",
            title: "Reorder Items",
            description: "Press and hold an item, then drag to reorder",
            color: .indigo,
            animation: AnyView(LongPressReorderAnimation())
        )
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Page Indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        TutorialPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // Navigation Buttons
                HStack(spacing: 16) {
                    if currentPage > 0 {
                        Button {
                            withAnimation {
                                currentPage -= 1
                            }
                        } label: {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                    } else {
                        Spacer()
                    }
                    
                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                            if currentPage < pages.count - 1 {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Tutorial Page Model

private struct TutorialPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let animation: AnyView
}

// MARK: - Tutorial Page View

private struct TutorialPageView: View {
    let page: TutorialPage
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: page.icon)
                    .font(.system(size: 48))
                    .foregroundStyle(page.color)
            }
            .padding(.bottom, 16)
            
            // Title
            Text(page.title)
                .font(.title.bold())
                .multilineTextAlignment(.center)
            
            // Description
            Text(page.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .fixedSize(horizontal: false, vertical: true)
            
            // Animation Demo
            page.animation
                .frame(height: 80)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 32)
                .padding(.top, 16)
            
            Spacer()
            Spacer()
        }
    }
}

// MARK: - Animations

struct CreateChecklistAnimation: View {
    @State private var showChecklist = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Plus button
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(showChecklist ? 0.3 : 0.1))
                    .frame(width: 50, height: 50)
                    .scaleEffect(showChecklist ? 1.2 : 1.0)
                
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundStyle(Color.accentColor)
            }
            
            // New checklist appearing
            if showChecklist {
                HStack {
                    Image(systemName: "checklist")
                        .foregroundStyle(.secondary)
                    Text("My New List")
                        .font(.headline)
                    Spacer()
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                startAnimation()
            }
        }
    }

    private func startAnimation() {
        // Pulse and show checklist
        withAnimation(.easeInOut(duration: 0.5)) {
            showChecklist = true
        }
        
        // Hold for 3 seconds, then hide and restart
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showChecklist = false
            }
            
            // Restart cycle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                startAnimation()
            }
        }
    }
}

// Screen 2: Checkmark Animation
struct CheckmarkAnimation: View {
    @State private var isChecked = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Animated circle/checkmark
            ZStack {
                Circle()
                    .strokeBorder(Color.accentColor, lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .opacity(isChecked ? 0 : 1)
                
                ZStack {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
                .opacity(isChecked ? 1 : 0)
                .scaleEffect(isChecked ? 1 : 0.5)
            }
            
            Text("Sample Item")
                .font(.body)
            
            Spacer()
        }
        .padding(.horizontal)
        .frame(height: 44)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                startAnimation()
            }
        }
    }

    private func startAnimation() {
        // Check the item
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isChecked = true
        }

        // Hold checked for 2.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isChecked = false
            }

            // Restart cycle after a short pause
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                startAnimation()
            }
        }
    }
}

// Screen 3: Tap to Edit Animation
struct TapToEditAnimation: View {
    @State private var isEditing = false
    @State private var text = "Sample Item"
    @State private var showCursor = false
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .strokeBorder(Color.accentColor, lineWidth: 2)
                .frame(width: 24, height: 24)
            
            ZStack(alignment: .leading) {
                // Background highlight when editing
                if isEditing {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accentColor.opacity(0.1))
                }
                
                HStack(spacing: 0) {
                    Text(text)
                        .font(.body)
                    
                    // Blinking cursor
                    if showCursor {
                        Rectangle()
                            .fill(Color.accentColor)
                            .frame(width: 2, height: 20)
                            .padding(.leading, 2)
                    }
                }
                .padding(.horizontal, isEditing ? 6 : 0)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .frame(height: 44)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                startAnimation()
            }
        }
    }

    private func startAnimation() {
        // Cursor appears first
        withAnimation(.easeInOut(duration: 0.2)) {
            showCursor = true
        }

        // Field activates (highlight)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isEditing = true
            }

            // Schedule deletions and typing using a fixed base time
            let base = DispatchTime.now() + 0.4

            let deleteSteps = [
                "Sample Ite", "Sample It", "Sample I", "Sample ",
                "Sample", "Sampl", "Samp", "Sam", "Sa", "S", ""
            ]
            for (i, str) in deleteSteps.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: base + Double(i) * 0.1) {
                    text = str
                }
            }

            let typeBase = base + Double(deleteSteps.count) * 0.1
            let typeSteps = [
                "P", "Pa", "Pac", "Pack", "Packi", "Packin",
                "Packing", "Packing ", "Packing L", "Packing Li", "Packing Lis", "Packing List"
            ]
            for (i, str) in typeSteps.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: typeBase + Double(i) * 0.1) {
                    text = str
                }
            }

            // Hold for 2s after typing finishes, then reset
            let holdBase = typeBase + Double(typeSteps.count) * 0.1
            DispatchQueue.main.asyncAfter(deadline: holdBase + 2.0) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isEditing = false
                    showCursor = false
                }
                text = "Sample Item"

                // Restart cycle — 2s pause in unselected state
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    startAnimation()
                }
            }
        }
    }
}

// Screen 4: Tap to Add Tags Animation
struct TapToAddTagsAnimation: View {
    @State private var isEditing = false
    @State private var showCursor = false
    @State private var showTagButton = false
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .strokeBorder(Color.accentColor, lineWidth: 2)
                .frame(width: 24, height: 24)
            
            ZStack(alignment: .leading) {
                // Background highlight when editing
                if isEditing {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accentColor.opacity(0.1))
                }
                
                HStack(spacing: 0) {
                    Text("Sample Item")
                        .font(.body)
                    
                    // Blinking cursor
                    if showCursor {
                        Rectangle()
                            .fill(Color.accentColor)
                            .frame(width: 2, height: 20)
                            .padding(.leading, 2)
                    }
                }
                .padding(.horizontal, isEditing ? 6 : 0)
            }
            
            Spacer()
            
            // Tag button
            if showTagButton {
                Image(systemName: "tag.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.purple)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal)
        .frame(height: 44)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                startAnimation()
            }
        }
    }

    private func startAnimation() {
        // Cursor appears first
        withAnimation(.easeInOut(duration: 0.2)) {
            showCursor = true
        }

        // Field activates (selected)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isEditing = true
            }

            // Tag icon appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showTagButton = true
                }

                // Hold for 2.5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    // Reset
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isEditing = false
                        showCursor = false
                        showTagButton = false
                    }

                    // Restart cycle — 1s pause in unselected state
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        startAnimation()
                    }
                }
            }
        }
    }
}

// Screen 5: Swipe Actions Animation
struct SwipeActionsAnimation: View {
    @State private var offset: CGFloat = 0
    @State private var showingLeft = true
    @State private var animationCount = 0
    
    var body: some View {
        ZStack(alignment: showingLeft ? .leading : .trailing) {
            // Action button revealed
            HStack {
                if showingLeft {
                    Image(systemName: "plus.square.on.square")
                        .foregroundStyle(.white)
                        .frame(width: 70)
                        .frame(maxHeight: .infinity)
                        .background(Color.blue)
                    Spacer()
                } else {
                    Spacer()
                    Image(systemName: "trash")
                        .foregroundStyle(.white)
                        .frame(width: 70)
                        .frame(maxHeight: .infinity)
                        .background(Color.red)
                }
            }
            
            // Sliding item
            HStack(spacing: 12) {
                Circle()
                    .strokeBorder(Color.accentColor, lineWidth: 2)
                    .frame(width: 24, height: 24)
                
                Text("Sample Item")
                    .font(.body)
                
                Spacer()
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color(.systemBackground))
            .offset(x: offset)
        }
        .frame(height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Swipe right (duplicate)
        withAnimation(.easeInOut(duration: 0.8)) {
            showingLeft = true
            offset = 70
        }
        
        // Hold for 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
            // Return to center
            withAnimation(.easeInOut(duration: 0.4)) {
                offset = 0
            }
            
            // Swipe left (delete)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    showingLeft = false
                    offset = -70
                }
                
                // Hold for 1.5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
                    // Return to center
                    withAnimation(.easeInOut(duration: 0.4)) {
                        offset = 0
                        showingLeft = true
                    }
                    
                    // Restart cycle after 1 second
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        startAnimation()
                    }
                }
            }
        }
    }
}

// Screen 6: Long Press Reorder Animation
struct LongPressReorderAnimation: View {
    @State private var draggedItem: Int? = nil
    @State private var offset: CGFloat = 0
    
    private let items = ["First Item", "Second Item", "Third Item"]
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(spacing: 12) {
                    Circle()
                        .strokeBorder(Color.accentColor, lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    Text(item)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Image(systemName: "line.3.horizontal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(radius: draggedItem == index ? 4 : 0)
                .scaleEffect(draggedItem == index ? 1.05 : 1.0)
                .offset(y: draggedItem == index ? offset : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: draggedItem)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: offset)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Press and hold first item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            draggedItem = 0
            
            // Drag down
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                offset = 40
                
                // Hold
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    // Release
                    draggedItem = nil
                    offset = 0
                    
                    // Restart
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        startAnimation()
                    }
                }
            }
        }
    }
}

#Preview {
    TutorialView()
}


import SwiftUI
import SwiftData

// MARK: - Settings sheet

struct ChecklistSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @Bindable var checklist: Checklist
    
    @Query(sort: \ChecklistCategory.name) private var categories: [ChecklistCategory]
    
    @State private var showCategorySheet = false
    @FocusState private var isNameFocused: Bool
    
    var body: some View {
        NavigationStack {
            List {
                Section("Name") {
                    TextField("Checklist Name", text: $checklist.name)
                        .font(.headline)
                        .submitLabel(.done)
                        .focused($isNameFocused)
                        .onChange(of: checklist.name) { _ in
                            save()
                        }
                }
                
                Section("Category") {
                    Button {
                        showCategorySheet = true
                    } label: {
                        HStack {
                            Text(checklist.category?.name ?? "No Category")
                                .foregroundColor(checklist.category == nil ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Display") {
                    Toggle("Show Progress Bar", isOn: $checklist.showProgressBar)
                        .onChange(of: checklist.showProgressBar) { _ in save() }
                    
                    Toggle("Show Tags on Items", isOn: $checklist.showTagsOnItems)
                        .onChange(of: checklist.showTagsOnItems) { _ in save() }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { isNameFocused = false }
                }
            }
            .sheet(isPresented: $showCategorySheet) {
                CategoryPickerSheet(selectedCategory: Binding(
                    get: { checklist.category },
                    set: { newCategory in
                        checklist.category = newCategory
                        save()
                    }
                ))
                .environmentObject(entitlementManager)
            }
        }
    }
    
    private func save() {
        try? context.save()
    }
}

// MARK: - Help sheet with animated demonstrations

struct ChecklistHelpSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text("How to use your checklist")
                        .font(.title2.bold())
                        .padding(.top)
                    
                    GestureDemoCard(
                        title: "Tap to Edit",
                        description: "Tap any item to edit its text",
                        systemImage: "hand.tap",
                        color: .blue
                    ) {
                        TapToEditAnimation()
                    }
                    
                    GestureDemoCard(
                        title: "Add Tags to Items",
                        description: "Tap an item, then tap the tag icon to add tags",
                        systemImage: "tag",
                        color: .purple
                    ) {
                        TapToAddTagsAnimation()
                    }
                    
                    GestureDemoCard(
                        title: "Swipe Right to Duplicate",
                        description: "Swipe an item to the right to create a copy",
                        systemImage: "plus.square.on.square",
                        color: .blue
                    ) {
                        SwipeRightAnimation()
                    }
                    
                    GestureDemoCard(
                        title: "Swipe Left to Delete",
                        description: "Swipe an item to the left to remove it",
                        systemImage: "trash",
                        color: .red
                    ) {
                        SwipeLeftAnimation()
                    }
                    
                    GestureDemoCard(
                        title: "Long Press to Reorder",
                        description: "Press and hold an item, then drag to reorder",
                        systemImage: "arrow.up.arrow.down",
                        color: .orange
                    ) {
                        LongPressReorderAnimation()
                    }
                    
                    GestureDemoCard(
                        title: "Tap Circle to Complete",
                        description: "Tap the circle to mark an item complete",
                        systemImage: "checkmark.circle",
                        color: .green
                    ) {
                        CheckmarkAnimation()
                    }
                }
                .padding()
            }
            .navigationTitle("Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Gesture demo card

struct GestureDemoCard<Content: View>: View {
    let title: String
    let description: String
    let systemImage: String
    let color: Color
    @ViewBuilder let animation: Content
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            animation
                .frame(height: 60)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Swipe animations for help sheet

struct SwipeRightAnimation: View {
    @State private var offset: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Duplicate button revealed
            HStack {
                Image(systemName: "plus.square.on.square")
                    .foregroundStyle(.white)
                    .frame(width: 70)
                    .frame(maxHeight: .infinity)
                    .background(Color.blue)
                Spacer()
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
        .padding(.horizontal)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                offset = 70
            }
        }
    }
}

struct SwipeLeftAnimation: View {
    @State private var offset: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete button revealed
            HStack {
                Spacer()
                Image(systemName: "trash")
                    .foregroundStyle(.white)
                    .frame(width: 70)
                    .frame(maxHeight: .infinity)
                    .background(Color.red)
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
        .padding(.horizontal)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                offset = -70
            }
        }
    }
}

// MARK: - Main checklist run view

struct ChecklistRunView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @Bindable var checklist: Checklist

    @State private var hiddenTagIDs: Set<PersistentIdentifier> = []
    @State private var hideUntagged = false
    @State private var showResetConfirmation = false
    @State private var showSettingsSheet = false
    @State private var showHelpSheet = false
    @State private var tagPickerItem: ChecklistItem?
    @State private var editingItemID: PersistentIdentifier?
    
    @FocusState private var focusedItemID: PersistentIdentifier?

    // MARK: - Computed

    private var visibleItems: [ChecklistItem] {
        checklist.sortedItems.filter { item in
            // Filter out untagged items if hideUntagged is true
            if hideUntagged && item.tags.isEmpty {
                return false
            }
            
            // If item has no tags, show it (unless hideUntagged is true, which we already checked)
            guard !item.tags.isEmpty else { return true }
            
            // If no tags are hidden, show all tagged items
            guard !hiddenTagIDs.isEmpty else { return true }
            
            // Show item if at least one of its tags is NOT hidden
            // (Hide only if ALL its tags are hidden)
            return item.tags.contains { tag in
                !hiddenTagIDs.contains(tag.persistentModelID)
            }
        }
    }

    private var hiddenItemCount: Int {
        checklist.items.filter { item in
            // Count untagged items as hidden if hideUntagged is true
            if hideUntagged && item.tags.isEmpty {
                return true
            }
            
            // Only count as hidden if the item has tags AND all of them are hidden
            guard !item.tags.isEmpty else { return false }
            guard !hiddenTagIDs.isEmpty else { return false }
            
            // Item is hidden only if ALL its tags are in the hidden set
            return !item.tags.contains { tag in
                !hiddenTagIDs.contains(tag.persistentModelID)
            }
        }.count
    }

    private var completionInfo: (completed: Int, total: Int) {
        let relevant = visibleItems.filter { $0.status != .deferred }
        let completed = relevant.filter { $0.status == .complete }.count
        return (completed, relevant.count)
    }

    private var progress: Double {
        let info = completionInfo
        guard info.total > 0 else { return 0 }
        return Double(info.completed) / Double(info.total)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tag filter bar
            if !checklist.usedTags.isEmpty {
                tagFilterBar
                Divider()
            }

            // Completion header
            if checklist.showProgressBar {
                completionHeader
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
            }

            // Hidden items note
            if hiddenItemCount > 0 {
                HStack {
                    Image(systemName: "tag.slash")
                        .font(.caption)
                    Text("\(hiddenItemCount) tagged \(hiddenItemCount == 1 ? "item" : "items") hidden")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if checklist.showProgressBar || hiddenItemCount > 0 {
                Divider()
            }

            // Item list
            List {
                ForEach(visibleItems) { item in
                    EditableRunItemRow(
                        item: item,
                        showTags: checklist.showTagsOnItems,
                        focusedItemID: $focusedItemID,
                        onTagsTapped: {
                            tagPickerItem = item
                        },
                        onReturn: {
                            addItem()
                        }
                    )
                    .listRowSeparator(.visible, edges: .bottom)
                    .listRowSeparatorTint(.clear)
                    .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteItem(item)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            duplicateItem(item)
                        } label: {
                            Label("Duplicate", systemImage: "plus.square.on.square")
                        }
                        .tint(.blue)
                    }
                }
                .onMove { indices, destination in
                    moveItems(fromOffsets: indices, toOffset: destination)
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle(checklist.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    addItem()
                } label: {
                    Image(systemName: "plus")
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showSettingsSheet = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                    
                    Button {
                        showHelpSheet = true
                    } label: {
                        Label("Help", systemImage: "questionmark.circle")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Label("Reset Checklist", systemImage: "arrow.counterclockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedItemID = nil }
            }
        }
        .sheet(isPresented: $showSettingsSheet) {
            ChecklistSettingsSheet(checklist: checklist)
                .environmentObject(entitlementManager)
        }
        .sheet(isPresented: $showHelpSheet) {
            ChecklistHelpSheet()
        }
        .sheet(item: $tagPickerItem) { item in
            TagPickerSheet(selectedTags: Binding(
                get: { item.tags },
                set: { newTags in
                    item.tags = newTags
                    save()
                }
            ))
        }
        .confirmationDialog(
            "Reset Checklist?",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset All Items", role: .destructive) {
                resetChecklist()
            }
        } message: {
            Text("All items will be set back to incomplete. Tag filters will stay the same.")
        }
        .onAppear {
            // Auto-focus if this is a freshly created checklist (single empty item)
            if checklist.items.count == 1, let first = checklist.sortedItems.first, first.text.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    focusedItemID = first.persistentModelID
                }
            }
        }
    }

    // MARK: - Tag filter bar

    private var tagFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Untagged filter
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        hideUntagged.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        if hideUntagged {
                            Image(systemName: "eye.slash")
                                .font(.caption)
                        } else {
                            Image(systemName: "tag.slash")
                                .font(.caption)
                        }
                        Text("Untagged")
                            .font(.subheadline.weight(.medium))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        hideUntagged ? Color(.systemGray5) : Color.accentColor,
                        in: Capsule()
                    )
                    .foregroundStyle(hideUntagged ? Color.secondary : .white)
                    .overlay(
                        Capsule()
                            .strokeBorder(hideUntagged ? Color(.systemGray3) : .clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                
                // Regular tags
                ForEach(checklist.usedTags) { tag in
                    let isHidden = hiddenTagIDs.contains(tag.persistentModelID)
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            if isHidden {
                                hiddenTagIDs.remove(tag.persistentModelID)
                            } else {
                                hiddenTagIDs.insert(tag.persistentModelID)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            if isHidden {
                                Image(systemName: "eye.slash")
                                    .font(.caption)
                            } else {
                                Image(systemName: tag.iconName)
                                    .font(.caption)
                            }
                            Text(tag.name)
                                .font(.subheadline.weight(.medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            isHidden ? Color(.systemGray5) : Color.accentColor,
                            in: Capsule()
                        )
                        .foregroundStyle(isHidden ? Color.secondary : .white)
                        .overlay(
                            Capsule()
                                .strokeBorder(isHidden ? Color(.systemGray3) : .clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Completion header

    private var completionHeader: some View {
        let info = completionInfo
        let allDone = info.total > 0 && info.completed == info.total

        return VStack(spacing: 8) {
            HStack {
                Text("Progress")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(info.completed) / \(info.total)")
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(allDone ? .green : .primary)
            }
            ProgressView(value: progress)
                .tint(allDone ? .green : .accentColor)
                .animation(.easeInOut, value: progress)
        }
    }

    // MARK: - Actions
    
    private func addItem() {
        let order = checklist.items.count
        let newItem = ChecklistItem(text: "", order: order)
        checklist.items.append(newItem)
        save()
        
        // Focus the new item after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            focusedItemID = newItem.persistentModelID
        }
    }
    
    private func deleteItem(_ item: ChecklistItem) {
        withAnimation {
            context.delete(item)
            save()
        }
    }
    
    private func duplicateItem(_ item: ChecklistItem) {
        guard let index = checklist.sortedItems.firstIndex(where: { $0.persistentModelID == item.persistentModelID }) else { return }
        let copy = ChecklistItem(text: item.text, order: index + 1)
        copy.tags = item.tags
        copy.status = item.status
        
        // Adjust order for items after the duplicated one
        for i in (index + 1)..<checklist.sortedItems.count {
            checklist.sortedItems[i].order += 1
        }
        
        checklist.items.append(copy)
        save()
    }
    
    private func moveItems(fromOffsets source: IndexSet, toOffset destination: Int) {
        var sortedItems = checklist.sortedItems
        sortedItems.move(fromOffsets: source, toOffset: destination)
        
        // Reindex all items
        for (index, item) in sortedItems.enumerated() {
            item.order = index
        }
        
        save()
    }

    private func resetChecklist() {
        for item in checklist.items {
            item.status = .incomplete
        }
        save()
    }

    private func save() {
        try? context.save()
    }
}

// MARK: - Editable Run item row

struct EditableRunItemRow: View {
    @Bindable var item: ChecklistItem
    let showTags: Bool
    @FocusState.Binding var focusedItemID: PersistentIdentifier?
    let onTagsTapped: () -> Void
    let onReturn: () -> Void
    
    @Environment(\.modelContext) private var context
    
    private var isFocused: Bool { focusedItemID == item.persistentModelID }

    var body: some View {
        HStack(spacing: 14) {
            completionButton
            itemContent
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .opacity(item.status == .complete || item.status == .deferred ? 0.45 : 1)
        .animation(.easeInOut(duration: 0.2), value: item.status)
    }

    private var completionButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                switch item.status {
                case .incomplete:
                    item.status = .complete
                case .complete:
                    item.status = .incomplete
                case .deferred:
                    item.status = .incomplete
                }
                try? context.save()
            }
        } label: {
            circleView
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var circleView: some View {
        switch item.status {
        case .incomplete:
            Circle()
                .strokeBorder(Color.accentColor, lineWidth: 2)
                .frame(width: 26, height: 26)
        case .complete:
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 26, height: 26)
        case .deferred:
            // Show a dash placeholder to maintain alignment
            Rectangle()
                .fill(Color.clear)
                .frame(width: 26, height: 26)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(white: 0.8))
                        .frame(width: 14, height: 3)
                )
        }
    }

    private var itemContent: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                TextField("Item text", text: $item.text)
                    .focused($focusedItemID, equals: item.persistentModelID)
                    .submitLabel(.return)
                    .strikethrough(item.status == .complete, color: .secondary)
                    .onSubmit {
                        onReturn()
                    }
                    .onChange(of: item.text) { oldValue, newValue in
                        // Remove empty items when focus is lost
                        if !isFocused && newValue.trimmingCharacters(in: .whitespaces).isEmpty {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                context.delete(item)
                                try? context.save()
                            }
                        }
                    }

                if showTags && !item.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(item.tags) { tag in
                            HStack(spacing: 3) {
                                Image(systemName: tag.iconName)
                                    .font(.system(size: 9))
                                Text(tag.name)
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray5), in: Capsule())
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            if isFocused {
                Button(action: onTagsTapped) {
                    HStack(spacing: 4) {
                        if !item.tags.isEmpty {
                            Text("\(item.tags.count)")
                                .font(.caption.bold())
                        }
                        Image(systemName: "tag")
                    }
                    .font(.subheadline)
                    .foregroundColor(item.tags.isEmpty ? .secondary : .accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(item.tags.isEmpty
                                  ? Color(.systemGray5)
                                  : Color.accentColor.opacity(0.15))
                    )
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .trailing)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

import SwiftUI
import SwiftData

private struct NewChecklistRoute: Hashable {}

struct ChecklistListView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var entitlementManager: EntitlementManager

    @Query(sort: \Checklist.createdAt, order: .reverse) private var checklists: [Checklist]
    @Query(sort: \ChecklistCategory.name) private var allCategories: [ChecklistCategory]

    @State private var path = NavigationPath()
    @State private var selectedCategory: ChecklistCategory?
    @State private var checklistToDelete: Checklist?
    @State private var showDeleteConfirmation = false
    @State private var paywallReason: PaywallReason?
    @State private var showProfile = false
    @State private var showTutorial = false
    
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial = false
    
    // Only show categories that have at least one checklist
    private var categoriesWithChecklists: [ChecklistCategory] {
        allCategories.filter { category in
            checklists.contains { $0.category?.persistentModelID == category.persistentModelID }
        }
    }

    private var filteredChecklists: [Checklist] {
        guard let cat = selectedCategory else { return checklists }
        return checklists.filter { $0.category?.persistentModelID == cat.persistentModelID }
    }

    /// Groups for the "All" view — one entry per category, then uncategorized at the end.
    private var groupedChecklists: [(id: String, header: String?, checklists: [Checklist])] {
        var result: [(id: String, header: String?, checklists: [Checklist])] = []

        for cat in categoriesWithChecklists {
            let items = checklists.filter { $0.category?.persistentModelID == cat.persistentModelID }
            guard !items.isEmpty else { continue }
            result.append((cat.name, cat.name, items))
        }

        let uncategorized = checklists.filter { $0.category == nil }
        if !uncategorized.isEmpty {
            // Only show "No Category" header when there are also categorized sections
            let header: String? = result.isEmpty ? nil : "No Category"
            result.append(("__uncategorized__", header, uncategorized))
        }

        return result
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                if !categoriesWithChecklists.isEmpty {
                    CategoryFilterBar(
                        categories: categoriesWithChecklists,
                        selectedCategory: $selectedCategory
                    )
                    Divider()
                }

                if filteredChecklists.isEmpty {
                    emptyState
                } else {
                    List {
                        if selectedCategory == nil {
                            // Grouped by category
                            ForEach(groupedChecklists, id: \.id) { group in
                                if let header = group.header {
                                    Section(header) {
                                        ForEach(group.checklists) { checklist in
                                            checklistRow(checklist)
                                        }
                                    }
                                } else {
                                    Section {
                                        ForEach(group.checklists) { checklist in
                                            checklistRow(checklist)
                                        }
                                    }
                                }
                            }
                        } else {
                            // Flat filtered list for a single selected category
                            ForEach(filteredChecklists) { checklist in
                                checklistRow(checklist)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Checklists")
            .navigationDestination(for: Checklist.self) { checklist in
                ChecklistRunView(checklist: checklist)
            }
            .navigationDestination(for: NewChecklistRoute.self) { _ in
                ChecklistEditView(path: $path)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showProfile = true
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .font(.title3)
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        handleAddChecklist()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .confirmationDialog(
                "Delete \"\(checklistToDelete?.name ?? "")\"?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let checklist = checklistToDelete {
                        context.delete(checklist)
                        try? context.save()
                    }
                }
            } message: {
                Text("This will permanently delete the checklist and all its items.")
            }
            .sheet(item: $paywallReason) { reason in
                PaywallView(reason: reason)
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
            .sheet(isPresented: $showTutorial) {
                TutorialView()
                    .onDisappear {
                        hasSeenTutorial = true
                    }
            }
            .onAppear {
                if !hasSeenTutorial {
                    // Delay slightly to let the view settle
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showTutorial = true
                    }
                }
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checklist")
                .font(.system(size: 56))
                .foregroundStyle(.tertiary)
            Text("No Checklists")
                .font(.title2.bold())
            Text("Tap + to create your first checklist.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }

    // MARK: - Row helper

    @ViewBuilder
    private func checklistRow(_ checklist: Checklist) -> some View {
        NavigationLink(value: checklist) {
            ChecklistRowView(checklist: checklist)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                checklistToDelete = checklist
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                duplicateChecklist(checklist)
            } label: {
                Label("Duplicate", systemImage: "plus.square.on.square")
            }
            .tint(.blue)
        }
    }

    // MARK: - Actions

    private func handleAddChecklist() {
        if entitlementManager.limits.canAdd(checklists: checklists.count) {
            path.append(NewChecklistRoute())
        } else {
            paywallReason = .checklistLimit(entitlementManager.limits.maxChecklists ?? 1)
        }
    }

    private func duplicateChecklist(_ checklist: Checklist) {
        if !entitlementManager.limits.canAdd(checklists: checklists.count) {
            paywallReason = .checklistLimit(entitlementManager.limits.maxChecklists ?? 1)
            return
        }
        let copy = Checklist(name: checklist.name + " Copy")
        copy.category = checklist.category
        context.insert(copy)
        for (index, item) in checklist.sortedItems.enumerated() {
            let itemCopy = ChecklistItem(text: item.text, order: index)
            itemCopy.tags = item.tags
            copy.items.append(itemCopy)
        }
        try? context.save()
    }
}

// MARK: - Category filter bar

struct CategoryFilterBar: View {
    let categories: [ChecklistCategory]
    @Binding var selectedCategory: ChecklistCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "All", 
                    isSelected: selectedCategory == nil,
                    showsCheckmark: true
                ) {
                    selectedCategory = nil
                }
                ForEach(categories) { category in
                    FilterChip(
                        title: category.name,
                        isSelected: selectedCategory?.persistentModelID == category.persistentModelID,
                        showsCheckmark: true
                    ) {
                        if selectedCategory?.persistentModelID == category.persistentModelID {
                            selectedCategory = nil
                        } else {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var showsCheckmark: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                if isSelected && showsCheckmark {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.semibold))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                isSelected ? Color.accentColor : Color(.systemGray5),
                in: Capsule()
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Checklist row

struct ChecklistRowView: View {
    let checklist: Checklist

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(checklist.name)
                    .font(.headline)
                    .lineLimit(1)
                if let category = checklist.category {
                    Text(category.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            CompletionFractionLabel(checklist: checklist)
        }
        .padding(.vertical, 2)
    }
}

struct CompletionFractionLabel: View {
    let checklist: Checklist

    var body: some View {
        let info = checklist.listViewCompletionInfo
        let allDone = info.total > 0 && info.completed == info.total
        Text("\(info.completed)/\(info.total)")
            .font(.subheadline.monospacedDigit().weight(.medium))
            .foregroundStyle(allDone ? .green : .secondary)
    }
}

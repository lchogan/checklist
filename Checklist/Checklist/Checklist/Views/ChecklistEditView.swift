import SwiftUI
import SwiftData

struct ChecklistEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlementManager: EntitlementManager

    @Query(sort: \ChecklistCategory.name) private var categories: [ChecklistCategory]

    @Binding var path: NavigationPath

    @State private var name: String = ""
    @State private var selectedCategory: ChecklistCategory?
    @State private var showCategorySheet = false

    @FocusState private var isNameFocused: Bool

    var body: some View {
        List {
            Section {
                TextField("Checklist Name", text: $name)
                    .font(.headline)
                    .submitLabel(.done)
                    .focused($isNameFocused)
                    .onSubmit {
                        save()
                    }

                Button {
                    showCategorySheet = true
                } label: {
                    HStack {
                        Text(selectedCategory?.name ?? "No Category")
                            .foregroundColor(selectedCategory == nil ? .secondary : .primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("New Checklist")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                .fontWeight(.semibold)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showCategorySheet) {
            CategoryPickerSheet(selectedCategory: $selectedCategory)
                .environmentObject(entitlementManager)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isNameFocused = true
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let checklist = Checklist(name: trimmedName)
        checklist.category = selectedCategory
        context.insert(checklist)

        let firstItem = ChecklistItem(text: "", order: 0)
        checklist.items.append(firstItem)

        try? context.save()

        // Replace the edit view with the run view in the navigation stack
        path.removeLast()
        path.append(checklist)
    }
}

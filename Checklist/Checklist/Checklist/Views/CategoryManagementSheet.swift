import SwiftUI
import SwiftData

// MARK: - Common Icons

/// Comprehensive SF Symbol icon library organized by category
struct IconLibrary {
    struct IconItem: Identifiable {
        let id: String
        let name: String
        let symbol: String
        let category: String
        let keywords: [String]
        
        init(name: String, symbol: String, category: String, keywords: [String] = []) {
            self.id = symbol
            self.name = name
            self.symbol = symbol
            self.category = category
            self.keywords = keywords
        }
    }
    
    static let all: [IconItem] = [
        // Common & Popular
        IconItem(name: "Star", symbol: "star.fill", category: "Common", keywords: ["favorite", "important", "highlight"]),
        IconItem(name: "Heart", symbol: "heart.fill", category: "Common", keywords: ["love", "like", "favorite"]),
        IconItem(name: "Flag", symbol: "flag.fill", category: "Common", keywords: ["marker", "important", "reminder"]),
        IconItem(name: "Bookmark", symbol: "bookmark.fill", category: "Common", keywords: ["save", "mark"]),
        IconItem(name: "Pin", symbol: "pin.fill", category: "Common", keywords: ["location", "mark"]),
        IconItem(name: "Checkmark", symbol: "checkmark.circle.fill", category: "Common", keywords: ["done", "complete", "check"]),
        IconItem(name: "Tag", symbol: "tag.fill", category: "Common", keywords: ["label", "category"]),
        
        // Home & Living
        IconItem(name: "House", symbol: "house.fill", category: "Home", keywords: ["home", "living"]),
        IconItem(name: "Building", symbol: "building.2.fill", category: "Home", keywords: ["apartment", "condo"]),
        IconItem(name: "Bed", symbol: "bed.double.fill", category: "Home", keywords: ["bedroom", "sleep"]),
        IconItem(name: "Sofa", symbol: "sofa.fill", category: "Home", keywords: ["couch", "living room"]),
        IconItem(name: "Lamp", symbol: "lamp.desk.fill", category: "Home", keywords: ["light", "desk"]),
        IconItem(name: "Key", symbol: "key.fill", category: "Home", keywords: ["lock", "security"]),
        IconItem(name: "Door", symbol: "door.left.hand.open", category: "Home", keywords: ["entrance", "exit"]),
        IconItem(name: "Stairs", symbol: "stairs", category: "Home", keywords: ["up", "down"]),
        
        // Work & Productivity
        IconItem(name: "Briefcase", symbol: "briefcase.fill", category: "Work", keywords: ["work", "job", "business"]),
        IconItem(name: "Folder", symbol: "folder.fill", category: "Work", keywords: ["files", "documents", "organize"]),
        IconItem(name: "Document", symbol: "doc.fill", category: "Work", keywords: ["file", "paper"]),
        IconItem(name: "Calendar", symbol: "calendar", category: "Work", keywords: ["date", "schedule", "plan"]),
        IconItem(name: "Clock", symbol: "clock.fill", category: "Work", keywords: ["time", "timer"]),
        IconItem(name: "Alarm", symbol: "alarm.fill", category: "Work", keywords: ["wake", "reminder"]),
        IconItem(name: "Checklist", symbol: "checklist", category: "Work", keywords: ["tasks", "todo"]),
        IconItem(name: "Paperclip", symbol: "paperclip", category: "Work", keywords: ["attach", "clip"]),
        IconItem(name: "Pencil", symbol: "pencil", category: "Work", keywords: ["write", "edit"]),
        IconItem(name: "Highlighter", symbol: "highlighter", category: "Work", keywords: ["mark", "important"]),
        IconItem(name: "Scissors", symbol: "scissors", category: "Work", keywords: ["cut", "craft"]),
        IconItem(name: "Paperplane", symbol: "paperplane.fill", category: "Work", keywords: ["send", "mail"]),
        IconItem(name: "Tray", symbol: "tray.fill", category: "Work", keywords: ["inbox", "organize"]),
        
        // Education & Learning
        IconItem(name: "Book", symbol: "book.fill", category: "Education", keywords: ["read", "study", "learn"]),
        IconItem(name: "Books", symbol: "books.vertical.fill", category: "Education", keywords: ["library", "reading"]),
        IconItem(name: "Backpack", symbol: "backpack.fill", category: "Education", keywords: ["school", "student"]),
        IconItem(name: "Graduationcap", symbol: "graduationcap.fill", category: "Education", keywords: ["graduate", "education"]),
        IconItem(name: "Pencil Ruler", symbol: "pencil.and.ruler.fill", category: "Education", keywords: ["design", "draft"]),
        IconItem(name: "Character Book", symbol: "character.book.closed.fill", category: "Education", keywords: ["language", "learning"]),
        
        // Shopping & Finance
        IconItem(name: "Cart", symbol: "cart.fill", category: "Shopping", keywords: ["shopping", "buy", "store"]),
        IconItem(name: "Bag", symbol: "bag.fill", category: "Shopping", keywords: ["shopping", "purchase"]),
        IconItem(name: "Basket", symbol: "basket.fill", category: "Shopping", keywords: ["groceries", "shopping"]),
        IconItem(name: "Gift", symbol: "gift.fill", category: "Shopping", keywords: ["present", "birthday"]),
        IconItem(name: "Dollar", symbol: "dollarsign.circle.fill", category: "Shopping", keywords: ["money", "finance", "payment"]),
        IconItem(name: "Credit Card", symbol: "creditcard.fill", category: "Shopping", keywords: ["payment", "card"]),
        IconItem(name: "Banknote", symbol: "banknote.fill", category: "Shopping", keywords: ["money", "cash"]),
        IconItem(name: "Chart", symbol: "chart.line.uptrend.xyaxis", category: "Shopping", keywords: ["finance", "growth", "stocks"]),
        
        // Health & Fitness
        IconItem(name: "Heart Health", symbol: "heart.text.square.fill", category: "Health", keywords: ["health", "medical", "care"]),
        IconItem(name: "Cross", symbol: "cross.case.fill", category: "Health", keywords: ["medical", "first aid", "health"]),
        IconItem(name: "Pills", symbol: "pills.fill", category: "Health", keywords: ["medicine", "medication", "health"]),
        IconItem(name: "Syringe", symbol: "syringe.fill", category: "Health", keywords: ["medical", "vaccine", "shot"]),
        IconItem(name: "Stethoscope", symbol: "stethoscope", category: "Health", keywords: ["doctor", "medical"]),
        IconItem(name: "Lungs", symbol: "lungs.fill", category: "Health", keywords: ["breathing", "health"]),
        IconItem(name: "Figure Run", symbol: "figure.run", category: "Health", keywords: ["fitness", "exercise", "running"]),
        IconItem(name: "Figure Walk", symbol: "figure.walk", category: "Health", keywords: ["walking", "exercise"]),
        IconItem(name: "Dumbbell", symbol: "dumbbell.fill", category: "Health", keywords: ["gym", "workout", "fitness"]),
        IconItem(name: "Bicycle", symbol: "bicycle", category: "Health", keywords: ["cycling", "exercise", "bike"]),
        IconItem(name: "Tennis", symbol: "tennis.racket", category: "Health", keywords: ["sport", "game"]),
        IconItem(name: "Football", symbol: "football.fill", category: "Health", keywords: ["sport", "game"]),
        IconItem(name: "Basketball", symbol: "basketball.fill", category: "Health", keywords: ["sport", "game"]),
        
        // Food & Drink
        IconItem(name: "Fork Knife", symbol: "fork.knife", category: "Food", keywords: ["eat", "dining", "restaurant"]),
        IconItem(name: "Cup", symbol: "cup.and.saucer.fill", category: "Food", keywords: ["coffee", "tea", "drink"]),
        IconItem(name: "Mug", symbol: "mug.fill", category: "Food", keywords: ["coffee", "drink"]),
        IconItem(name: "Wine Glass", symbol: "wineglass.fill", category: "Food", keywords: ["drink", "wine", "alcohol"]),
        IconItem(name: "Birthday Cake", symbol: "birthday.cake.fill", category: "Food", keywords: ["cake", "birthday", "celebration"]),
        IconItem(name: "Carrot", symbol: "carrot.fill", category: "Food", keywords: ["vegetable", "food", "healthy"]),
        IconItem(name: "Pizza", symbol: "pizza.fill", category: "Food", keywords: ["food", "dinner"]),
        IconItem(name: "Takeout Bag", symbol: "takeoutbag.and.cup.and.straw.fill", category: "Food", keywords: ["food", "restaurant", "delivery"]),
        
        // Travel & Transportation
        IconItem(name: "Airplane", symbol: "airplane", category: "Travel", keywords: ["travel", "flight", "trip"]),
        IconItem(name: "Car", symbol: "car.fill", category: "Travel", keywords: ["drive", "vehicle", "auto"]),
        IconItem(name: "Bus", symbol: "bus.fill", category: "Travel", keywords: ["transit", "transport"]),
        IconItem(name: "Train", symbol: "train.side.front.car", category: "Travel", keywords: ["transit", "rail"]),
        IconItem(name: "Tram", symbol: "tram.fill", category: "Travel", keywords: ["transit", "streetcar"]),
        IconItem(name: "Bicycle", symbol: "bicycle", category: "Travel", keywords: ["bike", "cycling"]),
        IconItem(name: "Scooter", symbol: "scooter", category: "Travel", keywords: ["ride", "transport"]),
        IconItem(name: "Sailboat", symbol: "sailboat.fill", category: "Travel", keywords: ["boat", "sailing", "water"]),
        IconItem(name: "Ferry", symbol: "ferry.fill", category: "Travel", keywords: ["boat", "transport"]),
        IconItem(name: "Suitcase", symbol: "suitcase.fill", category: "Travel", keywords: ["luggage", "travel", "trip"]),
        IconItem(name: "Map", symbol: "map.fill", category: "Travel", keywords: ["navigation", "travel", "location"]),
        IconItem(name: "Signpost", symbol: "signpost.right.fill", category: "Travel", keywords: ["direction", "navigation"]),
        IconItem(name: "Location", symbol: "location.fill", category: "Travel", keywords: ["place", "map", "pin"]),
        IconItem(name: "Globe", symbol: "globe", category: "Travel", keywords: ["world", "international", "travel"]),
        
        // Communication
        IconItem(name: "Phone", symbol: "phone.fill", category: "Communication", keywords: ["call", "telephone"]),
        IconItem(name: "Video", symbol: "video.fill", category: "Communication", keywords: ["call", "video chat"]),
        IconItem(name: "Message", symbol: "message.fill", category: "Communication", keywords: ["text", "chat", "sms"]),
        IconItem(name: "Envelope", symbol: "envelope.fill", category: "Communication", keywords: ["mail", "email", "letter"]),
        IconItem(name: "At Symbol", symbol: "at", category: "Communication", keywords: ["email", "mention"]),
        IconItem(name: "Bell", symbol: "bell.fill", category: "Communication", keywords: ["notification", "alert", "reminder"]),
        IconItem(name: "Megaphone", symbol: "megaphone.fill", category: "Communication", keywords: ["announcement", "broadcast"]),
        IconItem(name: "Speaker", symbol: "speaker.wave.3.fill", category: "Communication", keywords: ["sound", "audio", "volume"]),
        
        // Entertainment & Media
        IconItem(name: "Music Note", symbol: "music.note", category: "Entertainment", keywords: ["music", "song", "audio"]),
        IconItem(name: "Headphones", symbol: "headphones", category: "Entertainment", keywords: ["music", "audio", "listen"]),
        IconItem(name: "Guitar", symbol: "guitars.fill", category: "Entertainment", keywords: ["music", "instrument"]),
        IconItem(name: "Mic", symbol: "mic.fill", category: "Entertainment", keywords: ["microphone", "audio", "recording"]),
        IconItem(name: "Camera", symbol: "camera.fill", category: "Entertainment", keywords: ["photo", "picture"]),
        IconItem(name: "Video Camera", symbol: "video.fill", category: "Entertainment", keywords: ["recording", "film"]),
        IconItem(name: "Film", symbol: "film.fill", category: "Entertainment", keywords: ["movie", "video"]),
        IconItem(name: "TV", symbol: "tv.fill", category: "Entertainment", keywords: ["television", "screen"]),
        IconItem(name: "Gamecontroller", symbol: "gamecontroller.fill", category: "Entertainment", keywords: ["gaming", "play", "game"]),
        IconItem(name: "Dice", symbol: "die.face.5.fill", category: "Entertainment", keywords: ["game", "random"]),
        IconItem(name: "Paintbrush", symbol: "paintbrush.fill", category: "Entertainment", keywords: ["art", "paint", "creative"]),
        IconItem(name: "Paintpalette", symbol: "paintpalette.fill", category: "Entertainment", keywords: ["art", "color", "creative"]),
        IconItem(name: "Photo", symbol: "photo.fill", category: "Entertainment", keywords: ["picture", "image"]),
        
        // Nature & Weather
        IconItem(name: "Leaf", symbol: "leaf.fill", category: "Nature", keywords: ["nature", "plant", "green"]),
        IconItem(name: "Tree", symbol: "tree.fill", category: "Nature", keywords: ["nature", "forest"]),
        IconItem(name: "Sun", symbol: "sun.max.fill", category: "Nature", keywords: ["weather", "sunny", "bright"]),
        IconItem(name: "Moon", symbol: "moon.fill", category: "Nature", keywords: ["night", "sleep"]),
        IconItem(name: "Cloud", symbol: "cloud.fill", category: "Nature", keywords: ["weather", "cloudy"]),
        IconItem(name: "Cloud Rain", symbol: "cloud.rain.fill", category: "Nature", keywords: ["weather", "rain"]),
        IconItem(name: "Snow", symbol: "snowflake", category: "Nature", keywords: ["weather", "winter", "cold"]),
        IconItem(name: "Wind", symbol: "wind", category: "Nature", keywords: ["weather", "breeze"]),
        IconItem(name: "Bolt", symbol: "bolt.fill", category: "Nature", keywords: ["lightning", "storm", "electricity"]),
        IconItem(name: "Drop", symbol: "drop.fill", category: "Nature", keywords: ["water", "liquid"]),
        IconItem(name: "Flame", symbol: "flame.fill", category: "Nature", keywords: ["fire", "hot"]),
        IconItem(name: "Pawprint", symbol: "pawprint.fill", category: "Nature", keywords: ["pet", "animal", "dog", "cat"]),
        IconItem(name: "Hare", symbol: "hare.fill", category: "Nature", keywords: ["rabbit", "animal", "pet"]),
        IconItem(name: "Tortoise", symbol: "tortoise.fill", category: "Nature", keywords: ["turtle", "animal", "pet"]),
        IconItem(name: "Bird", symbol: "bird.fill", category: "Nature", keywords: ["animal", "fly"]),
        IconItem(name: "Ladybug", symbol: "ladybug.fill", category: "Nature", keywords: ["bug", "insect"]),
        
        // Technology
        IconItem(name: "Computer", symbol: "desktopcomputer", category: "Technology", keywords: ["desktop", "pc", "work"]),
        IconItem(name: "Laptop", symbol: "laptopcomputer", category: "Technology", keywords: ["computer", "mac", "work"]),
        IconItem(name: "iPhone", symbol: "iphone", category: "Technology", keywords: ["phone", "mobile"]),
        IconItem(name: "iPad", symbol: "ipad", category: "Technology", keywords: ["tablet"]),
        IconItem(name: "Apple Watch", symbol: "applewatch", category: "Technology", keywords: ["watch", "wearable"]),
        IconItem(name: "Keyboard", symbol: "keyboard.fill", category: "Technology", keywords: ["type", "input"]),
        IconItem(name: "Mouse", symbol: "computermouse.fill", category: "Technology", keywords: ["click", "pointer"]),
        IconItem(name: "Printer", symbol: "printer.fill", category: "Technology", keywords: ["print", "paper"]),
        IconItem(name: "Display", symbol: "display", category: "Technology", keywords: ["monitor", "screen"]),
        IconItem(name: "Server", symbol: "server.rack", category: "Technology", keywords: ["data", "storage"]),
        IconItem(name: "Wifi", symbol: "wifi", category: "Technology", keywords: ["wireless", "internet", "network"]),
        IconItem(name: "Antenna", symbol: "antenna.radiowaves.left.and.right", category: "Technology", keywords: ["signal", "broadcast"]),
        IconItem(name: "Network", symbol: "network", category: "Technology", keywords: ["connection", "internet"]),
        
        // Symbols & Shapes
        IconItem(name: "Circle", symbol: "circle.fill", category: "Symbols", keywords: ["shape", "round"]),
        IconItem(name: "Square", symbol: "square.fill", category: "Symbols", keywords: ["shape", "box"]),
        IconItem(name: "Triangle", symbol: "triangle.fill", category: "Symbols", keywords: ["shape"]),
        IconItem(name: "Diamond", symbol: "diamond.fill", category: "Symbols", keywords: ["shape", "gem"]),
        IconItem(name: "Hexagon", symbol: "hexagon.fill", category: "Symbols", keywords: ["shape"]),
        IconItem(name: "Shield", symbol: "shield.fill", category: "Symbols", keywords: ["protect", "security"]),
        IconItem(name: "Crown", symbol: "crown.fill", category: "Symbols", keywords: ["premium", "king", "queen"]),
        IconItem(name: "Sparkles", symbol: "sparkles", category: "Symbols", keywords: ["magic", "special", "new"]),
        IconItem(name: "Light Bulb", symbol: "lightbulb.fill", category: "Symbols", keywords: ["idea", "think"]),
        IconItem(name: "Gear", symbol: "gearshape.fill", category: "Symbols", keywords: ["settings", "config"]),
        IconItem(name: "Wrench", symbol: "wrench.fill", category: "Symbols", keywords: ["tool", "fix", "repair"]),
        IconItem(name: "Hammer", symbol: "hammer.fill", category: "Symbols", keywords: ["tool", "build"]),
        IconItem(name: "Theatermasks", symbol: "theatermasks.fill", category: "Symbols", keywords: ["drama", "acting", "theater"]),
        IconItem(name: "Party Popper", symbol: "party.popper.fill", category: "Symbols", keywords: ["celebration", "party", "fun"]),
        IconItem(name: "Balloon", symbol: "balloon.fill", category: "Symbols", keywords: ["party", "celebration"]),
        IconItem(name: "Rosette", symbol: "rosette", category: "Symbols", keywords: ["award", "badge"]),
        IconItem(name: "Trophy", symbol: "trophy.fill", category: "Symbols", keywords: ["award", "win", "achievement"]),
        IconItem(name: "Medal", symbol: "medal.fill", category: "Symbols", keywords: ["award", "achievement"]),
        IconItem(name: "Infinity", symbol: "infinity", category: "Symbols", keywords: ["unlimited", "forever"]),
    ]
    
    static let categories = Array(Set(all.map { $0.category })).sorted()
    
    static func search(_ query: String) -> [IconItem] {
        let trimmed = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { return all }
        
        return all.filter { icon in
            icon.name.lowercased().contains(trimmed) ||
            icon.keywords.contains { $0.contains(trimmed) } ||
            icon.category.lowercased().contains(trimmed)
        }
    }
}

// Keep old CommonIcons for backwards compatibility (for tags)
struct CommonIcons {
    static let all: [(name: String, symbol: String)] = IconLibrary.all.map { ($0.name, $0.symbol) }
    
    static func symbolName(for index: Int) -> String {
        guard index >= 0 && index < all.count else { return "circle" }
        return all[index].symbol
    }
}

// MARK: - Icon Picker Sheet

/// Icon picker sheet with search and category filtering
struct IconPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    @Binding var selectedIcon: String
    
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    
    let columns = [
        GridItem(.adaptive(minimum: 60), spacing: 16)
    ]
    
    private var filteredIcons: [IconLibrary.IconItem] {
        var icons = IconLibrary.all
        
        // Filter by search
        if !searchText.isEmpty {
            icons = IconLibrary.search(searchText)
        }
        
        // Filter by category
        if let category = selectedCategory {
            icons = icons.filter { $0.category == category }
        }
        
        return icons
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search icons", text: $searchText)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
                
                // Category filter
                if searchText.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryChip(
                                title: "All",
                                isSelected: selectedCategory == nil
                            ) {
                                selectedCategory = nil
                            }
                            
                            ForEach(IconLibrary.categories, id: \.self) { category in
                                CategoryChip(
                                    title: category,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                }
                
                Divider()
                
                // Icon grid
                if filteredIcons.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No icons found")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Try a different search term")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(filteredIcons) { icon in
                                Button {
                                    selectedIcon = icon.symbol
                                    dismiss()
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: icon.symbol)
                                            .font(.system(size: 28))
                                            .frame(width: 50, height: 50)
                                            .background(
                                                selectedIcon == icon.symbol
                                                    ? Color.accentColor.opacity(0.2)
                                                    : Color(white: 0.95)
                                            )
                                            .cornerRadius(10)
                                        Text(icon.name)
                                            .font(.caption2)
                                            .lineLimit(1)
                                    }
                                    .foregroundColor(selectedIcon == icon.symbol ? .accentColor : .primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Category Chip

private struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected ? Color.accentColor : Color(.systemGray5),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Category Picker Sheet

/// Sheet for selecting a single category for a checklist.
struct CategoryPickerSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlementManager: EntitlementManager

    @Query(sort: \ChecklistCategory.name) private var categories: [ChecklistCategory]

    @Binding var selectedCategory: ChecklistCategory?

    @State private var newCategoryName = ""
    @State private var categoryToDelete: ChecklistCategory?
    @State private var showDeleteConfirmation = false
    @State private var paywallReason: PaywallReason?
    @FocusState private var newCategoryFocused: Bool

    var body: some View {
        NavigationStack {
            List {
                // Existing categories
                Section {
                    // None option
                    Button {
                        selectedCategory = nil
                    } label: {
                        HStack {
                            Text("None")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundColor(selectedCategory == nil ? .accentColor : Color(white: 0.85))
                                .fontWeight(selectedCategory == nil ? .semibold : .regular)
                        }
                    }
                    .buttonStyle(.plain)

                    ForEach(categories) { category in
                        CategoryRow(
                            category: category,
                            isSelected: selectedCategory?.persistentModelID == category.persistentModelID,
                            onSelect: {
                                selectedCategory = category
                            }
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                categoryToDelete = category
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }

                // Add new category
                Section("New Category") {
                    HStack(spacing: 8) {
                        TextField("Category name", text: $newCategoryName)
                            .focused($newCategoryFocused)
                            .submitLabel(.done)
                            .onSubmit { addCategory() }
                        
                        if !newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty {
                            Button("Add") { addCategory() }
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
            .navigationTitle("Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .confirmationDialog(
                "Delete \"\(categoryToDelete?.name ?? "")\"?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Category", role: .destructive) {
                    if let cat = categoryToDelete { performDelete(cat) }
                }
                Button("Cancel", role: .cancel) { categoryToDelete = nil }
            } message: {
                Text("Checklists in this category will become uncategorised.")
            }
            .sheet(item: $paywallReason) { reason in
                PaywallView(reason: reason)
            }
        }
    }

    // MARK: - Actions

    private func addCategory() {
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        guard entitlementManager.limits.canAdd(categories: categories.count) else {
            paywallReason = .categoryLimit(entitlementManager.limits.maxCategories ?? 3)
            return
        }

        guard !categories.contains(where: { $0.name.lowercased() == trimmed.lowercased() }) else {
            newCategoryName = ""
            return
        }

        let category = ChecklistCategory(name: trimmed)
        context.insert(category)
        try? context.save()
        newCategoryName = ""
    }

    private func performDelete(_ category: ChecklistCategory) {
        context.delete(category)
        try? context.save()
        categoryToDelete = nil
    }
}

// MARK: - Category Row

private struct CategoryRow: View {
    @Bindable var category: ChecklistCategory
    let isSelected: Bool
    let onSelect: () -> Void

    @Environment(\.modelContext) private var context

    var body: some View {
        HStack(spacing: 0) {
            // Editable text field - takes remaining space but leaves room for checkmark
            TextField("Category name", text: $category.name)
                .submitLabel(.done)
                .onChange(of: category.name) {
                    try? context.save()
                }
                .frame(maxWidth: .infinity, alignment: .leading)

            // Selection area - tappable region for selecting/deselecting
            Button {
                print("Selection button tapped") // Debug log
                onSelect()
            } label: {
                HStack(spacing: 0) {
                    Image(systemName: "checkmark")
                        .foregroundColor(isSelected ? .accentColor : Color(white: 0.85))
                        .fontWeight(isSelected ? .semibold : .regular)
                        .frame(width: 24, height: 44)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.leading, 12)
        }
    }
}

import SwiftUI
import SwiftData

// MARK: - Pantry suggestion data

private struct Suggestion: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let category: String
}

private let suggestions: [Suggestion] = [
    // Proteins
    .init(name: "Chicken",      category: "Proteins"),
    .init(name: "Ground beef",  category: "Proteins"),
    .init(name: "Salmon",       category: "Proteins"),
    .init(name: "Shrimp",       category: "Proteins"),
    .init(name: "Eggs",         category: "Proteins"),
    .init(name: "Tofu",         category: "Proteins"),
    .init(name: "Tuna",         category: "Proteins"),
    // Produce
    .init(name: "Garlic",       category: "Produce"),
    .init(name: "Onion",        category: "Produce"),
    .init(name: "Tomato",       category: "Produce"),
    .init(name: "Spinach",      category: "Produce"),
    .init(name: "Bell pepper",  category: "Produce"),
    .init(name: "Broccoli",     category: "Produce"),
    .init(name: "Carrot",       category: "Produce"),
    .init(name: "Potato",       category: "Produce"),
    .init(name: "Lemon",        category: "Produce"),
    .init(name: "Avocado",      category: "Produce"),
    .init(name: "Zucchini",     category: "Produce"),
    // Dairy
    .init(name: "Milk",         category: "Dairy"),
    .init(name: "Butter",       category: "Dairy"),
    .init(name: "Cheddar cheese", category: "Dairy"),
    .init(name: "Parmesan",     category: "Dairy"),
    .init(name: "Heavy cream",  category: "Dairy"),
    .init(name: "Greek yogurt", category: "Dairy"),
    // Grains
    .init(name: "Rice",         category: "Grains"),
    .init(name: "Pasta",        category: "Grains"),
    .init(name: "Bread",        category: "Grains"),
    .init(name: "Flour",        category: "Grains"),
    .init(name: "Oats",         category: "Grains"),
    .init(name: "Tortillas",    category: "Grains"),
    // Pantry
    .init(name: "Olive oil",    category: "Pantry"),
    .init(name: "Soy sauce",    category: "Pantry"),
    .init(name: "Salt",         category: "Pantry"),
    .init(name: "Black pepper", category: "Pantry"),
    .init(name: "Cumin",        category: "Pantry"),
    .init(name: "Paprika",      category: "Pantry"),
    .init(name: "Garlic powder", category: "Pantry"),
    .init(name: "Honey",        category: "Pantry"),
    .init(name: "Sugar",        category: "Pantry"),
    .init(name: "Vinegar",      category: "Pantry"),
    .init(name: "Chicken broth", category: "Pantry"),
    .init(name: "Tomato paste", category: "Pantry"),
    .init(name: "Canned tomatoes", category: "Pantry"),
    .init(name: "Coconut milk", category: "Pantry"),
]

private let categories = ["Proteins", "Produce", "Dairy", "Grains", "Pantry"]

// MARK: - PantrySelectionStep

struct PantrySelectionStep: View {
    @Environment(FlowCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var searchText = ""
    @State private var customName = ""

    private var firstName: String {
        profiles.first?.name.components(separatedBy: " ").first ?? "there"
    }

    private var groups: [(String, [Suggestion])] {
        let filtered = searchText.isEmpty ? suggestions : suggestions.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
        if !searchText.isEmpty { return [("Results", filtered)] }
        return categories.compactMap { cat in
            let items = filtered.filter { $0.category == cat }
            return items.isEmpty ? nil : (cat, items)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Greeting
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hello \(firstName)! 👋")
                            .font(.largeTitle.bold())
                        Text("Let's plan your meals for this week. What do you have in your fridge?")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Custom item add row
                    HStack {
                        TextField("Add a custom ingredient...", text: $customName)
                            .padding(10)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                            .submitLabel(.done)
                            .onSubmit(addCustom)
                        Button(action: addCustom) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(customName.isEmpty ? .gray : .orange)
                        }
                        .disabled(customName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal)

                    // Category groups
                    ForEach(groups, id: \.0) { category, items in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(category)
                                .font(.headline)
                                .padding(.horizontal)
                            ChipFlow(items: items) { item in
                                IngredientChip(
                                    name: item.name,
                                    isSelected: coordinator.selectedPantryNames.contains(item.name)
                                ) { toggle(item.name) }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 100)
            }
            .searchable(text: $searchText, prompt: "Search ingredients")
            .navigationTitle("What's in your fridge?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: confirm) {
                        Text(coordinator.selectedPantryNames.isEmpty
                             ? "Skip"
                             : "Next (\(coordinator.selectedPantryNames.count))")
                        .bold()
                        .foregroundStyle(.orange)
                    }
                }
            }
        }
    }

    private func toggle(_ name: String) {
        if coordinator.selectedPantryNames.contains(name) {
            coordinator.selectedPantryNames.remove(name)
        } else {
            coordinator.selectedPantryNames.insert(name)
        }
    }

    private func addCustom() {
        let t = customName.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        coordinator.selectedPantryNames.insert(t)
        customName = ""
    }

    private func confirm() {
        // Replace pantry items with current selection
        let existing = (try? modelContext.fetch(FetchDescriptor<PantryItem>())) ?? []
        existing.forEach { modelContext.delete($0) }
        coordinator.selectedPantryNames.forEach { modelContext.insert(PantryItem(name: $0)) }
        try? modelContext.save()
        coordinator.step = .mealCount
    }
}

// MARK: - Shared chip components (used by PantryView too)

struct IngredientChip: View {
    let name: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                if isSelected { Image(systemName: "checkmark").font(.caption.bold()) }
                Text(name).font(HungiTheme.caption)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? HungiTheme.forest : HungiTheme.tan)
            .foregroundStyle(isSelected ? HungiTheme.cream : HungiTheme.darkBrown)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(HungiTheme.darkBrown, lineWidth: isSelected ? 2 : 1))
            .shadow(color: HungiTheme.darkBrown, radius: 0, x: isSelected ? 1 : 0, y: isSelected ? 1 : 0)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.12), value: isSelected)
    }
}

/// Wrapping flow layout for chip rows.
struct ChipFlow<Item: Identifiable, Content: View>: View {
    let items: [Item]
    @ViewBuilder let content: (Item) -> Content
    @State private var height: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            self.layout(in: geo)
        }
        .frame(height: height)
    }

    private func layout(in geo: GeometryProxy) -> some View {
        var x: CGFloat = 0; var y: CGFloat = 0
        let gap: CGFloat = 8; let rowH: CGFloat = 36
        return ZStack(alignment: .topLeading) {
            ForEach(items) { item in
                content(item).fixedSize()
                    .alignmentGuide(.leading) { d in
                        if x + d.width > geo.size.width { x = 0; y += rowH + gap }
                        let r = -x
                        if item.id == items.last?.id { x = 0 } else { x += d.width + gap }
                        return r
                    }
                    .alignmentGuide(.top) { _ in
                        let r = -y
                        if item.id == items.last?.id { y = 0 }
                        return r
                    }
            }
        }
        .background(GeometryReader { g in
            Color.clear.onAppear { height = g.size.height }
                .onChange(of: g.size.height) { _, h in height = h }
        })
    }
}

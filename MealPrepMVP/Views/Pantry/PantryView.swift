import SwiftUI
import SwiftData

struct PantryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PantryItem.createdAt) private var pantryItems: [PantryItem]

    @State private var newItemName = ""
    @State private var newItemQuantity = ""
    @State private var newItemUnit = ""
    @State private var searchText = ""

    private var filteredItems: [PantryItem] {
        guard !searchText.isEmpty else { return pantryItems }
        return pantryItems.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                // Add item row
                Section {
                    HStack(spacing: 8) {
                        TextField("Ingredient...", text: $newItemName)
                            .submitLabel(.done)
                            .onSubmit(addItem)
                            .font(HungiTheme.body)

                        TextField("Qty", text: $newItemQuantity)
                            .frame(width: 40)
                            .multilineTextAlignment(.center)
                            .keyboardType(.decimalPad)
                            .font(HungiTheme.caption)

                        Picker("", selection: $newItemUnit) {
                            ForEach(ItemUnit.options, id: \.self) { unit in
                                Text(unit.isEmpty ? "unit" : unit).tag(unit)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 72)

                        Button(action: addItem) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(newItemName.trimmingCharacters(in: .whitespaces).isEmpty ? HungiTheme.tan : HungiTheme.harvest)
                        }
                        .disabled(newItemName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                if filteredItems.isEmpty && !pantryItems.isEmpty {
                    Text("No results for \"\(searchText)\"")
                        .font(HungiTheme.body)
                        .foregroundStyle(HungiTheme.woodBrown)
                } else if pantryItems.isEmpty {
                    ContentUnavailableView(
                        "Pantry is empty",
                        systemImage: "tray",
                        description: Text("Add ingredients you have at home.")
                    )
                } else {
                    Section("In your pantry (\(filteredItems.count))") {
                        ForEach(filteredItems) { item in
                            PantryRow(item: item)
                        }
                        .onDelete(perform: deleteItems)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(HungiTheme.parchment)
            .navigationTitle("My Pantry")
            .searchable(text: $searchText, prompt: "Search pantry")
            .toolbar {
                if !filteredItems.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton().foregroundStyle(HungiTheme.woodBrown)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear all") {
                        pantryItems.forEach { modelContext.delete($0) }
                    }
                    .foregroundStyle(HungiTheme.terracotta)
                    .disabled(pantryItems.isEmpty)
                }
            }
        }
    }

    private func addItem() {
        let trimmed = newItemName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        modelContext.insert(PantryItem(
            name: trimmed,
            quantity: newItemQuantity.trimmingCharacters(in: .whitespaces),
            unit: newItemUnit
        ))
        newItemName = ""
        newItemQuantity = ""
        newItemUnit = ""
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets { modelContext.delete(filteredItems[index]) }
    }
}

// MARK: - Pantry Row

struct PantryRow: View {
    @Bindable var item: PantryItem

    var body: some View {
        HStack {
            Text(item.name)
                .font(HungiTheme.body)
                .foregroundStyle(HungiTheme.darkBrown)
            Spacer()
            if !item.displayQuantity.isEmpty {
                Text(item.displayQuantity)
                    .font(HungiTheme.caption)
                    .foregroundStyle(HungiTheme.woodBrown)
            }
        }
    }
}

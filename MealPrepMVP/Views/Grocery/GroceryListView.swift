import SwiftUI
import SwiftData

struct GroceryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GroceryItem.createdAt) private var items: [GroceryItem]
    @Query private var pantryItems: [PantryItem]

    @State private var newItemName = ""
    @State private var newItemQuantity = ""
    @State private var newItemUnit = ""

    private var unchecked: [GroceryItem] { items.filter { !$0.isChecked } }
    private var checked: [GroceryItem] { items.filter { $0.isChecked } }

    var body: some View {
        NavigationStack {
            List {
                // Add item row
                Section {
                    HStack(spacing: 8) {
                        TextField("Item name...", text: $newItemName)
                            .submitLabel(.done).onSubmit(addItem)
                        TextField("Qty", text: $newItemQuantity)
                            .frame(width: 40).multilineTextAlignment(.center)
                            .keyboardType(.decimalPad)
                        Picker("", selection: $newItemUnit) {
                            ForEach(ItemUnit.options, id: \.self) { u in
                                Text(u.isEmpty ? "unit" : u).tag(u)
                            }
                        }
                        .labelsHidden().frame(width: 72)
                        Button(action: addItem) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(newItemName.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : .blue)
                        }
                        .disabled(newItemName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                if !unchecked.isEmpty {
                    Section("Need to buy (\(unchecked.count))") {
                        ForEach(unchecked) { item in
                            GroceryRow(
                                item: item,
                                onSendToPantry: { sendToPantry(item) }
                            )
                            .swipeActions(edge: .leading) {
                                Button {
                                    sendToPantry(item)
                                } label: {
                                    Label("Add to Pantry", systemImage: "tray.and.arrow.down.fill")
                                }
                                .tint(.orange)
                            }
                        }
                        .onDelete { deleteFrom(unchecked, at: $0) }
                    }
                }

                if !checked.isEmpty {
                    Section("In cart / have it") {
                        ForEach(checked) { item in
                            GroceryRow(
                                item: item,
                                onSendToPantry: { sendToPantry(item) }
                            )
                            .swipeActions(edge: .leading) {
                                Button {
                                    sendToPantry(item)
                                } label: {
                                    Label("Add to Pantry", systemImage: "tray.and.arrow.down.fill")
                                }
                                .tint(.orange)
                            }
                        }
                        .onDelete { deleteFrom(checked, at: $0) }
                    }
                }

                if items.isEmpty {
                    ContentUnavailableView(
                        "No grocery items",
                        systemImage: "cart",
                        description: Text("Items you need for your weekly plan will appear here.")
                    )
                }
            }
            .navigationTitle("Grocery List")
            .toolbar {
                if !checked.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear checked") { checked.forEach { modelContext.delete($0) } }
                            .foregroundStyle(.red)
                    }
                }
            }
        }
    }

    private func addItem() {
        let trimmed = newItemName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        modelContext.insert(GroceryItem(name: trimmed,
                                        quantity: newItemQuantity.trimmingCharacters(in: .whitespaces),
                                        unit: newItemUnit))
        newItemName = ""; newItemQuantity = ""; newItemUnit = ""
    }

    private func deleteFrom(_ source: [GroceryItem], at offsets: IndexSet) {
        for i in offsets { modelContext.delete(source[i]) }
    }

    /// Move item from grocery list to pantry, then remove from grocery list.
    private func sendToPantry(_ item: GroceryItem) {
        let existingNames = Set(pantryItems.map { $0.name.lowercased() })
        if !existingNames.contains(item.name.lowercased()) {
            modelContext.insert(PantryItem(name: item.name, quantity: item.quantity, unit: item.unit))
        }
        modelContext.delete(item)
    }
}

// MARK: - Grocery Row

struct GroceryRow: View {
    @Bindable var item: GroceryItem
    let onSendToPantry: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation { item.isChecked.toggle() }
            } label: {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isChecked ? .green : .secondary)
            }
            .buttonStyle(.plain)

            Text(item.name)
                .strikethrough(item.isChecked)
                .foregroundStyle(item.isChecked ? .secondary : .primary)

            Spacer()

            if !item.displayQuantity.isEmpty {
                Text(item.displayQuantity).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}

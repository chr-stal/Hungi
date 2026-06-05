import SwiftUI
import SwiftData

struct KitchenView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GroceryItem.createdAt) private var groceryItems: [GroceryItem]
    @Query(sort: \PantryItem.createdAt) private var pantryItems: [PantryItem]

    // Grocery add row state
    @State private var newGroceryName = ""
    @State private var newGroceryQty = ""
    @State private var newGroceryUnit = ""

    // Pantry add row state
    @State private var newPantryName = ""
    @State private var newPantryQty = ""
    @State private var newPantryUnit = ""

    @State private var searchText = ""

    private var unchecked: [GroceryItem] { groceryItems.filter { !$0.isChecked && matches($0.name) } }
    private var checked: [GroceryItem]   { groceryItems.filter {  $0.isChecked && matches($0.name) } }
    private var filteredPantry: [PantryItem] { pantryItems.filter { matches($0.name) } }

    private func matches(_ name: String) -> Bool {
        searchText.isEmpty || name.localizedCaseInsensitiveContains(searchText)
    }

    var body: some View {
        NavigationStack {
            List {
                // ── SHOPPING LIST ──────────────────────────────────────
                Section {
                    // Add grocery row
                    HStack(spacing: 6) {
                        TextField("Add item…", text: $newGroceryName)
                            .foregroundStyle(HungiTheme.darkBrown)
                            .tint(HungiTheme.darkBrown)
                            .submitLabel(.done)
                            .onSubmit(addGroceryItem)
                        TextField("Qty", text: $newGroceryQty)
                            .frame(width: 36).multilineTextAlignment(.center)
                            .keyboardType(.decimalPad)
                            .foregroundStyle(HungiTheme.darkBrown)
                        Picker("", selection: $newGroceryUnit) {
                            ForEach(ItemUnit.options, id: \.self) { u in
                                Text(u.isEmpty ? "unit" : u).tag(u)
                            }
                        }
                        .labelsHidden().frame(width: 68)
                        Button(action: addGroceryItem) {
                            Image(systemName: "plus.circle.fill").font(.title2)
                                .foregroundStyle(newGroceryName.trimmingCharacters(in: .whitespaces).isEmpty
                                                 ? HungiTheme.tan : HungiTheme.harvest)
                        }
                        .disabled(newGroceryName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .listRowBackground(HungiTheme.cream)

                    // Unchecked items
                    ForEach(unchecked) { item in
                        GroceryRow(item: item, onSendToPantry: { moveToPantry(item) })
                            .swipeActions(edge: .leading) {
                                Button { moveToPantry(item) } label: {
                                    Label("Got it! ✓", systemImage: "tray.and.arrow.down.fill")
                                }
                                .tint(HungiTheme.forest)
                            }
                            .listRowBackground(HungiTheme.cream)
                    }
                    .onDelete { deleteGrocery(unchecked, at: $0) }

                    // Checked items (in cart)
                    if !checked.isEmpty {
                        ForEach(checked) { item in
                            GroceryRow(item: item, onSendToPantry: { moveToPantry(item) })
                                .swipeActions(edge: .leading) {
                                    Button { moveToPantry(item) } label: {
                                        Label("Got it! ✓", systemImage: "tray.and.arrow.down.fill")
                                    }
                                    .tint(HungiTheme.forest)
                                }
                                .listRowBackground(HungiTheme.cream.opacity(0.6))
                        }
                        .onDelete { deleteGrocery(checked, at: $0) }
                    }

                    if groceryItems.isEmpty {
                        Text("Nothing on your list — your plan will auto-populate this.")
                            .font(HungiTheme.caption)
                            .foregroundStyle(HungiTheme.woodBrown)
                            .listRowBackground(HungiTheme.cream)
                    }
                } header: {
                    HStack {
                        Label("Shopping List", systemImage: "cart.fill")
                            .foregroundStyle(HungiTheme.harvest)
                        Spacer()
                        if !groceryItems.isEmpty {
                            Button("All → Pantry") { groceryItems.forEach { moveToPantry($0) } }
                                .font(HungiTheme.caption.bold())
                                .foregroundStyle(HungiTheme.forest)
                        }
                    }
                }

                // ── PANTRY ─────────────────────────────────────────────
                Section {
                    // Add pantry row
                    HStack(spacing: 6) {
                        TextField("Add item…", text: $newPantryName)
                            .foregroundStyle(HungiTheme.darkBrown)
                            .tint(HungiTheme.darkBrown)
                            .submitLabel(.done)
                            .onSubmit(addPantryItem)
                        TextField("Qty", text: $newPantryQty)
                            .frame(width: 36).multilineTextAlignment(.center)
                            .keyboardType(.decimalPad)
                            .foregroundStyle(HungiTheme.darkBrown)
                        Picker("", selection: $newPantryUnit) {
                            ForEach(ItemUnit.options, id: \.self) { u in
                                Text(u.isEmpty ? "unit" : u).tag(u)
                            }
                        }
                        .labelsHidden().frame(width: 68)
                        Button(action: addPantryItem) {
                            Image(systemName: "plus.circle.fill").font(.title2)
                                .foregroundStyle(newPantryName.trimmingCharacters(in: .whitespaces).isEmpty
                                                 ? HungiTheme.tan : HungiTheme.harvest)
                        }
                        .disabled(newPantryName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .listRowBackground(HungiTheme.cream)

                    ForEach(filteredPantry) { item in
                        PantryRow(item: item)
                            .swipeActions(edge: .leading) {
                                Button { moveToGrocery(item) } label: {
                                    Label("Need more", systemImage: "cart.badge.plus")
                                }
                                .tint(HungiTheme.harvest)
                            }
                            .listRowBackground(HungiTheme.cream)
                    }
                    .onDelete { deletePantry(at: $0) }

                    if pantryItems.isEmpty {
                        Text("Items you mark as bought will appear here.")
                            .font(HungiTheme.caption)
                            .foregroundStyle(HungiTheme.woodBrown)
                            .listRowBackground(HungiTheme.cream)
                    }
                } header: {
                    HStack {
                        Label("In My Kitchen", systemImage: "refrigerator.fill")
                            .foregroundStyle(HungiTheme.woodBrown)
                        Spacer()
                        if !pantryItems.isEmpty {
                            Button("Clear all") { pantryItems.forEach { modelContext.delete($0) } }
                                .font(HungiTheme.caption.bold())
                                .foregroundStyle(HungiTheme.terracotta)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(HungiTheme.parchment)
            .searchable(text: $searchText, prompt: "Search ingredients")
            .navigationTitle("Kitchen 🥘")
            .toolbar {
                if !checked.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear checked") { checked.forEach { modelContext.delete($0) } }
                            .font(HungiTheme.caption)
                            .foregroundStyle(HungiTheme.terracotta)
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func addGroceryItem() {
        let t = newGroceryName.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        modelContext.insert(GroceryItem(name: t,
                                        quantity: newGroceryQty.trimmingCharacters(in: .whitespaces),
                                        unit: newGroceryUnit))
        newGroceryName = ""; newGroceryQty = ""; newGroceryUnit = ""
    }

    private func addPantryItem() {
        let t = newPantryName.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        modelContext.insert(PantryItem(name: t,
                                       quantity: newPantryQty.trimmingCharacters(in: .whitespaces),
                                       unit: newPantryUnit))
        newPantryName = ""; newPantryQty = ""; newPantryUnit = ""
    }

    private func deleteGrocery(_ source: [GroceryItem], at offsets: IndexSet) {
        offsets.forEach { modelContext.delete(source[$0]) }
    }

    private func deletePantry(at offsets: IndexSet) {
        offsets.forEach { modelContext.delete(filteredPantry[$0]) }
    }

    private func moveToPantry(_ item: GroceryItem) {
        let existingNames = Set(pantryItems.map { $0.name.lowercased() })
        if !existingNames.contains(item.name.lowercased()) {
            modelContext.insert(PantryItem(name: item.name, quantity: item.quantity, unit: item.unit))
        }
        modelContext.delete(item)
    }

    private func moveToGrocery(_ item: PantryItem) {
        let existingNames = Set(groceryItems.map { $0.name.lowercased() })
        if !existingNames.contains(item.name.lowercased()) {
            modelContext.insert(GroceryItem(name: item.name, quantity: item.quantity, unit: item.unit))
        }
        modelContext.delete(item)
    }
}

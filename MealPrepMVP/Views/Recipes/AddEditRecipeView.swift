import SwiftUI
import SwiftData
import PhotosUI

struct AddEditRecipeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var recipe: Recipe?

    // Basic
    @State private var name = ""
    @State private var instructions = ""
    @State private var mealType = MealType.any
    @State private var cuisine = ""
    @State private var cookTime = ""

    // Macros
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""

    // Ingredients
    @State private var ingredients: [(name: String, quantity: String)] = []
    @State private var newIngName = ""
    @State private var newIngQty = ""

    // Image
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?

    private var isEditing: Bool { recipe != nil }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                // Photo
                Section {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        if let imageData, let img = UIImage(data: imageData) {
                            Image(uiImage: img).resizable().scaledToFill()
                                .frame(maxWidth: .infinity).frame(height: 200)
                                .clipped().clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(HungiTheme.darkBrown, lineWidth: 2))
                        } else {
                            HStack {
                                Spacer()
                                VStack(spacing: 8) {
                                    Image(systemName: "camera.fill").font(.title2).foregroundStyle(HungiTheme.harvest)
                                    Text("Add Photo").font(HungiTheme.caption).foregroundStyle(HungiTheme.harvest)
                                }
                                Spacer()
                            }
                            .frame(height: 100)
                        }
                    }
                    .listRowInsets(.init())
                    .listRowBackground(Color.clear)
                    if imageData != nil {
                        Button("Remove photo", role: .destructive) { imageData = nil; selectedPhoto = nil }
                    }
                }
                .onChange(of: selectedPhoto) { _, new in
                    Task { imageData = try? await new?.loadTransferable(type: Data.self) }
                }

                // Name
                Section("Recipe Name") {
                    TextField("e.g. Chicken Stir Fry", text: $name)
                        .font(HungiTheme.body)
                }

                // Type & time
                Section("Details") {
                    Picker("Meal Type", selection: $mealType) {
                        ForEach(MealType.all, id: \.self) { t in
                            Label(MealType.displayName(for: t), systemImage: MealType.icon(for: t)).tag(t)
                        }
                    }
                    .tint(HungiTheme.harvest)
                    Picker("Cuisine", selection: $cuisine) {
                        Text("Any").tag("")
                        ForEach(CuisineType.names, id: \.self) { c in
                            Text("\(CuisineType.emoji(for: c)) \(c)").tag(c)
                        }
                    }
                    .tint(HungiTheme.harvest)
                    HStack {
                        Text("Cook Time").font(HungiTheme.body).foregroundStyle(HungiTheme.darkBrown)
                        Spacer()
                        TextField("0", text: $cookTime).keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing).frame(width: 60)
                        Text("min").font(HungiTheme.caption).foregroundStyle(HungiTheme.woodBrown)
                    }
                }

                // Macros
                Section {
                    macroRow(label: "Calories", binding: $calories, unit: "kcal")
                    macroRow(label: "Protein",  binding: $protein,  unit: "g")
                    macroRow(label: "Carbs",    binding: $carbs,    unit: "g")
                    macroRow(label: "Fat",      binding: $fat,      unit: "g")
                } header: { Text("Macros (optional)") }

                // Ingredients
                Section {
                    ForEach(ingredients.indices, id: \.self) { i in
                        HStack {
                            Text(ingredients[i].name)
                                .font(HungiTheme.body).foregroundStyle(HungiTheme.darkBrown)
                            Spacer()
                            Text(ingredients[i].quantity)
                                .font(HungiTheme.caption).foregroundStyle(HungiTheme.woodBrown)
                        }
                    }
                    .onDelete { ingredients.remove(atOffsets: $0) }

                    HStack {
                        TextField("Ingredient", text: $newIngName).font(HungiTheme.body)
                        Divider()
                        TextField("Qty", text: $newIngQty).frame(width: 60)
                            .font(HungiTheme.caption)
                        Button(action: addIngredient) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(newIngName.trimmingCharacters(in: .whitespaces).isEmpty ? HungiTheme.tan : HungiTheme.harvest)
                        }
                        .disabled(newIngName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } header: { Text("Ingredients") }

                // Instructions
                Section("Instructions (optional)") {
                    TextEditor(text: $instructions).frame(minHeight: 100)
                        .font(HungiTheme.body)
                }
            }
            .scrollContentBackground(.hidden)
            .background(HungiTheme.parchment)
            .navigationTitle(isEditing ? "Edit Recipe" : "New Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(HungiTheme.woodBrown)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                        .foregroundStyle(canSave ? HungiTheme.harvest : HungiTheme.tan)
                }
            }
            .onAppear(perform: loadExisting)
        }
    }

    @ViewBuilder
    private func macroRow(label: String, binding: Binding<String>, unit: String) -> some View {
        HStack {
            Text(label).frame(width: 80, alignment: .leading)
                .font(HungiTheme.body).foregroundStyle(HungiTheme.darkBrown)
            TextField("0", text: binding).keyboardType(.numberPad).multilineTextAlignment(.trailing)
            Text(unit).font(HungiTheme.caption).foregroundStyle(HungiTheme.woodBrown)
        }
    }

    private func loadExisting() {
        guard let r = recipe else { return }
        name = r.name
        instructions = r.instructions
        mealType = r.mealType
        cuisine = r.cuisine
        cookTime = r.cookTime > 0 ? "\(r.cookTime)" : ""
        calories = r.calories > 0 ? "\(r.calories)" : ""
        protein  = r.protein > 0  ? "\(r.protein)"  : ""
        carbs    = r.carbs > 0    ? "\(r.carbs)"    : ""
        fat      = r.fat > 0      ? "\(r.fat)"      : ""
        imageData = r.imageData
        ingredients = r.ingredients.map { ($0.name, $0.quantity) }
    }

    private func addIngredient() {
        let t = newIngName.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        ingredients.append((t, newIngQty.trimmingCharacters(in: .whitespaces)))
        newIngName = ""; newIngQty = ""
    }

    private func save() {
        let target: Recipe
        if let existing = recipe {
            existing.name = name; existing.instructions = instructions
            existing.mealType = mealType
            existing.cuisine = cuisine
            existing.cookTime = Int(cookTime) ?? 0
            existing.calories = Int(calories) ?? 0
            existing.protein  = Int(protein)  ?? 0
            existing.carbs    = Int(carbs)    ?? 0
            existing.fat      = Int(fat)      ?? 0
            existing.imageData = imageData
            existing.ingredients.forEach { modelContext.delete($0) }
            existing.ingredients = []
            target = existing
        } else {
            let r = Recipe(name: name, instructions: instructions,
                           cookTime: Int(cookTime) ?? 0, mealType: mealType, cuisine: cuisine,
                           calories: Int(calories) ?? 0, protein: Int(protein) ?? 0,
                           carbs: Int(carbs) ?? 0, fat: Int(fat) ?? 0)
            r.imageData = imageData
            modelContext.insert(r)
            target = r
        }
        for item in ingredients {
            let ing = RecipeIngredient(name: item.name, quantity: item.quantity)
            modelContext.insert(ing)
            target.ingredients.append(ing)
        }
        dismiss()
    }
}

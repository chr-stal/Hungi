import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    let recipe: Recipe
    @State private var showingEdit = false

    var body: some View {
        List {
            // Recipe image
            if let imageData = recipe.imageData, let uiImage = UIImage(data: imageData) {
                Section {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipped()
                        .listRowInsets(.init())
                }
            }

            // Badges row (meal type + cook time)
            Section {
                HStack(spacing: 10) {
                    PixelBadge(
                        text: MealType.displayName(for: recipe.mealType),
                        background: MealType.color(for: recipe.mealType),
                        foreground: .white
                    )
                    if recipe.cookTime > 0 {
                        PixelBadge(
                            text: "⏱ \(recipe.cookTimeDisplay)",
                            background: HungiTheme.darkBrown,
                            foreground: HungiTheme.wheat
                        )
                    }
                    Spacer()
                }
                .listRowBackground(HungiTheme.cream)
            }

            // Macros row
            if recipe.calories > 0 {
                Section("Nutrition") {
                    HStack(spacing: 0) {
                        MacroCell(icon: "flame.fill", color: HungiTheme.harvest,
                                  value: "\(recipe.calories)", unit: "kcal", label: "Calories")
                        Divider().frame(height: 48).background(HungiTheme.tan)
                        MacroCell(icon: "bolt.fill", color: HungiTheme.forest,
                                  value: "\(recipe.protein)g", unit: "", label: "Protein")
                        Divider().frame(height: 48).background(HungiTheme.tan)
                        MacroCell(icon: "leaf.fill", color: HungiTheme.wheat,
                                  value: "\(recipe.carbs)g", unit: "", label: "Carbs")
                        Divider().frame(height: 48).background(HungiTheme.tan)
                        MacroCell(icon: "drop.fill", color: HungiTheme.terracotta,
                                  value: "\(recipe.fat)g", unit: "", label: "Fat")
                    }
                    .listRowBackground(HungiTheme.cream)
                }
            }

            Section("Ingredients") {
                if recipe.ingredients.isEmpty {
                    Text("No ingredients added")
                        .font(HungiTheme.body)
                        .foregroundStyle(HungiTheme.woodBrown)
                        .listRowBackground(HungiTheme.cream)
                } else {
                    ForEach(recipe.ingredients) { ingredient in
                        HStack {
                            Text(ingredient.name)
                                .font(HungiTheme.body)
                                .foregroundStyle(HungiTheme.darkBrown)
                            Spacer()
                            if !ingredient.quantity.isEmpty {
                                Text(ingredient.quantity)
                                    .font(HungiTheme.caption)
                                    .foregroundStyle(HungiTheme.woodBrown)
                            }
                        }
                        .listRowBackground(HungiTheme.cream)
                    }
                }
            }

            if !recipe.instructions.isEmpty {
                Section("Instructions") {
                    Text(recipe.instructions)
                        .font(HungiTheme.body)
                        .foregroundStyle(HungiTheme.darkBrown)
                        .listRowBackground(HungiTheme.cream)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(HungiTheme.parchment)
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            Button("Edit") { showingEdit = true }
                .foregroundStyle(HungiTheme.harvest)
        }
        .sheet(isPresented: $showingEdit) {
            AddEditRecipeView(recipe: recipe)
        }
    }
}

private struct MacroCell: View {
    let icon: String
    let color: Color
    let value: String
    let unit: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon).font(.caption).foregroundStyle(color)
            Text(value + unit).font(.caption.bold()).foregroundStyle(HungiTheme.darkBrown)
            Text(label).font(.caption2).foregroundStyle(HungiTheme.woodBrown)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
}

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

            Section("Ingredients") {
                if recipe.ingredients.isEmpty {
                    Text("No ingredients added").foregroundStyle(.secondary)
                } else {
                    ForEach(recipe.ingredients) { ingredient in
                        HStack {
                            Text(ingredient.name)
                            Spacer()
                            if !ingredient.quantity.isEmpty {
                                Text(ingredient.quantity).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            if !recipe.instructions.isEmpty {
                Section("Instructions") {
                    Text(recipe.instructions)
                }
            }
        }
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            Button("Edit") { showingEdit = true }
        }
        .sheet(isPresented: $showingEdit) {
            AddEditRecipeView(recipe: recipe)
        }
    }
}

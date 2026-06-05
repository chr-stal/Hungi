import SwiftUI
import SwiftData

struct RecipeListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.createdAt, order: .reverse) private var recipes: [Recipe]
    @State private var showingAddRecipe = false

    var body: some View {
        NavigationStack {
            Group {
                if recipes.isEmpty {
                    ZStack {
                        HungiTheme.parchment.ignoresSafeArea()
                        ContentUnavailableView(
                            "No recipes yet",
                            systemImage: "book",
                            description: Text("Tap + to add your first recipe.")
                        )
                    }
                } else {
                    List {
                        ForEach(recipes) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                RecipeRow(recipe: recipe)
                            }
                        }
                        .onDelete(perform: deleteRecipes)
                    }
                    .scrollContentBackground(.hidden)
                    .background(HungiTheme.parchment)
                }
            }
            .navigationTitle("Recipes")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !recipes.isEmpty {
                        EditButton().foregroundStyle(HungiTheme.woodBrown)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddRecipe = true } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(HungiTheme.harvest)
                    }
                }
            }
            .sheet(isPresented: $showingAddRecipe) {
                AddEditRecipeView()
            }
        }
    }

    private func deleteRecipes(at offsets: IndexSet) {
        for index in offsets { modelContext.delete(recipes[index]) }
    }
}

// MARK: - Recipe Row

struct RecipeRow: View {
    let recipe: Recipe

    var body: some View {
        HStack(spacing: 12) {
            if let imageData = recipe.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(HungiTheme.darkBrown, lineWidth: 1.5))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(HungiTheme.tan)
                    .frame(width: 56, height: 56)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(HungiTheme.darkBrown, lineWidth: 1.5))
                    .overlay {
                        Image(systemName: "fork.knife")
                            .foregroundStyle(HungiTheme.woodBrown)
                    }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(recipe.name)
                    .font(HungiTheme.headline)
                    .foregroundStyle(HungiTheme.darkBrown)
                Text("\(recipe.ingredients.count) ingredient\(recipe.ingredients.count == 1 ? "" : "s")")
                    .font(HungiTheme.caption)
                    .foregroundStyle(HungiTheme.woodBrown)
            }
        }
        .padding(.vertical, 4)
    }
}

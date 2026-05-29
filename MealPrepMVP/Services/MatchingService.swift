import Foundation

struct RecipeMatch: Identifiable {
    let id = UUID()
    let recipe: Recipe
    let matchedIngredients: [RecipeIngredient]
    let missingIngredients: [RecipeIngredient]
    let score: Double

    var matchPercentage: Int { Int(score * 100) }
}

enum MatchingService {
    /// Returns up to `limit` recipes ranked by how many pantry items match their ingredients.
    static func topMatches(
        recipes: [Recipe],
        pantryItems: [PantryItem],   // what the user has at home
        limit: Int = 3
    ) -> [RecipeMatch] {
        let pantryNames = Set(pantryItems.map { normalize($0.name) })

        return recipes
            .compactMap { recipe -> RecipeMatch? in
                guard !recipe.ingredients.isEmpty else { return nil }
                let matched = recipe.ingredients.filter { pantryNames.contains(normalize($0.name)) }
                let missing = recipe.ingredients.filter { !pantryNames.contains(normalize($0.name)) }
                let score = Double(matched.count) / Double(recipe.ingredients.count)
                guard score > 0 else { return nil }
                return RecipeMatch(
                    recipe: recipe,
                    matchedIngredients: matched,
                    missingIngredients: missing,
                    score: score
                )
            }
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map { $0 }
    }

    private static func normalize(_ name: String) -> String {
        name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

import Foundation

enum GroceryDiffService {
    struct MissingItem {
        let name: String
        let quantity: String
    }

    /// Returns ingredients needed by `recipes` that are NOT already in `pantryItems`.
    static func compute(for recipes: [Recipe], having pantryItems: [PantryItem]) -> [MissingItem] {
        let pantryNames = Set(pantryItems.map { normalize($0.name) })
        var seen: Set<String> = []
        var result: [MissingItem] = []

        for recipe in recipes {
            for ingredient in recipe.ingredients {
                let key = normalize(ingredient.name)
                guard !pantryNames.contains(key), !seen.contains(key) else { continue }
                seen.insert(key)
                result.append(MissingItem(name: ingredient.name, quantity: ingredient.quantity))
            }
        }

        return result.sorted { $0.name < $1.name }
    }

    private static func normalize(_ s: String) -> String {
        s.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

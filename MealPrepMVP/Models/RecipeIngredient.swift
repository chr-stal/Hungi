import SwiftData
import Foundation

@Model
final class RecipeIngredient {
    var name: String
    var quantity: String
    var recipe: Recipe?

    init(name: String, quantity: String = "") {
        self.name = name
        self.quantity = quantity
    }
}

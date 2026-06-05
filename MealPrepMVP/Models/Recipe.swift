import SwiftData
import Foundation

@Model
final class Recipe {
    var name: String
    var instructions: String
    var createdAt: Date

    // Metadata
    var cookTime: Int       // minutes; 0 = unset
    var mealType: String    // MealType constants
    var cuisine: String     // CuisineType constants; "" = unset
    var rating: Int         // 1-10 user rating; 0 = unrated
    var calories: Int       // kcal per serving; 0 = unset
    var protein: Int        // grams
    var carbs: Int          // grams
    var fat: Int            // grams

    @Attribute(.externalStorage) var imageData: Data?

    @Relationship(deleteRule: .cascade, inverse: \RecipeIngredient.recipe)
    var ingredients: [RecipeIngredient]

    init(
        name: String,
        instructions: String = "",
        cookTime: Int = 0,
        mealType: String = MealType.any,
        cuisine: String = "",
        rating: Int = 0,
        calories: Int = 0,
        protein: Int = 0,
        carbs: Int = 0,
        fat: Int = 0
    ) {
        self.name = name
        self.instructions = instructions
        self.cookTime = cookTime
        self.mealType = mealType
        self.cuisine = cuisine
        self.rating = rating
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.createdAt = Date()
        self.ingredients = []
    }

    var ratingDisplay: String {
        rating > 0 ? "★ \(rating)/10" : ""
    }

    var cookTimeDisplay: String {
        guard cookTime > 0 else { return "—" }
        return cookTime < 60 ? "\(cookTime) min" : "\(cookTime / 60)h \(cookTime % 60)m"
    }
}

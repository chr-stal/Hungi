import SwiftData
import Foundation

@Model
final class WeeklyPlan {
    var weekStartDate: Date
    var targetBreakfast: Int
    var targetLunch: Int
    var targetDinner: Int

    /// Accepted recipes for this week. Nullify so deleting a recipe doesn't destroy the plan.
    @Relationship(deleteRule: .nullify) var meals: [Recipe]

    init(
        weekStartDate: Date = .now,
        targetBreakfast: Int = 1,
        targetLunch: Int = 2,
        targetDinner: Int = 2
    ) {
        self.weekStartDate = weekStartDate
        self.targetBreakfast = targetBreakfast
        self.targetLunch = targetLunch
        self.targetDinner = targetDinner
        self.meals = []
    }

    var targetTotal: Int { targetBreakfast + targetLunch + targetDinner }
    var isComplete: Bool { meals.count >= targetTotal }

    // Categorized meals
    var breakfastMeals: [Recipe] { meals.filter { $0.mealType == MealType.breakfast } }
    var lunchMeals: [Recipe]     { meals.filter { $0.mealType == MealType.lunch } }
    var dinnerMeals: [Recipe]    { meals.filter { $0.mealType == MealType.dinner } }
    var anyMeals: [Recipe]       { meals.filter { $0.mealType == MealType.any } }

    // Totals
    var totalCalories: Int  { meals.reduce(0) { $0 + $1.calories } }
    var totalProtein: Int   { meals.reduce(0) { $0 + $1.protein } }
    var totalCarbs: Int     { meals.reduce(0) { $0 + $1.carbs } }
    var totalFat: Int       { meals.reduce(0) { $0 + $1.fat } }
    var totalCookTime: Int  { meals.reduce(0) { $0 + $1.cookTime } }
}

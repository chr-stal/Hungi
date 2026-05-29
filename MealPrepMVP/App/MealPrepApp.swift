import SwiftUI
import SwiftData

@main
struct MealPrepApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([
            Recipe.self, RecipeIngredient.self,
            GroceryItem.self, PantryItem.self,
            UserProfile.self, WeeklyPlan.self
        ])
        do {
            container = try ModelContainer(for: schema)
        } catch {
            Self.wipeStore()
            do { container = try ModelContainer(for: schema) }
            catch { fatalError("Failed to create ModelContainer: \(error)") }
        }
        seedRecipesIfNeeded(in: container.mainContext)
    }

    var body: some Scene {
        WindowGroup { ContentView() }
            .modelContainer(container)
    }

    private static func wipeStore() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        ["default.store", "default.store-shm", "default.store-wal"].forEach {
            try? FileManager.default.removeItem(at: dir.appendingPathComponent($0))
        }
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
    }
}

// MARK: - Seed recipes (runs once on first install / after schema wipe)

private func seedRecipesIfNeeded(in context: ModelContext) {
    guard ((try? context.fetchCount(FetchDescriptor<Recipe>())) ?? 0) == 0 else { return }

    // (name, instructions, cookTime, mealType, cal, protein, carbs, fat, ingredients[(name, qty)])
    let data: [(String, String, Int, String, Int, Int, Int, Int, [(String, String)])] = [
        (
            "Chicken Stir Fry",
            "Heat oil in a wok over high heat. Add garlic, cook 30 sec. Add chicken until cooked through. Add bell pepper and broccoli, toss 3-4 min. Drizzle soy sauce and serve.",
            30, MealType.dinner, 380, 35, 20, 18,
            [("Chicken","1 lb"),("Garlic","3 cloves"),("Soy sauce","3 tbsp"),
             ("Bell pepper","1"),("Broccoli","2 cups"),("Olive oil","2 tbsp")]
        ),
        (
            "Scrambled Eggs",
            "Whisk eggs with milk, salt, and pepper. Melt butter in nonstick pan over low heat. Gently stir eggs, pulling from edges. Remove while slightly wet.",
            10, MealType.breakfast, 220, 18, 3, 15,
            [("Eggs","3"),("Milk","2 tbsp"),("Butter","1 tbsp"),
             ("Salt","to taste"),("Black pepper","to taste")]
        ),
        (
            "Pasta Aglio e Olio",
            "Cook pasta in salted water. Sauté garlic in olive oil until golden. Drain pasta, toss with garlic oil, parmesan, and pasta water. Finish with black pepper.",
            25, MealType.dinner, 520, 15, 72, 22,
            [("Pasta","8 oz"),("Garlic","4 cloves"),("Olive oil","1/4 cup"),
             ("Parmesan","1/2 cup"),("Black pepper","to taste")]
        ),
        (
            "Garlic Butter Shrimp",
            "Melt butter with olive oil. Add garlic, cook 1 min. Add shrimp 2-3 min per side until pink. Squeeze lemon over top.",
            20, MealType.dinner, 310, 32, 5, 18,
            [("Shrimp","1 lb"),("Garlic","4 cloves"),("Butter","3 tbsp"),
             ("Lemon","1"),("Olive oil","1 tbsp")]
        ),
        (
            "Chicken Rice Bowl",
            "Cook rice. Season chicken with garlic powder, salt, pepper. Pan-fry in olive oil. Slice and serve over rice with soy sauce.",
            30, MealType.lunch, 450, 38, 45, 12,
            [("Chicken","1 lb"),("Rice","1 cup"),("Garlic powder","1 tsp"),
             ("Soy sauce","2 tbsp"),("Olive oil","1 tbsp")]
        ),
        (
            "Veggie Omelette",
            "Whisk eggs. Sauté spinach and bell pepper in butter until soft. Pour eggs over veg, add cheese when mostly set, fold and serve.",
            15, MealType.breakfast, 280, 20, 8, 18,
            [("Eggs","3"),("Spinach","1 cup"),("Bell pepper","1/2"),
             ("Cheddar cheese","1/4 cup"),("Butter","1 tbsp")]
        ),
        (
            "Honey Garlic Salmon",
            "Mix honey, soy sauce, garlic, and olive oil. Marinate salmon 10 min. Sear 3-4 min per side, basting with marinade.",
            25, MealType.dinner, 420, 40, 18, 20,
            [("Salmon","2 fillets"),("Honey","2 tbsp"),("Soy sauce","2 tbsp"),
             ("Garlic","3 cloves"),("Olive oil","1 tbsp")]
        ),
        (
            "Overnight Oats",
            "Combine oats, milk, and honey in a jar. Stir well. Cover and refrigerate overnight. Top with yogurt before serving.",
            5, MealType.breakfast, 340, 12, 58, 7,
            [("Oats","1/2 cup"),("Milk","1/2 cup"),("Honey","1 tbsp"),
             ("Greek yogurt","1/4 cup")]
        ),
        (
            "Chicken Soup",
            "Sauté onion and garlic in olive oil. Add chicken, carrots, and chicken broth. Simmer 30 min. Season with salt and pepper.",
            45, MealType.lunch, 290, 30, 18, 8,
            [("Chicken","1 lb"),("Onion","1"),("Garlic","3 cloves"),
             ("Carrot","2"),("Chicken broth","4 cups"),("Olive oil","1 tbsp"),
             ("Salt","to taste"),("Black pepper","to taste")]
        ),
    ]

    for (name, inst, time, type, cal, prot, carb, fatG, ings) in data {
        let r = Recipe(name: name, instructions: inst,
                       cookTime: time, mealType: type,
                       calories: cal, protein: prot, carbs: carb, fat: fatG)
        context.insert(r)
        for (ingName, qty) in ings {
            let ing = RecipeIngredient(name: ingName, quantity: qty)
            context.insert(ing)
            r.ingredients.append(ing)
        }
    }
    try? context.save()
}

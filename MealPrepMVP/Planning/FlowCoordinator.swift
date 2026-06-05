import SwiftData
import Observation

@Observable
final class FlowCoordinator {

    enum Step {
        case name           // First-ever launch: name entry
        case ingredients    // "What do you want to use up?" — high-weight text entry
        case mealCount      // Cuisine preferences — medium weight
        case pantry         // Review/edit pantry items from last time
        case swiping        // Tinder-style recipe cards
        case summary        // Weekly summary + B/L/D assignment
        case done           // Planning complete — show main tabs
    }

    // MARK: - State
    var step: Step

    // Step 2: key ingredients (highest match weight)
    var keyIngredients: [String] = []

    // Step 3: cuisine preferences (medium match weight)
    var selectedCuisines: Set<String> = []

    // Step 4: pantry items to factor into base score
    var selectedPantryNames: Set<String> = []

    // Meal count target (default; user can exceed in summary)
    var targetMealCount: Int = 7

    // Swipe step
    var acceptedRecipes: [Recipe] = []
    var declinedIDs: Set<PersistentIdentifier> = []

    // MARK: - Computed
    var acceptedCount: Int { acceptedRecipes.count }

    // MARK: - Init
    init(hasProfile: Bool, currentPantryItems: [PantryItem]) {
        // Skip name step for returning users; everyone goes through ingredients
        step = hasProfile ? .ingredients : .name
        selectedPantryNames = Set(currentPantryItems.map { $0.name })
    }

    // MARK: - Actions
    func accept(_ recipe: Recipe) {
        guard !acceptedRecipes.contains(where: { $0.persistentModelID == recipe.persistentModelID }) else { return }
        acceptedRecipes.append(recipe)
    }

    func removeAccepted(_ recipe: Recipe) {
        acceptedRecipes.removeAll { $0.persistentModelID == recipe.persistentModelID }
    }

    func decline(_ recipe: Recipe) {
        declinedIDs.insert(recipe.persistentModelID)
    }
}

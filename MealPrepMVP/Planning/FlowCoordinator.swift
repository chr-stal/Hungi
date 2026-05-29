import SwiftData
import Observation

@Observable
final class FlowCoordinator {

    enum Step {
        case name           // First-ever launch — enter name
        case pantry         // Select what's in fridge/pantry
        case mealCount      // Set B/L/D targets
        case swiping        // Tinder-style recipe cards
        case summary        // Weekly summary
        case done           // Planning complete — show main tabs
    }

    // MARK: - State
    var step: Step

    // Name step
    var draftName: String = ""

    // Pantry step
    var selectedPantryNames: Set<String> = []

    // Meal count step
    var targetBreakfast: Int = 1
    var targetLunch: Int = 2
    var targetDinner: Int = 2

    // Swipe step
    var acceptedRecipes: [Recipe] = []
    var declinedIDs: Set<PersistentIdentifier> = []

    // MARK: - Computed
    var targetTotal: Int { targetBreakfast + targetLunch + targetDinner }
    var plateCount: Int  { acceptedRecipes.count }
    var plateIsFull: Bool { plateCount >= targetTotal }

    // MARK: - Init
    init(hasProfile: Bool, currentPantryItems: [PantryItem]) {
        step = hasProfile ? .pantry : .name
        selectedPantryNames = Set(currentPantryItems.map { $0.name })
    }

    // MARK: - Actions
    func accept(_ recipe: Recipe) { acceptedRecipes.append(recipe) }
    func undoAccept() { if !acceptedRecipes.isEmpty { acceptedRecipes.removeLast() } }
    func decline(_ recipe: Recipe) { declinedIDs.insert(recipe.persistentModelID) }
}

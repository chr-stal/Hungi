import SwiftUI
import SwiftData

/// Root container for the weekly meal-planning wizard.
/// Shows the correct step based on FlowCoordinator.step.
struct WeeklyPlanningFlow: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var pantryItems: [PantryItem]
    @Query private var profiles: [UserProfile]

    @State private var coordinator: FlowCoordinator?

    var body: some View {
        Group {
            if let coordinator {
                flowView(coordinator)
                    .environment(coordinator)
            } else {
                ProgressView()
                    .onAppear { buildCoordinator() }
            }
        }
    }

    @ViewBuilder
    private func flowView(_ coordinator: FlowCoordinator) -> some View {
        switch coordinator.step {
        case .name:
            NameEntryStep()
        case .ingredients:
            IngredientsEntryStep()
        case .mealCount:
            MealCountStep()
        case .pantry:
            PantrySelectionStep()
        case .swiping:
            RecipeSwipeView()
        case .summary:
            WeeklySummaryView()
        case .done:
            Color.clear
        }
    }

    private func buildCoordinator() {
        coordinator = FlowCoordinator(
            hasProfile: !profiles.isEmpty,
            currentPantryItems: pantryItems
        )
    }
}

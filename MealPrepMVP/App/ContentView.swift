import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \WeeklyPlan.weekStartDate, order: .reverse) private var plans: [WeeklyPlan]
    @Query private var profiles: [UserProfile]

    /// Show the planning flow if there's no profile yet OR no plan yet.
    private var shouldShowFlow: Bool {
        profiles.isEmpty || plans.isEmpty
    }

    var body: some View {
        if shouldShowFlow {
            WeeklyPlanningFlow()
        } else {
            MainTabView()
        }
    }
}

// MARK: - Main tab view

struct MainTabView: View {
    var body: some View {
        TabView {
            WeeklyOverviewView()
                .tabItem { Label("Overview", systemImage: "calendar") }

            PantryView()
                .tabItem { Label("Pantry", systemImage: "refrigerator.fill") }

            GroceryListView()
                .tabItem { Label("Grocery", systemImage: "cart.fill") }

            RecipeListView()
                .tabItem { Label("Recipes", systemImage: "book.fill") }
        }
    }
}

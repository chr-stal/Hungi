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

            #if DEBUG
            DevResetView()
                .tabItem { Label("Dev", systemImage: "wrench.and.screwdriver.fill") }
            #endif
        }
    }
}

// MARK: - Dev Reset (DEBUG only)

#if DEBUG
struct DevResetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var plans: [WeeklyPlan]
    @Query private var pantryItems: [PantryItem]
    @Query private var groceryItems: [GroceryItem]

    @State private var showConfirm = false
    @State private var didReset = false

    var body: some View {
        NavigationStack {
            ZStack {
                HungiTheme.parchment.ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    VStack(spacing: 12) {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(HungiTheme.woodBrown)
                        Text("Dev Tools")
                            .font(HungiTheme.largeTitle)
                            .foregroundStyle(HungiTheme.darkBrown)
                        Text("Only visible in DEBUG builds")
                            .font(HungiTheme.caption)
                            .foregroundStyle(HungiTheme.woodBrown)
                    }

                    // Current state summary
                    VStack(spacing: 0) {
                        DevStatRow(label: "Profiles", value: "\(profiles.count)")
                        Divider().background(HungiTheme.tan)
                        DevStatRow(label: "Weekly Plans", value: "\(plans.count)")
                        Divider().background(HungiTheme.tan)
                        DevStatRow(label: "Pantry Items", value: "\(pantryItems.count)")
                        Divider().background(HungiTheme.tan)
                        DevStatRow(label: "Grocery Items", value: "\(groceryItems.count)")
                    }
                    .background(HungiTheme.cream)
                    .clipShape(RoundedRectangle(cornerRadius: HungiTheme.cardRadius))
                    .pixelBorder()
                    .padding(.horizontal, 28)

                    if didReset {
                        Text("✅ Reset complete — go back to Overview")
                            .font(HungiTheme.caption)
                            .foregroundStyle(HungiTheme.forest)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Button(action: { showConfirm = true }) {
                        Label("Reset to Launch Screen", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PixelButtonStyle(background: HungiTheme.terracotta))
                    .padding(.horizontal, 28)

                    Spacer()
                }
            }
            .navigationTitle("Dev Tools")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("Reset App?", isPresented: $showConfirm) {
            Button("Reset", role: .destructive, action: reset)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will delete your profile, weekly plans, pantry, and grocery list. Recipes are kept. The app will return to the name entry screen.")
        }
    }

    private func reset() {
        profiles.forEach     { modelContext.delete($0) }
        plans.forEach        { modelContext.delete($0) }
        pantryItems.forEach  { modelContext.delete($0) }
        groceryItems.forEach { modelContext.delete($0) }
        try? modelContext.save()
        didReset = true
    }
}

private struct DevStatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(HungiTheme.body)
                .foregroundStyle(HungiTheme.darkBrown)
            Spacer()
            Text(value)
                .font(HungiTheme.headline)
                .foregroundStyle(HungiTheme.woodBrown)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
#endif

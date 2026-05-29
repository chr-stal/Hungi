import SwiftUI
import SwiftData

struct WeeklySummaryView: View {
    @Environment(FlowCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext
    @Query private var pantryItems: [PantryItem]
    @Query(sort: \WeeklyPlan.weekStartDate, order: .reverse) private var plans: [WeeklyPlan]
    @Query private var groceryItems: [GroceryItem]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Week 🎉")
                            .font(.largeTitle.bold())
                        Text("\(coordinator.acceptedRecipes.count) meals planned")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    // Macros totals card
                    let totalCals  = coordinator.acceptedRecipes.reduce(0) { $0 + $1.calories }
                    let totalProt  = coordinator.acceptedRecipes.reduce(0) { $0 + $1.protein }
                    let totalCarbs = coordinator.acceptedRecipes.reduce(0) { $0 + $1.carbs }
                    let totalFat   = coordinator.acceptedRecipes.reduce(0) { $0 + $1.fat }
                    let totalTime  = coordinator.acceptedRecipes.reduce(0) { $0 + $1.cookTime }

                    if totalCals > 0 || totalTime > 0 {
                        VStack(spacing: 12) {
                            Text("Weekly Totals")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            HStack(spacing: 0) {
                                if totalTime > 0 {
                                    SummaryStatCell(value: "\(totalTime)", unit: "min", label: "Prep Time", icon: "clock.fill", color: .blue)
                                    Divider().frame(height: 50)
                                }
                                if totalCals > 0 {
                                    SummaryStatCell(value: "\(totalCals)", unit: "kcal", label: "Calories", icon: "flame.fill", color: .orange)
                                    Divider().frame(height: 50)
                                    SummaryStatCell(value: "\(totalProt)g", unit: "", label: "Protein", icon: "bolt.fill", color: .green)
                                    Divider().frame(height: 50)
                                    SummaryStatCell(value: "\(totalCarbs)g", unit: "", label: "Carbs", icon: "leaf.fill", color: .yellow)
                                    Divider().frame(height: 50)
                                    SummaryStatCell(value: "\(totalFat)g", unit: "", label: "Fat", icon: "drop.fill", color: .red)
                                }
                            }
                        }
                        .padding()
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }

                    // Meals by category
                    ForEach([MealType.breakfast, MealType.lunch, MealType.dinner, MealType.any], id: \.self) { type in
                        let meals = coordinator.acceptedRecipes.filter { $0.mealType == type }
                        if !meals.isEmpty {
                            mealSection(type: type, meals: meals)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Weekly Summary")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button(action: finishAndGoToGrocery) {
                    Label("See Your Grocery List!", systemImage: "cart.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.orange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .background(.regularMaterial)
            }
        }
    }

    @ViewBuilder
    private func mealSection(type: String, meals: [Recipe]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(MealType.displayName(for: type), systemImage: MealType.icon(for: type))
                .font(.headline)
                .foregroundStyle(MealType.color(for: type))
                .padding(.horizontal)

            ForEach(meals) { recipe in
                HStack(spacing: 12) {
                    // Thumbnail
                    if let data = recipe.imageData, let img = UIImage(data: data) {
                        Image(uiImage: img).resizable().scaledToFill()
                            .frame(width: 56, height: 56).clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        RoundedRectangle(cornerRadius: 8).fill(MealType.color(for: recipe.mealType).opacity(0.2))
                            .frame(width: 56, height: 56)
                            .overlay { Image(systemName: "fork.knife").foregroundStyle(MealType.color(for: recipe.mealType)) }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(recipe.name).font(.headline)
                        HStack(spacing: 8) {
                            if recipe.cookTime > 0 {
                                Label(recipe.cookTimeDisplay, systemImage: "clock")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            if recipe.calories > 0 {
                                Label("\(recipe.calories) kcal", systemImage: "flame")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
    }

    private func finishAndGoToGrocery() {
        // 1. Save the weekly plan
        let plan = WeeklyPlan(
            targetBreakfast: coordinator.targetBreakfast,
            targetLunch: coordinator.targetLunch,
            targetDinner: coordinator.targetDinner
        )
        plan.meals = coordinator.acceptedRecipes
        modelContext.insert(plan)

        // 2. Generate grocery list (diff: plan ingredients minus pantry)
        let missing = GroceryDiffService.compute(for: coordinator.acceptedRecipes, having: pantryItems)
        let existingNames = Set(groceryItems.map { $0.name.lowercased() })
        for item in missing {
            guard !existingNames.contains(item.name.lowercased()) else { continue }
            modelContext.insert(GroceryItem(name: item.name, quantity: item.quantity))
        }

        try? modelContext.save()

        // 3. Transition to main tabs
        coordinator.step = .done
    }
}

private struct SummaryStatCell: View {
    let value: String
    let unit: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.caption).foregroundStyle(color)
            Text(value + unit).font(.headline.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

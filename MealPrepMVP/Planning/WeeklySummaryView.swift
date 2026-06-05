import SwiftUI
import SwiftData

struct WeeklySummaryView: View {
    @Environment(FlowCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext
    @Query private var pantryItems: [PantryItem]
    @Query private var groceryItems: [GroceryItem]

    // Local meal-type overrides — keyed by recipe.persistentModelID
    @State private var mealTypeOverrides: [PersistentIdentifier: String] = [:]
    @State private var showAddRecipe = false

    // MARK: - Helpers

    private func assignedType(for recipe: Recipe) -> String {
        mealTypeOverrides[recipe.persistentModelID] ?? recipe.mealType
    }

    private func cycleType(for recipe: Recipe) {
        let current = assignedType(for: recipe)
        let next: String
        switch current {
        case MealType.breakfast: next = MealType.lunch
        case MealType.lunch:     next = MealType.dinner
        case MealType.dinner:    next = MealType.any
        default:                 next = MealType.breakfast
        }
        mealTypeOverrides[recipe.persistentModelID] = next
    }

    // Totals computed from current assignments
    private var totalCals:  Int { coordinator.acceptedRecipes.reduce(0) { $0 + $1.calories } }
    private var totalProt:  Int { coordinator.acceptedRecipes.reduce(0) { $0 + $1.protein } }
    private var totalCarbs: Int { coordinator.acceptedRecipes.reduce(0) { $0 + $1.carbs } }
    private var totalFat:   Int { coordinator.acceptedRecipes.reduce(0) { $0 + $1.fat } }
    private var totalTime:  Int { coordinator.acceptedRecipes.reduce(0) { $0 + $1.cookTime } }

    var body: some View {
        NavigationStack {
            ZStack {
                HungiTheme.parchment.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // Totals card
                        if totalCals > 0 || totalTime > 0 {
                            VStack(spacing: 12) {
                                Text("Weekly Totals")
                                    .font(HungiTheme.headline)
                                    .foregroundStyle(HungiTheme.darkBrown)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                HStack(spacing: 0) {
                                    if totalTime > 0 {
                                        SummaryStatCell(value: "\(totalTime)", unit: "min",
                                                        label: "Prep Time", icon: "clock.fill",
                                                        color: HungiTheme.woodBrown)
                                        Divider().frame(height: 50).background(HungiTheme.tan)
                                    }
                                    if totalCals > 0 {
                                        SummaryStatCell(value: "\(totalCals)", unit: "kcal",
                                                        label: "Calories", icon: "flame.fill",
                                                        color: HungiTheme.harvest)
                                        Divider().frame(height: 50).background(HungiTheme.tan)
                                        SummaryStatCell(value: "\(totalProt)g", unit: "",
                                                        label: "Protein", icon: "bolt.fill",
                                                        color: HungiTheme.forest)
                                        Divider().frame(height: 50).background(HungiTheme.tan)
                                        SummaryStatCell(value: "\(totalCarbs)g", unit: "",
                                                        label: "Carbs", icon: "leaf.fill",
                                                        color: HungiTheme.wheat)
                                        Divider().frame(height: 50).background(HungiTheme.tan)
                                        SummaryStatCell(value: "\(totalFat)g", unit: "",
                                                        label: "Fat", icon: "drop.fill",
                                                        color: HungiTheme.terracotta)
                                    }
                                }
                            }
                            .padding()
                            .background(HungiTheme.cream)
                            .clipShape(RoundedRectangle(cornerRadius: HungiTheme.cardRadius))
                            .pixelBorder()
                            .pixelShadow()
                            .padding(.horizontal)
                        }

                        // Recipes list
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("\(coordinator.acceptedRecipes.count) Meals Planned")
                                    .font(HungiTheme.headline)
                                    .foregroundStyle(HungiTheme.darkBrown)
                                Spacer()
                                Text("Tap badge to change meal type")
                                    .font(HungiTheme.caption)
                                    .foregroundStyle(HungiTheme.woodBrown)
                            }
                            .padding(.horizontal)

                            if coordinator.acceptedRecipes.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "fork.knife").font(.largeTitle)
                                        .foregroundStyle(HungiTheme.woodBrown)
                                    Text("No meals yet — go back and swipe some!")
                                        .font(HungiTheme.body).foregroundStyle(HungiTheme.woodBrown)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity).padding(32)
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(Array(coordinator.acceptedRecipes.enumerated()), id: \.element.id) { idx, recipe in
                                        SummaryRecipeRow(
                                            recipe: recipe,
                                            assignedType: assignedType(for: recipe),
                                            onCycleType: { cycleType(for: recipe) },
                                            onRemove: { coordinator.removeAccepted(recipe) }
                                        )
                                        if idx < coordinator.acceptedRecipes.count - 1 {
                                            Divider().background(HungiTheme.tan).padding(.leading, 80)
                                        }
                                    }
                                }
                                .background(HungiTheme.cream)
                                .clipShape(RoundedRectangle(cornerRadius: HungiTheme.cardRadius))
                                .pixelBorder()
                                .padding(.horizontal)
                            }

                            // Add more recipes button
                            Button {
                                showAddRecipe = true
                            } label: {
                                Label("Add from Recipe Book", systemImage: "plus")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PixelButtonStyle(background: HungiTheme.woodBrown))
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Your Week 🎉")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("← Back") { coordinator.step = .swiping }
                        .font(HungiTheme.caption)
                        .foregroundStyle(HungiTheme.wheat)
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider().background(HungiTheme.tan)
                    Button(action: finishAndGoToGrocery) {
                        Label("Create Grocery List!", systemImage: "cart.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PixelButtonStyle(background: HungiTheme.harvest))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(HungiTheme.parchment)
                }
            }
            .sheet(isPresented: $showAddRecipe) {
                AddRecipeFromBookSheet(
                    existingIDs: Set(coordinator.acceptedRecipes.map { $0.persistentModelID }),
                    onAdd: { coordinator.accept($0) }
                )
            }
        }
    }

    // MARK: - Save

    private func finishAndGoToGrocery() {
        let recipes = coordinator.acceptedRecipes

        // Apply meal type overrides before saving
        for recipe in recipes {
            if let override = mealTypeOverrides[recipe.persistentModelID] {
                recipe.mealType = override
            }
        }

        let breakfastCount = recipes.filter { $0.mealType == MealType.breakfast }.count
        let lunchCount     = recipes.filter { $0.mealType == MealType.lunch }.count
        let dinnerCount    = recipes.filter { $0.mealType == MealType.dinner }.count

        let plan = WeeklyPlan(
            targetBreakfast: breakfastCount,
            targetLunch:     lunchCount,
            targetDinner:    dinnerCount
        )
        plan.meals = recipes
        modelContext.insert(plan)

        let missing = GroceryDiffService.compute(for: recipes, having: pantryItems)
        let existingNames = Set(groceryItems.map { $0.name.lowercased() })
        for item in missing {
            guard !existingNames.contains(item.name.lowercased()) else { continue }
            modelContext.insert(GroceryItem(name: item.name, quantity: item.quantity))
        }

        try? modelContext.save()
        coordinator.step = .done
    }
}

// MARK: - Summary Recipe Row

private struct SummaryRecipeRow: View {
    let recipe: Recipe
    let assignedType: String
    let onCycleType: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let data = recipe.imageData, let img = UIImage(data: data) {
                Image(uiImage: img).resizable().scaledToFill()
                    .frame(width: 56, height: 56).clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(HungiTheme.darkBrown, lineWidth: 1.5))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(MealType.color(for: recipe.mealType).opacity(0.2))
                    .frame(width: 56, height: 56)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(HungiTheme.darkBrown, lineWidth: 1.5))
                    .overlay { Image(systemName: "fork.knife")
                        .foregroundStyle(MealType.color(for: recipe.mealType)) }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(HungiTheme.headline)
                    .foregroundStyle(HungiTheme.darkBrown)
                    .lineLimit(1)

                // Tappable meal type badge
                Button(action: onCycleType) {
                    Label(MealType.displayName(for: assignedType),
                          systemImage: MealType.icon(for: assignedType))
                        .font(HungiTheme.caption)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(MealType.color(for: assignedType))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.15), value: assignedType)
            }

            Spacer()

            // Remove button
            Button(action: onRemove) {
                Image(systemName: "minus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(HungiTheme.terracotta)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
    }
}

// MARK: - Stat cell

private struct SummaryStatCell: View {
    let value: String; let unit: String; let label: String; let icon: String; let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.caption).foregroundStyle(color)
            Text(value + unit).font(HungiTheme.caption.bold()).foregroundStyle(HungiTheme.darkBrown)
            Text(label).font(HungiTheme.caption).foregroundStyle(HungiTheme.woodBrown)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 8)
    }
}

// MARK: - Add from Recipe Book sheet

private struct AddRecipeFromBookSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Recipe.createdAt, order: .reverse) private var allRecipes: [Recipe]

    let existingIDs: Set<PersistentIdentifier>
    let onAdd: (Recipe) -> Void

    private var available: [Recipe] {
        allRecipes.filter { !existingIDs.contains($0.persistentModelID) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if available.isEmpty {
                    ZStack {
                        HungiTheme.parchment.ignoresSafeArea()
                        ContentUnavailableView("All recipes added",
                                               systemImage: "checkmark.circle",
                                               description: Text("Every recipe is already on your plate."))
                    }
                } else {
                    List(available) { recipe in
                        Button {
                            onAdd(recipe)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                if let data = recipe.imageData, let img = UIImage(data: data) {
                                    Image(uiImage: img).resizable().scaledToFill()
                                        .frame(width: 48, height: 48).clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    RoundedRectangle(cornerRadius: 8).fill(HungiTheme.tan)
                                        .frame(width: 48, height: 48)
                                        .overlay { Image(systemName: "fork.knife").foregroundStyle(HungiTheme.woodBrown) }
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(recipe.name).font(HungiTheme.headline)
                                        .foregroundStyle(HungiTheme.darkBrown)
                                    Text(MealType.displayName(for: recipe.mealType))
                                        .font(HungiTheme.caption).foregroundStyle(HungiTheme.woodBrown)
                                }
                                Spacer()
                                Image(systemName: "plus.circle").foregroundStyle(HungiTheme.harvest)
                            }
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(HungiTheme.cream)
                    }
                    .scrollContentBackground(.hidden)
                    .background(HungiTheme.parchment)
                }
            }
            .navigationTitle("Add Recipes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }.foregroundStyle(HungiTheme.harvest)
                }
            }
        }
    }
}

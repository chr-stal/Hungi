import SwiftUI
import SwiftData

struct WeeklyOverviewView: View {
    @Query(sort: \WeeklyPlan.weekStartDate, order: .reverse) private var plans: [WeeklyPlan]
    @State private var showingReplan = false

    var currentPlan: WeeklyPlan? { plans.first }

    var body: some View {
        NavigationStack {
            Group {
                if let plan = currentPlan, !plan.meals.isEmpty {
                    planView(plan)
                } else {
                    ContentUnavailableView(
                        "No meals planned yet",
                        systemImage: "calendar",
                        description: Text("Tap \"Plan This Week\" to get started.")
                    )
                }
            }
            .navigationTitle("Weekly Overview")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Plan This Week") { showingReplan = true }
                        .foregroundStyle(.orange)
                }
            }
            .sheet(isPresented: $showingReplan) {
                WeeklyPlanningFlow()
            }
        }
    }

    @ViewBuilder
    private func planView(_ plan: WeeklyPlan) -> some View {
        List {
            // Per meal rows
            ForEach([MealType.breakfast, MealType.lunch, MealType.dinner, MealType.any], id: \.self) { type in
                let meals = plan.meals.filter { $0.mealType == type }
                if !meals.isEmpty {
                    Section(MealType.displayName(for: type)) {
                        ForEach(meals) { recipe in
                            MealOverviewRow(recipe: recipe)
                        }
                    }
                }
            }

            // Totals row
            Section {
                HStack(spacing: 0) {
                    TotalCell(icon: "clock.fill",  color: .blue,   value: "\(plan.totalCookTime)", unit: "min",  label: "Total time")
                    if plan.totalCalories > 0 {
                        Divider().frame(height: 48)
                        TotalCell(icon: "flame.fill",  color: .orange, value: "\(plan.totalCalories)", unit: "kcal", label: "Calories")
                        Divider().frame(height: 48)
                        TotalCell(icon: "bolt.fill",   color: .green,  value: "\(plan.totalProtein)g", unit: "",    label: "Protein")
                        Divider().frame(height: 48)
                        TotalCell(icon: "leaf.fill",   color: Color(red: 0.9, green: 0.75, blue: 0), value: "\(plan.totalCarbs)g",   unit: "",    label: "Carbs")
                        Divider().frame(height: 48)
                        TotalCell(icon: "drop.fill",   color: .red,    value: "\(plan.totalFat)g",     unit: "",    label: "Fat")
                    }
                }
            } header: {
                Text("Weekly Totals")
            }
        }
    }
}

// MARK: - Sub-views

private struct MealOverviewRow: View {
    let recipe: Recipe

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let data = recipe.imageData, let img = UIImage(data: data) {
                Image(uiImage: img).resizable().scaledToFill()
                    .frame(width: 48, height: 48).clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(MealType.color(for: recipe.mealType).opacity(0.15))
                    .frame(width: 48, height: 48)
                    .overlay { Image(systemName: "fork.knife").foregroundStyle(MealType.color(for: recipe.mealType)) }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(recipe.name).font(.headline)
                HStack(spacing: 8) {
                    if recipe.cookTime > 0 {
                        Label(recipe.cookTimeDisplay, systemImage: "clock").font(.caption).foregroundStyle(.secondary)
                    }
                    if recipe.calories > 0 {
                        Label("\(recipe.calories) kcal", systemImage: "flame").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Macro pills (compact)
            if recipe.protein > 0 {
                VStack(spacing: 2) {
                    Text("\(recipe.protein)g").font(.caption.bold()).foregroundStyle(.green)
                    Text("P").font(.caption2).foregroundStyle(.secondary)
                    Text("\(recipe.carbs)g").font(.caption.bold()).foregroundStyle(Color(red: 0.9, green: 0.75, blue: 0))
                    Text("C").font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

private struct TotalCell: View {
    let icon: String
    let color: Color
    let value: String
    let unit: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon).font(.caption).foregroundStyle(color)
            Text(value + unit).font(.caption.bold())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
}

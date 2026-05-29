import SwiftUI

/// Full recipe detail shown when user taps a swipe card.
struct RecipeDetailCardView: View {
    let match: RecipeMatch
    let onAddToPlate: () -> Void
    let alreadyAdded: Bool

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Hero image
                    if let data = match.recipe.imageData, let img = UIImage(data: data) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 260)
                            .clipped()
                    } else {
                        ZStack {
                            LinearGradient(
                                colors: [MealType.color(for: match.recipe.mealType).opacity(0.5), Color(.systemGray4)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                            Image(systemName: "fork.knife")
                                .font(.system(size: 50))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity).frame(height: 180)
                    }

                    VStack(alignment: .leading, spacing: 20) {
                        // Title + badges
                        VStack(alignment: .leading, spacing: 8) {
                            Text(match.recipe.name).font(.title.bold())

                            HStack(spacing: 8) {
                                Label(MealType.displayName(for: match.recipe.mealType),
                                      systemImage: MealType.icon(for: match.recipe.mealType))
                                    .font(.caption.bold())
                                    .padding(.horizontal, 10).padding(.vertical, 5)
                                    .background(MealType.color(for: match.recipe.mealType))
                                    .foregroundStyle(.white).clipShape(Capsule())

                                if match.recipe.cookTime > 0 {
                                    Label(match.recipe.cookTimeDisplay, systemImage: "clock")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 10).padding(.vertical, 5)
                                        .background(.quaternary).clipShape(Capsule())
                                }

                                Text("\(match.matchPercentage)% match")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 10).padding(.vertical, 5)
                                    .background(matchColor.opacity(0.15))
                                    .foregroundStyle(matchColor).clipShape(Capsule())
                            }
                        }

                        // Macros row (only if set)
                        if match.recipe.calories > 0 {
                            HStack(spacing: 0) {
                                MacroCell(value: match.recipe.calories, unit: "kcal", label: "Calories")
                                Divider().frame(height: 40)
                                MacroCell(value: match.recipe.protein, unit: "g", label: "Protein")
                                Divider().frame(height: 40)
                                MacroCell(value: match.recipe.carbs, unit: "g", label: "Carbs")
                                Divider().frame(height: 40)
                                MacroCell(value: match.recipe.fat, unit: "g", label: "Fat")
                            }
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                        }

                        // Ingredients
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ingredients").font(.headline)
                            ForEach(match.recipe.ingredients) { ing in
                                let have = match.matchedIngredients.contains { $0.id == ing.id }
                                HStack(spacing: 10) {
                                    Image(systemName: have ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundStyle(have ? .green : .orange)
                                    Text(ing.name)
                                    Spacer()
                                    if !ing.quantity.isEmpty {
                                        Text(ing.quantity).foregroundStyle(.secondary).font(.subheadline)
                                    }
                                }
                            }

                            if !match.missingIngredients.isEmpty {
                                Text("You'll need to buy \(match.missingIngredients.count) ingredient\(match.missingIngredients.count == 1 ? "" : "s").")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 4)
                            }
                        }

                        // Instructions
                        if !match.recipe.instructions.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Instructions").font(.headline)
                                Text(match.recipe.instructions)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: {
                    onAddToPlate()
                    dismiss()
                }) {
                    Label(alreadyAdded ? "Added to plate ✓" : "Add to plate",
                          systemImage: alreadyAdded ? "checkmark" : "plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(alreadyAdded ? Color.gray : Color.orange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .disabled(alreadyAdded)
                .background(.regularMaterial)
            }
        }
    }

    private var matchColor: Color {
        switch match.score {
        case 0.8...: return .green
        case 0.5..<0.8: return .orange
        default: return .red
        }
    }
}

private struct MacroCell: View {
    let value: Int
    let unit: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)\(unit)").font(.headline.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
}

import SwiftUI
import SwiftData

struct RecipeSwipeView: View {
    @Environment(FlowCoordinator.self) private var coordinator
    @Query private var allRecipes: [Recipe]
    @Query private var pantryItems: [PantryItem]

    @State private var dragOffset: CGSize = .zero
    @State private var isAnimating = false          // guards against double-swipe
    @State private var showDetail: RecipeMatch? = nil
    @State private var showPlate: Bool = false

    private let swipeThreshold: CGFloat = 110

    // MARK: - Ranked deck

    private var rankedMatches: [RecipeMatch] {
        let pantryNames = Set(pantryItems.map {
            $0.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        })
        // Key ingredients from step 2 — normalized
        let keyNames = coordinator.keyIngredients.map {
            $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return allRecipes.map { recipe -> RecipeMatch in
            let ingNames = recipe.ingredients.map {
                $0.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            }

            let matched = recipe.ingredients.filter { pantryNames.contains($0.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)) }
            let missing = recipe.ingredients.filter { !pantryNames.contains($0.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)) }

            let total = Double(recipe.ingredients.count)

            // Base pantry score
            let baseScore = total == 0 ? 0.0 : Double(matched.count) / total

            // Key ingredient bonus — each key name that appears in any ingredient bumps by 0.25
            let keyBonus: Double = keyNames.isEmpty ? 0.0 : keyNames.reduce(0.0) { acc, key in
                let hit = ingNames.contains { $0.contains(key) || key.contains($0) }
                return acc + (hit ? 0.25 : 0.0)
            }

            // Cuisine bonus (medium weight)
            let cuisineBonus: Double = (!coordinator.selectedCuisines.isEmpty
                && coordinator.selectedCuisines.contains(recipe.cuisine)) ? 0.2 : 0.0

            let score = min(1.0, baseScore + keyBonus + cuisineBonus)
            return RecipeMatch(recipe: recipe, matchedIngredients: matched,
                               missingIngredients: missing, score: score)
        }
        .sorted { $0.score > $1.score }
    }

    private var remainingMatches: [RecipeMatch] {
        let acceptedIDs = Set(coordinator.acceptedRecipes.map { $0.persistentModelID })
        return rankedMatches.filter {
            !coordinator.declinedIDs.contains($0.recipe.persistentModelID) &&
            !acceptedIDs.contains($0.recipe.persistentModelID)
        }
    }

    private var visibleCards: [RecipeMatch] { Array(remainingMatches.prefix(3)) }
    private var isDone: Bool { remainingMatches.isEmpty }

    // Running totals for accepted recipes
    private var totalCals:  Int { coordinator.acceptedRecipes.reduce(0) { $0 + $1.calories } }
    private var totalProt:  Int { coordinator.acceptedRecipes.reduce(0) { $0 + $1.protein } }
    private var totalCarbs: Int { coordinator.acceptedRecipes.reduce(0) { $0 + $1.carbs } }
    private var totalTime:  Int { coordinator.acceptedRecipes.reduce(0) { $0 + $1.cookTime } }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                HungiTheme.parchment.ignoresSafeArea()

                if isDone {
                    completionView
                } else {
                    VStack(spacing: 12) {
                        countRow
                        if totalCals > 0 || totalTime > 0 { macrosRow }

                        Spacer()

                        // Card stack — reversed so top card (index 0) renders last = on top
                        ZStack {
                            ForEach(Array(visibleCards.enumerated().reversed()), id: \.element.id) { position, match in
                                let isTop = position == 0
                                RecipeCardView(
                                    match: match,
                                    dragOffset: isTop ? dragOffset : .zero
                                )
                                .frame(width: 340, height: 480)
                                .offset(
                                    x: isTop ? dragOffset.width : 0,
                                    y: isTop ? dragOffset.height * 0.1 : CGFloat(position) * 10
                                )
                                .scaleEffect(1.0 - CGFloat(position) * 0.04)
                                .rotationEffect(.degrees(isTop ? Double(dragOffset.width) / 22 : 0))
                                .zIndex(isTop ? 10 : Double(visibleCards.count - position))
                                .gesture(isTop && !isAnimating ? dragGesture(for: match) : nil)
                                .onTapGesture { if isTop && !isAnimating { showDetail = match } }
                            }
                        }

                        Spacer()
                        actionButtons
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Find Your Meals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { coordinator.step = .pantry }.foregroundStyle(.orange)
                }
                ToolbarItem(placement: .navigationBarTrailing) { plateButton }
            }
            .sheet(item: $showDetail) { match in
                RecipeDetailCardView(
                    match: match,
                    onAddToPlate: { coordinator.accept(match.recipe) },
                    alreadyAdded: coordinator.acceptedRecipes.contains {
                        $0.persistentModelID == match.recipe.persistentModelID
                    }
                )
            }
            .sheet(isPresented: $showPlate) { PlateView() }
        }
    }

    // MARK: - Top bars

    private var countRow: some View {
        HStack {
            Label("\(coordinator.acceptedCount) meal\(coordinator.acceptedCount == 1 ? "" : "s") added",
                  systemImage: "fork.knife")
                .font(HungiTheme.caption)
                .foregroundStyle(HungiTheme.woodBrown)
            Spacer()
            Text("\(remainingMatches.count) left")
                .font(HungiTheme.caption)
                .foregroundStyle(HungiTheme.woodBrown)
        }
        .padding(.horizontal, 4)
        .padding(.top, 4)
    }

    private var macrosRow: some View {
        HStack(spacing: 12) {
            if totalTime > 0 {
                MacroChip(icon: "clock.fill", value: "\(totalTime)m", color: HungiTheme.woodBrown)
            }
            if totalCals > 0 {
                MacroChip(icon: "flame.fill", value: "\(totalCals)kcal", color: HungiTheme.harvest)
                MacroChip(icon: "bolt.fill", value: "\(totalProt)g P", color: HungiTheme.forest)
                MacroChip(icon: "leaf.fill", value: "\(totalCarbs)g C", color: HungiTheme.wheat)
            }
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Buttons

    private var actionButtons: some View {
        HStack(spacing: 36) {
            Button {
                if let top = visibleCards.first { declineAndAnimate(top) }
            } label: {
                Image(systemName: "xmark").font(.title2.bold()).foregroundStyle(HungiTheme.cream)
            }
            .buttonStyle(PixelCircleButtonStyle(background: HungiTheme.terracotta))
            .disabled(isAnimating)

            Button { coordinator.step = .summary } label: {
                Text("Done →")
            }
            .buttonStyle(PixelButtonStyle(background: HungiTheme.wheat, foreground: HungiTheme.darkBrown))

            Button {
                if let top = visibleCards.first { acceptAndAnimate(top) }
            } label: {
                Image(systemName: "checkmark").font(.title2.bold()).foregroundStyle(HungiTheme.cream)
            }
            .buttonStyle(PixelCircleButtonStyle(background: HungiTheme.forest))
            .disabled(isAnimating)
        }
        .padding(.bottom, 32)
    }

    private var plateButton: some View {
        Button { showPlate = true } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "fork.knife.circle").font(.title2).foregroundStyle(.orange)
                if coordinator.acceptedCount > 0 {
                    Text("\(coordinator.acceptedCount)")
                        .font(.caption2.bold()).foregroundStyle(.white)
                        .padding(4).background(Color.red).clipShape(Circle())
                        .offset(x: 8, y: -8)
                }
            }
        }
    }

    private var completionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "tray.and.arrow.down.fill").font(.system(size: 70)).foregroundStyle(.orange)
            Text("All recipes seen!").font(.title.bold())
            Text("\(coordinator.acceptedCount) meal\(coordinator.acceptedCount == 1 ? "" : "s") added.")
                .foregroundStyle(.secondary)
            Button { coordinator.step = .summary } label: {
                Text("See Summary →").font(.headline).frame(maxWidth: .infinity).padding()
                    .background(.orange).foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Gesture & animation
    //
    // FIX: use withAnimation completion callback (iOS 17) so the card fully
    // exits the screen before the deck updates. This prevents the mid-swipe
    // freeze caused by SwiftUI cancelling in-flight animations on re-render.

    private func dragGesture(for match: RecipeMatch) -> some Gesture {
        DragGesture()
            .onChanged { value in dragOffset = value.translation }
            .onEnded { value in
                if value.translation.width > swipeThreshold {
                    acceptAndAnimate(match)
                } else if value.translation.width < -swipeThreshold {
                    declineAndAnimate(match)
                } else {
                    withAnimation(.spring(response: 0.4)) { dragOffset = .zero }
                }
            }
    }

    private func acceptAndAnimate(_ match: RecipeMatch) {
        guard !isAnimating else { return }
        isAnimating = true
        withAnimation(.easeOut(duration: 0.25)) {
            dragOffset = CGSize(width: 700, height: dragOffset.height)
        } completion: {
            coordinator.accept(match.recipe)
            dragOffset = .zero
            isAnimating = false
        }
    }

    private func declineAndAnimate(_ match: RecipeMatch) {
        guard !isAnimating else { return }
        isAnimating = true
        withAnimation(.easeOut(duration: 0.25)) {
            dragOffset = CGSize(width: -700, height: dragOffset.height)
        } completion: {
            coordinator.decline(match.recipe)
            dragOffset = .zero
            isAnimating = false
        }
    }
}

// MARK: - Macro chip

private struct MacroChip: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.caption2).foregroundStyle(color)
            Text(value).font(HungiTheme.caption).foregroundStyle(HungiTheme.darkBrown)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(HungiTheme.cream)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(HungiTheme.darkBrown, lineWidth: 1))
    }
}

// MARK: - Plate sheet

private struct PlateView: View {
    @Environment(FlowCoordinator.self) private var coordinator
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if coordinator.acceptedRecipes.isEmpty {
                    ContentUnavailableView("Plate is empty", systemImage: "fork.knife",
                                           description: Text("Swipe right on recipes to add them."))
                } else {
                    List(coordinator.acceptedRecipes) { recipe in
                        HStack(spacing: 12) {
                            if let data = recipe.imageData, let img = UIImage(data: data) {
                                Image(uiImage: img).resizable().scaledToFill()
                                    .frame(width: 44, height: 44).clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            } else {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(MealType.color(for: recipe.mealType).opacity(0.2))
                                    .frame(width: 44, height: 44)
                                    .overlay { Image(systemName: "fork.knife")
                                        .foregroundStyle(MealType.color(for: recipe.mealType)) }
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(recipe.name).font(HungiTheme.body).foregroundStyle(HungiTheme.darkBrown)
                                if recipe.rating > 0 {
                                    Text(recipe.ratingDisplay).font(HungiTheme.caption)
                                        .foregroundStyle(HungiTheme.harvest)
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(HungiTheme.parchment)
                }
            }
            .navigationTitle("Your Plate (\(coordinator.acceptedCount))")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.foregroundStyle(HungiTheme.harvest)
                }
            }
        }
    }
}

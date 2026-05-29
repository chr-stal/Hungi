import SwiftUI
import SwiftData

struct RecipeSwipeView: View {
    @Environment(FlowCoordinator.self) private var coordinator
    @Query private var allRecipes: [Recipe]
    @Query private var pantryItems: [PantryItem]

    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGSize = .zero
    @State private var showDetail: RecipeMatch? = nil
    @State private var showPlate: Bool = false

    private let swipeThreshold: CGFloat = 110

    // All recipes sorted by match score (highest first)
    private var rankedMatches: [RecipeMatch] {
        let pantryNames = Set(pantryItems.map { $0.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) })
        return allRecipes
            .map { recipe -> RecipeMatch in
                let matched = recipe.ingredients.filter { pantryNames.contains($0.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)) }
                let missing = recipe.ingredients.filter { !pantryNames.contains($0.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)) }
                let score = recipe.ingredients.isEmpty ? 0.0 : Double(matched.count) / Double(recipe.ingredients.count)
                return RecipeMatch(recipe: recipe, matchedIngredients: matched, missingIngredients: missing, score: score)
            }
            .sorted { $0.score > $1.score }
    }

    private var remainingMatches: [RecipeMatch] {
        rankedMatches.filter { match in
            !coordinator.declinedIDs.contains(match.recipe.persistentModelID) &&
            !coordinator.acceptedRecipes.contains(where: { $0.persistentModelID == match.recipe.persistentModelID })
        }
    }

    // Current top cards to render (up to 3)
    private var visibleCards: [(Int, RecipeMatch)] {
        let end = min(currentIndex + 3, rankedMatches.count)
        guard currentIndex < rankedMatches.count else { return [] }
        return (currentIndex..<end).reversed().map { ($0, rankedMatches[$0]) }
    }

    private var isDone: Bool { currentIndex >= rankedMatches.count || coordinator.plateIsFull }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                if isDone {
                    completionView
                } else {
                    VStack(spacing: 20) {
                        progressBar

                        Spacer()

                        // Card stack
                        ZStack {
                            ForEach(visibleCards, id: \.0) { idx, match in
                                let position = idx - currentIndex
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
                                .zIndex(Double(-position))
                                .gesture(isTop ? dragGesture(for: match) : nil)
                                .onTapGesture { if isTop { showDetail = match } }
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
                    Button("Back") { coordinator.step = .mealCount }.foregroundStyle(.orange)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    plateButton
                }
            }
            .sheet(item: $showDetail) { match in
                RecipeDetailCardView(
                    match: match,
                    onAddToPlate: {
                        coordinator.accept(match.recipe)
                        if currentIndex == rankedMatches.firstIndex(where: { $0.recipe.persistentModelID == match.recipe.persistentModelID }) {
                            advance()
                        }
                    },
                    alreadyAdded: coordinator.acceptedRecipes.contains { $0.persistentModelID == match.recipe.persistentModelID }
                )
            }
            .sheet(isPresented: $showPlate) {
                PlateView()
            }
        }
    }

    // MARK: - Sub-views

    private var progressBar: some View {
        VStack(spacing: 6) {
            HStack {
                Text("\(coordinator.plateCount) of \(coordinator.targetTotal) meals added")
                    .font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                Text("\(rankedMatches.count - currentIndex) left")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            ProgressView(value: Double(coordinator.plateCount), total: Double(coordinator.targetTotal))
                .tint(.orange)
        }
        .padding(.horizontal, 4)
    }

    private var actionButtons: some View {
        HStack(spacing: 50) {
            // Decline
            Button {
                if currentIndex < rankedMatches.count {
                    decline(rankedMatches[currentIndex])
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.title.bold())
                    .foregroundStyle(.red)
                    .frame(width: 64, height: 64)
                    .background(Color(.systemBackground))
                    .clipShape(Circle())
                    .shadow(color: .red.opacity(0.3), radius: 6)
            }

            // Done button
            Button { coordinator.step = .summary } label: {
                Text("Done")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .clipShape(Capsule())
            }

            // Accept
            Button {
                if currentIndex < rankedMatches.count {
                    acceptAndAdvance(rankedMatches[currentIndex])
                }
            } label: {
                Image(systemName: "checkmark")
                    .font(.title.bold())
                    .foregroundStyle(.green)
                    .frame(width: 64, height: 64)
                    .background(Color(.systemBackground))
                    .clipShape(Circle())
                    .shadow(color: .green.opacity(0.3), radius: 6)
            }
        }
        .padding(.bottom, 32)
    }

    private var plateButton: some View {
        Button { showPlate = true } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "fork.knife.circle")
                    .font(.title2)
                    .foregroundStyle(.orange)
                if coordinator.plateCount > 0 {
                    Text("\(coordinator.plateCount)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(4)
                        .background(Color.red)
                        .clipShape(Circle())
                        .offset(x: 8, y: -8)
                }
            }
        }
    }

    private var completionView: some View {
        VStack(spacing: 24) {
            Image(systemName: coordinator.plateIsFull ? "checkmark.seal.fill" : "tray.and.arrow.down.fill")
                .font(.system(size: 70))
                .foregroundStyle(.orange)

            Text(coordinator.plateIsFull ? "Plate is full!" : "All recipes seen!")
                .font(.title.bold())

            Text("\(coordinator.plateCount) meal\(coordinator.plateCount == 1 ? "" : "s") added to your plate.")
                .foregroundStyle(.secondary)

            Button(action: { coordinator.step = .summary }) {
                Text("See Summary →")
                    .font(.headline)
                    .frame(maxWidth: .infinity).padding()
                    .background(.orange).foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Gestures & actions

    private func dragGesture(for match: RecipeMatch) -> some Gesture {
        DragGesture()
            .onChanged { value in dragOffset = value.translation }
            .onEnded { value in
                if value.translation.width > swipeThreshold {
                    acceptAndAdvance(match)
                } else if value.translation.width < -swipeThreshold {
                    decline(match)
                } else {
                    withAnimation(.spring(response: 0.4)) { dragOffset = .zero }
                }
            }
    }

    private func acceptAndAdvance(_ match: RecipeMatch) {
        coordinator.accept(match.recipe)
        animateOffScreen(toRight: true)
    }

    private func decline(_ match: RecipeMatch) {
        coordinator.decline(match.recipe)
        animateOffScreen(toRight: false)
    }

    private func animateOffScreen(toRight: Bool) {
        withAnimation(.easeOut(duration: 0.3)) {
            dragOffset = CGSize(width: toRight ? 600 : -600, height: 0)
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            advance()
            dragOffset = .zero
        }
    }

    private func advance() {
        withAnimation(.easeInOut(duration: 0.2)) {
            currentIndex += 1
        }
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
                    ContentUnavailableView("Plate is empty", systemImage: "fork.knife", description: Text("Swipe right on recipes to add them."))
                } else {
                    List {
                        ForEach(MealType.all.filter { type in coordinator.acceptedRecipes.contains { $0.mealType == type } }, id: \.self) { type in
                            let meals = coordinator.acceptedRecipes.filter { $0.mealType == type }
                            Section(MealType.displayName(for: type)) {
                                ForEach(meals) { recipe in
                                    HStack {
                                        Image(systemName: MealType.icon(for: recipe.mealType))
                                            .foregroundStyle(MealType.color(for: recipe.mealType))
                                        Text(recipe.name)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Your Plate (\(coordinator.plateCount)/\(coordinator.targetTotal))")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}

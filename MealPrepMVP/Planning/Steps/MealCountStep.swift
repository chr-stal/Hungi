import SwiftUI

struct MealCountStep: View {
    @Environment(FlowCoordinator.self) private var coordinator

    var body: some View {
        @Bindable var coord = coordinator

        ZStack {
            HungiTheme.parchment.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    Spacer(minLength: 8)

                    // Header
                    VStack(spacing: 10) {
                        Text("🍽️")
                            .font(.system(size: 56))
                        Text("What are you feeling?")
                            .font(HungiTheme.title)
                            .foregroundStyle(HungiTheme.darkBrown)
                            .multilineTextAlignment(.center)
                        Text("Pick cuisines you're craving — we'll boost those recipes in your feed")
                            .font(HungiTheme.body)
                            .foregroundStyle(HungiTheme.woodBrown)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Cuisine chips
                    ChipFlow(items: CuisineType.options.map { CuisineChipItem(name: $0.name, emoji: $0.emoji) }) { item in
                        let isSelected = coord.selectedCuisines.contains(item.name)
                        CuisineChip(item: item, isSelected: isSelected) {
                            if isSelected {
                                coord.selectedCuisines.remove(item.name)
                            } else {
                                coord.selectedCuisines.insert(item.name)
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    if coord.selectedCuisines.isEmpty {
                        Text("Skip to see all cuisines equally")
                            .font(HungiTheme.caption)
                            .foregroundStyle(HungiTheme.woodBrown)
                    }

                    Button(action: { coordinator.step = .pantry }) {
                        Text(coord.selectedCuisines.isEmpty ? "Skip →" : "Next (\(coord.selectedCuisines.count) selected) →")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PixelButtonStyle(background: HungiTheme.harvest))
                    .padding(.horizontal, 28)
                    .padding(.bottom, 48)
                }
            }
        }
        .navigationTitle("Cuisine Vibes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("← Back") { coordinator.step = .ingredients }
                    .font(HungiTheme.caption)
                    .foregroundStyle(HungiTheme.wheat)
            }
        }
    }
}

// MARK: - Helpers

private struct CuisineChipItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let emoji: String
}

private struct CuisineChip: View {
    let item: CuisineChipItem
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 5) {
                Text(item.emoji)
                Text(item.name).font(HungiTheme.caption)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? HungiTheme.harvest : HungiTheme.cream)
            .foregroundStyle(isSelected ? HungiTheme.cream : HungiTheme.darkBrown)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(HungiTheme.darkBrown, lineWidth: isSelected ? 2 : 1))
            .shadow(color: HungiTheme.darkBrown, radius: 0, x: isSelected ? 1 : 0, y: isSelected ? 1 : 0)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.12), value: isSelected)
    }
}

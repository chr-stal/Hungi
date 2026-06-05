import SwiftUI
import SwiftData

struct IngredientsEntryStep: View {
    @Environment(FlowCoordinator.self) private var coordinator
    @Query private var profiles: [UserProfile]

    @State private var inputText = ""

    private var firstName: String {
        profiles.first?.name.components(separatedBy: " ").first ?? "there"
    }

    var body: some View {
        @Bindable var coord = coordinator

        ZStack {
            HungiTheme.parchment.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Hey \(firstName)! 👋")
                                .font(HungiTheme.largeTitle)
                                .foregroundStyle(HungiTheme.darkBrown)
                            Text("What do you want your meals to include this week?")
                                .font(HungiTheme.body)
                                .foregroundStyle(HungiTheme.woodBrown)
                            Text("These ingredients carry the most weight in your recipe matches.")
                                .font(HungiTheme.caption)
                                .foregroundStyle(HungiTheme.woodBrown.opacity(0.8))
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)

                        // Add ingredient row
                        HStack(spacing: 10) {
                            TextField("e.g. ground beef, spinach…", text: $inputText)
                                .foregroundStyle(HungiTheme.darkBrown)
                                .tint(HungiTheme.darkBrown)
                                .font(HungiTheme.body)
                                .padding(12)
                                .background(HungiTheme.cream)
                                .clipShape(RoundedRectangle(cornerRadius: HungiTheme.buttonRadius))
                                .overlay(RoundedRectangle(cornerRadius: HungiTheme.buttonRadius)
                                    .stroke(HungiTheme.darkBrown, lineWidth: 1.5))
                                .submitLabel(.done)
                                .onSubmit(addIngredient)

                            Button(action: addIngredient) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                                     ? HungiTheme.tan : HungiTheme.harvest)
                            }
                            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        .padding(.horizontal)

                        // Added ingredients list
                        if !coord.keyIngredients.isEmpty {
                            VStack(spacing: 0) {
                                ForEach(Array(coord.keyIngredients.enumerated()), id: \.offset) { idx, ingredient in
                                    HStack {
                                        Image(systemName: "star.fill")
                                            .font(.caption)
                                            .foregroundStyle(HungiTheme.harvest)
                                        Text(ingredient)
                                            .font(HungiTheme.body)
                                            .foregroundStyle(HungiTheme.darkBrown)
                                        Spacer()
                                        Button {
                                            coord.keyIngredients.remove(at: idx)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(HungiTheme.terracotta)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    if idx < coord.keyIngredients.count - 1 {
                                        Divider().background(HungiTheme.tan).padding(.leading, 40)
                                    }
                                }
                            }
                            .background(HungiTheme.cream)
                            .clipShape(RoundedRectangle(cornerRadius: HungiTheme.cardRadius))
                            .pixelBorder()
                            .padding(.horizontal)
                        } else {
                            // Empty state hint
                            HStack(spacing: 10) {
                                Image(systemName: "star").foregroundStyle(HungiTheme.tan)
                                Text("Add ingredients above — they'll rank recipes higher")
                                    .font(HungiTheme.caption)
                                    .foregroundStyle(HungiTheme.woodBrown)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 120)
                }

                // Bottom buttons
                VStack(spacing: 0) {
                    Divider().background(HungiTheme.tan)
                    HStack(spacing: 16) {
                        Button("← Back") { coordinator.step = .name }
                            .font(HungiTheme.caption.bold())
                            .foregroundStyle(HungiTheme.woodBrown)

                        Button(action: { coordinator.step = .mealCount }) {
                            Text(coord.keyIngredients.isEmpty
                                 ? "Skip"
                                 : "Next (\(coord.keyIngredients.count)) →")
                            .bold()
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PixelButtonStyle(background: HungiTheme.harvest))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(HungiTheme.parchment)
                }
            }
        }
        .navigationTitle("What's on the menu?")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func addIngredient() {
        let trimmed = inputText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !coordinator.keyIngredients.contains(trimmed) else {
            inputText = ""
            return
        }
        coordinator.keyIngredients.append(trimmed)
        inputText = ""
    }
}

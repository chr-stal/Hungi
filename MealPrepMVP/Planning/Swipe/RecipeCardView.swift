import SwiftUI

struct RecipeCardView: View {
    let match: RecipeMatch
    var dragOffset: CGSize = .zero

    private var swipeOpacity: Double { min(abs(dragOffset.width) / 80.0, 1.0) }
    private var isAccepting: Bool { dragOffset.width > 20 }
    private var isDeclining: Bool { dragOffset.width < -20 }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background image or placeholder
            if let data = match.recipe.imageData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [MealType.color(for: match.recipe.mealType).opacity(0.6), Color(.systemGray4)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    Image(systemName: "fork.knife")
                        .font(.system(size: 60))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            // Bottom info overlay
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // Meal type badge
                    Label(MealType.displayName(for: match.recipe.mealType),
                          systemImage: MealType.icon(for: match.recipe.mealType))
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(MealType.color(for: match.recipe.mealType))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())

                    Spacer()

                    // Cook time
                    if match.recipe.cookTime > 0 {
                        Label(match.recipe.cookTimeDisplay, systemImage: "clock")
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                }

                Text(match.recipe.name)
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .shadow(radius: 2)

                // Match bar
                HStack(spacing: 8) {
                    ProgressView(value: match.score)
                        .progressViewStyle(.linear)
                        .tint(matchColor)
                        .frame(maxWidth: 120)
                    Text("\(match.matchPercentage)% match")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                }
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [.clear, .black.opacity(0.75)],
                    startPoint: .top, endPoint: .bottom
                )
            )

            // Swipe direction overlays
            if isAccepting {
                acceptOverlay.opacity(swipeOpacity)
            } else if isDeclining {
                declineOverlay.opacity(swipeOpacity)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }

    private var acceptOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20).fill(Color.green.opacity(0.35))
            VStack {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.green)
                        .padding(24)
                    Spacer()
                }
                Spacer()
            }
        }
    }

    private var declineOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20).fill(Color.red.opacity(0.35))
            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.red)
                        .padding(24)
                }
                Spacer()
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

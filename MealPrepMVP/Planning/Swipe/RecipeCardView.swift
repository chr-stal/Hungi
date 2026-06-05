import SwiftUI

struct RecipeCardView: View {
    let match: RecipeMatch
    var dragOffset: CGSize = .zero

    private var swipeOpacity: Double { min(abs(dragOffset.width) / 80.0, 1.0) }
    private var isAccepting: Bool { dragOffset.width > 20 }
    private var isDeclining: Bool { dragOffset.width < -20 }

    var body: some View {
        VStack(spacing: 0) {
            // Image area
            ZStack(alignment: .topLeading) {
                imageBackground
                    .frame(height: 300)
                    .clipped()

                // Top badges
                HStack {
                    PixelBadge(
                        text: MealType.displayName(for: match.recipe.mealType),
                        background: MealType.color(for: match.recipe.mealType),
                        foreground: .white
                    )
                    Spacer()
                    if match.recipe.cookTime > 0 {
                        PixelBadge(
                            text: "⏱ \(match.recipe.cookTimeDisplay)",
                            background: HungiTheme.darkBrown,
                            foreground: HungiTheme.wheat
                        )
                    }
                }
                .padding(12)

                // Swipe stamp overlay
                if isAccepting || isDeclining {
                    stampOverlay.opacity(swipeOpacity)
                }
            }

            // Parchment info panel
            VStack(alignment: .leading, spacing: 8) {
                Text(match.recipe.name)
                    .font(HungiTheme.title2)
                    .foregroundStyle(HungiTheme.darkBrown)

                HStack(spacing: 8) {
                    PixelProgressBar(value: match.score, tint: matchColor)
                        .frame(maxWidth: 100)
                    Text("\(match.matchPercentage)% match")
                        .font(HungiTheme.caption)
                        .foregroundStyle(matchColor)
                    Spacer()
                    if match.recipe.rating > 0 {
                        Text(match.recipe.ratingDisplay)
                            .font(HungiTheme.caption.bold())
                            .foregroundStyle(HungiTheme.harvest)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(HungiTheme.cream)
        }
        .clipShape(RoundedRectangle(cornerRadius: HungiTheme.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: HungiTheme.cardRadius)
                .stroke(HungiTheme.darkBrown, lineWidth: HungiTheme.borderWidth)
        )
        .shadow(
            color: HungiTheme.darkBrown,
            radius: 0,
            x: HungiTheme.shadowX,
            y: HungiTheme.shadowY
        )
    }

    @ViewBuilder
    private var imageBackground: some View {
        if let data = match.recipe.imageData, let img = UIImage(data: data) {
            Image(uiImage: img).resizable().scaledToFill()
        } else {
            ZStack {
                LinearGradient(
                    colors: [MealType.color(for: match.recipe.mealType).opacity(0.7),
                             HungiTheme.tan],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                Image(systemName: "fork.knife")
                    .font(.system(size: 64))
                    .foregroundStyle(HungiTheme.cream.opacity(0.5))
            }
        }
    }

    private var stampOverlay: some View {
        ZStack {
            (isAccepting ? HungiTheme.forest : HungiTheme.terracotta).opacity(0.25)
            VStack {
                HStack {
                    if isAccepting {
                        SwipeStamp(accept: true).padding(16)
                        Spacer()
                    } else {
                        Spacer()
                        SwipeStamp(accept: false).padding(16)
                    }
                }
                Spacer()
            }
        }
    }

    private var matchColor: Color {
        switch match.score {
        case 0.8...: return HungiTheme.forest
        case 0.5..<0.8: return HungiTheme.harvest
        default: return HungiTheme.terracotta
        }
    }
}

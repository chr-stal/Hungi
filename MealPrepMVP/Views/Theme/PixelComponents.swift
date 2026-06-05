import SwiftUI

// MARK: - Wood Panel
/// Navigation-bar-style wood background used as section headers.
struct WoodPanel<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            HungiTheme.woodBrown
            Canvas { ctx, size in
                for y in stride(from: CGFloat(0), to: size.height, by: 5) {
                    var p = Path(); p.move(to: .init(x: 0, y: y)); p.addLine(to: .init(x: size.width, y: y))
                    ctx.stroke(p, with: .color(.black.opacity(0.04)), lineWidth: 1)
                }
            }
            content()
        }
    }
}

// MARK: - Parchment Card
/// Cream-coloured panel with dark border and pixel shadow.
struct ParchmentCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(HungiTheme.cream)
            .clipShape(RoundedRectangle(cornerRadius: HungiTheme.cardRadius))
            .pixelBorder()
            .pixelShadow()
    }
}

// MARK: - Pixel Badge
struct PixelBadge: View {
    let text: String
    var background: Color = HungiTheme.darkBrown
    var foreground: Color = HungiTheme.wheat

    var body: some View {
        Text(text)
            .font(HungiTheme.caption2)
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(foreground.opacity(0.5), lineWidth: 1))
    }
}

// MARK: - Pixel Progress Bar
struct PixelProgressBar: View {
    let value: Double   // 0–1
    var tint: Color = HungiTheme.forest
    var height: CGFloat = 10

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(HungiTheme.tan)
                RoundedRectangle(cornerRadius: 3)
                    .fill(tint)
                    .frame(width: geo.size.width * CGFloat(min(max(value, 0), 1)))
            }
        }
        .frame(height: height)
        .overlay(RoundedRectangle(cornerRadius: 3).stroke(HungiTheme.darkBrown, lineWidth: 1.5))
    }
}

// MARK: - Swipe Stamp
/// "YUM!" or "NOPE" stamp overlay shown during card swipe.
struct SwipeStamp: View {
    let accept: Bool

    var body: some View {
        Text(accept ? "YUM!" : "NOPE")
            .font(HungiTheme.title2)
            .foregroundStyle(accept ? HungiTheme.forest : HungiTheme.terracotta)
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(accept ? HungiTheme.forest : HungiTheme.terracotta, lineWidth: 3)
            )
            .rotationEffect(.degrees(accept ? -12 : 12))
    }
}

// MARK: - Pixel Stepper Row
struct PixelStepperRow: View {
    let label: String
    let icon: String
    let color: Color
    @Binding var count: Int

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)
                .padding(.leading, 16)

            Text(label).font(HungiTheme.body)

            Spacer()

            HStack(spacing: 0) {
                Button { if count > 0 { count -= 1 } } label: {
                    Image(systemName: "minus")
                        .font(.caption.bold())
                        .frame(width: 32, height: 32)
                        .background(count > 0 ? HungiTheme.terracotta : HungiTheme.tan)
                        .foregroundStyle(HungiTheme.cream)
                }
                .buttonStyle(.plain)

                Text("\(count)")
                    .font(HungiTheme.headline)
                    .frame(width: 40)
                    .background(HungiTheme.parchment)

                Button { count += 1 } label: {
                    Image(systemName: "plus")
                        .font(.caption.bold())
                        .frame(width: 32, height: 32)
                        .background(HungiTheme.forest)
                        .foregroundStyle(HungiTheme.cream)
                }
                .buttonStyle(.plain)
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(HungiTheme.darkBrown, lineWidth: 2))
            .shadow(color: HungiTheme.darkBrown, radius: 0, x: 2, y: 2)
            .padding(.trailing, 16)
            .padding(.vertical, 12)
        }
    }
}

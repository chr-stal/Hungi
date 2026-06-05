import SwiftUI

// MARK: - Hungi Design System
// Cottagecore / Studio Ghibli kitchen inspired: soft pastels, warm lavender,
// blush rose, sage mint, and buttery cream — cozy and cute ✿

enum HungiTheme {

    // MARK: Colors
    static let parchment  = Color(hex: "FFF8F0")   // warm blush white — main background
    static let cream      = Color(hex: "FFFBF5")   // softest cream — card / panel fill
    static let tan        = Color(hex: "F2D9C8")   // dusty rose peach — secondary surface
    static let woodBrown  = Color(hex: "A07898")   // muted mauve — navigation bars
    static let darkBrown  = Color(hex: "6B4C6B")   // deep plum — borders, text
    static let wheat      = Color(hex: "FFE8A3")   // pastel butter — gold highlights
    static let forest     = Color(hex: "85C4A8")   // soft mint — accept / success
    static let harvest    = Color(hex: "F4A7B9")   // blush rose — primary action
    static let terracotta = Color(hex: "E89BAE")   // dusty pink — decline / danger
    static let sage       = Color(hex: "B5D5C5")   // pale sage — info tint
    static let lavender   = Color(hex: "C9B8E8")   // soft lavender — accent / extra
    static let peach      = Color(hex: "FFD1BA")   // warm peach — extra surface tint

    // MARK: Typography  (rounded = friendlier, closer to the cozy aesthetic)
    static let largeTitle = Font.system(.largeTitle, design: .rounded, weight: .black)
    static let title      = Font.system(.title,      design: .rounded, weight: .bold)
    static let title2     = Font.system(.title2,     design: .rounded, weight: .bold)
    static let headline   = Font.system(.headline,   design: .rounded, weight: .bold)
    static let body       = Font.system(.body,       design: .rounded)
    static let caption    = Font.system(.caption,    design: .rounded, weight: .semibold)
    static let caption2   = Font.system(.caption2,   design: .rounded, weight: .bold)

    // MARK: Layout
    static let borderWidth: CGFloat  = 2.5  // slightly softer than before
    static let shadowX: CGFloat      = 2.5
    static let shadowY: CGFloat      = 3.5
    static let cardRadius: CGFloat   = 18   // rounder = cuter
    static let chipRadius: CGFloat   = 24
    static let buttonRadius: CGFloat = 12   // soft pill-ish buttons
}

// MARK: - Hex color init
extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var n: UInt64 = 0
        Scanner(string: h).scanHexInt64(&n)
        let r = Double((n >> 16) & 0xFF) / 255
        let g = Double((n >> 8)  & 0xFF) / 255
        let b = Double(n         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - View Modifiers

struct PixelBorder: ViewModifier {
    var color: Color    = HungiTheme.darkBrown
    var radius: CGFloat = HungiTheme.cardRadius
    var width: CGFloat  = HungiTheme.borderWidth

    func body(content: Content) -> some View {
        content
            .overlay(RoundedRectangle(cornerRadius: radius).stroke(color, lineWidth: width))
    }
}

struct PixelShadow: ViewModifier {
    var color: Color  = HungiTheme.lavender   // soft lavender shadow instead of dark brown
    var pressed: Bool = false

    func body(content: Content) -> some View {
        content
            .offset(y: pressed ? 1.5 : 0)
            .shadow(
                color: color.opacity(0.7),
                radius: 0,
                x: pressed ? 0 : HungiTheme.shadowX,
                y: pressed ? 0 : HungiTheme.shadowY
            )
    }
}

extension View {
    func pixelBorder(color: Color = HungiTheme.darkBrown,
                     radius: CGFloat = HungiTheme.cardRadius,
                     width: CGFloat = HungiTheme.borderWidth) -> some View {
        modifier(PixelBorder(color: color, radius: radius, width: width))
    }

    func pixelShadow(color: Color = HungiTheme.lavender, pressed: Bool = false) -> some View {
        modifier(PixelShadow(color: color, pressed: pressed))
    }
}

// MARK: - ButtonStyle

struct PixelButtonStyle: ButtonStyle {
    var background: Color = HungiTheme.harvest    // blush rose default
    var foreground: Color = HungiTheme.darkBrown  // plum text (readable on pastels)
    var radius: CGFloat   = HungiTheme.buttonRadius

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(HungiTheme.headline)
            .foregroundStyle(foreground)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(configuration.isPressed ? background.opacity(0.80) : background)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .overlay(RoundedRectangle(cornerRadius: radius).stroke(HungiTheme.darkBrown.opacity(0.6), lineWidth: 2))
            .offset(y: configuration.isPressed ? 1.5 : 0)
            .shadow(color: HungiTheme.lavender.opacity(0.8), radius: 0,
                    x: configuration.isPressed ? 0 : 2,
                    y: configuration.isPressed ? 0 : 3)
            .animation(.easeInOut(duration: 0.08), value: configuration.isPressed)
    }
}

// Circle variant for accept/decline buttons
struct PixelCircleButtonStyle: ButtonStyle {
    var background: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 60, height: 60)
            .background(configuration.isPressed ? background.opacity(0.75) : background)
            .clipShape(Circle())
            .overlay(Circle().stroke(HungiTheme.darkBrown.opacity(0.6), lineWidth: 2.5))
            .offset(y: configuration.isPressed ? 1.5 : 0)
            .shadow(color: HungiTheme.lavender.opacity(0.8), radius: 0,
                    x: configuration.isPressed ? 0 : 2.5,
                    y: configuration.isPressed ? 0 : 3.5)
            .animation(.easeInOut(duration: 0.08), value: configuration.isPressed)
    }
}

// MARK: - Cozy Extras ✿

// Soft gradient background — use as .background(HungiTheme.cozyGradient)
extension HungiTheme {
    static let cozyGradient = LinearGradient(
        colors: [
            Color(hex: "FFF0F5"),  // blush top
            Color(hex: "F0F5FF"),  // periwinkle bottom
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // Pastel chip / tag colors to cycle through for categories, tags, etc.
    static let chipPalette: [Color] = [
        Color(hex: "FFD6E0"),  // rose
        Color(hex: "D6F0E0"),  // mint
        Color(hex: "E8D6FF"),  // lilac
        Color(hex: "FFF0C8"),  // butter
        Color(hex: "D6EEFF"),  // sky
        Color(hex: "FFE6CC"),  // peach
    ]
}

//import SwiftUI
//
//// MARK: - Hungi Design System
//// Stardew Valley / Cooking Mama inspired: warm parchment, wood browns,
//// harvest greens, chunky pixel borders with offset shadows.
//
//enum HungiTheme {
//
//    // MARK: Colors
//    static let parchment  = Color(hex: "FAF0DC")   // main background
//    static let cream      = Color(hex: "FDF6E3")   // card / panel fill
//    static let tan        = Color(hex: "C4A882")   // secondary surface
//    static let woodBrown  = Color(hex: "7C4F2A")   // navigation bars
//    static let darkBrown  = Color(hex: "3D2B1F")   // borders, text
//    static let wheat      = Color(hex: "F5D55A")   // gold highlights
//    static let forest     = Color(hex: "5B8C3E")   // accept / success
//    static let harvest    = Color(hex: "E8741E")   // primary action
//    static let terracotta = Color(hex: "D45F3C")   // decline / danger
//    static let sage       = Color(hex: "7CB8A4")   // info tint
//
//    // MARK: Typography  (rounded = friendlier, closer to the game aesthetic)
//    static let largeTitle = Font.system(.largeTitle, design: .rounded, weight: .black)
//    static let title      = Font.system(.title,      design: .rounded, weight: .bold)
//    static let title2     = Font.system(.title2,     design: .rounded, weight: .bold)
//    static let headline   = Font.system(.headline,   design: .rounded, weight: .bold)
//    static let body       = Font.system(.body,       design: .rounded)
//    static let caption    = Font.system(.caption,    design: .rounded, weight: .semibold)
//    static let caption2   = Font.system(.caption2,   design: .rounded, weight: .bold)
//
//    // MARK: Layout
//    static let borderWidth: CGFloat  = 3
//    static let shadowX: CGFloat      = 3
//    static let shadowY: CGFloat      = 4
//    static let cardRadius: CGFloat   = 14
//    static let chipRadius: CGFloat   = 20
//    static let buttonRadius: CGFloat = 8
//}
//
//// MARK: - Hex color init
//extension Color {
//    init(hex: String) {
//        let h = hex.trimmingCharacters(in: .alphanumerics.inverted)
//        var n: UInt64 = 0
//        Scanner(string: h).scanHexInt64(&n)
//        let r = Double((n >> 16) & 0xFF) / 255
//        let g = Double((n >> 8)  & 0xFF) / 255
//        let b = Double(n         & 0xFF) / 255
//        self.init(red: r, green: g, blue: b)
//    }
//}
//
//// MARK: - View Modifiers
//
//struct PixelBorder: ViewModifier {
//    var color: Color    = HungiTheme.darkBrown
//    var radius: CGFloat = HungiTheme.cardRadius
//    var width: CGFloat  = HungiTheme.borderWidth
//
//    func body(content: Content) -> some View {
//        content
//            .overlay(RoundedRectangle(cornerRadius: radius).stroke(color, lineWidth: width))
//    }
//}
//
//struct PixelShadow: ViewModifier {
//    var color: Color  = HungiTheme.darkBrown
//    var pressed: Bool = false
//
//    func body(content: Content) -> some View {
//        content
//            .offset(y: pressed ? 2 : 0)
//            .shadow(
//                color: color,
//                radius: 0,
//                x: pressed ? 0 : HungiTheme.shadowX,
//                y: pressed ? 0 : HungiTheme.shadowY
//            )
//    }
//}
//
//extension View {
//    func pixelBorder(color: Color = HungiTheme.darkBrown,
//                     radius: CGFloat = HungiTheme.cardRadius,
//                     width: CGFloat = HungiTheme.borderWidth) -> some View {
//        modifier(PixelBorder(color: color, radius: radius, width: width))
//    }
//
//    func pixelShadow(color: Color = HungiTheme.darkBrown, pressed: Bool = false) -> some View {
//        modifier(PixelShadow(color: color, pressed: pressed))
//    }
//}
//
//// MARK: - ButtonStyle
//
//struct PixelButtonStyle: ButtonStyle {
//    var background: Color = HungiTheme.harvest
//    var foreground: Color = HungiTheme.cream
//    var radius: CGFloat   = HungiTheme.buttonRadius
//
//    func makeBody(configuration: Configuration) -> some View {
//        configuration.label
//            .font(HungiTheme.headline)
//            .foregroundStyle(foreground)
//            .padding(.horizontal, 20)
//            .padding(.vertical, 12)
//            .background(configuration.isPressed ? background.opacity(0.85) : background)
//            .clipShape(RoundedRectangle(cornerRadius: radius))
//            .overlay(RoundedRectangle(cornerRadius: radius).stroke(HungiTheme.darkBrown, lineWidth: 2.5))
//            .offset(y: configuration.isPressed ? 2 : 0)
//            .shadow(color: HungiTheme.darkBrown, radius: 0,
//                    x: configuration.isPressed ? 0 : 2,
//                    y: configuration.isPressed ? 0 : 3)
//            .animation(.easeInOut(duration: 0.08), value: configuration.isPressed)
//    }
//}
//
//// Circle variant for accept/decline buttons
//struct PixelCircleButtonStyle: ButtonStyle {
//    var background: Color
//
//    func makeBody(configuration: Configuration) -> some View {
//        configuration.label
//            .frame(width: 60, height: 60)
//            .background(configuration.isPressed ? background.opacity(0.8) : background)
//            .clipShape(Circle())
//            .overlay(Circle().stroke(HungiTheme.darkBrown, lineWidth: 3))
//            .offset(y: configuration.isPressed ? 2 : 0)
//            .shadow(color: HungiTheme.darkBrown, radius: 0,
//                    x: configuration.isPressed ? 0 : 3,
//                    y: configuration.isPressed ? 0 : 4)
//            .animation(.easeInOut(duration: 0.08), value: configuration.isPressed)
//    }
//}

import SwiftUI

/// String constants for meal type tags stored on Recipe.
enum MealType {
    static let breakfast = "breakfast"
    static let lunch     = "lunch"
    static let dinner    = "dinner"
    static let any       = "any"

    static let all: [String] = [breakfast, lunch, dinner, any]

    static func displayName(for type: String) -> String {
        switch type {
        case breakfast: return "Breakfast"
        case lunch:     return "Lunch"
        case dinner:    return "Dinner"
        default:        return "Any Meal"
        }
    }

    static func icon(for type: String) -> String {
        switch type {
        case breakfast: return "sunrise.fill"
        case lunch:     return "sun.max.fill"
        case dinner:    return "moon.stars.fill"
        default:        return "fork.knife"
        }
    }

    static func color(for type: String) -> Color {
        switch type {
        case breakfast: return .orange
        case lunch:     return Color(red: 0.9, green: 0.75, blue: 0)
        case dinner:    return .indigo
        default:        return .gray
        }
    }
}

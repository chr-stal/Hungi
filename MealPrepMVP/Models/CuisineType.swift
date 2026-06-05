import Foundation

struct CuisineType {
    static let options: [(name: String, emoji: String)] = [
        ("American",       "🍔"),
        ("Italian",        "🍝"),
        ("Asian",          "🥢"),
        ("Japanese",       "🍱"),
        ("Mexican",        "🌮"),
        ("Mediterranean",  "🫒"),
        ("Indian",         "🍛"),
        ("Thai",           "🥜"),
        ("Chinese",        "🥡"),
        ("Greek",          "🏛️"),
        ("Middle Eastern", "🥙"),
    ]

    static var names: [String] { options.map(\.name) }

    static func emoji(for cuisine: String) -> String {
        options.first { $0.name == cuisine }?.emoji ?? "🍽️"
    }
}

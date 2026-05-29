import SwiftData
import Foundation

@Model
final class PantryItem {
    var name: String
    var quantity: String
    var unit: String
    var createdAt: Date

    init(name: String, quantity: String = "", unit: String = "") {
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.createdAt = Date()
    }

    /// Display-friendly quantity string, e.g. "2 cups" or just "2"
    var displayQuantity: String {
        guard !quantity.isEmpty else { return unit.isEmpty ? "" : unit }
        return unit.isEmpty ? quantity : "\(quantity) \(unit)"
    }
}

// MARK: - Shared unit options
enum ItemUnit {
    static let options: [String] = [
        "", "whole", "cups", "tbsp", "tsp",
        "oz", "lbs", "g", "kg",
        "ml", "L",
        "pieces", "cloves", "slices", "cans", "bags"
    ]

    static func label(for unit: String) -> String {
        unit.isEmpty ? "unit" : unit
    }
}

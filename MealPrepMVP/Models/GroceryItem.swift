import SwiftData
import Foundation

@Model
final class GroceryItem {
    var name: String
    var quantity: String
    var unit: String
    var isChecked: Bool
    var createdAt: Date

    init(name: String, quantity: String = "", unit: String = "") {
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.isChecked = false
        self.createdAt = Date()
    }

    var displayQuantity: String {
        guard !quantity.isEmpty else { return unit.isEmpty ? "" : unit }
        return unit.isEmpty ? quantity : "\(quantity) \(unit)"
    }
}

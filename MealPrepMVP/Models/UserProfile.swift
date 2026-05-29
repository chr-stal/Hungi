import SwiftData
import Foundation

@Model
final class UserProfile {
    var name: String
    var createdAt: Date

    init(name: String) {
        self.name = name
        self.createdAt = Date()
    }
}

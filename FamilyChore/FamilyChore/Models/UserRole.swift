import Foundation

/// Defines the possible roles a user can have within the app.
enum UserRole: String, Codable, CaseIterable {
    case parent = "Parent"
    case child = "Child"

    // Provides a user-friendly display name
    var displayName: String {
        return self.rawValue
    }
}
import Foundation
import FirebaseFirestore // Required for @DocumentID

/// Represents a user's profile information stored in Firestore.
struct UserProfile: Codable, Identifiable {
    /// The unique identifier for the user, typically the Firebase Auth UID.
    /// This property is automatically populated by Firestore when fetching data.
    @DocumentID var id: String?

    /// The user's email address used for login.
    var email: String

    /// The role assigned to the user (Parent or Child).
    var role: UserRole

    /// The identifier of the family this user belongs to. Optional for initial parent signup.
    var familyId: String?

    /// URL string pointing to the user's profile picture in Firebase Storage. Optional.
    var profilePictureUrl: String?

    /// The user's display name (e.g., Child's name). Optional, might be added later.
    var name: String? // Added name field as it's useful, especially for children

    /// The user's Points (e.g., Child's points). Optional, might be added later.
    var points: Int32? // Added name field as it's useful, especially for children

    // Example initializer (optional, Codable provides one)
    init(id: String? = nil, email: String, role: UserRole, familyId: String? = nil, profilePictureUrl: String? = nil, name: String? = nil, points: Int32? = 0) {
        self.id = id
        self.email = email
        self.role = role
        self.familyId = familyId
        self.profilePictureUrl = profilePictureUrl
        self.name = name
        self.points = points
    }
}

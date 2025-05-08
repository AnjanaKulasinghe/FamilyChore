import Foundation
// FirebaseFirestore import removed as it's not directly used in this model
// and was causing a "No such module" error.
// Interactions with Firestore are likely handled by FirebaseService.swift.

/// Represents a child user within a family, extending basic user profile info.
/// Note: This might be redundant if UserProfile contains all necessary child info.
/// Consider if a separate Child model is truly needed or if UserProfile with role 'child' suffices.
/// For now, creating as per the plan.
struct Child: Codable, Identifiable {
    /// Corresponds to the UserProfile ID (Firebase Auth UID) for this child.
    var id: String

    /// The child's name.
    var name: String

    /// URL string for the child's profile picture.
    var profilePictureUrl: String?

    /// Points accumulated by the child from completed tasks.
    var points: Int = 0

    // Link back to UserProfile if needed, though 'id' should match UserProfile.id
    // var userProfileId: String // Could explicitly store this
}